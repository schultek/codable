import 'package:codable/core.dart';

import 'generics.dart';

final class CodableUtils {
  static Codable<T> fromHandlers<T>({
    required T Function(Decoder decoder) decode,
    required void Function(T value, Encoder encoder) encode,
  }) =>
      _CodableFromHandlers(decode, encode);

  static Codable1<T, A> fromHandlers1<T, A>({
    required T Function<A>(Decoder decoder, [Decodable<A>? decodableA]) decode,
    required void Function<A>(T value, Encoder encoder, [Encodable<A>? encodableA]) encode,
  }) =>
      _Codable1FromHandlers(decode, encode);
}

final class DecodableUtils {
  static Decodable<T> fromHandler<T>({
    required T Function(Decoder decoder) decode,
  }) =>
      _DecodableFromHandler(decode);
}

final class EncodeUtils {
  static Encodable<T> fromHandler<T>({
    required void Function(T value, Encoder encoder) encode,
  }) =>
      _EncodeFromHandler(encode);
}

final class _DecodableFromHandler<T> implements Decodable<T> {
  const _DecodableFromHandler(this._decode);

  final T Function(Decoder decoder) _decode;

  @override
  T decode(Decoder decoder) => _decode(decoder);
}

final class _EncodeFromHandler<T> implements Encodable<T> {
  const _EncodeFromHandler(this._encode);

  final void Function(T value, Encoder encoder) _encode;

  @override
  void encode(T value, Encoder encoder) => _encode(value, encoder);
}

final class _CodableFromHandlers<T> implements Codable<T> {
  const _CodableFromHandlers(this._decode, this._encode);

  final T Function(Decoder decoder) _decode;
  final void Function(T value, Encoder encoder) _encode;

  @override
  T decode(Decoder decoder) => _decode(decoder);
  @override
  void encode(T value, Encoder encoder) => _encode(value, encoder);
}

final class _Codable1FromHandlers<T, A> implements Codable1<T, A> {
  const _Codable1FromHandlers(this._decode, this._encode);

  final T Function(Decoder decoder, [Decodable<A>? decodableA]) _decode;
  final void Function(T value, Encoder encoder, [Encodable<A>? encodableA]) _encode;

  @override
  T decode(Decoder decoder, [Decodable<A>? decodableA]) => _decode(decoder, decodableA);
  @override
  void encode(covariant T value, Encoder encoder, [Encodable<A>? encodableA]) => _encode(value, encoder, encodableA);
}
