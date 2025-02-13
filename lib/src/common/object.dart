import 'package:codable/core.dart';

/// A [Codable] that can encode and decode standard Dart objects (Maps, Lists, etc.).
class ObjectCodable implements Codable<Object?> {
  const ObjectCodable();

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
