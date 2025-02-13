import 'dart:convert';

import 'package:codable/standard.dart';

import '../../core.dart';
import '../common/object.dart';
import 'converter.dart';

typedef DecodeCallback<T> = R Function<R>(T value, Decodable<R> using);
typedef EncodeCallback<T> = T Function<R>(R value, Encodable<R> using);

abstract class CodableCodec<Out> extends Codec<Object?, Out> with CodableCompatibleCodec<Object?, Out> {
  const CodableCodec();

  T performDecode<T>(Out value, {required Decodable<T> using});
  Out performEncode<T>(T value, {required Encodable<T> using});

  @override
  Converter<Out, Object?> get decoder => CallbackConverter(performDecode<Object?>, const ObjectCodable());

  @override
  Converter<Object?, Out> get encoder => CallbackConverter(performEncode<Object?>, const ObjectCodable());

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
  Converter<Out, T> get decoder => CallbackConverter(codec.performDecode<T>, codable);

  @override
  Converter<T, Out> get encoder => CallbackConverter(codec.performEncode<T>, codable);

  @override
  Codec<T, R> fuse<R>(Codec<Out, R> other) {
    final fused = codec.fuse(other);
    if (fused is CodableCodec<R>) {
      return _CodableCodec<T, R>(fused, codable);
    }
    return super.fuse(other);
  }
}
