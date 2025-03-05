/// This file contains interfaces and helper utilities to work with generic types.
/// The interfaces follow the same pattern as the [Encodable], [Decodable] and [Codable] interfaces and are
/// suffixed with a number indicating the number of type parameters.
///
/// Generic (en/de/)codables can be combined with child (en/de/)codables for each type parameter through the [use]
/// extension methods:
///
/// ```dart
/// // Generic codables can only encode / decode the base type.
/// final Codable1<Box<dynamic>> boxCodable = ...;
/// // Combine with another codable to get a fully defined codable for the specific type.
/// final Codable<Box<Uri>> boxUriCodable = boxCodable.use(Uri.codable);
/// ```
library generic;

import 'package:codable_dart/core.dart';

// ==============================
// Generics with 1 type parameter
// ==============================

abstract interface class Encodable1<T, A> implements Encodable<T> {
  @override
  void encode(T value, Encoder encoder, [Encodable<A>? encodableA]);
}

/// Variant of [Decodable] that decodes a generic value of type [T] with one type parameter [A].
abstract interface class Decodable1<T, A> implements Decodable<T> {
  /// Decodes a value of type [T] using the [decoder].
  ///
  /// The implementation should first use [Decoder.whatsNext] to determine the type of the encoded data.
  /// Then it should use one of the typed [Decoder].decode...() methods to decode into its target type.
  /// If the returned [DecodingType] is not supported, the implementation can use [Decoder.expect] to throw a detailed error.
  ///
  /// The [decodableA] parameter should be used to decode nested values of type [A]. When it is `null` the
  /// implementation may choose to throw an error or use a fallback way of decoding values of type [A].
  @override
  T decode(Decoder decoder, [Decodable<A>? decodableA]);
}

/// Variant of [Codable] that can encode and decode a generic value of type [T] with one type parameter [A].
abstract class Codable1<T, A> implements Codable<T>, Decodable1<T, A>, Encodable1<T, A> {
  const Codable1();
}

extension UseEncodable1<T, A> on Encodable1<T, A> {
  /// Combines a generic [Encodable1] of type T<A> with an explicit [Encodable] for its type parameter A.
  ///
  /// This will pass [encodableA] to [Encodable1.encode] when encoding a value of type [T].
  Encodable<T> use([Encodable<A>? encodableA]) => _UseEncodable1(this, encodableA);
}

extension UseDecodable1<T, A> on Decodable1<T, A> {
  /// Combines a generic [Decodable1] of type T<A> with an explicit [Decodable] for its type parameter A.
  ///
  /// This will pass [decodableA] to [Decodable1.decode] when decoding a value of type [T].
  Decodable<T> use([Decodable<A>? decodableA]) => _UseDecodable1(this, decodableA);
}

extension UseCodable1<T, A> on Codable1<T, A> {
  /// Combines a generic [Codable1] of type T<A> with an explicit [Codable] for its type parameter A.
  ///
  /// This will pass [codableA] to [Codable1.decode] and [Codable1.encode] when encoding and decoding a value of type [T].
  Codable<T> use([Codable<A>? codableA]) => _UseCodable1(this, codableA);

  /// Combines a generic [Codable1] of type T<A> with an explicit [Decodable] for its type parameter A.
  ///
  /// This will pass [decodableA] to [Codable1.decode] when decoding a value of type [T].
  Decodable<T> useDecodable([Decodable<A>? decodableA]) => _UseDecodable1(this, decodableA);

  /// Combines a generic [Codable1] of type T<A> with an explicit [Encodable] for its type parameter A.
  ///
  /// This will pass [encodableA] to [Codable1.encode] when encoding a value of type [T].
  Encodable<T> useEncodable([Encodable<A>? encodableA]) => _UseEncodable1(this, encodableA);
}

abstract interface class ComposedDecodable1<T, A> implements Decodable<T> {
  /// Extracts the child [Decodable] for the type parameter [A] from the composed [Decodable] for type T<A>.
  R extract<R>(R Function<A>(Decodable<A>? decodableA) fn);
}

class _UseEncodable1<T, A> implements Encodable<T> {
  const _UseEncodable1(this._encodable, this._encodableA);

  final Encodable1<T, A> _encodable;
  final Encodable<A>? _encodableA;

  @override
  void encode(T value, Encoder encoder) {
    _encodable.encode(value, encoder, _encodableA);
  }
}

class _UseDecodable1<T, A> implements ComposedDecodable1<T, A> {
  const _UseDecodable1(this._decodable, this._decodableA);

  final Decodable1<T, A> _decodable;
  final Decodable<A>? _decodableA;

  @override
  T decode(Decoder decoder) {
    return _decodable.decode(decoder, _decodableA);
  }

  @override
  R extract<R>(R Function<A>(Decodable<A>? decodableA) fn) {
    return fn<A>(_decodableA);
  }
}

class _UseCodable1<T, A> implements Codable<T>, ComposedDecodable1<T, A> {
  const _UseCodable1(this._codable, this._codableA);

  final Codable1<T, A> _codable;
  final Codable<A>? _codableA;

  @override
  T decode(Decoder decoder) {
    return _codable.decode(decoder, _codableA);
  }

  @override
  void encode(T value, Encoder encoder) {
    _codable.encode(value, encoder, _codableA);
  }

  @override
  R extract<R>(R Function<A>(Codable<A>? codableA) fn) {
    return fn<A>(_codableA);
  }
}

// ===============================
// Generics with 2 type parameters
// ===============================

/// Variant of [Encodable] that encodes a generic value of type [T] with two type parameters [A] and [B].
abstract interface class Encodable2<T, A, B> implements Encodable<T> {
  /// Encodes the [value] using the [encoder] and optional [Encodable]s for the type parameters [A] and [B].
  ///
  /// The implementation should use one of the typed [Encoder].encode...() methods to encode the value.
  /// It is expected to call exactly one of the encoding methods a single time. Never more or less.
  ///
  /// The [encodableA] and [encodableB] parameters should be used to encode nested values of type [A] and [B].
  /// When either is `null` the implementation may choose to throw an error or use a fallback way of encoding
  /// values either type.
  @override
  void encode(T value, Encoder encoder, [Encodable<A>? encodableA, Encodable<B>? encodableB]);
}

/// Variant of [Decodable] that decodes a generic value of type [T] with two type parameters [A] and [B].
abstract interface class Decodable2<T, A, B> implements Decodable<T> {
  /// Decodes a value of type [T] using the [decoder].
  ///
  /// The implementation should first use [Decoder.whatsNext] to determine the type of the encoded data.
  /// Then it should use one of the typed [Decoder].decode...() methods to decode into its target type.
  /// If the returned [DecodingType] is not supported, the implementation can use [Decoder.expect] to throw a detailed error.
  ///
  /// The [decodableA] and [decodableB] parameters should be used to decode nested values of type [A] and [B].
  /// When either is `null` the implementation may choose to throw an error or use a fallback way of decoding
  /// values of either type.
  @override
  T decode(Decoder decoder, [Decodable<A>? decodableA, Decodable<B>? decodableB]);
}

/// Variant of [Codable] that can encode and decode a generic value of type [T] with two type parameters [A] and [B].
abstract class Codable2<T, A, B> implements Codable<T>, Decodable2<T, A, B>, Encodable2<T, A, B> {
  const Codable2();
}

extension UseEncodable2<T, A, B> on Encodable2<T, A, B> {
  /// Combines a generic [Encodable2] of type T<A, B> with explicit [Encodable]s for its type parameters A and B.
  ///
  /// This will pass [encodableA] and [encodableB] to [Encodable2.encode] when encoding a value of type [T].
  Encodable<T> use([Encodable<A>? encodableA, Encodable<B>? encodableB]) =>
      _UseEncodable2(this, encodableA, encodableB);
}

extension UseDecodable2<T, A, B> on Decodable2<T, A, B> {
  /// Combines a generic [Decodable2] of type T<A, B> with explicit [Decodable]s for its type parameters A and B.
  ///
  /// This will pass [decodableA] and [decodableB] to [Decodable2.decode] when decoding a value of type [T].
  Decodable<T> use([Decodable<A>? decodableA, Decodable<B>? decodableB]) =>
      _UseDecodable2(this, decodableA, decodableB);
}

extension UseCodable2<T, A, B> on Codable2<T, A, B> {
  /// Combines a generic [Codable2] of type T<A, B> with explicit [Codable]s for its type parameters A and B.
  ///
  /// This will pass [codableA] and [codableB] to [Codable2.decode] and [Codable2.encode] when encoding and decoding
  /// a value of type [T].
  Codable<T> use([Codable<A>? codableA, Codable<B>? codableB]) => _UseCodable2(this, codableA, codableB);

  /// Combines a generic [Codable2] of type T<A, B> with an explicit [Decodable]s for its type parameters A and B.
  ///
  /// This will pass [decodableA] and [decodableB] to [Codable2.decode] when decoding a value of type [T].
  Decodable<T> useDecodable([Decodable<A>? decodableA, Decodable<B>? decodableB]) =>
      _UseDecodable2(this, decodableA, decodableB);

  /// Combines a generic [Codable2] of type T<A> with an explicit [Encodable]s for its type parameters A and B.
  ///
  /// This will pass [encodableA] and [encodableB] to [Codable2.encode] when encoding a value of type [T].
  Encodable<T> useEncodable([Encodable<A>? encodableA, Encodable<B>? encodableB]) =>
      _UseEncodable2(this, encodableA, encodableB);
}

abstract interface class ComposedDecodable2<T, A, B> implements Decodable<T> {
  /// Extracts the child [Decodable]s for the type parameters [A] and [B] from the composed [Decodable]
  /// for type T<A, B>.
  R extract<R>(R Function<A, B>(Decodable<A>? decodableA, Decodable<B>? decodableB) fn);
}

class _UseEncodable2<T, A, B> implements Encodable<T> {
  const _UseEncodable2(this._encodable, this.encodableA, this.encodableB);

  final Encodable2<T, A, B> _encodable;
  final Encodable<A>? encodableA;
  final Encodable<B>? encodableB;

  @override
  void encode(T value, Encoder encoder) {
    _encodable.encode(value, encoder, encodableA, encodableB);
  }
}

class _UseDecodable2<T, A, B> implements ComposedDecodable2<T, A, B> {
  const _UseDecodable2(this._decodable, this.decodableA, this.decodableB);

  final Decodable2<T, A, B> _decodable;
  final Decodable<A>? decodableA;
  final Decodable<B>? decodableB;

  @override
  T decode(Decoder decoder) {
    return _decodable.decode(decoder, decodableA, decodableB);
  }

  @override
  R extract<R>(R Function<A, B>(Decodable<A>? decodableA, Decodable<B>? decodableB) fn) {
    return fn<A, B>(decodableA, decodableB);
  }
}

class _UseCodable2<T, A, B> implements Codable<T>, ComposedDecodable2<T, A, B> {
  const _UseCodable2(this._codable, this.codableA, this.codableB);

  final Codable2<T, A, B> _codable;
  final Codable<A>? codableA;
  final Codable<B>? codableB;

  @override
  T decode(Decoder decoder) {
    return _codable.decode(decoder, codableA, codableB);
  }

  @override
  void encode(T value, Encoder encoder) {
    _codable.encode(value, encoder, codableA, codableB);
  }

  @override
  R extract<R>(R Function<A, B>(Codable<A>? codableA, Codable<B>? codableB) fn) {
    return fn<A, B>(codableA, codableB);
  }
}
