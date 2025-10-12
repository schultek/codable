/// This file contains interfaces and helper utilities to work with generic types.
library generic;

import 'package:codable_dart/core.dart';

/// Interface for a [Decodable] that wraps another [Decodable] of the same (or similar) type.
abstract interface class ComposedDecodable<T> implements Decodable<T> {
  /// Unwraps the inner [Decodable] and passes it to the provided function [fn].
  R unwrap<R>(R Function<A>(Decodable<A>? codable) fn);
}

// ==============================
// Generics with 1 type parameter
// ==============================

/// Interface for a [Decodable] of a generic type T<A>, that is composed of another [Decodable] for A.
abstract interface class ComposedDecodable1<T> implements Decodable<T> {
  /// Extracts the child [Decodable] for the type parameter A from the composed [Decodable] for type T<A>.
  R extract<R>(R Function<A>(Decodable<A>? decodableA) fn);
}

// ===============================
// Generics with 2 type parameters
// ===============================

/// Interface for a [Decodable] of a generic type T<A, B>, that is composed of other [Decodable]s for A and B.
abstract interface class ComposedDecodable2<T> implements Decodable<T> {
  /// Extracts the child [Decodable]s for the type parameters A and B from the composed [Decodable]
  /// for type T<A, B>.
  R extract<R>(R Function<A, B>(Decodable<A>? decodableA, Decodable<B>? decodableB) fn);
}

extension ExtractDecodable<T> on Decodable<T>? {
  R extractArg1<R>(R Function<A>(Decodable<A>? decodableA) fn) {
    if (this case ComposedDecodable d) {
      return d.unwrap(<A>(c) => c.extractArg1(fn));
    }
    if (this case ComposedDecodable1 d) {
      return d.extract(fn);
    }
    return fn<dynamic>(null);
  }

  R extractArg2<R>(R Function<A, B>(Decodable<A>? decodableA, Decodable<B>? decodableB) fn) {
    if (this case ComposedDecodable d) {
      return d.unwrap(<A>(c) => c.extractArg2(fn));
    }
    if (this case ComposedDecodable2 d) {
      return d.extract(fn);
    }
    return fn<dynamic, dynamic>(null, null);
  }
}