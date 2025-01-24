import 'dart:convert';

import 'package:codable/core.dart';
import 'package:codable/standard.dart';

import 'converter.dart';

class StandardCodableCodec<T, C extends Codable<T>> extends Codec<T, Object?> {
  final C codable;

  StandardCodableCodec(this.codable);

  @override
  Converter<Object?, T> get decoder => CallbackConverter(
      (input) => StandardDecoder.decode(input, using: codable));

  @override
  Converter<T, Object?> get encoder => CallbackConverter(
      (input) => StandardEncoder.encode<T>(input, using: codable));
}

extension StandardCodec<T> on Codable<T> {
  Codec<T, Object?> get standardCodec =>
      StandardCodableCodec<T, Codable<T>>(this);
}
