import 'dart:convert';

import 'package:codable_dart/msgpack.dart';
import 'package:codable_dart/src/core/interface.dart';

import '../../common.dart';
import 'codec.dart';

const Codec<Object?, List<int>> msgPack = CodableCodec(_MsgPackDelegate(), ObjectCodable());

class _MsgPackDelegate extends CodableCodecDelegate<List<int>> {
  const _MsgPackDelegate();

  @override
  T decode<T>(List<int> input, Decodable<T> using) => MsgPackDecoder.decode(input, using);

  @override
  List<int> encode<T>(T input, Encodable<T> using) => MsgPackEncoder.encode(input, using: using);
}
