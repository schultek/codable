import 'package:codable_dart/core.dart';

/// Enums can define static [Codable]s and implement [SelfEncodable] just like normal classes.
enum Color implements SelfEncodable {
  none,
  green,
  blue,
  red;

  static const Codable<Color> codable = ColorCodable();

  // This is a more elaborate implementation to showcase the flexibility of the codable protocol.
  // You could also just have a fixed string or int encoding for all formats.
  @override
  void encode(Encoder encoder) {
    if (encoder.isHumanReadable()) {
      encoder.encodeStringOrNull(switch (this) {
        Color.green => 'green',
        Color.blue => 'blue',
        Color.red => 'red',
        Color.none => null,
      });
    } else {
      encoder.encodeIntOrNull(switch (this) {
        Color.green => 0,
        Color.blue => 1,
        Color.red => 2,
        Color.none => null,
      });
    }
  }
}

class ColorCodable extends SelfCodable<Color> {
  const ColorCodable();

  // This is a more elaborate implementation to showcase the flexibility of the codable protocol.
  // You could also just have a fixed string or int decoding for all formats.
  @override
  Color decode(Decoder decoder) {
    return switch (decoder.whatsNext()) {
      // Enums (as any other class) may treat 'null' as a value or fallback to a default value.
      DecodingType.nil => Color.none,
      DecodingType.string => decodeString(decoder.decodeStringOrNull(), decoder),
      DecodingType.num || DecodingType.int => decodeInt(decoder.decodeIntOrNull(), decoder),
      DecodingType.unknown when decoder.isHumanReadable() => decodeString(decoder.decodeStringOrNull(), decoder),
      DecodingType.unknown => decodeInt(decoder.decodeIntOrNull(), decoder),
      _ => decoder.expect('Color as string or int'),
    };
  }

  Color decodeString(String? value, Decoder decoder) {
    return switch (value) {
      'green' => Color.green,
      'blue' => Color.blue,
      'red' => Color.red,
      // Enums (as any other class) may treat 'null' as a value or fallback to a default value.
      null => Color.none,
      // Throw an error on any unknown value. We could also choose a default value here as well.
      _ => decoder.expect('Color of green, blue, red or null'),
    };
  }

  Color decodeInt(int? value, Decoder decoder) {
    return switch (value) {
      0 => Color.green,
      1 => Color.blue,
      2 => Color.red,
      // Enums (as any other class) may treat 'null' as a value or fallback to a default value.
      null => Color.none,
      // Throw an error on any unknown value. We could also choose a default value here as well.
      _ => decoder.expect('Color of 0, 1, 2 or 3'),
    };
  }
}
