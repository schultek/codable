/// CSV reference implementation.
///
/// This is limited to simple values only, no nested objects or lists.
/// Values are separated by ",".
///
/// Different to other formats, this implementation operates exclusively on lists
/// of models, since all CSV data consists of a number of rows.
library csv;

import 'dart:convert';
import 'dart:typed_data';

import 'package:codable/core.dart';
import 'package:codable/extended.dart';

extension CsvDecodable<T> on Decodable<T> {
  /// Decodes a CSV string into a list of objects.
  List<T> fromCsv(String csv) {
    return CsvDecoder.decode(csv, this);
  }

  List<T> fromCsvBytes(Uint8List bytes) {
    return CsvDecoder.decodeBytes(bytes, this);
  }
}

extension CsvEncodable<T> on Encodable<T> {
  /// Encodes a list of objects into a CSV string.
  String toCsv(Iterable<T> value) {
    return CsvEncoder.encode(value, using: this);
  }

  Uint8List toCsvBytes(Iterable<T> value) {
    return CsvEncoder.encodeBytes(value, using: this);
  }
}

extension CsvSelfEncodable<T extends SelfEncodable> on Iterable<T> {
  /// Encodes a list of objects into a CSV string.
  String toCsv() {
    return CsvEncoder.encode(this);
  }
}

class CsvDecoder with _CsvDecoder implements Decoder {
  CsvDecoder._(
    this.buffer, [
    this._offset = 0,
    List<String>? keys,
  ]) {
    this.keys = keys ?? [];
    if (keys == null) {
      _readKeys();
    }
  }

  static List<T> decode<T>(String value, Decodable<T> decodable) {
    final decoder = CsvDecoder._(value.codeUnits);
    return decoder.decodeRows(decodable);
  }

  static List<T> decodeBytes<T>(Uint8List value, Decodable<T> decodable) {
    final decoder = CsvDecoder._(Uint16List.view(value.buffer));
    return decoder.decodeRows(decodable);
  }

  @override
  final List<int> buffer;
  @override
  int _offset;

  late final List<String> keys;

  void _readKeys() {
    while (true) {
      keys.add(_readString());
      if (_offset >= buffer.length) {
        break;
      } else if (buffer[_offset] == tokenComma) {
        _offset++;
        continue;
      } else if (_skipWhitespace()) {
        break;
      } else {
        throw CodableException.unexpectedType(
            expected: ', or end of line', data: buffer, offset: _offset);
      }
    }
  }

  List<T> decodeRows<T>(Decodable<T> decodable) {
    final rows = <T>[];

    while (_offset < buffer.length) {
      if (buffer[_offset] != tokenLineFeed) {
        throw CodableException.unexpectedType(
            expected: 'end of line', data: buffer, offset: _offset);
      }
      _offset++;
      if (_offset >= buffer.length) {
        break;
      }
      rows.add(decodeObject(using: decodable));
    }

    return rows;
  }

  @override
  DecodingType whatsNext() {
    return DecodingType.keyed;
  }

  @override
  bool decodeBool() {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeBool',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  bool? decodeBoolOrNull() {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeBoolOrNull',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  int decodeInt() {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeInt',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  int? decodeIntOrNull() {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeIntOrNull',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  double decodeDouble() {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeDouble',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  double? decodeDoubleOrNull() {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeDoubleOrNull',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  num decodeNum() {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeNum',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  num? decodeNumOrNull() {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeNumOrNull',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  String decodeString() {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeString',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  String? decodeStringOrNull() {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeStringOrNull',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  bool decodeIsNull() {
    return false;
  }

  @override
  T decodeObject<T>({Decodable<T>? using}) {
    if (using != null) {
      return using.decode(this);
    } else {
      throw CodableException.unexpectedType(
          expected: 'Decodable', actual: '$T');
    }
  }

  @override
  T? decodeObjectOrNull<T>({Decodable<T>? using}) {
    return decodeObject(using: using);
  }

  @override
  List<E> decodeList<E>({Decodable<E>? using}) {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeList',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  List<E>? decodeListOrNull<E>({Decodable<E>? using}) {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeListOrNull',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  Map<K, V> decodeMap<K, V>(
      {Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeMap',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  Map<K, V>? decodeMapOrNull<K, V>(
      {Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeMapOrNull',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  IteratedDecoder decodeIterated() {
    throw CodableException.unsupportedMethod('CsvDecoder', 'decodeIterated',
        reason:
            'Row-level decoding only supports decodeKeyed() and decodeMapped().');
  }

  @override
  KeyedDecoder decodeKeyed() {
    return CsvKeyedDecoder._(this);
  }

  @override
  MappedDecoder decodeMapped() {
    return CompatMappedDecoder.wrap(decodeKeyed());
  }

  @override
  bool isHumanReadable() {
    return true;
  }

  @override
  Decoder clone() {
    return CsvDecoder._(buffer, _offset, keys);
  }

  @override
  Never expect(String expect) {
    throw CodableException.unexpectedType(
        expected: expect, data: buffer, offset: _offset);
  }
}

abstract mixin class _CsvDecoder {
  List<int> get buffer;
  int get _offset;
  set _offset(int value);

  String _readString() {
    if (_skipWhitespace()) {
      return '';
    }
    if (buffer[_offset] == tokenDoubleQuote) {
      return _readQuotedString();
    }
    return _readUnquotedString();
  }

  String _readQuotedString() {
    if (buffer[_offset] != tokenDoubleQuote) {
      throw CodableException.unexpectedType(
          expected: '"', data: buffer, offset: _offset);
    }
    final start = _offset + 1;
    var i = start;
    while (true) {
      final c = buffer[i++];
      if (c == tokenDoubleQuote) {
        _offset = i;
        return String.fromCharCodes(buffer, start, i - 1);
      }
    }
  }

  String _readUnquotedString() {
    if (_offset >= buffer.length) {
      return '';
    }
    final start = _offset;
    var i = start;
    while (true) {
      final c = buffer[i];
      if (c == tokenLineFeed || c == tokenComma) {
        _offset = i;
        return String.fromCharCodes(buffer, start, i);
      }
      i++;
      if (i >= buffer.length) {
        _offset = i;
        return String.fromCharCodes(buffer, start, i);
      }
    }
  }

  bool _skipWhitespace() {
    var i = _offset;
    while (i < buffer.length) {
      if (buffer[i] > tokenSpace) {
        break;
      } else if (buffer[i] == tokenLineFeed) {
        _offset = i;
        return true;
      }
      i++;
    }
    _offset = i;
    return false;
  }
}

class CsvKeyedDecoder implements KeyedDecoder {
  CsvKeyedDecoder._(this._parent, [this._key = -1]);

  final CsvDecoder _parent;
  int _key;

  @override
  DecodingType whatsNext() {
    if (decodeIsNull()) return DecodingType.nil;
    return DecodingType.unknown;
  }

  @override
  bool decodeBool() {
    final value = _parent._readString().toLowerCase();
    return value == 'true' || value == 'yes' || value == '1';
  }

  @override
  bool? decodeBoolOrNull() {
    if (decodeIsNull()) return null;
    return decodeBool();
  }

  @override
  int decodeInt() {
    return int.parse(_parent._readString());
  }

  @override
  int? decodeIntOrNull() {
    if (decodeIsNull()) return null;
    return int.parse(_parent._readString());
  }

  @override
  double decodeDouble() {
    return double.parse(_parent._readString());
  }

  @override
  double? decodeDoubleOrNull() {
    if (decodeIsNull()) return null;
    return double.parse(_parent._readString());
  }

  @override
  num decodeNum() {
    return num.parse(_parent._readString());
  }

  @override
  num? decodeNumOrNull() {
    if (decodeIsNull()) return null;
    return num.parse(_parent._readString());
  }

  @override
  String decodeString() {
    return _parent._readString();
  }

  @override
  String? decodeStringOrNull() {
    if (decodeIsNull()) return null;
    return _parent._readString();
  }

  @override
  bool decodeIsNull() {
    switch (_parent.buffer[_parent._offset]) {
      case tokenComma:
      case tokenLineFeed:
        return true;
      default:
        return false;
    }
  }

  @override
  T decodeObject<T>({Decodable<T>? using}) {
    if (using != null) {
      return using.decode(this);
    } else {
      return _parent._readString() as T;
    }
  }

  @override
  T? decodeObjectOrNull<T>({Decodable<T>? using}) {
    if (decodeIsNull()) return null;

    return decodeObject(using: using);
  }

  @override
  List<E> decodeList<E>({Decodable<E>? using}) {
    throw CodableException.unsupportedMethod('CsvKeyedDecoder', 'decodeList',
        reason: 'The csv format does not support nested lists.');
  }

  @override
  List<E>? decodeListOrNull<E>({Decodable<E>? using}) {
    throw CodableException.unsupportedMethod(
        'CsvKeyedDecoder', 'decodeListOrNull',
        reason: 'The csv format does not support nested lists.');
  }

  @override
  Map<K, V> decodeMap<K, V>(
      {Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    throw CodableException.unsupportedMethod('CsvKeyedDecoder', 'decodeMap',
        reason: 'The csv format does not support nested maps.');
  }

  @override
  Map<K, V>? decodeMapOrNull<K, V>(
      {Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    throw CodableException.unsupportedMethod(
        'CsvKeyedDecoder', 'decodeMapOrNull',
        reason: 'The csv format does not support nested maps.');
  }

  @override
  IteratedDecoder decodeIterated() {
    throw CodableException.unsupportedMethod(
        'CsvKeyedDecoder', 'decodeIterated',
        reason: 'The csv format does not support nested collections.');
  }

  @override
  KeyedDecoder decodeKeyed() {
    throw CodableException.unsupportedMethod('CsvKeyedDecoder', 'decodeKeyed',
        reason: 'The csv format does not support nested objects.');
  }

  @override
  MappedDecoder decodeMapped() {
    throw CodableException.unsupportedMethod('CsvKeyedDecoder', 'decodeMapped',
        reason: 'The csv format does not support nested objects.');
  }

  @override
  Object? nextKey() {
    if (_parent._offset >= _parent.buffer.length) {
      return null;
    }
    _key++;
    if (_key >= _parent.keys.length) {
      if (_parent.buffer[_parent._offset] != tokenLineFeed) {
        throw CodableException.unexpectedType(
            expected: 'end of line',
            data: _parent.buffer,
            offset: _parent._offset);
      }
      return null;
    }
    if (_key > 0) {
      if (_parent.buffer[_parent._offset] != tokenComma) {
        throw CodableException.unexpectedType(
            expected: ',', data: _parent.buffer, offset: _parent._offset);
      }
      _parent._offset++;
    }
    return _parent.keys[_key];
  }

  @override
  void skipCurrentValue() {
    _skip();
  }

  @override
  void skipRemainingKeys() {
    var i = _parent._offset;
    while (i < _parent.buffer.length) {
      if (_parent.buffer[i] == tokenLineFeed) {
        _parent._offset = i;
        return;
      }
      i++;
    }
    _parent._offset = i;
  }

  void _skip() {
    var i = _parent._offset;
    var quoted = false;
    while (i < _parent.buffer.length) {
      if (_parent.buffer[i] == tokenDoubleQuote) {
        quoted = !quoted;
      } else if (!quoted && _parent.buffer[i] == tokenComma) {
        _parent._offset = i++;
        return;
      }
      i++;
    }
    _parent._offset = i;
  }

  @override
  bool isHumanReadable() {
    return true;
  }

  @override
  KeyedDecoder clone() {
    return CsvKeyedDecoder._(_parent, _key);
  }

  @override
  Never expect(String expected) {
    throw CodableException.unexpectedType(
        expected: expected, data: _parent.buffer, offset: _parent._offset);
  }
}

class CsvEncoder<S extends Sink<String>> implements Encoder {
  CsvEncoder._(this.writer);

  static String encode<T>(Iterable<T> value, {Encodable<T>? using}) {
    final sink = _StringBufferSink();
    final encoder = CsvEncoder._(sink);
    for (final e in value) {
      encoder.encodeObject(e, using: using);
    }
    return '${encoder.keys.join(',')}\n${sink.buffer}';
  }

  static Uint8List encodeBytes<T>(Iterable<T> value, {Encodable<T>? using}) {
    final encoder = CsvEncoder._(_StringBytesSink());
    for (final e in value) {
      encoder.encodeObject(e, using: using);
    }
    // TODO: can we do a chunked encoding here? It is hard when
    return utf8.encode('${encoder.keys.join(',')}\n${encoder.writer}');
  }

  final List<String> keys = [];
  final S writer;

  @override
  void encodeBool(bool value) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeBool',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeBoolOrNull(bool? value) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeBoolOrNull',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeInt(int value) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeInt',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeIntOrNull(int? value) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeIntOrNull',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeDouble(double value) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeDouble',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeDoubleOrNull(double? value) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeDoubleOrNull',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeNum(num value) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeNum',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeNumOrNull(num? value) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeNumOrNull',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeString(String value) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeString',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeStringOrNull(String? value) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeStringOrNull',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeNull() {}

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
      throw CodableException.unexpectedType(
          expected: 'Encodable or SelfEncodable', actual: '$T', data: value);
    }
  }

  @override
  void encodeObjectOrNull<T>(T? value, {Encodable<T>? using}) {
    if (value == null) return;
    encodeObject(value, using: using);
  }

  @override
  void encodeIterable<E>(Iterable<E> value, {Encodable<E>? using}) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeIterable',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeIterableOrNull<E>(Iterable<E>? value, {Encodable<E>? using}) {
    throw CodableException.unsupportedMethod(
        'CsvEncoder', 'encodeIterableOrNull',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeMap<K, V>(Map<K, V> value,
      {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeMap',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  void encodeMapOrNull<K, V>(Map<K, V>? value,
      {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeMapOrNull',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  IteratedEncoder encodeIterated() {
    throw CodableException.unsupportedMethod('CsvEncoder', 'encodeIterated',
        reason:
            'Row-level encoding only supports encodeKeyed() and encodeMapped().');
  }

  @override
  KeyedEncoder encodeKeyed() {
    return CsvKeyedEncoder(writer, keys);
  }

  @override
  bool isHumanReadable() {
    return true;
  }
}

class CsvKeyedEncoder implements KeyedEncoder {
  CsvKeyedEncoder(this.writer, this.keys, [this._key = 0]);

  final Sink<String> writer;
  final List<String> keys;
  int _key;

  late final _child = CsvValueEncoder(writer);

  void _encodeKey(String k) {
    if (_key > 0) writer.add(',');

    if (_key < keys.length) {
      assert(k == keys[_key]);
    } else {
      keys.add(k);
    }
    _key++;
  }

  @override
  void encodeBool(String key, bool value, {int? id}) {
    _encodeKey(key);
    writer.add('$value');
  }

  @override
  void encodeBoolOrNull(String key, bool? value, {int? id}) {
    _encodeKey(key);
    if (value == null) return;
    writer.add('$value');
  }

  @override
  void encodeInt(String key, int value, {int? id}) {
    _encodeKey(key);
    writer.add('$value');
  }

  @override
  void encodeIntOrNull(String key, int? value, {int? id}) {
    _encodeKey(key);
    if (value == null) return;
    writer.add('$value');
  }

  @override
  void encodeDouble(String key, double value, {int? id}) {
    _encodeKey(key);
    writer.add('$value');
  }

  @override
  void encodeDoubleOrNull(String key, double? value, {int? id}) {
    _encodeKey(key);
    if (value == null) return;
    writer.add('$value');
  }

  @override
  void encodeNum(String key, num value, {int? id}) {
    _encodeKey(key);
    writer.add('$value');
  }

  @override
  void encodeNumOrNull(String key, num? value, {int? id}) {
    _encodeKey(key);
    if (value == null) return;
    writer.add('$value');
  }

  @override
  void encodeString(String key, String value, {int? id}) {
    _encodeKey(key);
    _child.encodeString(value);
  }

  @override
  void encodeStringOrNull(String key, String? value, {int? id}) {
    _encodeKey(key);
    _child.encodeStringOrNull(value);
  }

  @override
  void encodeNull(String key, {int? id}) {
    _encodeKey(key);
  }

  @override
  bool canEncodeCustom<T>() {
    return false;
  }

  @override
  void encodeObject<T>(String key, T value, {int? id, Encodable<T>? using}) {
    _encodeKey(key);
    _child.encodeObject(value, using: using);
  }

  @override
  void encodeObjectOrNull<T>(String key, T? value,
      {int? id, Encodable<T>? using}) {
    _encodeKey(key);
    _child.encodeObjectOrNull(value, using: using);
  }

  @override
  void encodeIterable<E>(String key, Iterable<E> value,
      {int? id, Encodable<E>? using}) {
    throw CodableException.unsupportedMethod(
        'CsvKeyedEncoder', 'encodeIterable',
        reason: 'The csv format does not support nested iterables.');
  }

  @override
  void encodeIterableOrNull<E>(String key, Iterable<E>? value,
      {int? id, Encodable<E>? using}) {
    throw CodableException.unsupportedMethod(
        'CsvKeyedEncoder', 'encodeIterableOrNull',
        reason: 'The csv format does not support nested iterables.');
  }

  @override
  void encodeMap<K, V>(String key, Map<K, V> value,
      {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    throw CodableException.unsupportedMethod('CsvKeyedEncoder', 'encodeMap',
        reason: 'The csv format does not support nested maps.');
  }

  @override
  void encodeMapOrNull<K, V>(String key, Map<K, V>? value,
      {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    throw CodableException.unsupportedMethod(
        'CsvKeyedEncoder', 'encodeMapOrNull',
        reason: 'The csv format does not support nested maps.');
  }

  @override
  IteratedEncoder encodeIterated(String key, {int? id}) {
    throw CodableException.unsupportedMethod(
        'CsvKeyedEncoder', 'encodeIterated',
        reason: 'The csv format does not support nested collections.');
  }

  @override
  KeyedEncoder encodeKeyed(String key, {int? id}) {
    throw CodableException.unsupportedMethod('CsvKeyedEncoder', 'encodeKeyed',
        reason: 'The csv format does not support nested objects.');
  }

  @override
  bool isHumanReadable() {
    return true;
  }

  @override
  void end() {
    writer.add('\n');
  }
}

class CsvValueEncoder implements Encoder {
  CsvValueEncoder(this.writer);

  final Sink<String> writer;

  @override
  void encodeBool(bool value) {
    writer.add('$value');
  }

  @override
  void encodeBoolOrNull(bool? value) {
    if (value == null) return;
    writer.add('$value');
  }

  @override
  void encodeInt(int value) {
    writer.add('$value');
  }

  @override
  void encodeIntOrNull(int? value) {
    if (value == null) return;
    writer.add('$value');
  }

  @override
  void encodeDouble(double value) {
    writer.add('$value');
  }

  @override
  void encodeDoubleOrNull(double? value) {
    if (value == null) return;
    writer.add('$value');
  }

  @override
  void encodeNum(num value) {
    writer.add('$value');
  }

  @override
  void encodeNumOrNull(num? value) {
    if (value == null) return;
    writer.add('$value');
  }

  @override
  void encodeString(String value) {
    if (value.contains(',')) {
      writer.add('"$value"');
    } else {
      writer.add(value);
    }
  }

  @override
  void encodeStringOrNull(String? value) {
    if (value == null) return;
    encodeString(value);
  }

  @override
  void encodeNull() {}

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
      encodeString(value.toString());
    }
  }

  @override
  void encodeObjectOrNull<T>(T? value, {Encodable<T>? using}) {
    if (value == null) return;
    encodeObject(value, using: using);
  }

  @override
  void encodeIterable<E>(Iterable<E> value, {Encodable<E>? using}) {
    throw CodableException.unsupportedMethod(
        'CsvValueEncoder', 'encodeIterable',
        reason: 'The csv format does not support nested iterables.');
  }

  @override
  void encodeIterableOrNull<E>(Iterable<E>? value, {Encodable<E>? using}) {
    throw CodableException.unsupportedMethod(
        'CsvValueEncoder', 'encodeIterableOrNull',
        reason: 'The csv format does not support nested iterables.');
  }

  @override
  void encodeMap<K, V>(Map<K, V> value,
      {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    throw CodableException.unsupportedMethod('CsvValueEncoder', 'encodeMap',
        reason: 'The csv format does not support nested maps.');
  }

  @override
  void encodeMapOrNull<K, V>(Map<K, V>? value,
      {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    throw CodableException.unsupportedMethod(
        'CsvValueEncoder', 'encodeMapOrNull',
        reason: 'The csv format does not support nested maps.');
  }

  @override
  IteratedEncoder encodeIterated() {
    throw CodableException.unsupportedMethod(
        'CsvValueEncoder', 'encodeIterated',
        reason: 'The csv format does not support nested collections.');
  }

  @override
  KeyedEncoder encodeKeyed() {
    throw CodableException.unsupportedMethod('CsvValueEncoder', 'encodeKeyed',
        reason: 'The csv format does not support nested objects.');
  }

  @override
  bool isHumanReadable() {
    return true;
  }
}

class _StringBufferSink implements Sink<String> {
  final buffer = StringBuffer();

  @override
  void add(String data) {
    buffer.write(data);
  }

  @override
  // TODO: Add a guard?
  void close() {}
}

class _StringBytesSink implements Sink<String> {
  final buffer = BytesBuilder(copy: false);
  late final builder = utf8.encoder
      .startChunkedConversion(ByteConversionSink.withCallback(buffer.add));

  @override
  void add(String data) {
    builder.add(data);
  }

  @override
  void close() {
    builder.close();
  }
}

const tokenSpace = 0x20;
const tokenLineFeed = 0x0A;

const tokenDoubleQuote = 0x22;
const tokenComma = 0x2C;
