import 'dart:convert';
import 'dart:typed_data';

import 'package:codable/core.dart';
import 'package:codable/csv.dart';
import 'package:codable/src/codec/codec.dart';

const CsvCodec csv = CsvCodec();

class CsvCodec extends CodableCodec<String> {
  const CsvCodec();

  @override
  T performDecode<T>(String value, {required Decodable<T> using}) {
    return CsvDecoder.decode(value, using);
  }

  @override
  String performEncode<T>(T value, {required Encodable<T> using}) {
    return CsvEncoder.encode(value, using: using);
  }

  @override
  Codec<Object?, To> fuse<To>(Codec<String, To> other) {
    if (other is Utf8Codec) {
      return _CsvUtf8CodableCodec() as Codec<Object?, To>;
    }
    return super.fuse<To>(other);
  }
}

class _CsvUtf8CodableCodec extends CodableCodec<Uint8List> {
  @override
  T performDecode<T>(Uint8List value, {required Decodable<T> using}) {
    return CsvDecoder.decodeBytes(value, using);
  }

  @override
  Uint8List performEncode<T>(T value, {required Encodable<T> using}) {
    return CsvEncoder.encodeBytes(value, using: using);
  }
}
