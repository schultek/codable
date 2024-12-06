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

import 'package:codable/core.dart';

// ==============================
// Generics with 1 type parameter
// ==============================

/// Variant of [SelfEncodable] that encodes a generic value of type [T] with one type parameter [A].
abstract interface class SelfEncodable1<A> implements SelfEncodable {
  /// Encodes the object using the [encoder] and an optional [Encodable] for the type parameter [A].
  ///
  /// The implementation should use one of the typed [Encoder].encode...() methods to encode the value.
  /// It is expected to call exactly one of the encoding methods a single time. Never more or less.
  ///
  /// The [encodableA] parameter should be used to encode nested values of type [A]. When it is `null` the
  /// implementation may choose to throw an error or use a fallback way of encoding values of type [A].
  @override
  void encode(Encoder encoder, [Encodable<A>? encodableA]);
}

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

abstract class SelfCodable1<T extends SelfEncodable1<A>, A> implements Codable1<T, A> {
  const SelfCodable1();

  @override
  void encode(T value, Encoder encoder, [Encodable<A>? encodableA]) {
    value.encode(encoder, encodableA);
  }
}

extension UseSelfEncodable1<T, A> on SelfEncodable1<A> {
  /// Combines a generic [SelfEncodable1] of type T<A> with an explicit [Encodable] for its type parameter A.
  ///
  /// This will pass [encodableA] to [SelfEncodable1.encode] when encoding a value of type [T].
  SelfEncodable use([Encodable<A>? encodableA]) => _UseSelfEncodable1(this, encodableA);
}

extension UseEncodable1<T, A> on Encodable1<T, A> {
  /// Combines a generic [Encodable1] of type T<A> with an explicit [Encodable] for its type parameter A.
  ///
  /// This will pass [encodableA] to [SelfEncodable1.encode] when encoding a value of type [T].
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
}

abstract interface class ComposedEncodable1<T, A> implements Encodable<T> {
  /// Extracts the child [Encodable] for the type parameter [A] from the composed [Encodable] for type T<A>.
  R extract<R>(R Function<A>(Encodable<A>? encodableA) fn);
}

abstract interface class ComposedDecodable1<T, A> implements Decodable<T> {
  /// Extracts the child [Decodable] for the type parameter [A] from the composed [Decodable] for type T<A>.
  R extract<R>(R Function<A>(Decodable<A>? decodableA) fn);
}

abstract interface class ComposedCodable1<T, A>
    implements Codable<T>, ComposedEncodable1<T, A>, ComposedDecodable1<T, A> {
  /// Extracts the child [Codable] for the type parameter [A] from the composed [Codable] for type T<A>.
  R extract<R>(R Function<A>(Codable<A>? codableA) fn);
}

class _UseSelfEncodable1<T, A> implements SelfEncodable {
  const _UseSelfEncodable1(this._selfEncodable, this._encodableA);

  final SelfEncodable1<A> _selfEncodable;
  final Encodable<A>? _encodableA;

  @override
  void encode(Encoder encoder) {
    _selfEncodable.encode(encoder, _encodableA);
  }
}

class _UseEncodable1<T, A> implements ComposedEncodable1<T, A> {
  const _UseEncodable1(this._encodable, this._encodableA);

  final Encodable1<T, A> _encodable;
  final Encodable<A>? _encodableA;

  @override
  void encode(T value, Encoder encoder) {
    _encodable.encode(value, encoder, _encodableA);
  }

  @override
  R extract<R>(R Function<A>(Encodable<A>? encodableA) fn) {
    return fn<A>(_encodableA);
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

class _UseCodable1<T, A> implements ComposedCodable1<T, A> {
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

/// Variant of [SelfEncodable] that encodes a generic value of type [T] with one type parameter [A].
abstract interface class SelfEncodable2<A, B> implements SelfEncodable {
  /// Encodes the object using the [encoder] and an optional [Encodable] for the type parameter [A].
  ///
  /// The implementation should use one of the typed [Encoder].encode...() methods to encode the value.
  /// It is expected to call exactly one of the encoding methods a single time. Never more or less.
  ///
  /// The [encodableA] parameter should be used to encode nested values of type [A]. When it is `null` the
  /// implementation may choose to throw an error or use a fallback way of encoding values of type [A].
  @override
  void encode(Encoder encoder, [Encodable<A>? encodableA, Encodable<B>? encodableB]);
}

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

extension UseSelfEncodable2<A, B> on SelfEncodable2<A, B> {
  /// Combines a generic [SelfEncodable2] of type T<A, B> with explicit [Encodable]s for its type parameters A and B.
  ///
  /// This will pass [encodableA] and [encodableB] to [Encodable2.encode] when encoding a value of type [T].
  SelfEncodable use([Encodable<A>? encodableA, Encodable<B>? encodableB]) =>
      _UseSelfEncodable2(this, encodableA, encodableB);
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
}

abstract interface class ComposedEncodable2<T, A, B> implements Encodable<T> {
  /// Extracts the child [Encodable]s for the type parameters [A] and [B] from the composed [Encodable]
  /// for type T<A, B>.
  R extract<R>(R Function<A, B>(Encodable<A>? encodableA, Encodable<B>? encodableB) fn);
}

abstract interface class ComposedDecodable2<T, A, B> implements Decodable<T> {
  /// Extracts the child [Decodable]s for the type parameters [A] and [B] from the composed [Decodable]
  /// for type T<A, B>.
  R extract<R>(R Function<A, B>(Decodable<A>? decodableA, Decodable<B>? decodableB) fn);
}

abstract interface class ComposedCodable2<T, A, B>
    implements Codable<T>, ComposedEncodable2<T, A, B>, ComposedDecodable2<T, A, B> {
  /// Extracts the child [Codable]s for the type parameters [A] and [B] from the composed [Codable]
  /// for type T<A, B>.
  R extract<R>(R Function<A, B>(Codable<A>? codableA, Codable<B>? codableB) fn);
}

class _UseSelfEncodable2<T, A, B> implements SelfEncodable {
  const _UseSelfEncodable2(this._selfEncodable, this._encodableA, this._encodableB);

  final SelfEncodable2<A, B> _selfEncodable;
  final Encodable<A>? _encodableA;
  final Encodable<B>? _encodableB;

  @override
  void encode(Encoder encoder) {
    _selfEncodable.encode(encoder, _encodableA, _encodableB);
  }
}

class _UseEncodable2<T, A, B> implements ComposedEncodable2<T, A, B> {
  const _UseEncodable2(this._encodable, this.encodableA, this.encodableB);

  final Encodable2<T, A, B> _encodable;
  final Encodable<A>? encodableA;
  final Encodable<B>? encodableB;

  @override
  void encode(T value, Encoder encoder) {
    _encodable.encode(value, encoder, encodableA, encodableB);
  }

  @override
  R extract<R>(R Function<A, B>(Encodable<A>? encodableA, Encodable<B>? encodableB) fn) {
    return fn<A, B>(encodableA, encodableB);
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

class _UseCodable2<T, A, B> implements ComposedCodable2<T, A, B> {
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
