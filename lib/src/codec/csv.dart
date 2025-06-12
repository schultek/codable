import 'dart:convert';

import 'package:codable_dart/core.dart';
import 'package:codable_dart/csv.dart';
import 'package:codable_dart/src/codec/codec.dart';
import 'package:codable_dart/src/common/object.dart';

const Codec<Object?, String> csv = CodableCodec(_CsvDelegate(), ObjectCodable());

class _CsvDelegate extends CodableCodecDelegate<String> {
  const _CsvDelegate();

  @override
  T decode<T>(String input, Decodable<T> using) => CsvDecoder.decode(input, using);

  @override
  String encode<T>(T input, Encodable<T> using) => CsvEncoder.encode(input, using: using);

  @override
  CodableCodecDelegate<R>? fuse<R>(Codec<String, R> other) {
    if (other is Utf8Codec) {
      return const _CsvBytesDelegate() as CodableCodecDelegate<R>;
    }
    return null;
  }
}

class _CsvBytesDelegate extends CodableCodecDelegate<List<int>> {
  const _CsvBytesDelegate();

  @override
  T decode<T>(List<int> input, Decodable<T> using) => CsvDecoder.decodeBytes(input, using);

  @override
  List<int> encode<T>(T input, Encodable<T> using) => CsvEncoder.encodeBytes(input, using: using);
}
