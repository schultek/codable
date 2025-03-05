import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';

extension AsListCodable<T> on Codable<T> {
  /// Returns a [Codable] that can encode and decode a list of [T].
  ///
  /// This let's you use any format extensions with lists:
  /// ```dart
  /// final List<Person> people = Person.codable.list().fromJson(...);
  /// final String json = Person.codable.list().toJson(people);
  /// ```
  Codable<List<T>> list() => ListCodable<T>(this);
}

extension AsListDecodable<T> on Decodable<T> {
  /// Returns a [Decodable] object that can decode a list of [T].
  Decodable<List<T>> list() => ListDecodable<T>(this);
}

extension AsListEncodable<T> on Encodable<T> {
  /// Returns an [Encodable] that can encode a list of [T].
  Encodable<List<T>> list() => ListEncodable<T>(this);
}

extension AsSetCodable<T> on Codable<T> {
  /// Returns a [Codable] that can encode and decode a set of [T].
  ///
  /// This let's you use any format extensions with sets:
  /// ```dart
  /// final Set<Person> people = Person.codable.set().fromJson(...);
  /// final String json = Person.codable.set().toJson(people);
  /// ```
  Codable<Set<T>> set() => SetCodable<T>(this);
}

extension AsSetDecodable<T> on Decodable<T> {
  /// Returns a [Decodable] object that can decode a set of [T].
  Decodable<Set<T>> set() => SetDecodable<T>(this);
}

extension AsSetEncodable<T> on Encodable<T> {
  /// Returns an [Encodable] that can encode a set of [T].
  Encodable<Set<T>> set() => SetEncodable<T>(this);
}

extension AsIterableEncodable<T extends SelfEncodable> on Iterable<T> {
  /// Returns an [Encodable] that can encode an iterable of [T].
  ///
  /// This let's you use any format extensions directly on a [List] of [Encodable]s:
  /// ```dart
  /// final Iterable<Person> people = ...;
  /// final String json = people.encodable.toJson();
  /// ```
  SelfEncodable get encode => IterableSelfEncodable(this);
}

/// A [Codable] that can encode and decode a list of [E].
///
/// Prefer using [AsListCodable.list] instead of the constructor.
class ListCodable<E> with _ListDecodable<E> implements Codable<List<E>>, ComposedDecodable1<List<E>, E> {
  const ListCodable(this.codable);

  @override
  final Codable<E> codable;

  @override
  void encode(List<E> value, Encoder encoder) {
    encoder.encodeIterable(value, using: codable);
  }

  @override
  R extract<R>(R Function<A>(Codable<A>? codableA) fn) {
    return fn<E>(codable);
  }
}

/// A [Decodable] implementation that can decode a list of [E].
///
/// Prefer using [AsListDecodable.list] instead of the constructor.
class ListDecodable<E> with _ListDecodable<E> implements ComposedDecodable1<List<E>, E> {
  const ListDecodable(this.codable);

  @override
  final Decodable<E> codable;
}

/// An [Encodable] that can encode a list of [E].
///
/// Prefer using [AsListEncodable.list] instead of the constructor.
class ListEncodable<E> implements Encodable<List<E>> {
  const ListEncodable(this.codable);

  final Encodable<E> codable;

  @override
  void encode(List<E> value, Encoder encoder) {
    encoder.encodeIterable(value, using: codable);
  }
}

mixin _ListDecodable<E> implements ComposedDecodable1<List<E>, E> {
  Decodable<E> get codable;

  @override
  List<E> decode(Decoder decoder) {
    return switch (decoder.whatsNext()) {
      DecodingType.list || DecodingType.unknown => decoder.decodeList(using: codable),
      DecodingType.iterated => [for (final d = decoder.decodeIterated(); d.nextItem();) d.decodeObject(using: codable)],
      _ => decoder.expect('list or iterated'),
    };
  }

  @override
  R extract<R>(R Function<A>(Decodable<A>? codableA) fn) {
    return fn<E>(codable);
  }
}

/// A [Codable] that can encode and decode a set of [E].
///
/// Prefer using [AsSetCodable.set] instead of the constructor.
class SetCodable<E> with _SetDecodable<E> implements Codable<Set<E>>, ComposedDecodable1<Set<E>, E> {
  const SetCodable(this.codable);

  @override
  final Codable<E> codable;

  @override
  void encode(Set<E> value, Encoder encoder) {
    encoder.encodeIterable(value, using: codable);
  }

  @override
  R extract<R>(R Function<A>(Codable<A>? codableA) fn) {
    return fn<E>(codable);
  }
}

/// A [Decodable] implementation that can decode a set of [E].
///
/// Prefer using [AsSetDecodable.set] instead of the constructor.
class SetDecodable<E> with _SetDecodable<E> implements ComposedDecodable1<Set<E>, E> {
  const SetDecodable(this.codable);

  @override
  final Decodable<E> codable;
}

/// An [Encodable] that can encode a set of [E].
///
/// Prefer using [AsSetEncodable.set] instead of the constructor.
class SetEncodable<E> implements Encodable<Set<E>> {
  const SetEncodable(this.codable);

  final Encodable<E> codable;

  @override
  void encode(Set<E> value, Encoder encoder) {
    encoder.encodeIterable(value, using: codable);
  }
}

mixin _SetDecodable<E> implements ComposedDecodable1<Set<E>, E> {
  Decodable<E> get codable;

  @override
  Set<E> decode(Decoder decoder) {
    return switch (decoder.whatsNext()) {
      DecodingType.list || DecodingType.unknown => decoder.decodeList(using: codable).toSet(),
      DecodingType.iterated => {for (final d = decoder.decodeIterated(); d.nextItem();) d.decodeObject(using: codable)},
      _ => decoder.expect('list or iterated'),
    };
  }

  @override
  R extract<R>(R Function<A>(Decodable<A>? codableA) fn) {
    return fn<E>(codable);
  }
}

/// An [Encodable] that can encode an iterable of [T].
///
/// Prefer using [AsIterableEncodable.encode] instead of the constructor.
class IterableSelfEncodable<T extends SelfEncodable> implements SelfEncodable {
  const IterableSelfEncodable(this.value);

  final Iterable<T> value;

  @override
  void encode(Encoder encoder) {
    encoder.encodeIterable(value);
  }
}
