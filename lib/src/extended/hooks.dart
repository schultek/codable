
import 'package:codable_dart/core.dart';

import 'generics.dart';

extension CodableHookExtension<T> on Codable<T> {
  /// Returns a [Codable] that applies the provided [Hook] when encoding and decoding [T].
  Codable<T> hook(Hook hook) => CodableHook(this, hook);

  /// If hook is not null, returns a [Codable] that applies the provided [Hook] when encoding and decoding [T].
  /// Else returns this.
  Codable<T> maybeHook(Hook? hook) => hook == null ? this : CodableHook(this, hook);
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

class CodableHook<T> implements Codable<T>, ComposedDecodable<T> {
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
  
  @override
  R unwrap<R>(R Function<A>(Decodable<A>? codable) fn) {
    return fn<T>(codable);
  }
}

class CodableWithHooks<T> implements Codable<T>, ComposedDecodable<T> {
  CodableWithHooks(Codable<T> codable, Hook hook, [Hook? superHook]) : _codable = codable.hook(hook).maybeHook(superHook);

  CodableWithHooks.inherited(Codable<T> codable, Hook hook) : _codable = codable.hook(hook);

  final Codable<T> _codable;

  @override
  T decode(Decoder decoder) {
    return _codable.decode(decoder);
  }

  @override
  void encode(T value, Encoder encoder) {
    _codable.encode(value, encoder);
  }
  
  @override
  R unwrap<R>(R Function<A>(Decodable<A>? codable) fn) {
    return fn<T>(_codable);
  }
}