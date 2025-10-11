/// This file contains interfaces and helper utilities to work with generic types.
library generic;

import 'package:codable_dart/core.dart';

// ==============================
// Generics with 1 type parameter
// ==============================

abstract interface class ComposedDecodable1<T, A> implements Decodable<T> {
  /// Extracts the child [Decodable] for the type parameter [A] from the composed [Decodable] for type T<A>.
  R extract<R>(R Function<A>(Decodable<A>? decodableA) fn);
}

// ===============================
// Generics with 2 type parameters
// ===============================

abstract interface class ComposedDecodable2<T, A, B> implements Decodable<T> {
  /// Extracts the child [Decodable]s for the type parameters [A] and [B] from the composed [Decodable]
  /// for type T<A, B>.
  R extract<R>(R Function<A, B>(Decodable<A>? decodableA, Decodable<B>? decodableB) fn);
}