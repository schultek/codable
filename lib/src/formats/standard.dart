import 'package:codable/core.dart';
import 'package:codable/extended.dart';

extension StandardDecodable<T> on Decodable<T> {
  T fromValue(Object? value) {
    return StandardDecoder.decode<T>(value, using: this);
  }

  T fromMap(Map<String, dynamic> map) => fromValue(map);
}

extension StandardEncodable<T> on Encodable<T> {
  Object? toValue(T value) {
    return StandardEncoder.encode<T>(value, using: this);
  }

  Map<String, dynamic> toMap(T value) => toValue(value) as Map<String, dynamic>;
}

extension StandardSelfEncodable<T extends SelfEncodable> on T {
  Object? toValue() {
    return StandardEncoder.encode<T>(this);
  }

  Map<String, dynamic> toMap() => toValue() as Map<String, dynamic>;
}

abstract class _StandardDecoder {
  _StandardDecoder([this._isHumanReadable = true, this._customTypes = const []]);

  final bool _isHumanReadable;
  final List<CustomTypeDelegate> _customTypes;

  bool isHumanReadable() {
    return _isHumanReadable;
  }

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

  V _decode<V>(dynamic value, Decodable<V>? decodable) {
    return StandardDecoder._(value, _isHumanReadable, _customTypes).decodeObject(using: decodable);
  }

  List<E> _decodeList<E>(List value, Decodable<E>? using) {
    if (using == null) {
      return value.cast<E>();
    }
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

  Map<K, V> _decodeMap<K, V>(Map value, Decodable<K>? keyUsing, Decodable<V>? valueUsing) {
    try {
      return value.map((key, value) => MapEntry(_decode(key, keyUsing), _decode(value, valueUsing)));
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: 'Map'), st);
    }
  }
}

class StandardDecoder extends _StandardDecoder implements Decoder {
  StandardDecoder._(this._value, [super._isHumanReadable, super._customTypes]);

  final Object? _value;

  static T decode<T>(
    Object? value, {
    Decodable<T>? using,
    bool isHumanReadable = true,
    List<CustomTypeDelegate> customTypes = const [],
  }) {
    return StandardDecoder._(value, isHumanReadable, customTypes).decodeObject(using: using);
  }

  @override
  DecodingType whatsNext() {
    return _whatsNext(_value);
  }

  @override
  bool decodeBool() {
    try {
      return _value as bool;
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'bool', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  bool? decodeBoolOrNull() {
    try {
      return _value as bool?;
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'bool?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  int decodeInt() {
    try {
      return (_value as num).toInt();
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'int', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  int? decodeIntOrNull() {
    try {
      return (_value as num?)?.toInt();
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'int?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  double decodeDouble() {
    try {
      return (_value as num).toDouble();
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'double', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  double? decodeDoubleOrNull() {
    try {
      return (_value as num?)?.toDouble();
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'double?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  num decodeNum() {
    try {
      return _value as num;
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'num', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  num? decodeNumOrNull() {
    try {
      return _value as num?;
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'num?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  String decodeString() {
    try {
      return _value as String;
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'String', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  String? decodeStringOrNull() {
    try {
      return _value as String?;
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'String?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  bool decodeIsNull() {
    return _value == null;
  }

  @override
  T decodeObject<T>({Decodable<T>? using}) {
    try {
      if (using != null) {
        return using.decode(this);
      }
      final delegate = _customTypes.whereType<CustomTypeDelegate<T>>().firstOrNull;
      if (delegate != null) {
        return delegate.decode(this);
      }
      return _value as T;
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: '$T'), st);
    }
  }

  @override
  T? decodeObjectOrNull<T>({Decodable<T>? using}) {
    if (_value == null) return null;
    return decodeObject(using: using);
  }

  @override
  List<I> decodeList<I>({Decodable<I>? using}) {
    try {
      return _decodeList(_value as List, using);
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'List<$I>', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  List<I>? decodeListOrNull<I>({Decodable<I>? using}) {
    if (_value == null) return null;
    try {
      return _decodeList(_value as List, using);
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'List<$I>?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  Map<K, V> decodeMap<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    try {
      return _decodeMap(_value as Map, keyUsing, valueUsing);
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'Map<$K, $V>', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  Map<K, V>? decodeMapOrNull<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    if (_value == null) return null;
    try {
      return _decodeMap(_value as Map, keyUsing, valueUsing);
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'Map<$K, $V>?', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  IteratedDecoder decodeIterated() {
    try {
      return StandardIteratedDecoder._(_value as List, _isHumanReadable, _customTypes);
    } on TypeError {
      throw CodableException.unexpectedType(expected: 'List', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  KeyedDecoder decodeKeyed() {
    return CompatKeyedDecoder.wrap(decodeMapped());
  }

  @override
  MappedDecoder decodeMapped() {
    try {
      return StandardMappedDecoder(_value as Map<Object, dynamic>, _isHumanReadable, _customTypes);
    } on TypeError {
      throw CodableException.unexpectedType(
          expected: 'Map<Object, dynamic>', actual: '${_value.runtimeType}', data: _value);
    }
  }

  @override
  Decoder clone() {
    return this;
  }

  @override
  Never expect(String expected) {
    throw CodableException.unexpectedType(expected: expected, actual: '${_value.runtimeType}', data: _value);
  }
}

class StandardMappedDecoder extends _StandardDecoder implements MappedDecoder {
  StandardMappedDecoder(this._value, [super._isHumanReadable, super._customTypes]);

  final Map<Object, dynamic> _value;

  @override
  DecodingType whatsNext(String key, {int? id}) {
    return _whatsNext(_value[key]);
  }

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

  @override
  bool decodeIsNull(String key, {int? id}) {
    return _value.containsKey(key) && _value[key] == null;
  }

  @override
  T decodeObject<T>(String key, {int? id, Decodable<T>? using}) {
    try {
      return _decode(_value[key], using);
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: '["$key"]'), st);
    }
  }

  @override
  T? decodeObjectOrNull<T>(String key, {int? id, Decodable<T>? using}) {
    final v = _value[key];
    if (v == null) return null;
    try {
      return _decode(v, using);
    } catch (e, st) {
      Error.throwWithStackTrace(CodableException.wrap(e, method: 'decode', hint: '["$key"]'), st);
    }
  }

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

  @override
  List<E>? decodeListOrNull<E>(String key, {int? id, Decodable<E>? using}) {
    if (_value[key] == null) return null;
    return decodeList(key, id: id, using: using);
  }

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

  @override
  Map<K, V>? decodeMapOrNull<K, V>(String key, {int? id, Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    if (_value[key] == null) return null;
    return decodeMap(key, id: id, keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @override
  Iterable<Object> get keys => _value.keys;

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

  @override
  KeyedDecoder decodeKeyed(String key, {int? id}) {
    return CompatKeyedDecoder.wrap(decodeMapped(key));
  }

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

  @override
  Never expect(String key, String expected, {int? id}) {
    throw CodableException.wrap(
      CodableException.unexpectedType(expected: expected, actual: '${_value[key].runtimeType}', data: _value[key]),
      method: 'decode',
      hint: '["$key"]',
    );
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

  Object? _encode<V>(V value, Encodable<V>? encodable) {
    if (encodable == null && value is! SelfEncodable) return value;

    final encoder = StandardEncoder(_isHumanReadable, _customTypes);
    encoder.encodeObject(value, using: encodable);
    return encoder._value;
  }

  List _encodeIterable<E>(Iterable<E> value, Encodable<E>? using) {
    var list = [];
    if (value case List v) {
      for (var i = 0; i < value.length; i++) {
        list.add(_encode(v[i], using));
      }
    } else {
      for (var e in value) {
        list.add(_encode(e, using));
      }
    }
    return list;
  }

  Map _encodeMap<K, V>(Map<K, V> value, Encodable<K>? keyUsing, Encodable<V>? valueUsing) {
    return value.map((key, value) => MapEntry(_encode(key, keyUsing), _encode(value, valueUsing)));
  }
}

class StandardEncoder extends _StandardEncoder implements Encoder {
  StandardEncoder([super._isHumanReadable, super._customTypes]);

  Object? _value;

  static Object? encode<T>(
    T value, {
    Encodable<T>? using,
    bool isHumanReadable = true,
    List<CustomTypeDelegate> customTypes = const [],
  }) {
    final encoder = StandardEncoder(isHumanReadable, customTypes);
    encoder.encodeObject(value, using: using);
    return encoder._value;
  }

  @override
  void encodeBool(bool value) {
    _value = value;
  }

  @override
  void encodeBoolOrNull(bool? value) {
    _value = value;
  }

  @override
  void encodeInt(int value) {
    _value = value;
  }

  @override
  void encodeIntOrNull(int? value) {
    _value = value;
  }

  @override
  void encodeDouble(double value) {
    _value = value;
  }

  @override
  void encodeDoubleOrNull(double? value) {
    _value = value;
  }

  @override
  void encodeNum(num value) {
    _value = value;
  }

  @override
  void encodeNumOrNull(num? value) {
    _value = value;
  }

  @override
  void encodeString(String value) {
    _value = value;
  }

  @override
  void encodeStringOrNull(String? value) {
    _value = value;
  }

  @override
  void encodeNull() {
    _value = null;
  }

  @override
  void encodeObject<T>(T value, {Encodable<T>? using}) {
    if (using != null) {
      using.encode(value, this);
    } else if (value is SelfEncodable) {
      value.encode(this);
    } else {
      final delegate = _customTypes.whereType<CustomTypeDelegate<T>>().firstOrNull;
      if (delegate != null) {
        delegate.encode(value, this);
      } else {
        _value = value;
      }
    }
  }

  @override
  void encodeObjectOrNull<T>(T? value, {Encodable<T>? using}) {
    if (value == null) {
      _value = null;
      return;
    }
    encodeObject(value, using: using);
  }

  @override
  void encodeIterable<E>(Iterable<E> value, {Encodable<E>? using}) {
    _value = _encodeIterable(value, using);
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
  void encodeMap<K, V>(Map<K, V> value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _value = _encodeMap(value, keyUsing, valueUsing);
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
  IteratedEncoder encodeIterated() {
    return StandardIteratedEncoder._(_value = <dynamic>[], _isHumanReadable, _customTypes);
  }

  @override
  KeyedEncoder encodeKeyed() {
    return StandardKeyedEncoder._(_value = <String, dynamic>{}, _isHumanReadable, _customTypes);
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
  void encodeBoolOrNull(bool? value) {
    _value.add(value);
  }

  @override
  void encodeInt(int value) {
    _value.add(value);
  }

  @override
  void encodeIntOrNull(int? value) {
    _value.add(value);
  }

  @override
  void encodeDouble(double value) {
    _value.add(value);
  }

  @override
  void encodeDoubleOrNull(double? value) {
    _value.add(value);
  }

  @override
  void encodeNum(num value) {
    _value.add(value);
  }

  @override
  void encodeNumOrNull(num? value) {
    _value.add(value);
  }

  @override
  void encodeString(String value) {
    _value.add(value);
  }

  @override
  void encodeStringOrNull(String? value) {
    _value.add(value);
  }

  @override
  void encodeNull() {
    _value.add(null);
  }

  @override
  void encodeObject<T>(T value, {Encodable<T>? using}) {
    if (using != null) {
      using.encode(value, this);
    } else if (value is SelfEncodable) {
      value.encode(this);
    } else {
      final delegate = _customTypes.whereType<CustomTypeDelegate<T>>().firstOrNull;
      if (delegate != null) {
        delegate.encode(value, this);
      } else {
        _value.add(value);
      }
    }
  }

  @override
  void encodeObjectOrNull<T>(T? value, {Encodable<T>? using}) {
    if (value == null) {
      _value.add(null);
      return;
    }
    encodeObject(value, using: using);
  }

  @override
  void encodeIterable<E>(Iterable<E> value, {Encodable<E>? using}) {
    _value.add(_encodeIterable(value, using));
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
  void encodeMap<K, V>(Map<K, V> value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _value.add(_encodeMap(value, keyUsing, valueUsing));
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
  IteratedEncoder encodeIterated() {
    final list = <dynamic>[];
    _value.add(list);
    return StandardIteratedEncoder._(list, _isHumanReadable, _customTypes);
  }

  @override
  KeyedEncoder encodeKeyed() {
    final map = <String, dynamic>{};
    _value.add(map);
    return StandardKeyedEncoder._(map, _isHumanReadable, _customTypes);
  }

  @override
  void end() {
    // Do nothing
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
  void encodeBoolOrNull(String key, bool? value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeDouble(String key, double value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeDoubleOrNull(String key, double? value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeInt(String key, int value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeIntOrNull(String key, int? value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeNum(String key, num value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeNumOrNull(String key, num? value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeString(String key, String value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeStringOrNull(String key, String? value, {int? id}) {
    _value[key] = value;
  }

  @override
  void encodeNull(String key, {int? id}) {
    _value[key] = null;
  }

  @override
  void encodeObject<T>(String key, T value, {int? id, Encodable<T>? using}) {
    _value[key] = _encode(value, using);
  }

  @override
  void encodeObjectOrNull<T>(String key, T? value, {int? id, Encodable<T>? using}) {
    if (value == null) {
      _value[key] = null;
      return;
    }
    _value[key] = _encode(value, using);
  }

  @override
  void encodeIterable<E>(String key, Iterable<E> value, {int? id, Encodable<E>? using}) {
    _value[key] = _encodeIterable(value, using);
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
  void encodeMap<K, V>(String key, Map<K, V> value, {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _value[key] = _encodeMap(value, keyUsing, valueUsing);
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
  IteratedEncoder encodeIterated(String key, {int? id}) {
    return StandardIteratedEncoder._(_value[key] = <dynamic>[], _isHumanReadable, _customTypes);
  }

  @override
  KeyedEncoder encodeKeyed(String key, {int? id}) {
    return StandardKeyedEncoder._(_value[key] = <String, dynamic>{}, _isHumanReadable, _customTypes);
  }

  @override
  void end() {
    // Do nothing
  }
}
