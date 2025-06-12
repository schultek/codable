import 'dart:convert';

import 'package:codable_dart/standard.dart';

import '../../core.dart';

abstract class CodableCodecDelegate<Out> {
  const CodableCodecDelegate();

  T decode<T>(Out input, Decodable<T> using);
  Out encode<T>(T input, Encodable<T> using);

  Sink<Out> startChunkedConversion<T>(Sink<T> sink, Decodable<T> decodable) {
    throw UnsupportedError(
      "This codable does not support chunked conversions: $this",
    );
  }

  CodableCodecDelegate<R>? fuse<R>(Codec<Out, R> other) {
    return null;
  }
}

class CodableCodec<In, Out> extends Codec<In, Out> implements CodableCompatibleCodec<In, Out> {
  const CodableCodec(this.delegate, this.codable);

  final CodableCodecDelegate<Out> delegate;
  final Codable<In> codable;

  @override
  Converter<Out, In> get decoder => _CodableDecoder(delegate, codable);

  @override
  Converter<In, Out> get encoder => _CodableEncoder(delegate, codable);

  @override
  Codec<T, Out>? fuseCodable<T>(Codable<T> codable) {
    return CodableCodec<T, Out>(delegate, codable);
  }

  @override
  Codec<In, R> fuse<R>(Codec<Out, R> other) {
    final d2 = delegate.fuse(other);
    if (d2 != null) {
      return CodableCodec<In, R>(d2, codable);
    } else {
      return super.fuse(other);
    }
  }
}

class _CodableDecoder<In, Out> extends Converter<Out, In> {
  const _CodableDecoder(this.delegate, this.decodable);

  final CodableCodecDelegate<Out> delegate;
  final Decodable<In> decodable;

  @override
  In convert(Out input) => delegate.decode(input, decodable);

  @override
  Sink<Out> startChunkedConversion(Sink<In> sink) {
    return delegate.startChunkedConversion(sink, decodable);
  }
}

class _CodableEncoder<In, Out> extends Converter<In, Out> {
  const _CodableEncoder(this.delegate, this.encodable);

  final CodableCodecDelegate<Out> delegate;
  final Encodable<In> encodable;

  @override
  Out convert(In input) => delegate.encode(input, encodable);
}
