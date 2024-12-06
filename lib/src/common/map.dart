import 'package:codable/core.dart';
import 'package:codable/extended.dart';

import '../formats/standard.dart';

extension AsMapCodable<T> on Codable<T> {
  /// Returns a [Codable] that can encode and decode a map of [K] and [T].
  ///
  /// This let's you use any format extensions with maps:
  /// ```dart
  /// final Map<String, Person> people = Person.codable.map().fromJson(...);
  /// final String json = Person.codable.map().toJson(people);
  /// ```
  ///
  /// Optionally you can provide a [keyCodable] to specify how to encode and decode the keys.
  /// ```dart
  /// final Map<Uri, Person> people = Person.codable.map(Uri.codable).fromJson(...);
  /// final String json = Person.codable.map(Uri.codable).toJson(people);
  /// ```
  Codable<Map<K, T>> map<K>([Codable<K>? keyCodable]) => MapCodable(keyCodable, this);
}

extension AsMapEncodable<T extends SelfEncodable> on Map<dynamic, T> {
  /// Returns an [Encodable] that can encode a map of [K] and [T].
  ///
  /// This let's you use any format extensions directly on a [Map] of [Encodable]s:
  /// ```dart
  /// final Map<String, Person> people = ...;
  /// final String json = people.encode.toJson();
  /// ```
  SelfEncodable get encode => MapSelfEncodable(this);
}

/// A [Codable] that can encode and decode a map of [K] and [V].
///
/// Prefer using [AsMapCodable.map] instead of the constructor.
class MapCodable<K, V> implements ComposedCodable2<Map<K, V>, K, V> {
  const MapCodable(this.keyCodable, this.codable);

  final Codable<K>? keyCodable;
  final Codable<V> codable;

  @override
  Map<K, V> decode(Decoder decoder) {
    return switch (decoder.whatsNext()) {
      DecodingType.map ||
      DecodingType.mapped ||
      DecodingType.unknown =>
        decoder.decodeMap(keyUsing: keyCodable, valueUsing: codable),
      DecodingType.keyed => decodeKeyed(decoder.decodeKeyed()),
      _ => decoder.expect('map or keyed'),
    };
  }

  Map<K, V> decodeKeyed(KeyedDecoder keyed) {
    final map = <K, V>{};
    for (Object? key; (key = keyed.nextKey()) != null;) {
      if (keyCodable != null) {
        key = StandardDecoder.decode<K>(key, keyCodable!);
      }
      map[key as K] = keyed.decodeObject(using: codable);
    }
    return map;
  }

  @override
  void encode(Map<K, V> value, Encoder encoder) {
    if (keyCodable != null) {
      encoder.encodeMap(value, keyUsing: keyCodable, valueUsing: codable);
    } else if (value case Map<SelfEncodable, V> v) {
      encoder.encodeMap<SelfEncodable, V>(v, keyUsing: Encodable.self(), valueUsing: codable);
    } else {
      encoder.encodeMap(value, valueUsing: codable);
    }
  }

  @override
  R extract<R>(R Function<A, B>(Codable<A>? codableA, Codable<B>? codableB) fn) {
    return fn<K, V>(keyCodable, codable);
  }
}

/// An [Encodable] that can encode a map of [K] and [T].
///
/// Prefer using [AsMapEncodable.encode] instead of the constructor.
class MapSelfEncodable<T extends SelfEncodable> implements SelfEncodable {
  const MapSelfEncodable(this.value);

  final Map<dynamic, T> value;

  @override
  void encode(Encoder encoder) {
    if (value case Map<SelfEncodable, T> v) {
      encoder.encodeMap<SelfEncodable, T>(v, keyUsing: Encodable.self(), valueUsing: Encodable.self());
    } else {
      encoder.encodeMap<dynamic, T>(value, valueUsing: Encodable.self());
    }
  }
}
