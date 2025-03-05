/// JSON reference implementation.
///
/// A format that encodes models to a JSON string or bytes.
///
/// To decrease the effort for the reference implementation, this is based largely
/// on the `crimson` package from pub. A "real" implementation would probably be
/// fully custom for optimal performance.
library json;

import 'dart:convert';

import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';
import 'package:codable_dart/standard.dart';
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
    return JsonEncoder.encode<T>(value, using: this);
  }
}

extension JsonSelfEncodableSelf<T extends SelfEncodable> on T {
  String toJson() {
    return utf8.decode(toJsonBytes());
  }

  List<int> toJsonBytes() {
    return JsonEncoder.encode<T>(this);
  }
}

class JsonDecoder implements Decoder, IteratedDecoder, KeyedDecoder {
  JsonDecoder._(this._reader);
  final Crimson _reader;

  static T decode<T>(List<int> value, Decodable<T> decodable) {
    return decodable.decode(JsonDecoder._(Crimson(value)));
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
  bool decodeBool() {
    return _reader.read() as bool;
  }

  @override
  bool? decodeBoolOrNull() {
    return _reader.read() as bool?;
  }

  @override
  double decodeDouble() {
    return _reader.readDouble();
  }

  @override
  double? decodeDoubleOrNull() {
    return _reader.readDoubleOrNull();
  }

  @override
  int decodeInt() {
    return _reader.readInt();
  }

  @override
  int? decodeIntOrNull() {
    return _reader.readIntOrNull();
  }

  @override
  num decodeNum() {
    return _reader.readNum();
  }

  @override
  num? decodeNumOrNull() {
    return _reader.readNumOrNull();
  }

  @override
  String decodeString() {
    return _reader.readString();
  }

  @override
  String? decodeStringOrNull() {
    return _reader.readStringOrNull();
  }

  @override
  bool decodeIsNull() {
    return _reader.skipNull();
  }

  @override
  T decodeObject<T>({Decodable<T>? using}) {
    if (using != null) {
      return using.decode(this);
    } else {
      return _reader.read() as T;
    }
  }

  @override
  T? decodeObjectOrNull<T>({Decodable<T>? using}) {
    if (_reader.skipNull()) return null;
    return decodeObject(using: using);
  }

  @override
  List<I> decodeList<I>({Decodable<I>? using}) {
    return [
      for (; _reader.iterArray();) decodeObject(using: using),
    ];
  }

  @override
  List<I>? decodeListOrNull<I>({Decodable<I>? using}) {
    if (_reader.skipNull()) return null;
    return decodeList(using: using);
  }

  @override
  Map<K, V> decodeMap<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    return {
      for (String? key; (key = _reader.iterObject()) != null;)
        StandardDecoder.decode<K>(key, using: keyUsing): decodeObject<V>(using: valueUsing),
    };
  }

  @override
  Map<K, V>? decodeMapOrNull<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    if (_reader.skipNull()) return null;
    return decodeMap(keyUsing: keyUsing, valueUsing: valueUsing);
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
  bool nextItem() {
    return _reader.iterArray();
  }

  @override
  Object? nextKey() {
    return _reader.iterObject();
  }

  @override
  void skipCurrentItem() {
    return _reader.skip();
  }

  @override
  void skipCurrentValue() {
    return _reader.skip();
  }

  @override
  void skipRemainingKeys() {
    return _reader.skipPartialObject();
  }

  @override
  void skipRemainingItems() {
    return _reader.skipPartialArray();
  }

  @override
  bool isHumanReadable() {
    return true;
  }

  @override
  JsonDecoder clone() {
    return JsonDecoder._(Crimson(_reader.buffer, _reader.offset));
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
}

class JsonEncoder implements Encoder, IteratedEncoder {
  JsonEncoder._(this._writer) {
    _keyed = JsonKeyedEncoder._(_writer, this);
  }

  final CrimsonWriter _writer;
  late final JsonKeyedEncoder _keyed;

  static List<int> encode<T>(T value, {Encodable<T>? using}) {
    var encoder = JsonEncoder._(CrimsonWriter());
    encoder.encodeObject(value, using: using);
    return encoder._writer.toBytes();
  }

  @override
  void encodeBool(bool value) {
    _writer.writeBool(value);
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
  void encodeInt(int value) {
    _writer.writeNum(value);
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
  void encodeDouble(double value) {
    _writer.writeNum(value);
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
  void encodeNum(num value) {
    _writer.writeNum(value);
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
  void encodeString(String value) {
    _writer.writeString(value);
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
  void encodeNull() {
    _writer.writeNull();
  }

  @override
  bool canEncodeCustom<T>() {
    return false;
  }

  @override
  void encodeObject<T>(T value, {Encodable<T>? using}) {
    if (using != null) {
      using.encode(value, this);
    } else if (value is SelfEncodable) {
      value.encode(this);
    } else {
      _writer.write(value);
    }
  }

  @override
  void encodeObjectOrNull<T>(T? value, {Encodable<T>? using}) {
    if (value == null) {
      _writer.writeNull();
    } else {
      encodeObject<T>(value, using: using);
    }
  }

  @override
  void encodeIterable<E>(Iterable<E> value, {Encodable<E>? using}) {
    _writer.writeArrayStart();
    for (final e in value) {
      encodeObject<E>(e, using: using);
    }
    _writer.writeArrayEnd();
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
  void encodeMap<K, V>(Map<K, V> value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _writer.writeObjectStart();
    for (final key in value.keys) {
      final v = value[key] as V;
      _writer.writeObjectKey(StandardEncoder.encode<K>(key, using: keyUsing) as String);
      encodeObject<V>(v, using: valueUsing);
    }
    _writer.writeObjectEnd();
  }

  @override
  void encodeMapOrNull<K, V>(Map<K, V>? value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    if (value == null) {
      _writer.writeNull();
    } else {
      encodeMap<K, V>(value, keyUsing: keyUsing, valueUsing: valueUsing);
    }
  }

  @override
  IteratedEncoder encodeIterated() {
    _writer.writeArrayStart();
    return this;
  }

  @override
  KeyedEncoder encodeKeyed() {
    _writer.writeObjectStart();
    return _keyed;
  }

  @override
  void end() {
    _writer.writeArrayEnd();
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

  @override
  void encodeBool(String key, bool value, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeBool(value);
  }

  @override
  void encodeBoolOrNull(String key, bool? value, {int? id}) {
    _writer.writeObjectKey(key);
    _parent.encodeBoolOrNull(value);
  }

  @override
  void encodeInt(String key, int value, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeNum(value);
  }

  @override
  void encodeIntOrNull(String key, int? value, {int? id}) {
    _writer.writeObjectKey(key);
    _parent.encodeIntOrNull(value);
  }

  @override
  void encodeDouble(String key, double value, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeNum(value);
  }

  @override
  void encodeDoubleOrNull(String key, double? value, {int? id}) {
    _writer.writeObjectKey(key);
    _parent.encodeDoubleOrNull(value);
  }

  @override
  void encodeNum(String key, num value, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeNum(value);
  }

  @override
  void encodeNumOrNull(String key, num? value, {int? id}) {
    _writer.writeObjectKey(key);
    _parent.encodeNumOrNull(value);
  }

  @override
  void encodeString(String key, String value, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeString(value);
  }

  @override
  void encodeStringOrNull(String key, String? value, {int? id}) {
    _writer.writeObjectKey(key);
    _parent.encodeStringOrNull(value);
  }

  @override
  void encodeNull(String key, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeNull();
  }

  @override
  bool canEncodeCustom<T>() {
    return false;
  }

  @override
  void encodeObject<T>(String key, T value, {int? id, Encodable<T>? using}) {
    _writer.writeObjectKey(key);
    _parent.encodeObject<T>(value, using: using);
  }

  @override
  void encodeObjectOrNull<T>(String key, T? value, {int? id, Encodable<T>? using}) {
    _writer.writeObjectKey(key);
    _parent.encodeObjectOrNull<T>(value, using: using);
  }

  @override
  void encodeIterable<E>(String key, Iterable<E> value, {int? id, Encodable<E>? using}) {
    _writer.writeObjectKey(key);
    _parent.encodeIterable<E>(value, using: using);
  }

  @override
  void encodeIterableOrNull<E>(String key, Iterable<E>? value, {int? id, Encodable<E>? using}) {
    _writer.writeObjectKey(key);
    _parent.encodeIterableOrNull<E>(value, using: using);
  }

  @override
  void encodeMap<K, V>(String key, Map<K, V> value, {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _writer.writeObjectKey(key);
    _parent.encodeMap<K, V>(value, keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @override
  void encodeMapOrNull<K, V>(String key, Map<K, V>? value,
      {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _writer.writeObjectKey(key);
    _parent.encodeMapOrNull<K, V>(value, keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @override
  IteratedEncoder encodeIterated(String key, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeArrayStart();
    return _parent;
  }

  @override
  KeyedEncoder encodeKeyed(String key, {int? id}) {
    _writer.writeObjectKey(key);
    _writer.writeObjectStart();
    return this;
  }

  @override
  void end() {
    _writer.writeObjectEnd();
  }

  @override
  bool isHumanReadable() {
    return true;
  }
}
