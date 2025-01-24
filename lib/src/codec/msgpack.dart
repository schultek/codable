import 'dart:convert';

import 'package:codable/core.dart';
import 'package:codable/msgpack.dart';

import 'converter.dart';

class MsgPackCodableCodec<T, C extends Codable<T>> extends Codec<T, List<int>> {
  final C codable;

  MsgPackCodableCodec(this.codable);

  @override
  Converter<List<int>, T> get decoder =>
      CallbackConverter((input) => MsgPackDecoder.decode(input, codable));

  @override
  Converter<T, List<int>> get encoder => CallbackConverter(
      (input) => MsgPackEncoder.encode<T>(input, using: codable));
}

extension MsgPackCodec<T> on Codable<T> {
  Codec<T, List<int>> get mgsPackCodec =>
      MsgPackCodableCodec<T, Codable<T>>(this);
}
