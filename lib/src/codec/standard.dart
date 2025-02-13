import 'dart:convert';

import 'package:codable/core.dart';
import 'package:codable/standard.dart';

import '../../json.dart';
import 'converter.dart';

class StandardCodableCodec<T, C extends Codable<T>> extends Codec<T, Object?> {
  final C codable;

  StandardCodableCodec(this.codable);

  @override
  Converter<Object?, T> get decoder => CallbackConverter(StandardDecoder.decode<T>, codable);

  @override
  Converter<T, Object?> get encoder => CallbackConverter(StandardEncoder.encode<T>, codable);

  @override
  Codec<T, R> fuse<R>(Codec<Object?, R> other) {
    if (other is JsonCodec) {
      return JsonCodableCodec().fuseCodable(codable) as Codec<T, R>;
    } else if (other is CodableCompatibleCodec<dynamic, R>) {
      return other.fuseCodable(codable) ?? super.fuse(other);
    } else {
      return super.fuse(other);
    }
  }
}

mixin CodableCompatibleCodec<In, Out> on Codec<In, Out> {
  Codec<T, Out>? fuseCodable<T>(Codable<T> codable);
}

extension StandardCodec<T> on Codable<T> {
  Codec<T, Object?> get codec => StandardCodableCodec<T, Codable<T>>(this);
}
