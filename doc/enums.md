Enums work exactly as normal models work. Therefore, an enum model should implement `SelfEncodable` and define a static `Codable<MyEnum> codable` member.

For example, a [`Color`](https://github.com/schultek/codable/blob/main/test/enum/model/color.dart) enum can be implemented like this:

```dart
/// Enums should define static [Codable]s and implement [SelfEncodable] just like normal classes.
enum Color implements SelfEncodable {
  green,
  blue,
  red;

  static const Codable<Color> codable = ColorCodable();

  @override
  void encode(Encoder encoder) {
    encoder.encodeString(this.name);
  }
}

class ColorCodable extends SelfCodable<Color> {
  const ColorCodable();

  @override
  Color decode(Decoder decoder) {
    return switch (decoder.whatsNext()) {
      DecodingType.string || DecodingType.unknown => switch (decoder.decodeString()) {
        'green' => Color.green,
        'blue' => Color.blue,
        'red' => Color.red,
        // Throw an error on any unknown value. We could also choose a default value here as well.
        _ => decoder.expect('Color of green, blue or red'),
      },
      _ => decoder.expect('Color as string'),
    };
  }
}
```
