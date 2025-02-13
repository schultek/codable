import 'dart:convert';

import 'package:codable/standard.dart';

import '../../core.dart';
import '../common/object.dart';
import 'converter.dart';

typedef DecodeCallback<T> = R Function<R>(T value, Decodable<R> using);
typedef EncodeCallback<T> = T Function<R>(R value, Encodable<R> using);

abstract class CodableCodec<Out> extends Codec<Object?, Out>
    with CodableCompatibleCodec<Object?, Out>  {
  const CodableCodec();

  T performDecode<T>(Out value, Decodable<T> using);
  Out performEncode<T>(T value, Encodable<T> using);

  @override
  Converter<Out, Object?> get decoder => CallbackConverter((v) => performDecode<Object?>(v, const ObjectCodable()));

  @override
  Converter<Object?, Out> get encoder => CallbackConverter((v) => performEncode<Object?>(v, const ObjectCodable()));

  @override
  Codec<T, Out>? fuseCodable<T>(Codable<T> codable) {
    return _CodableCodec<T, Out>(this, codable);
  }
}

class _CodableCodec<T, Out> extends Codec<T, Out> {
  const _CodableCodec(this.codec, this.codable);

  final CodableCodec<Out> codec;
  final Codable<T> codable;

  @override
  Converter<Out, T> get decoder => CallbackConverter((v) => codec.performDecode<T>(v, codable));

  @override
  Converter<T, Out> get encoder => CallbackConverter((v) => codec.performEncode<T>(v, codable));

  @override
  Codec<T, R> fuse<R>(Codec<Out, R> other) {
    final fused = codec.fuse(other);
    if (fused is CodableCodec<R>) {
      return _CodableCodec<T, R>(fused, codable);
    }
    return super.fuse(other);
  }
}
