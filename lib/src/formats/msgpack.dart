/// MessagePack reference implementation.
///
/// A format that encodes models to compact binary data.
///
/// To decrease the effort for the reference implementation, this is based largely
/// on the `messagepack` package from pub. A "real" implementation would probably be
/// fully custom for optimal performance.
library msgpack;

import 'dart:convert';
import 'dart:typed_data';

import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';

extension MsgPackDecodable<T> on Decodable<T> {
  T fromMsgPack(List<int> bytes) {
    return MsgPackDecoder.decode<T>(bytes, this);
  }
}

extension MsgPackEncodable<T> on Encodable<T> {
  List<int> toMsgPack(T value) {
    return MsgPackEncoder.encode<T>(value, using: this);
  }
}

extension MsgPackSelfEncodableSelf<T extends SelfEncodable> on T {
  List<int> toMsgPack() {
    return MsgPackEncoder.encode<T>(this);
  }
}

class MsgPackDecoder implements Decoder {
  MsgPackDecoder._(this._unpacker);
  final Unpacker _unpacker;

  static T decode<T>(List<int> value, Decodable<T> decodable) {
    return decodable.decode(MsgPackDecoder._(Unpacker.fromList(value)));
  }

  @override
  DecodingType whatsNext() {
    final b = _unpacker.whatIsNext();
    return switch (b) {
      0xc0 => DecodingType.nil,
      <= 0x7f || >= 0xe0 || (>= 0xcc && <= 0xd3) => DecodingType.int,
      0xc2 || 0xc3 => DecodingType.bool,
      0xca || 0xcb => DecodingType.double,
      0xc0 || 0xd9 || 0xda || 0xdb => DecodingType.string,
      _ when (b & 0xE0) == 0xA0 => DecodingType.string,
      0xc4 || 0xc5 || 0xc6 => DecodingType<Uint8List>.custom(),
      (>= 0x90 && <= 0x9F) || 0xdc || 0xdd => DecodingType.iterated,
      (>= 0x80 && <= 0x8F) || 0xde || 0xdf => DecodingType.keyed,
      (>= 0xd4 && <= 0xd8) || (>= 0xc7 && <= 0xc9) => switch (_unpacker._getExtType()) {
          -1 => DecodingType<DateTime>.custom(),
          _ => DecodingType.unknown,
        },
      _ => DecodingType.unknown,
    };
  }

  @override
  bool decodeBool() {
    return _unpacker.unpackBool()!;
  }

  @override
  bool? decodeBoolOrNull() {
    return _unpacker.unpackBool();
  }

  @override
  int decodeInt() {
    return _unpacker.unpackInt()!;
  }

  @override
  int? decodeIntOrNull() {
    return _unpacker.unpackInt();
  }

  @override
  double decodeDouble() {
    return (_unpacker._unpack() as num).toDouble();
  }

  @override
  double? decodeDoubleOrNull() {
    return (_unpacker._unpack() as num?)?.toDouble();
  }

  @override
  num decodeNum() {
    return _unpacker._unpack() as num;
  }

  @override
  num? decodeNumOrNull() {
    return _unpacker._unpack() as num?;
  }

  @override
  String decodeString() {
    return _unpacker.unpackString()!;
  }

  @override
  String? decodeStringOrNull() {
    return _unpacker.unpackString();
  }

  @override
  bool decodeIsNull() {
    return _unpacker.skipNull();
  }

  @override
  T decodeObject<T>({Decodable<T>? using}) {
    if (using != null) {
      return using.decode(this);
    } else {
      return _unpacker._unpack() as T;
    }
  }

  @override
  T? decodeObjectOrNull<T>({Decodable<T>? using}) {
    if (_unpacker.skipNull()) return null;
    return decodeObject(using: using);
  }

  @override
  List<I> decodeList<I>({Decodable<I>? using}) {
    var n = _unpacker.unpackListLength();
    return [
      for (var i = 0; i < n; i++) decodeObject(using: using),
    ];
  }

  @override
  List<I>? decodeListOrNull<I>({Decodable<I>? using}) {
    if (_unpacker.skipNull()) return null;
    return decodeList(using: using);
  }

  @override
  Map<K, V> decodeMap<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    final length = _unpacker.unpackMapLength();
    return {
      for (int i = 0; i < length; i++) decodeObject<K>(using: keyUsing): decodeObject<V>(using: valueUsing),
    };
  }

  @override
  Map<K, V>? decodeMapOrNull<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    if (_unpacker.skipNull()) return null;
    return decodeMap(keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @override
  IteratedDecoder decodeIterated() {
    return MsgPackCollectionDecoder(_unpacker, _unpacker.unpackListLength());
  }

  @override
  KeyedDecoder decodeKeyed() {
    return MsgPackCollectionDecoder(_unpacker, _unpacker.unpackMapLength());
  }

  @override
  MappedDecoder decodeMapped() {
    return CompatMappedDecoder.wrap(decodeKeyed());
  }

  @override
  bool isHumanReadable() {
    return false;
  }

  @override
  MsgPackDecoder clone() {
    return MsgPackDecoder._(Unpacker.copy(_unpacker._list, _unpacker._d, _unpacker._offset));
  }

  @override
  Never expect(String expected) {
    throw CodableException.unexpectedType(
      expected: expected,
      actual: whatsNext().toString(),
      data: _unpacker._list,
      offset: _unpacker._offset,
    );
  }
}

class MsgPackCollectionDecoder extends MsgPackDecoder implements KeyedDecoder, IteratedDecoder {
  MsgPackCollectionDecoder(super._unpacker, this.length) : super._();

  final int length;
  int index = -1;

  @override
  bool nextItem() {
    index++;
    return index < length;
  }

  @override
  Object? nextKey() {
    index++;
    if (index < length) {
      return _unpacker.unpackString();
    } else {
      return null;
    }
  }

  @override
  void skipCurrentItem() {
    _unpacker._unpack();
  }

  @override
  void skipCurrentValue() {
    _unpacker._unpack();
  }

  @override
  void skipRemainingKeys() {
    for (; nextKey() != null;) {
      skipCurrentValue();
    }
  }

  @override
  void skipRemainingItems() {
    for (; nextItem();) {
      skipCurrentItem();
    }
  }

  @override
  MsgPackCollectionDecoder clone() {
    return MsgPackCollectionDecoder(_unpacker, length)..index = index;
  }
}

class MsgPackEncoder implements Encoder {
  MsgPackEncoder._(this._packer);

  final Packer _packer;

  void tick() {}

  static List<int> encode<T>(T value, {Encodable<T>? using}) {
    var encoder = MsgPackEncoder._(Packer());
    encoder.encodeObject(value, using: using);
    return encoder._packer.takeBytes();
  }

  @override
  void encodeBool(bool value) {
    encodeBoolOrNull(value);
  }

  @override
  void encodeBoolOrNull(bool? value) {
    tick();
    _packer.packBool(value);
  }

  @override
  void encodeInt(int value) {
    encodeIntOrNull(value);
  }

  @override
  void encodeIntOrNull(int? value) {
    tick();
    _packer.packInt(value);
  }

  @override
  void encodeDouble(double value) {
    encodeDoubleOrNull(value);
  }

  @override
  void encodeDoubleOrNull(double? value) {
    tick();
    if (value?.truncate() == value) {
      _packer.packInt(value?.truncate());
    } else {
      _packer.packDouble(value);
    }
  }

  @override
  void encodeNum(num value) {
    encodeNumOrNull(value);
  }

  @override
  void encodeNumOrNull(num? value) {
    tick();
    if (value is int) {
      _packer.packInt(value);
    } else {
      _packer.packDouble(value?.toDouble());
    }
  }

  @override
  void encodeString(String value) {
    encodeStringOrNull(value);
  }

  @override
  void encodeStringOrNull(String? value) {
    tick();
    _packer.packString(value);
  }

  @override
  void encodeNull() {
    tick();
    _packer.packNull();
  }

  @override
  bool canEncodeCustom<T>() {
    return T == DateTime;
  }

  @override
  void encodeObject<T>(T value, {Encodable<T>? using}) {
    if (using != null) {
      using.encode(value, this);
    } else if (value is SelfEncodable) {
      value.encode(this);
    } else {
      tick();
      _packer._pack(value);
    }
  }

  @override
  void encodeObjectOrNull<T>(T? value, {Encodable<T>? using}) {
    if (value == null) {
      tick();
      _packer.packNull();
    } else {
      encodeObject(value, using: using);
    }
  }

  @override
  void encodeIterable<E>(Iterable<E> value, {Encodable<E>? using}) {
    tick();
    _packer.packListLength(value.length);
    for (final e in value) {
      encodeObject(e, using: using);
    }
  }

  @override
  void encodeIterableOrNull<E>(Iterable<E>? value, {Encodable<E>? using}) {
    if (value == null) {
      tick();
      _packer.packNull();
    } else {
      encodeIterable(value, using: using);
    }
  }

  @override
  void encodeMap<K, V>(Map<K, V> value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    tick();
    _packer.packMapLength(value.length);
    for (final key in value.keys) {
      final v = value[key] as V;
      encodeObject(key, using: keyUsing);
      encodeObject(v, using: valueUsing);
    }
  }

  @override
  void encodeMapOrNull<K, V>(Map<K, V>? value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    if (value == null) {
      tick();
      _packer.packNull();
    } else {
      encodeMap(value, keyUsing: keyUsing, valueUsing: valueUsing);
    }
  }

  @override
  IteratedEncoder encodeIterated() {
    tick();
    return MsgPackIteratedEncoder(_packer);
  }

  @override
  KeyedEncoder encodeKeyed() {
    tick();
    return MsgPackKeyedEncoder._(_packer);
  }

  @override
  bool isHumanReadable() {
    return false;
  }
}

class MsgPackIteratedEncoder extends MsgPackEncoder implements IteratedEncoder {
  MsgPackIteratedEncoder(this._parentPacker) : super._(Packer());

  final Packer _parentPacker;

  int realLength = 0;

  @override
  void tick() {
    realLength++;
  }

  @override
  void end() {
    _parentPacker.packListLength(realLength);
    _parentPacker._putBytes(_packer.takeBytes());
  }
}

class MsgPackKeyedEncoder implements KeyedEncoder {
  MsgPackKeyedEncoder._(this._parentPacker) {
    _packer = Packer();
  }

  final Packer _parentPacker;
  late final Packer _packer;

  int realLength = 0;

  void tick() {
    realLength++;
  }

  @override
  void end() {
    _parentPacker.packMapLength(realLength);
    _parentPacker._putBytes(_packer.takeBytes());
  }

  @override
  void encodeBool(String key, bool value, {int? id}) {
    tick();
    _packer.packString(key);
    _packer.packBool(value);
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
  void encodeInt(String key, int value, {int? id}) {
    tick();
    _packer.packString(key);
    _packer.packInt(value);
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
  void encodeDouble(String key, double value, {int? id}) {
    tick();
    _packer.packString(key);
    if (value.truncate() == value) {
      _packer.packInt(value.truncate());
    } else {
      _packer.packDouble(value);
    }
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
  void encodeNum(String key, num value, {int? id}) {
    tick();
    _packer.packString(key);
    if (value is int) {
      _packer.packInt(value);
    } else {
      _packer.packDouble(value.toDouble());
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
  void encodeString(String key, String value, {int? id}) {
    tick();
    _packer.packString(key);
    _packer.packString(value);
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
  void encodeNull(String key, {int? id}) {
    tick();
    _packer.packString(key);
    _packer.packNull();
  }

  @override
  bool canEncodeCustom<T>() {
    return T == DateTime;
  }

  @override
  void encodeObject<T>(String key, T value, {int? id, Encodable<T>? using}) {
    tick();
    _packer.packString(key);
    MsgPackEncoder._(_packer).encodeObject(value, using: using);
  }

  @override
  void encodeObjectOrNull<T>(String key, T? value, {int? id, Encodable<T>? using}) {
    if (value == null) {
      encodeNull(key, id: id);
    } else {
      encodeObject(key, value, id: id, using: using);
    }
  }

  @override
  void encodeIterable<E>(String key, Iterable<E> value, {int? id, Encodable<E>? using}) {
    tick();
    _packer.packString(key);
    MsgPackEncoder._(_packer).encodeIterable(value, using: using);
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
  void encodeMap<K, V>(String key, Map<K, V> value, {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    tick();
    _packer.packString(key);
    MsgPackEncoder._(_packer).encodeMap(value, keyUsing: keyUsing, valueUsing: valueUsing);
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
  IteratedEncoder encodeIterated(String key, {int? id}) {
    tick();
    _packer.packString(key);
    return MsgPackIteratedEncoder(_packer);
  }

  @override
  KeyedEncoder encodeKeyed(String key, {int? id}) {
    tick();
    _packer.packString(key);
    return MsgPackKeyedEncoder._(_packer);
  }

  @override
  bool isHumanReadable() {
    return false;
  }
}

// ===========================================
// COPIED AND ADAPTED FROM package:messagepack
// ===========================================

/// Streaming API for unpacking (deserializing) data from msgpack binary format.
///
/// unpackXXX methods returns value if it exist, or `null`.
/// Throws [FormatException] if value is not an requested type,
/// but in that case throwing exception not corrupt internal state,
/// so other unpackXXX methods can be called after that.
class Unpacker {
  /// Manipulates with provided [Uint8List] to sequentially unpack values.
  /// Use [Unpaker.fromList()] to unpack raw `List<int>` bytes.
  Unpacker(this._list) : _d = ByteData.view(_list.buffer, _list.offsetInBytes);

  ///Convenient
  Unpacker.fromList(List<int> l) : this(Uint8List.fromList(l));

  Unpacker.copy(this._list, this._d, this._offset);

  final Uint8List _list;
  final ByteData _d;
  int _offset = 0;

  final _strCodec = const Utf8Codec();

  bool skipNull() {
    final b = _d.getUint8(_offset);
    if (b == 0xc0) {
      _offset += 1;
      return true;
    }
    return false;
  }

  int whatIsNext() {
    return _d.getUint8(_offset);
  }

  /// Unpack value if it exist. Otherwise returns `null`.
  ///
  /// Throws [FormatException] if value is not a bool,
  bool? unpackBool() {
    final b = _d.getUint8(_offset);
    bool? v;
    if (b == 0xc2) {
      v = false;
      _offset += 1;
    } else if (b == 0xc3) {
      v = true;
      _offset += 1;
    } else if (b == 0xc0) {
      v = null;
      _offset += 1;
    } else {
      throw _formatException('bool', b);
    }
    return v;
  }

  /// Unpack value if it exist. Otherwise returns `null`.
  ///
  /// Throws [FormatException] if value is not an integer,
  int? unpackInt() {
    final b = _d.getUint8(_offset);
    int? v;
    if (b <= 0x7f || b >= 0xe0) {
      /// Int value in fixnum range [-32..127] encoded in header 1 byte
      v = _d.getInt8(_offset);
      _offset += 1;
    } else if (b == 0xcc) {
      v = _d.getUint8(++_offset);
      _offset += 1;
    } else if (b == 0xcd) {
      v = _d.getUint16(++_offset);
      _offset += 2;
    } else if (b == 0xce) {
      v = _d.getUint32(++_offset);
      _offset += 4;
    } else if (b == 0xcf) {
      v = _d.getUint64(++_offset);
      _offset += 8;
    } else if (b == 0xd0) {
      v = _d.getInt8(++_offset);
      _offset += 1;
    } else if (b == 0xd1) {
      v = _d.getInt16(++_offset);
      _offset += 2;
    } else if (b == 0xd2) {
      v = _d.getInt32(++_offset);
      _offset += 4;
    } else if (b == 0xd3) {
      v = _d.getInt64(++_offset);
      _offset += 8;
    } else if (b == 0xc0) {
      v = null;
      _offset += 1;
    } else {
      throw _formatException('integer', b);
    }
    return v;
  }

  /// Unpack value if it exist. Otherwise returns `null`.
  ///
  /// Throws [FormatException] if value is not a Double.
  double? unpackDouble() {
    final b = _d.getUint8(_offset);
    double? v;
    if (b == 0xca) {
      v = _d.getFloat32(++_offset);
      _offset += 4;
    } else if (b == 0xcb) {
      v = _d.getFloat64(++_offset);
      _offset += 8;
    } else if (b == 0xc0) {
      v = null;
      _offset += 1;
    } else {
      throw _formatException('double', b);
    }
    return v;
  }

  /// Unpack value if it exist. Otherwise returns `null`.
  ///
  /// Empty
  /// Throws [FormatException] if value is not a String.
  String? unpackString() {
    final b = _d.getUint8(_offset);
    if (b == 0xc0) {
      _offset += 1;
      return null;
    }
    int len;

    /// fixstr 101XXXXX stores a byte array whose len is upto 31 bytes:
    if (b & 0xE0 == 0xA0) {
      len = b & 0x1F;
      _offset += 1;
    } else if (b == 0xd9) {
      len = _d.getUint8(++_offset);
      _offset += 1;
    } else if (b == 0xda) {
      len = _d.getUint16(++_offset);
      _offset += 2;
    } else if (b == 0xdb) {
      len = _d.getUint32(++_offset);
      _offset += 4;
    } else {
      throw _formatException('String', b);
    }
    final data = Uint8List.view(_list.buffer, _list.offsetInBytes + _offset, len);
    _offset += len;
    return _strCodec.decode(data);
  }

  /// Unpack [List.length] if packed value is an [List] or `null`.
  ///
  /// Encoded in msgpack packet null or 0 length unpacks to 0 for convenience.
  /// Items of the [List] must be unpacked manually with respect to returned `length`
  /// Throws [FormatException] if value is not an [List].
  int unpackListLength() {
    final b = _d.getUint8(_offset);
    int len;
    if (b & 0xF0 == 0x90) {
      /// fixarray 1001XXXX stores an array whose length is upto 15 elements:
      len = b & 0xF;
      _offset += 1;
    } else if (b == 0xc0) {
      len = 0;
      _offset += 1;
    } else if (b == 0xdc) {
      len = _d.getUint16(++_offset);
      _offset += 2;
    } else if (b == 0xdd) {
      len = _d.getUint32(++_offset);
      _offset += 4;
    } else {
      throw _formatException('List length', b);
    }
    return len;
  }

  /// Unpack [Map.length] if packed value is an [Map] or `null`.
  ///
  /// Encoded in msgpack packet null or 0 length unpacks to 0 for convenience.
  /// Items of the [Map] must be unpacked manually with respect to returned `length`
  /// Throws [FormatException] if value is not an [Map].
  int unpackMapLength() {
    final b = _d.getUint8(_offset);
    int len;
    if (b & 0xF0 == 0x80) {
      /// fixmap 1000XXXX stores a map whose length is upto 15 elements
      len = b & 0xF;
      _offset += 1;
    } else if (b == 0xc0) {
      len = 0;
      _offset += 1;
    } else if (b == 0xde) {
      len = _d.getUint16(++_offset);
      _offset += 2;
    } else if (b == 0xdf) {
      len = _d.getUint32(++_offset);
      _offset += 4;
    } else {
      throw _formatException('Map length', b);
    }
    return len;
  }

  /// Unpack value if packed value is binary or `null`.
  ///
  /// Encoded in msgpack packet null unpacks to [List] with 0 length for convenience.
  /// Throws [FormatException] if value is not a binary.
  List<int> unpackBinary() {
    final b = _d.getUint8(_offset);
    int len;
    if (b == 0xc4) {
      len = _d.getUint8(++_offset);
      _offset += 1;
    } else if (b == 0xc0) {
      len = 0;
      _offset += 1;
    } else if (b == 0xc5) {
      len = _d.getUint16(++_offset);
      _offset += 2;
    } else if (b == 0xc6) {
      len = _d.getUint32(++_offset);
      _offset += 4;
    } else {
      throw _formatException('Binary', b);
    }
    final data = Uint8List.view(_list.buffer, _list.offsetInBytes + _offset, len);
    _offset += len;
    return data.toList();
  }

  Object? _unpack() {
    final b = _d.getUint8(_offset);
    if (b <= 0x7f ||
        b >= 0xe0 ||
        b == 0xcc ||
        b == 0xcd ||
        b == 0xce ||
        b == 0xcf ||
        b == 0xd0 ||
        b == 0xd1 ||
        b == 0xd2 ||
        b == 0xd3) {
      return unpackInt();
    } else if (b == 0xc0 || b == 0xc2 || b == 0xc3) {
      return unpackBool(); //null included
    } else if (b == 0xca || b == 0xcb) {
      return unpackDouble();
    } else if ((b & 0xE0) == 0xA0 || b == 0xc0 || b == 0xd9 || b == 0xda || b == 0xdb) {
      return unpackString();
    } else if (b == 0xc4 || b == 0xc5 || b == 0xc6) {
      return unpackBinary();
    } else if ((b & 0xF0) == 0x90 || b == 0xdc || b == 0xdd) {
      return unpackList();
    } else if ((b & 0xF0) == 0x80 || b == 0xde || b == 0xdf) {
      return unpackMap();
    } else if ((b >= 0xd4 && b <= 0xd8) || (b >= 0xc7 && b <= 0xc9)) {
      return unpackExt();
    } else {
      throw _formatException('Unknown', b);
    }
  }

  int _getExtType() {
    var b = _d.getUint8(_offset);
    if (b >= 0xd4 && b <= 0xd8) {
      return _d.getInt8(_offset + 1);
    } else if (b >= 0xc7 && b <= 0xc9) {
      var o = _offset + (1 << ((b & 0xF) - 7)) + 1;
      return _d.getInt8(o);
    } else {
      throw _formatException('Unknown', b);
    }
  }

  Object? unpackExt() {
    var b = _d.getUint8(_offset++);
    if (b >= 0xd4 && b <= 0xd8) {
      var t = _d.getInt8(_offset++);
      var l = 1 << (b & 0xF - 4);
      return _unpackExt(t, l);
    } else if (b >= 0xc7 && b <= 0xc9) {
      var l = 0;
      if (b == 0xc7) {
        l = _d.getUint8(_offset++);
      } else if (b == 0xc8) {
        l = _d.getUint16(_offset);
        _offset += 2;
      } else if (b == 0xc9) {
        l = _d.getUint32(_offset);
        _offset += 4;
      }
      var t = _d.getInt8(_offset++);
      return _unpackExt(t, l);
    } else {
      throw _formatException('Unknown', b);
    }
  }

  Object? _unpackExt(int type, int len) {
    if (type == -1) {
      return _unpackTimestamp(len);
    } else {
      throw _formatException('Unknown', type);
    }
  }

  DateTime _unpackTimestamp(int len) {
    switch (len) {
      case 4:
        var sec = _d.getUint32(_offset);
        _offset += 4;
        return DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true);
      case 8:
        var data = _d.getUint64(_offset);
        _offset += 8;
        var nsec = data >> 34;
        var sec = data & 0x00000003ffffffff;
        return DateTime.fromMillisecondsSinceEpoch(sec * 1000 + nsec ~/ 1000000, isUtc: true);
      case 12:
        var nsec = _d.getUint32(_offset);
        _offset += 4;
        var sec = _d.getInt64(_offset);
        _offset += 8;
        return DateTime.fromMillisecondsSinceEpoch(sec * 1000 + nsec ~/ 1000000, isUtc: true);
      default:
        throw _formatException('Unknown', len);
    }
  }

  /// Automatically unpacks `bytes` to [List] where items has corresponding data types.
  ///
  /// Return types declared as [Object] instead of `dynamic` for safety reasons.
  /// You need explicitly cast to proper types. And in case with [Object]
  /// compiler checks will force you to do it whereas with `dynamic` it will not.
  List<Object?> unpackList() {
    final length = unpackListLength();
    return List.generate(length, (_) => _unpack());
  }

  /// Automatically unpacks `bytes` to [Map] where key and values has corresponding data types.
  ///
  /// Return types declared as [Object] instead of `dynamic` for safety reasons.
  /// You need explicitly cast to proper types. And in case with [Object]
  /// compiler checks will force you to do it whereas with `dynamic` it will not.
  Map<Object?, Object?> unpackMap() {
    final length = unpackMapLength();
    return {for (var i = 0; i < length; i++) _unpack(): _unpack()};
  }

  Exception _formatException(String type, int b) =>
      FormatException('''Try to unpack $type value, but it's not an $type, byte = $b''');
}

/// Streaming API for packing (serializing) data to msgpack binary format.
///
/// Packer provide API for manually packing your data item by item in serial / streaming manner.
/// Use methods packXXX, where XXX is type names. Methods can take value and `null`.
/// If `null` provided for packXXX method it will be packed to `null` implicitly.
/// For explicitly packing `null` separate packNull function exist.
///
/// Streaming packing requires buffer to collect your data.
/// Try to figure out the best initial size of this buffer, that minimal enough to fit your most common data packing scenario.
/// Try to find balance. Provide this value in constructor [Packer()]
class Packer {
  /// Provide the [_bufSize] size, that minimal enough to fit your most used data packets.
  /// Try to find balance, small buffer is good, and if most of your data will fit to it, performance will be good.
  /// If buffer not enough it will be increased automatically.
  Packer([this._bufSize = 64]) {
    _newBuf(_bufSize);
  }

  int _bufSize;

  late Uint8List _buf;
  late ByteData _d;
  int _offset = 0;

  void _newBuf(int size) {
    _buf = Uint8List(size);
    _d = ByteData.view(_buf.buffer, _buf.offsetInBytes);
    _offset = 0;
  }

  final _builder = BytesBuilder(copy: false);
  final _strCodec = const Utf8Codec();

  void _nextBuf() {
    _flushBuf();
    _bufSize = _bufSize *= 2;
    _newBuf(_bufSize);
  }

  /// Flush [_buf] to [_builder] when [_buf] if almost full
  /// or when packer completes his job and transforms to bytes
  void _flushBuf() {
    _builder.add(Uint8List.view(
      _buf.buffer,
      _buf.offsetInBytes,
      _offset,
    ));
  }

  /// Pack binary and string uses this internally.
  void _putBytes(List<int> bytes) {
    final length = bytes.length;
    if (_buf.length - _offset < length) _nextBuf();
    if (_offset == 0) {
      /// buf flushed to builder, next new buf created, so we can write directly to builder
      _builder.add(bytes);
    } else {
      /// buf has space for us
      _buf.setRange(_offset, _offset + length, bytes);
      _offset += length;
    }
  }

  void _pack(dynamic value) {
    if (value == null) {
      packNull();
    } else if (value is String) {
      packString(value);
    } else if (value is bool) {
      packBool(value);
    } else if (value is int) {
      packInt(value);
    } else if (value is double) {
      packDouble(value);
    } else if (value is List) {
      packListLength(value.length);
      for (final e in value) {
        _pack(e);
      }
    } else if (value is Map) {
      packMapLength(value.length);
      for (final k in value.keys) {
        _pack(k);
        _pack(value[k]);
      }
    } else if (value is DateTime) {
      packTimestamp(value);
    } else {
      throw ArgumentError('Unsupported type: ${value.runtimeType}');
    }
  }

  /// Explicitly pack null value.
  /// Other packXXX implicitly handle null values.
  void packNull() {
    if (_buf.length - _offset < 1) _nextBuf();
    _d.setUint8(_offset++, 0xc0);
  }

  /// Pack [bool] or `null`.
  // ignore: avoid_positional_boolean_parameters
  void packBool(bool? v) {
    if (_buf.length - _offset < 1) _nextBuf();
    if (v == null) {
      _d.setUint8(_offset++, 0xc0);
    } else {
      _d.setUint8(_offset++, v ? 0xc3 : 0xc2);
    }
  }

  /// Pack [int] or `null`.
  void packInt(int? v) {
    // max 8 byte int + 1 control byte
    if (_buf.length - _offset < 9) _nextBuf();
    if (v == null) {
      _d.setUint8(_offset++, 0xc0);
    } else if (v >= 0) {
      if (v <= 127) {
        _d.setUint8(_offset++, v);
      } else if (v <= 0xFF) {
        _d.setUint8(_offset++, 0xcc);
        _d.setUint8(_offset++, v);
      } else if (v <= 0xFFFF) {
        _d.setUint8(_offset++, 0xcd);
        _d.setUint16(_offset, v);
        _offset += 2;
      } else if (v <= 0xFFFFFFFF) {
        _d.setUint8(_offset++, 0xce);
        _d.setUint32(_offset, v);
        _offset += 4;
      } else {
        _d.setUint8(_offset++, 0xcf);
        _d.setUint64(_offset, v);
        _offset += 8;
      }
    } else if (v >= -32) {
      _d.setInt8(_offset++, v);
    } else if (v >= -128) {
      _d.setUint8(_offset++, 0xd0);
      _d.setInt8(_offset++, v);
    } else if (v >= -32768) {
      _d.setUint8(_offset++, 0xd1);
      _d.setInt16(_offset, v);
      _offset += 2;
    } else if (v >= -2147483648) {
      _d.setUint8(_offset++, 0xd2);
      _d.setInt32(_offset, v);
      _offset += 4;
    } else {
      _d.setUint8(_offset++, 0xd3);
      _d.setInt64(_offset, v);
      _offset += 8;
    }
  }

  /// Pack [double] or `null`.
  void packDouble(double? v) {
    // 8 byte double + 1 control byte
    if (_buf.length - _offset < 9) _nextBuf();
    if (v == null) {
      _d.setUint8(_offset++, 0xc0);
      return;
    }
    _d.setUint8(_offset++, 0xcb);
    _d.setFloat64(_offset, v);
    _offset += 8;
  }

  /// Pack [String] or `null`.
  ///
  /// Depending on whether your distinguish empty [String] from `null` or not:
  /// - Empty and `null` is same: consider pack empty [String] to `null`, to save 1 byte on a wire.
  /// ```
  /// p.packStringEmptyIsNull(s) //or
  /// p.packString(s.isEmpty ? null : s) //or
  /// s.isEmpty ? p.packNull() : p.packString(s)
  /// ```
  /// - Empty and `null` distinguishable: no action required just save `p.packString(s)`.
  /// Throws [ArgumentError] if [String.length] exceed (2^32)-1.
  void packString(String? v) {
    // max 4 byte str header + 1 control byte
    if (_buf.length - _offset < 5) _nextBuf();
    if (v == null) {
      _d.setUint8(_offset++, 0xc0);
      return;
    }
    final encoded = _strCodec.encode(v);
    final length = encoded.length;
    if (length <= 31) {
      _d.setUint8(_offset++, 0xA0 | length);
    } else if (length <= 0xFF) {
      _d.setUint8(_offset++, 0xd9);
      _d.setUint8(_offset++, length);
    } else if (length <= 0xFFFF) {
      _d.setUint8(_offset++, 0xda);
      _d.setUint16(_offset, length);
      _offset += 2;
    } else if (length <= 0xFFFFFFFF) {
      _d.setUint8(_offset++, 0xdb);
      _d.setUint32(_offset, length);
      _offset += 4;
    } else {
      throw ArgumentError('Max String length is 0xFFFFFFFF');
    }
    _putBytes(encoded);
  }

  /// Convenient function that call [packString(v)] by passing empty [String] as `null`.
  ///
  /// Convenient when you not distinguish between empty [String] and null on msgpack wire.
  /// See [packString] method documentation for more details.
  void packStringEmptyIsNull(String? v) {
    if (v == null || v.isEmpty) {
      packNull();
    } else {
      packString(v);
    }
  }

  /// Pack `List<int>` or null.
  void packBinary(List<int>? buffer) {
    // max 4 byte binary header + 1 control byte
    if (_buf.length - _offset < 5) _nextBuf();
    if (buffer == null) {
      _d.setUint8(_offset++, 0xc0);
      return;
    }
    final length = buffer.length;
    if (length <= 0xFF) {
      _d.setUint8(_offset++, 0xc4);
      _d.setUint8(_offset++, length);
    } else if (length <= 0xFFFF) {
      _d.setUint8(_offset++, 0xc5);
      _d.setUint16(_offset, length);
      _offset += 2;
    } else if (length <= 0xFFFFFFFF) {
      _d.setUint8(_offset++, 0xc6);
      _d.setUint32(_offset, length);
      _offset += 4;
    } else {
      throw ArgumentError('Max binary length is 0xFFFFFFFF');
    }
    _putBytes(buffer);
  }

  /// Pack [List.length] or `null`.
  void packListLength(int? length) {
    // max 4 length header + 1 control byte
    if (_buf.length - _offset < 5) _nextBuf();
    if (length == null) {
      _d.setUint8(_offset++, 0xc0);
    } else if (length <= 0xF) {
      _d.setUint8(_offset++, 0x90 | length);
    } else if (length <= 0xFFFF) {
      _d.setUint8(_offset++, 0xdc);
      _d.setUint16(_offset, length);
      _offset += 2;
    } else if (length <= 0xFFFFFFFF) {
      _d.setUint8(_offset++, 0xdd);
      _d.setUint32(_offset, length);
      _offset += 4;
    } else {
      throw ArgumentError('Max list length is 0xFFFFFFFF');
    }
  }

  /// Pack [Map.length] or `null`.
  void packMapLength(int? length) {
    // max 4 byte header + 1 control byte
    if (_buf.length - _offset < 5) _nextBuf();
    if (length == null) {
      _d.setUint8(_offset++, 0xc0);
    } else if (length <= 0xF) {
      _d.setUint8(_offset++, 0x80 | length);
    } else if (length <= 0xFFFF) {
      _d.setUint8(_offset++, 0xde);
      _d.setUint16(_offset, length);
      _offset += 2;
    } else if (length <= 0xFFFFFFFF) {
      _d.setUint8(_offset++, 0xdf);
      _d.setUint32(_offset, length);
      _offset += 4;
    } else {
      throw ArgumentError('Max map length is 0xFFFFFFFF');
    }
  }

  void packTimestamp(DateTime? v) {
    if (v == null) {
      packNull();
      return;
    }
    var ms = v.millisecondsSinceEpoch;
    var s = (ms / 1000).floor();
    var ns = (ms % 1000) * 1000000;
    if ((s >> 34) == 0) {
      int data64 = (ns << 34) | s;
      if (data64 & 0xffffffff00000000 == 0) {
        // timestamp 32
        _d.setUint8(_offset++, 0xd6);
        _d.setInt8(_offset++, -1);
        _d.setUint32(_offset, data64);
      } else {
        // timestamp 64
        _d.setUint8(_offset++, 0xd7);
        _d.setInt8(_offset++, -1);
        _d.setUint64(_offset, data64);
      }
    } else {
      // timestamp 96
      _d.setUint8(_offset++, 0xc7);
      _d.setUint8(_offset++, 12);
      _d.setInt8(_offset++, -1);
      _d.setUint32(_offset, ns);
      _d.setInt64(_offset, s);
    }
  }

  /// Get bytes representation of this packer.
  /// Note: after this call do not reuse packer - create new.
  Uint8List takeBytes() {
    Uint8List bytes;
    if (_builder.isEmpty) {
      bytes = Uint8List.view(
        _buf.buffer,
        _buf.offsetInBytes,
        _offset,
      );
    } else {
      _flushBuf();
      bytes = _builder.takeBytes();
    }
    return bytes;
  }
}
