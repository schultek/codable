/// JSON reference implementation.
///
/// A format that encodes models to a JSON string or bytes.
///
/// To decrease the effort for the reference implementation, this is based largely
/// on the `crimson` package from pub. A "real" implementation would probably be
/// fully custom for optimal performance.
library json;

import 'dart:convert';

import 'package:codable/core.dart';
import 'package:codable/extended.dart';
import 'package:codable/standard.dart';
import 'package:crimson/crimson.dart';

extension JsonDecodable<T> on Decodable<T> {
  T fromJson(String json) {
    return fromJsonBytes(utf8.encode(json));
  }

  T fromJsonBytes(List<int> bytes) {
    return JsonDecoder.decode<T>(bytes, this);
  }
}

extension JsonEncodable<T> on Encodable<T> {
  String toJson(T value) {
    return utf8.decode(toJsonBytes(value));
  }

  List<int> toJsonBytes(T value) {
    return JsonEncoder.encode<T>(value, this);
  }
}

extension JsonSelfEncodableSelf<T extends SelfEncodable> on T {
  String toJson() {
    return utf8.decode(toJsonBytes());
  }

  List<int> toJsonBytes() {
    return JsonEncoder.encode<T>(this, Encodable.self());
  }
}

class JsonDecoder implements Decoder, IteratedDecoder, KeyedDecoder {
  JsonDecoder._(this._reader);
  final Crimson _reader;

  static T decode<T>(List<int> value, Decodable<T> decodable) {
    return decodable.decode(JsonDecoder._(Crimson(value)));
  }

  @pragma('vm:prefer-inline')
  @override
  T decodeObject<T>({required Decodable<T> using}) {
    return using.decode(this);
  }

  @pragma('vm:prefer-inline')
  @override
  T? decodeObjectOrNull<T>({required Decodable<T> using}) {
    if (_reader.skipNull()) return null;
    return using.decode(this);
  }

  @pragma('vm:prefer-inline')
  @override
  bool decodeBool() {
    return _reader.read() as bool;
  }

  @pragma('vm:prefer-inline')
  @override
  bool? decodeBoolOrNull() {
    return _reader.read() as bool?;
  }

  @pragma('vm:prefer-inline')
  @override
  double decodeDouble() {
    return _reader.readDouble();
  }

  @pragma('vm:prefer-inline')
  @override
  double? decodeDoubleOrNull() {
    return _reader.readDoubleOrNull();
  }

  @pragma('vm:prefer-inline')
  @override
  int decodeInt() {
    return _reader.readInt();
  }

  @pragma('vm:prefer-inline')
  @override
  int? decodeIntOrNull() {
    return _reader.readIntOrNull();
  }

  @pragma('vm:prefer-inline')
  @override
  List<I> decodeList<I>({Decodable<I>? using}) {
    if (using == null) return _reader.readArray().cast();
    return [
      for (; _reader.iterArray();) using.decode(this),
    ];
  }

  @pragma('vm:prefer-inline')
  @override
  List<I>? decodeListOrNull<I>({Decodable<I>? using}) {
    if (_reader.skipNull()) return null;
    return decodeList(using: using);
  }

  @pragma('vm:prefer-inline')
  @override
  Map<K, V> decodeMap<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    return switch ((keyUsing, valueUsing)) {
      (null, null) => _reader.readObject().cast(),
      (final dk?, null) => {
          for (String? key; (key = _reader.iterObject()) != null;) StandardDecoder.decode(key, dk): _reader.read() as V,
        },
      (null, final dv?) => {
          for (String? key; (key = _reader.iterObject()) != null;) key as K: dv.decode(this),
        },
      (final dk?, final dv?) => {
          for (String? key; (key = _reader.iterObject()) != null;) StandardDecoder.decode(key, dk): dv.decode(this),
        },
    };
  }

  @pragma('vm:prefer-inline')
  @override
  Map<K, V>? decodeMapOrNull<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    if (_reader.skipNull()) return null;
    return decodeMap(keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @pragma('vm:prefer-inline')
  @override
  num decodeNum() {
    return _reader.readNum();
  }

  @pragma('vm:prefer-inline')
  @override
  num? decodeNumOrNull() {
    return _reader.readNumOrNull();
  }

  @pragma('vm:prefer-inline')
  @override
  String decodeString() {
    return _reader.readString();
  }

  @pragma('vm:prefer-inline')
  @override
  String? decodeStringOrNull() {
    return _reader.readStringOrNull();
  }

  @pragma('vm:prefer-inline')
  @override
  bool decodeIsNull() {
    return _reader.skipNull();
  }

  @pragma('vm:prefer-inline')
  @override
  bool nextItem() {
    return _reader.iterArray();
  }

  @pragma('vm:prefer-inline')
  @override
  Object? nextKey() {
    return _reader.iterObject();
  }

  @pragma('vm:prefer-inline')
  @override
  void skipCurrentItem() {
    return _reader.skip();
  }

  @pragma('vm:prefer-inline')
  @override
  void skipCurrentValue() {
    return _reader.skip();
  }

  @pragma('vm:prefer-inline')
  @override
  void skipRemainingKeys() {
    return _reader.skipPartialObject();
  }

  @pragma('vm:prefer-inline')
  @override
  void skipRemainingItems() {
    return _reader.skipPartialArray();
  }

  @override
  JsonDecoder clone() {
    return JsonDecoder._(Crimson(_reader.buffer, _reader.offset));
  }

  @override
  dynamic decodeDynamic() {
    return _reader.read();
  }

  @override
  IteratedDecoder decodeIterated() {
    return this;
  }

  @override
  KeyedDecoder decodeKeyed() {
    return this;
  }

  @override
  MappedDecoder decodeMapped() {
    return CompatMappedDecoder.wrap(this);
  }

  @override
  DecodingType whatsNext() {
    final type = _reader.whatIsNext();
    return switch (type) {
      JsonType.nil => DecodingType.nil,
      JsonType.bool => DecodingType.bool,
      JsonType.number => DecodingType.num,
      JsonType.string => DecodingType.string,
      JsonType.object => DecodingType.keyed,
      JsonType.array => DecodingType.iterated,
    };
  }

  @override
  Never expect(String expected) {
    throw CodableException.unexpectedType(
      expected: expected,
      actual: _reader.whatIsNext().name,
      data: _reader.buffer,
      offset: _reader.offset,
    );
  }

  @override
  T decodeCustom<T>() {
    throw CodableException.unsupportedMethod('JsonDecoder', 'decodeCustom<$T>');
  }

  @override
  T? decodeCustomOrNull<T>() {
    throw CodableException.unsupportedMethod('JsonDecoder', 'decodeCustomOrNull<$T>');
  }

  @override
  bool isHumanReadable() {
    return true;
  }
}

class JsonEncoder implements Encoder, IteratedEncoder {
  JsonEncoder._(this._writer) {
    _keyed = JsonKeyedEncoder._(_writer, this);
  }

  final CrimsonWriter _writer;
  late final JsonKeyedEncoder _keyed;

  static List<int> encode<T>(T value, Encodable<T> encodable) {
    var encoder = JsonEncoder._(CrimsonWriter());
    encodable.encode(value, encoder);
    return encoder._writer.toBytes();
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeBool(bool value) {
    _writer.writeBool(value);
  }

  @pragma('vm:prefer-inline')
  @override
  IteratedEncoder encodeIterated() {
    _writer.writeArrayStart();
    return this;
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeDouble(double value) {
    _writer.writeNum(value);
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeInt(int value) {
    _writer.writeNum(value);
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeIterable<E>(Iterable<E> value, {Encodable<E>? using}) {
    _writer.writeArrayStart();
    if (using != null) {
      for (final e in value) {
        using.encode(e, this);
      }
    } else {
      for (final e in value) {
        _writer.write(e);
      }
    }
    _writer.writeArrayEnd();
  }

  @pragma('vm:prefer-inline')
  @override
  KeyedEncoder encodeKeyed() {
    _writer.writeObjectStart();
    return _keyed;
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeMap<K, V>(Map<K, V> value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _writer.writeObjectStart();
    if (keyUsing == null && valueUsing == null) {
      for (final key in value.keys) {
        final v = value[key] as V;
        _writer.writeObjectKey(key as String);
        _writer.write(v);
      }
    } else if (keyUsing == null && valueUsing != null) {
      for (final key in value.keys) {
        final v = value[key] as V;
        _writer.writeObjectKey(key as String);
        valueUsing.encode(v, this);
      }
    } else if (keyUsing != null && valueUsing == null) {
      for (final key in value.keys) {
        final v = value[key] as V;
        _writer.writeObjectKey(StandardEncoder.encode(key, keyUsing) as String);
        _writer.write(v);
      }
    } else {
      for (final key in value.keys) {
        final v = value[key] as V;
        _writer.writeObjectKey(StandardEncoder.encode(key, keyUsing!) as String);
        valueUsing!.encode(v, this);
      }
    }
    _writer.writeObjectEnd();
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeNull() {
    _writer.writeNull();
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeNum(num value) {
    _writer.writeNum(value);
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeObject<T>(T value, {required Encodable<T> using}) {
    using.encode(value, this);
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeString(String value) {
    _writer.writeString(value);
  }

  @override
  void end() {
    _writer.writeArrayEnd();
  }

  @override
  bool canEncodeCustom<T>() {
    return false;
  }

  @override
  void encodeCustom<T>(T value) {
    throw CodableException.unsupportedMethod('JsonEncoder', 'encodeCustom<$T>');
  }

  @override
  void encodeDynamic(value) {
    _writer.write(value);
  }

  @override
  void encodeBoolOrNull(bool? value) {
    if (value == null) {
      _writer.writeNull();
    } else {
      _writer.writeBool(value);
    }
  }

  @override
  void encodeCustomOrNull<T>(T? value) {
    throw CodableException.unsupportedMethod('JsonEncoder', 'encodeCustomOrNull<$T>');
  }

  @override
  void encodeDoubleOrNull(double? value) {
    if (value == null) {
      _writer.writeNull();
    } else {
      _writer.writeNum(value);
    }
  }

  @override
  void encodeIntOrNull(int? value) {
    if (value == null) {
      _writer.writeNull();
    } else {
      _writer.writeNum(value);
    }
  }

  @override
  void encodeIterableOrNull<E>(Iterable<E>? value, {Encodable<E>? using}) {
    if (value == null) {
      _writer.writeNull();
    } else {
      encodeIterable(value, using: using);
    }
  }

  @override
  void encodeMapOrNull<K, V>(Map<K, V>? value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    if (value == null) {
      _writer.writeNull();
    } else {
      encodeMap(value, keyUsing: keyUsing, valueUsing: valueUsing);
    }
  }

  @override
  void encodeNumOrNull(num? value) {
    if (value == null) {
      _writer.writeNull();
    } else {
      _writer.writeNum(value);
    }
  }

  @override
  void encodeObjectOrNull<T>(T? value, {required Encodable<T> using}) {
    if (value == null) {
      _writer.writeNull();
    } else {
      using.encode(value, this);
    }
  }

  @override
  void encodeStringOrNull(String? value) {
    if (value == null) {
      _writer.writeNull();
    } else {
      _writer.writeString(value);
    }
  }

  @override
  bool isHumanReadable() {
    return true;
  }
}

class JsonKeyedEncoder implements KeyedEncoder {
  JsonKeyedEncoder._(this._writer, this._parent);

  final CrimsonWriter _writer;
  final JsonEncoder _parent;

  @pragma('vm:prefer-inline')
  @override
  void encodeBool(String key, bool value, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeBool(value);
  }

  @pragma('vm:prefer-inline')
  @override
  IteratedEncoder encodeIterated(String key, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeArrayStart();
    return _parent;
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeDouble(String key, double value, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeNum(value);
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeInt(String key, int value, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeNum(value);
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeIterable<E>(String key, Iterable<E> value, {int? id, Encodable<E>? using}) {
    _writer.writeObjectKey(key);
    _parent.encodeIterable(value, using: using);
  }

  @pragma('vm:prefer-inline')
  @override
  KeyedEncoder encodeKeyed(String key, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeObjectStart();
    return this;
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeMap<K, V>(String key, Map<K, V> value, {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _writer.writeObjectKey(key);
    _parent.encodeMap(value, keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeNull(String key, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeNull();
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeNum(String key, num value, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeNum(value);
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeObject<T>(String key, T value, {int? id, required Encodable<T> using}) {
    _writer.writeObjectKey(key);
    using.encode(value, _parent);
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeString(String key, String value, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeString(value);
  }

  @override
  void end() {
    _writer.writeObjectEnd();
  }

  @override
  bool canEncodeCustom<T>() {
    return false;
  }

  @override
  void encodeCustom<T>(String key, T value, {int? id}) {
    throw CodableException.unsupportedMethod('JsonKeyedEncoder', 'encodeCustom<$T>');
  }

  @override
  void encodeDynamic(String key, dynamic value, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.write(value);
  }

  @override
  void encodeBoolOrNull(String key, bool? value, {int? id}) {
    if (value == null) {
      encodeNull(key, id: id);
    } else {
      encodeBool(key, value, id: id);
    }
  }

  @override
  void encodeCustomOrNull<T>(String key, T? value, {int? id}) {
    throw CodableException.unsupportedMethod('JsonKeyedEncoder', 'encodeCustomOrNull<$T>');
  }

  @override
  void encodeDoubleOrNull(String key, double? value, {int? id}) {
    if (value == null) {
      encodeNull(key, id: id);
    } else {
      encodeDouble(key, value, id: id);
    }
  }

  @override
  void encodeIntOrNull(String key, int? value, {int? id}) {
    if (value == null) {
      encodeNull(key, id: id);
    } else {
      encodeInt(key, value, id: id);
    }
  }

  @override
  void encodeIterableOrNull<E>(String key, Iterable<E>? value, {int? id, Encodable<E>? using}) {
    if (value == null) {
      encodeNull(key, id: id);
    } else {
      encodeIterable(key, value, id: id, using: using);
    }
  }

  @override
  void encodeMapOrNull<K, V>(String key, Map<K, V>? value,
      {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    if (value == null) {
      encodeNull(key, id: id);
    } else {
      encodeMap(key, value, id: id, keyUsing: keyUsing, valueUsing: valueUsing);
    }
  }

  @override
  void encodeNumOrNull(String key, num? value, {int? id}) {
    if (value == null) {
      encodeNull(key, id: id);
    } else {
      encodeNum(key, value, id: id);
    }
  }

  @override
  void encodeObjectOrNull<T>(String key, T? value, {int? id, required Encodable<T> using}) {
    if (value == null) {
      encodeNull(key, id: id);
    } else {
      encodeObject(key, value, id: id, using: using);
    }
  }

  @override
  void encodeStringOrNull(String key, String? value, {int? id}) {
    if (value == null) {
      encodeNull(key, id: id);
    } else {
      encodeString(key, value, id: id);
    }
  }

  @override
  bool isHumanReadable() {
    return true;
  }
}
