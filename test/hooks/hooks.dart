import 'package:codable_dart/core.dart';

import 'delegate.dart';

extension CodableHookExtension<T> on Codable<T> {
  /// Returns a [Codable] that applies the provided [Hook] when encoding and decoding [T].
  Codable<T> hook(Hook hook) => CodableHook(this, hook);
}

/// An object that can be used to modify the encoding and decoding behavior of a type of data format.
abstract mixin class Hook {
  /// Called before decoding a value of type [T] using the [decoder] and [decodable].
  ///
  /// The implementation may modify the decoding process by wrapping the [decoder] or [decodable], or
  /// by providing a custom decoding implementation.
  ///
  /// To forward to the original implementation, call `super.decode(decoder, decodable)`.
  T decode<T>(Decoder decoder, Decodable<T> decodable) => decodable.decode(decoder);

  /// Called before encoding a value of type [T] using the [encoder] and [encodable].
  ///
  /// The implementation may modify the encoding process by wrapping the [encoder] or [encodable], or
  /// by providing a custom encoding implementation.
  ///
  /// To forward to the original implementation, call `super.encode(value, encoder, encodable)`.
  void encode<T>(T value, Encoder encoder, Encodable<T> encodable) => encodable.encode(value, encoder);
}

class CodableHook<T> implements Codable<T> {
  const CodableHook(this.codable, this.hook);

  final Codable<T> codable;
  final Hook hook;

  @override
  T decode(Decoder decoder) {
    return hook.decode(decoder, codable);
  }

  @override
  void encode(T value, Encoder encoder) {
    hook.encode(value, encoder, codable);
  }
}

abstract mixin class ProxyHook implements Hook {
  @override
  T decode<T>(Decoder decoder, Decodable<T> decodable) {
    return decodable.decode(ProxyDecoder(decoder, this));
  }

  String visitString(String value) => value;
  String? visitStringOrNull(String? value) => value;

  @override
  void encode<T>(T value, Encoder encoder, Encodable<T> encodable) {
    encoder.encodeObject(value, using: encodable);
  }
}

class ProxyDecoder extends RecursiveDelegatingDecoder {
  ProxyDecoder(super.wrapped, this.hook);

  final ProxyHook hook;

  @override
  String decodeString() {
    return hook.visitString(super.decodeString());
  }

  @override
  String? decodeStringOrNull() {
    return hook.visitStringOrNull(super.decodeStringOrNull());
  }

  @override
  Decoder clone() {
    return ProxyDecoder(delegate.clone(), hook);
  }

  @override
  ProxyDecoder wrap(Decoder decoder) {
    return ProxyDecoder(decoder, hook);
  }
}
