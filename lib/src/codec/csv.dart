import 'dart:convert';
import 'dart:typed_data';

import 'package:codable/core.dart';
import 'package:codable/csv.dart';
import 'package:codable/src/codec/codec.dart';

import 'converter.dart';

const CsvCodec csv = CsvCodec();

class CsvCodec extends CodableBaseCodec<Object?, String> {
  const CsvCodec();

  @override
  Object? performDecode(String value) {
    return CsvDecoder.decode(value, const ObjectCodable());
  }

  @override
  String performEncode(Object? value) {
    return CsvEncoder.encode(value, using: const ObjectCodable());
  }

  @override
  Codec<T, String>? fuseCodable<T>(Codable<T> codable) {
    return CsvCodableCodec<T>(codable);
  }
}

class CsvCodableCodec<T> extends CodableCodec<T, String> {
  const CsvCodableCodec(super.codable);

  @override
  T performDecode(String value) {
    return CsvDecoder.decode(value, codable);
  }

  @override
  String performEncode(T value) {
    return CsvEncoder.encode(value, using: codable);
  }

  @override
  Codec<T, To> fuse<To>(Codec<String, To> other) {
    if (other is Utf8Codec) {
      return _CsvUtf8CodableCodec<T>(codable) as Codec<T, To>;
    }
    return super.fuse<To>(other);
  }
}

class _CsvUtf8CodableCodec<T> extends CodableCodec<T, Uint8List> {
  _CsvUtf8CodableCodec(super.codable);

  @override
  T performDecode(Uint8List value) {
    return CsvDecoder.decodeBytes(value, codable);
  }
  
  @override
  Uint8List performEncode(T value) {
    return CsvEncoder.encodeBytes(value, using: codable);
  }
}
