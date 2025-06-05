import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';

/// A [Codable] that can encode and decode standard Dart objects (Maps, Lists, etc.).
class ObjectCodable implements Codable<Object?> {
  const ObjectCodable();

  static SelfEncodable wrap(Object? value) {
    return SelfEncodable.fromHandler((encoder) {
      encoder.encodeObject(value, using: const ObjectCodable());
    });
  }

  @override
  Object? decode(Decoder decoder) {
    return switch (decoder.whatsNext()) {
      DecodingType.keyed || DecodingType.mapped || DecodingType.map => _decodeMap(decoder),
      DecodingType.list || DecodingType.iterated => _decodeList(decoder),
      DecodingType.string => decoder.decodeString(),
      DecodingType.int => decoder.decodeInt(),
      DecodingType.double => decoder.decodeDouble(),
      DecodingType.bool => decoder.decodeBool(),
      DecodingType.nil => null,
      _ => decoder.decodeObjectOrNull(),
    };
  }

  Map<String, Object?> _decodeMap(Decoder decoder) {
    final map = <String, Object?>{};
    var keyed = decoder.decodeKeyed();
    for (Object? key; (key = keyed.nextKey()) != null;) {
      map[key.toString()] = decoder.decodeObject(using: this);
    }
    return map;
  }

  List<Object?> _decodeList(Decoder decoder) {
    final list = <Object?>[];
    var iterated = decoder.decodeIterated();
    for (; iterated.nextItem();) {
      list.add(decoder.decodeObject(using: this));
    }
    return list;
  }

  @override
  void encode(Object? value, Encoder encoder) {
    if (value is Map<String, Object?>) {
      encoder.encodeMap(value, valueUsing: this);
    } else if (value is List<Object?>) {
      encoder.encodeIterable(value, using: this);
    } else if (value is String) {
      encoder.encodeString(value);
    } else if (value is int) {
      encoder.encodeInt(value);
    } else if (value is double) {
      encoder.encodeDouble(value);
    } else if (value is bool) {
      encoder.encodeBool(value);
    } else if (value == null) {
      encoder.encodeNull();
    } else {
      encoder.encodeObject(value);
    }
  }
}



extension AsNullableCodable<T> on Codable<T> {
  /// Returns a [Codable] that can encode and decode [T] or null.
  Codable<T?> get orNull => OrNullCodable<T>(this);
}

extension AsNullableDecodable<T> on Decodable<T> {
  /// Returns a [Decodable] object that can decode [T] or null.
  Decodable<T?> get orNull => OrNullDecodable<T>(this);
}

extension AsNullableListEncodable<T> on Encodable<T> {
  /// Returns an [Encodable] that can encode [T] or null.
  Encodable<T?> get orNull => OrNullEncodable<T>(this);
}


/// A [Codable] that can encode and decode [T] or null.
///
/// Prefer using [AsNullableCodable.orNull] instead of the constructor.
class OrNullCodable<T> with _OrNullDecodable<T> implements Codable<T?>, ComposedDecodable1<T?, T> {
  const OrNullCodable(this.codable);

  @override
  final Codable<T> codable;

  @override
  void encode(T? value, Encoder encoder) {
    encoder.encodeObjectOrNull(value, using: codable);
  }

  @override
  R extract<R>(R Function<A>(Codable<A>? codableA) fn) {
    return fn<T>(codable);
  }
}

/// A [Decodable] implementation that can decode [T] or null.
///
/// Prefer using [AsNullableDecodable.orNull] instead of the constructor.
class OrNullDecodable<T> with _OrNullDecodable<T> implements ComposedDecodable1<T?, T> {
  const OrNullDecodable(this.codable);

  @override
  final Decodable<T> codable;
}

/// An [Encodable] that can encode [T] or null.
///
/// Prefer using [AsNullableEncodable.orNull] instead of the constructor.
class OrNullEncodable<T> implements Encodable<T?> {
  const OrNullEncodable(this.codable);

  final Encodable<T> codable;

  @override
  void encode(T? value, Encoder encoder) {
    encoder.encodeObjectOrNull(value, using: codable);
  }
}

mixin _OrNullDecodable<T> implements ComposedDecodable1<T?, T> {
  Decodable<T> get codable;

  @override
  T? decode(Decoder decoder) {
    return switch (decoder.whatsNext()) {
      DecodingType.nil => decoder.decodeIsNull() ? null : decoder.expect('null'),
      _ => codable.decode(decoder),
    };
  }

  @override
  R extract<R>(R Function<A>(Decodable<A>? codableA) fn) {
    return fn<T>(codable);
  }
}