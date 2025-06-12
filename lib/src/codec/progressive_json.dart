import 'dart:async';
import 'dart:convert';

import 'package:codable_dart/core.dart';
import 'package:codable_dart/src/codec/codec.dart';

import '../../common.dart';
import '../formats/progressive_json.dart';

const Codec<Object?, List<int>> progressiveJson = CodableCodec(_ProgressiveJsonDelegate(), ObjectCodable());

class _ProgressiveJsonDelegate extends CodableCodecDelegate<List<int>> {
  const _ProgressiveJsonDelegate();

  @override
  T decode<T>(List<int> input, Decodable<T> using) => ProgressiveJsonDecoder.decodeSync(input, using);

  @override
  List<int> encode<T>(T input, Encodable<T> using) => ProgressiveJsonEncoder.encodeSync(input, using: using);

  @override
  Sink<List<int>> startChunkedConversion<T>(Sink<T> sink, Decodable<T> decodable) {
    final controller = StreamController<List<int>>();

    final out = ProgressiveJsonDecoder.decode<T>(controller.stream, decodable);
    out.listen(sink.add, onDone: sink.close);

    return controller;
  }
}