import 'dart:convert';

import 'package:codable/core.dart';
import 'package:codable/json.dart';

import 'converter.dart';

class JsonCodableCodec<T, C extends Codable<T>> extends Codec<T, List<int>> {
  final C codable;

  JsonCodableCodec(this.codable);

  @override
  Converter<List<int>, T> get decoder =>
      CallbackConverter((input) => JsonDecoder.decode(input, codable));

  @override
  Converter<T, List<int>> get encoder => CallbackConverter(
      (input) => JsonEncoder.encode<T>(input, using: codable));
}

extension JsonCodec<T> on Codable<T> {
  Codec<T, List<int>> get jsonCodec => JsonCodableCodec<T, Codable<T>>(this);
}
