import 'dart:convert' hide JsonDecoder, JsonEncoder;

import 'package:codable_dart/core.dart';
import 'package:codable_dart/src/common/object.dart';

import '../../json.dart';
import 'codec.dart';

const Codec<Object?, String> json = CodableCodec(_JsonDelegate(), ObjectCodable());

class _JsonDelegate extends CodableCodecDelegate<String> {
  const _JsonDelegate();

  @override
  T decode<T>(String input, Decodable<T> using) => JsonDecoder.decode(utf8.encode(input), using);

  @override
  String encode<T>(T input, Encodable<T> using) => utf8.decode(JsonEncoder.encode(input, using: using));

  @override
  CodableCodecDelegate<R>? fuse<R>(Codec<String, R> other) {
    if (other is Utf8Codec) {
      return const _JsonBytesDelegate() as CodableCodecDelegate<R>;
    }
    return null;
  }
}

class _JsonBytesDelegate extends CodableCodecDelegate<List<int>> {
  const _JsonBytesDelegate();

  @override
  T decode<T>(List<int> input, Decodable<T> using) => JsonDecoder.decode(input, using);

  @override
  List<int> encode<T>(T input, Encodable<T> using) => JsonEncoder.encode(input, using: using);
}
