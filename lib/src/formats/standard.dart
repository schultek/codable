import 'package:codable/core.dart';
import 'package:codable/extended.dart';

extension StandardDecodable<T> on Decodable<T> {
  T fromValue(Object? value) {
    return StandardDecoder.decode<T>(value, this);
  }

  T fromMap(Map<String, dynamic> map) {
    return StandardDecoder.decode<T>(map, this);
  }
}

extension StandardEncodable<T> on Encodable<T> {
  Object? toValue(T value) {
    return StandardEncoder.encode<T>(value, this);
  }

  Map<String, dynamic> toMap(T value) {
    return StandardEncoder.encode<T>(value, this) as Map<String, dynamic>;
  }
}

extension StandardSelfEncodable<T extends SelfEncodable> on T {
  Object? toValue() {
    return StandardEncoder.encode<T>(this, Encodable.self());
  }

  Map<String, dynamic> toMap() {
    return StandardEncoder.encode<T>(this, Encodable.self()) as Map<String, dynamic>;
  }
}

abstract class _StandardDecoder {
  _StandardDecoder([this._isHumanReadable = true, this._customTypes = const []]);

  final bool _isHumanReadable;
  final List<CustomTypeDelegate> _customTypes;

  bool isHumanReadable() {
    return _isHumanReadable;
  }

  @pragma('vm:prefer-inline')
  DecodingType _whatsNext(Object? value) {
    return switch (value) {
      null => DecodingType.nil,
      int() => DecodingType.int,
      double() => DecodingType.double,
      String() => DecodingType.string,
      bool() => DecodingType.bool,
      Map() => DecodingType.map,
      List() => DecodingType.list,
      final v => _customTypes.whatsNext(v) ?? DecodingType.unknown,
    };
  }

  @pragma('vm:prefer-inline')
  V _decode<V>(dynamic value, Decodable<V> decodable) {
    return StandardDecoder._(value, _isHumanReadable, _customTypes).decodeObject(using: decodable);
  }

  @pragma('vm:prefer-inline')
  List<E> _decodeList<E>(List value, Decodable<E>? using) {
    if (using == null) return value.cast<E>();
    final list = <E>[];
    var i = 0;
    try {
      for (; i < value.length; i++) {
        list.add(_decode(value[i], using));
      }
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: '[$i]'), st);
    }
    return list;
  }

  @pragma('vm:prefer-inline')
  Map<K, V> _decodeMap<K, V>(Map value, Decodable<K>? keyUsing, Decodable<V>? valueUsing) {
    try {
      return switch ((keyUsing, valueUsing)) {
        (null, null) => value.cast<K, V>(),
        (final ku?, null) => value.map((key, value) => MapEntry(_decode(key, ku), value as V)),
        (null, final vu?) => value.map((key, value) => MapEntry(key as K, _decode(value, vu))),
        (final ku?, final vu?) => value.map((key, value) => MapEntry(_decode(key, ku), _decode(value, vu))),
      };
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: 'Map'), st);
    }
  }

  @pragma('vm:prefer-inline')
  T _decodeCustom<T>(dynamic value) {
    if (value is T) return value;
    final delegate = _customTypes.whereType<CustomTypeDelegate<T>>().firstOrNull;
    if (delegate == null) {
      throw CodableException.unsupportedMethod('StandardDecoder', 'decodeCustom<$T>',
          reason: 'No custom type delegate was provided for type $T.');
    }
    return _decode(value, delegate);
  }
}

class StandardDecoder extends _StandardDecoder implements Decoder {
  StandardDecoder._(this._value, [super._isHumanReadable, super._customTypes]);

  final Object? _value;

  static T decode<T>(
    Object? value,
    Decodable<T> decodable, {
    bool isHumanReadable = true,
    List<CustomTypeDelegate> customTypes = const [],
  }) {
    return StandardDecoder._(value, isHumanReadable, customTypes).decodeObject(using: decodable);
  }

  @pragma('vm:prefer-inline')
  @override
  T decodeObject<T>({required Decodable<T> using}) {
    try {
      return using.decode(this);
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: '$T'), st);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  T? decodeObjectOrNull<T>({required Decodable<T> using}) {
    if (_value == null) return null;
    try {
      return using.decode(this);
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: '$T'), st);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  bool decodeBool() {
    try {
      return _value as bool;
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'bool', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  bool? decodeBoolOrNull() {
    try {
      return _value as bool?;
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'bool?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  double decodeDouble() {
    try {
      return (_value as num).toDouble();
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'double', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  double? decodeDoubleOrNull() {
    try {
      return (_value as num?)?.toDouble();
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'double?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  int decodeInt() {
    try {
      return (_value as num).toInt();
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'int', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  int? decodeIntOrNull() {
    try {
      return (_value as num?)?.toInt();
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'int?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  List<I> decodeList<I>({Decodable<I>? using}) {
    try {
      return _decodeList(_value as List, using);
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'List<$I>', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  List<I>? decodeListOrNull<I>({Decodable<I>? using}) {
    if (_value == null) return null;
    try {
      return _decodeList(_value as List, using);
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'List<$I>?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  Map<K, V> decodeMap<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    try {
      return _decodeMap(_value as Map, keyUsing, valueUsing);
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'Map<$K, $V>', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  Map<K, V>? decodeMapOrNull<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    if (_value == null) return null;
    try {
      return _decodeMap(_value as Map, keyUsing, valueUsing);
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'Map<$K, $V>?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  num decodeNum() {
    try {
      return _value as num;
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'num', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  num? decodeNumOrNull() {
    try {
      return _value as num?;
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'num?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  String decodeString() {
    try {
      return _value as String;
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'String', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  String? decodeStringOrNull() {
    try {
      return _value as String?;
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'String?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  bool decodeIsNull() {
    return _value == null;
  }

  @pragma('vm:prefer-inline')
  @override
  Decoder clone() {
    return this;
  }

  @pragma('vm:prefer-inline')
  @override
  dynamic decodeDynamic() {
    return _value;
  }

  @pragma('vm:prefer-inline')
  @override
  IteratedDecoder decodeIterated() {
    try {
      return StandardIteratedDecoder._(_value as List, _isHumanReadable, _customTypes);
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'List', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  KeyedDecoder decodeKeyed() {
    return CompatKeyedDecoder.wrap(decodeMapped());
  }

  @pragma('vm:prefer-inline')
  @override
  MappedDecoder decodeMapped() {
    try {
      return StandardMappedDecoder(_value as Map<Object, dynamic>, _isHumanReadable, _customTypes);
    } on TypeError {
      throw CodableException.unexpectedType(
          expected: 'Map<Object, dynamic>', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  Never expect(String expected) {
    throw CodableException.unexpectedType(expected: expected, actual: '${_value.runtimeType}', data: _value);
  }

  @pragma('vm:prefer-inline')
  @override
  DecodingType whatsNext() {
    return _whatsNext(_value);
  }

  @pragma('vm:prefer-inline')
  @override
  T decodeCustom<T>() {
    return _decodeCustom<T>(_value);
  }

  @override
  T? decodeCustomOrNull<T>() {
    if (_value == null) return null;
    return _decodeCustom<T>(_value);
  }
}

class StandardMappedDecoder extends _StandardDecoder implements MappedDecoder {
  StandardMappedDecoder(this._value, [super._isHumanReadable, super._customTypes]);

  final Map<Object, dynamic> _value;

  @pragma('vm:prefer-inline')
  @override
  T decodeObject<T>(String key, {int? id, required Decodable<T> using}) {
    try {
      return _decode(_value[key], using);
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: '["$key"]'), st);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  T? decodeObjectOrNull<T>(String key, {int? id, required Decodable<T> using}) {
    final v = _value[key];
    if (v == null) return null;
    try {
      return _decode(v, using);
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: '["$key"]'), st);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  bool decodeBool(String key, {int? id}) {
    try {
      return _value[key] as bool;
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(expected: 'bool', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    }
  }

  @pragma('vm:prefer-inline')
  @override
  bool? decodeBoolOrNull(String key, {int? id}) {
    try {
      return _value[key] as bool?;
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(expected: 'bool?', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    }
  }

  @pragma('vm:prefer-inline')
  @override
  double decodeDouble(String key, {int? id}) {
    try {
      return (_value[key] as num).toDouble();
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(expected: 'double', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    }
  }

  @pragma('vm:prefer-inline')
  @override
  double? decodeDoubleOrNull(String key, {int? id}) {
    try {
      return (_value[key] as num?)?.toDouble();
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(expected: 'double?', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    }
  }

  @pragma('vm:prefer-inline')
  @override
  int decodeInt(String key, {int? id}) {
    try {
      return (_value[key] as num).toInt();
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(expected: 'int', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    }
  }

  @pragma('vm:prefer-inline')
  @override
  int? decodeIntOrNull(String key, {int? id}) {
    try {
      return (_value[key] as num?)?.toInt();
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(expected: 'int?', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    }
  }

  @pragma('vm:prefer-inline')
  @override
  List<E> decodeList<E>(String key, {int? id, Decodable<E>? using}) {
    try {
      final v = _value[key] as List;
      return _decodeList(v, using);
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(expected: 'List', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: '["$key"]'), st);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  List<E>? decodeListOrNull<E>(String key, {int? id, Decodable<E>? using}) {
    if (_value[key] == null) return null;
    return decodeList(key, id: id, using: using);
  }

  @pragma('vm:prefer-inline')
  @override
  Map<K, V> decodeMap<K, V>(String key, {int? id, Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    try {
      return _decodeMap(_value[key] as Map, keyUsing, valueUsing);
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(
            expected: 'Map<$K, $V>', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: '["$key"]'), st);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  Map<K, V>? decodeMapOrNull<K, V>(String key, {int? id, Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    if (_value[key] == null) return null;
    return decodeMap(key, id: id, keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @pragma('vm:prefer-inline')
  @override
  num decodeNum(String key, {int? id}) {
    try {
      return _value[key] as num;
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(expected: 'num', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    }
  }

  @pragma('vm:prefer-inline')
  @override
  num? decodeNumOrNull(String key, {int? id}) {
    try {
      return _value[key] as num?;
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(expected: 'num?', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    }
  }

  @pragma('vm:prefer-inline')
  @override
  String decodeString(String key, {int? id}) {
    try {
      return _value[key] as String;
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(expected: 'String', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    }
  }

  @pragma('vm:prefer-inline')
  @override
  String? decodeStringOrNull(String key, {int? id}) {
    try {
      return _value[key] as String?;
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(expected: 'String?', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    }
  }

  @pragma('vm:prefer-inline')
  @override
  dynamic decodeDynamic(String key, {int? id}) {
    return _value[key];
  }

  @pragma('vm:prefer-inline')
  @override
  DecodingType whatsNext(String key, {int? id}) {
    return _whatsNext(_value[key]);
  }

  @pragma('vm:prefer-inline')
  @override
  Iterable<Object> get keys => _value.keys;

  @pragma('vm:prefer-inline')
  @override
  IteratedDecoder decodeIterated(String key, {int? id}) {
    try {
      return StandardIteratedDecoder._(_value[key] as List, _isHumanReadable, _customTypes);
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(expected: 'List', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    }
  }

  @pragma('vm:prefer-inline')
  @override
  KeyedDecoder decodeKeyed(String key, {int? id}) {
    return CompatKeyedDecoder.wrap(decodeMapped(key));
  }

  @pragma('vm:prefer-inline')
  @override
  MappedDecoder decodeMapped(String key, {int? id}) {
    try {
      return StandardMappedDecoder(_value[key] as Map<Object, dynamic>, _isHumanReadable, _customTypes);
    } on TypeError {
      throw CodableException.wrap(
        CodableException.unexpectedType(
            expected: 'Map<Object, dynamic>', actual: '${_value[key].runtimeType}', data: _value[key]),
        method: 'decode',
        hint: '["$key"]',
      );
    }
  }

  @pragma('vm:prefer-inline')
  @override
  Never expect(String key, String expected, {int? id}) {
    throw CodableException.wrap(
      CodableException.unexpectedType(expected: expected, actual: '${_value[key].runtimeType}', data: _value[key]),
      method: 'decode',
      hint: '["$key"]',
    );
  }

  @pragma('vm:prefer-inline')
  @override
  bool decodeIsNull(String key, {int? id}) {
    return _value.containsKey(key) && _value[key] == null;
  }

  @pragma('vm:prefer-inline')
  @override
  T decodeCustom<T>(String key, {int? id}) {
    try {
      return _decodeCustom<T>(_value[key]);
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: '["$key"]'), st);
    }
  }

  @override
  T? decodeCustomOrNull<T>(String key, {int? id}) {
    if (_value[key] == null) return null;
    try {
      return _decodeCustom<T>(_value[key]);
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: '["$key"]'), st);
    }
  }
}

class StandardIteratedDecoder extends StandardDecoder implements IteratedDecoder {
  StandardIteratedDecoder._(this.__value,
      [bool _isHumanReadable = true, List<CustomTypeDelegate> _customTypes = const [], this._index = 0])
      : super._(null, _isHumanReadable, _customTypes);

  final List __value;
  int _index;

  @override
  Object? get _value => __value[_index];

  @override
  bool nextItem() {
    _index++;
    return _index < __value.length;
  }

  @override
  void skipCurrentItem() {
    // Do nothing
  }

  @override
  void skipRemainingItems() {
    _index = __value.length;
  }

  @override
  IteratedDecoder clone() {
    return StandardIteratedDecoder._(__value, _isHumanReadable, _customTypes, _index);
  }
}

abstract class _StandardEncoder {
  _StandardEncoder([this._isHumanReadable = true, this._customTypes = const []]);

  final bool _isHumanReadable;
  final List<CustomTypeDelegate> _customTypes;

  bool isHumanReadable() {
    return _isHumanReadable;
  }

  bool canEncodeCustom<T>() {
    return _customTypes.whereType<CustomTypeDelegate<T>>().isNotEmpty;
  }

  @pragma('vm:prefer-inline')
  Object? _encode<V>(V value, Encodable<V> encodable) {
    final encoder = StandardEncoder(_isHumanReadable, _customTypes);
    encodable.encode(value, encoder);
    return encoder._value;
  }

  @pragma('vm:prefer-inline')
  Map _encodeMap<K, V>(Map<K, V> value, Encodable<K>? keyUsing, Encodable<V>? valueUsing) {
    return switch ((keyUsing, valueUsing)) {
      (null, null) => value,
      (final k?, null) => value.map((key, value) => MapEntry(_encode(key, k), value)),
      (null, final v?) => value.map((key, value) => MapEntry(key, _encode(value, v))),
      (final k?, final v?) => value.map((key, value) => MapEntry(_encode(key, k), _encode(value, v))),
    };
  }

  @pragma('vm:prefer-inline')
  dynamic _encodeCustom<T>(T value) {
    final delegate = _customTypes.whereType<CustomTypeDelegate<T>>().firstOrNull;
    if (delegate == null) {
      throw CodableException.unsupportedMethod('StandardEncoder', 'encodeCustom<$T>',
          reason: 'No custom type delegate was provided for type $T.');
    }
    return _encode(value, delegate);
  }
}

class StandardEncoder extends _StandardEncoder implements Encoder {
  StandardEncoder([super._isHumanReadable, super._customTypes]);

  Object? _value;

  static Object? encode<T>(
    T value,
    Encodable<T> encodable, {
    bool isHumanReadable = true,
    List<CustomTypeDelegate> customTypes = const [],
  }) {
    final encoder = StandardEncoder(isHumanReadable, customTypes);
    encodable.encode(value, encoder);
    return encoder._value;
  }

  @override
  void encodeBool(bool value) {
    _value = value;
  }

  @override
  IteratedEncoder encodeIterated() {
    return StandardIteratedEncoder._(_value = <dynamic>[], _isHumanReadable, _customTypes);
  }

  @override
  void encodeDouble(double value) {
    _value = value;
  }

  @override
  void encodeInt(int value) {
    _value = value;
  }

  @override
  void encodeIterable<E>(Iterable<E> value, {Encodable<E>? using}) {
    if (using == null) {
      _value = value;
      return;
    }
    _value = value.map((e) => _encode(e, using)).toList();
  }

  @override
  KeyedEncoder encodeKeyed() {
    return StandardKeyedEncoder._(_value = <String, dynamic>{}, _isHumanReadable, _customTypes);
  }

  @override
  void encodeMap<K, V>(Map<K, V> value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _value = _encodeMap(value, keyUsing, valueUsing);
  }

  @override
  void encodeNull() {
    _value = null;
  }

  @override
  void encodeNum(num value) {
    _value = value;
  }

  @override
  void encodeObject<T>(T value, {required Encodable<T> using}) {
    using.encode(value, this);
  }

  @override
  void encodeString(String value) {
    _value = value;
  }

  @override
  void encodeCustom<T>(T value) {
    _value = _encodeCustom<T>(value);
  }

  @override
  void encodeDynamic(dynamic value) {
    _value = value;
  }

  @override
  void encodeBoolOrNull(bool? value) {
    _value = value;
  }

  @override
  void encodeCustomOrNull<T>(T? value) {
    if (value == null) {
      _value = null;
      return;
    }
    _value = _encodeCustom<T>(value);
  }

  @override
  void encodeDoubleOrNull(double? value) {
    _value = value;
  }

  @override
  void encodeIntOrNull(int? value) {
    _value = value;
  }

  @override
  void encodeIterableOrNull<E>(Iterable<E>? value, {Encodable<E>? using}) {
    if (value == null) {
      _value = null;
      return;
    }
    encodeIterable(value, using: using);
  }

  @override
  void encodeMapOrNull<K, V>(Map<K, V>? value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    if (value == null) {
      _value = null;
      return;
    }
    _encodeMap(value, keyUsing, valueUsing);
  }

  @override
  void encodeNumOrNull(num? value) {
    _value = value;
  }

  @override
  void encodeObjectOrNull<T>(T? value, {required Encodable<T> using}) {
    if (value == null) {
      _value = null;
      return;
    }
    using.encode(value, this);
  }

  @override
  void encodeStringOrNull(String? value) {
    _value = value;
  }
}

class StandardIteratedEncoder extends _StandardEncoder implements IteratedEncoder {
  StandardIteratedEncoder._(this._value, [super._isHumanReadable, super._customTypes]);

  final List<dynamic> _value;

  @override
  void encodeBool(bool value) {
    _value.add(value);
  }

  @override
  IteratedEncoder encodeIterated() {
    final list = <dynamic>[];
    _value.add(list);
    return StandardIteratedEncoder._(list, _isHumanReadable, _customTypes);
  }

  @override
  void encodeDouble(double value) {
    _value.add(value);
  }

  @override
  void encodeInt(int value) {
    _value.add(value);
  }

  @override
  void encodeIterable<E>(Iterable<E> value, {Encodable<E>? using}) {
    if (using == null) {
      _value.add(value);
      return;
    }
    _value.add(value.map((e) => _encode(e, using)).toList());
  }

  @override
  KeyedEncoder encodeKeyed() {
    final map = <String, dynamic>{};
    _value.add(map);
    return StandardKeyedEncoder._(map, _isHumanReadable, _customTypes);
  }

  @override
  void encodeMap<K, V>(Map<K, V> value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _value.add(_encodeMap(value, keyUsing, valueUsing));
  }

  @override
  void encodeNull() {
    _value.add(null);
  }

  @override
  void encodeNum(num value) {
    _value.add(value);
  }

  @override
  void encodeObject<T>(T value, {required Encodable<T> using}) {
    using.encode(value, this);
  }

  @override
  void encodeString(String value) {
    _value.add(value);
  }

  @override
  void end() {
    // Do nothing
  }

  @override
  void encodeCustom<T>(T value) {
    _value.add(_encodeCustom<T>(value));
  }

  @override
  void encodeDynamic(dynamic value) {
    _value.add(value);
  }

  @override
  void encodeBoolOrNull(bool? value) {
    _value.add(value);
  }

  @override
  void encodeCustomOrNull<T>(T? value) {
    if (value == null) {
      _value.add(null);
      return;
    }
    _value.add(_encodeCustom<T>(value));
  }

  @override
  void encodeDoubleOrNull(double? value) {
    _value.add(value);
  }

  @override
  void encodeIntOrNull(int? value) {
    _value.add(value);
  }

  @override
  void encodeIterableOrNull<E>(Iterable<E>? value, {Encodable<E>? using}) {
    if (value == null) {
      _value.add(null);
      return;
    }
    encodeIterable(value, using: using);
  }

  @override
  void encodeMapOrNull<K, V>(Map<K, V>? value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    if (value == null) {
      _value.add(null);
      return;
    }
    _value.add(_encodeMap(value, keyUsing, valueUsing));
  }

  @override
  void encodeNumOrNull(num? value) {
    _value.add(value);
  }

  @override
  void encodeObjectOrNull<T>(T? value, {required Encodable<T> using}) {
    if (value == null) {
      _value.add(null);
      return;
    }
    using.encode(value, this);
  }

  @override
  void encodeStringOrNull(String? value) {
    _value.add(value);
  }
}

class StandardKeyedEncoder extends _StandardEncoder implements KeyedEncoder {
  StandardKeyedEncoder._(this._value, [super._isHumanReadable, super._customTypes]);

  final Map<String, dynamic> _value;

  @override
  void encodeBool(String key, bool value, {int? id}) {
    _value[key] = value;
  }

  @override
  IteratedEncoder encodeIterated(String key, {int? id}) {
    return StandardIteratedEncoder._(_value[key] = <dynamic>[], _isHumanReadable, _customTypes);
  }

  @override
  void encodeDouble(String key, double value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeInt(String key, int value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeIterable<E>(String key, Iterable<E> value, {int? id, Encodable<E>? using}) {
    if (using == null) {
      _value[key] = value;
      return;
    }
    _value[key] = [for (final e in value) _encode(e, using)];
  }

  @override
  KeyedEncoder encodeKeyed(String key, {int? id}) {
    return StandardKeyedEncoder._(_value[key] = <String, dynamic>{}, _isHumanReadable, _customTypes);
  }

  @override
  void encodeMap<K, V>(String key, Map<K, V> value, {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _value[key] = _encodeMap(value, keyUsing, valueUsing);
  }

  @override
  void encodeNull(String key, {int? id}) {
    _value[key] = null;
  }

  @override
  void encodeNum(String key, num value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeObject<T>(String key, T value, {int? id, required Encodable<T> using}) {
    _value[key] = _encode(value, using);
  }

  @override
  void encodeString(String key, String value, {int? id}) {
    _value[key] = value;
  }

  @override
  void end() {
    // Do nothing
  }

  @override
  void encodeCustom<T>(String key, T value, {int? id}) {
    _value[key] = _encodeCustom(value);
  }

  @override
  void encodeDynamic(String key, Object? value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeBoolOrNull(String key, bool? value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeCustomOrNull<T>(String key, T? value, {int? id}) {
    if (value == null) {
      _value[key] = null;
      return;
    }
    _value[key] = _encodeCustom(value);
  }

  @override
  void encodeDoubleOrNull(String key, double? value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeIntOrNull(String key, int? value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeIterableOrNull<E>(String key, Iterable<E>? value, {int? id, Encodable<E>? using}) {
    if (value == null) {
      _value[key] = null;
      return;
    }
    encodeIterable(key, value, id: id, using: using);
  }

  @override
  void encodeMapOrNull<K, V>(String key, Map<K, V>? value,
      {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    if (value == null) {
      _value[key] = null;
      return;
    }
    _value[key] = _encodeMap(value, keyUsing, valueUsing);
  }

  @override
  void encodeNumOrNull(String key, num? value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeObjectOrNull<T>(String key, T? value, {int? id, required Encodable<T> using}) {
    if (value == null) {
      _value[key] = null;
      return;
    }
    _value[key] = _encode(value, using);
  }

  @override
  void encodeStringOrNull(String key, String? value, {int? id}) {
    _value[key] = value;
  }
}
