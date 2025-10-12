To support generic classes, the respective `Codable` should accept a child (de/en)codable for each of the class'es type parameters.

For example the generic class `Box<T>` defines a codable like this:

```dart
class Box<T> implements SelfEncodable {
  Box(this.label, this.data);

  final String label;
  final T data;

  static Codable<Box<T>> codable<T>([Codable<T>? codable]) => BoxCodable(codable);

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    encoder.encodeKeyed()
      ..encodeString('label', label)
      ..encodeObject('data', data, using: encodableT)
      ..end();
  }
}

class BoxCodable<T> extends Codable<Box<T>> {
  const BoxCodable([Codable<T>? this.codableT]);

  final Codable<T>? codableT;

  @override
  void encode(Box<T> value, Encoder encoder) {
    value.encode(encoder, codableT);
  }

  @override
  Box<T> decode(Decoder decoder) {
    // For simplicity, we don't check the decoder.whatsNext() here. Don't do this for real implementations.
    final mapped = decoder.decodeMapped();
    return Box(
      mapped.decodeString('label'),
      mapped.decodeObject('data', using: codableT),
    );
  }
}
```

As you can see, `encode()` method and `BoxCodable` class accept additional `encodableT` and `ccodableT` parameters for properties of type `T`. Also, the static `codable` member on `Box` is now a method accepting a child codable as well.

For decoding and encoding a specific `Box<SomeType>`, simply provide a `Codable` for that inner type, e.g.:

```dart
final Box<Uri> box = Box.codable(UriCodable()).fromJson(...);
final String json = Box.codable(UriCodable()).toJson(box);
```

To be able to chain `.toJson()` on `box` directly, we need to define an additional extension:

```dart
extension BoxEncodableExtension<T> on Box<T> {
  SelfEncodable use([Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, encodableT));
  }
}
```

This allows us to also encode a box like this:

```dart
final String json = box.use(UriCodable()).toJson();
```

### Reusing Codables

The 'inner codable' system lets us provide explicit de/encodables for inner types.

Another benefit of this system is that we can construct non-generic instances that can be passed around freely.

```dart
void main() {
  final Box<Uri> box = ...;

  // Constructs a new codable that explicitly handles the [Box<Uri>] type.
  // From now on, there is no conceptual difference to non-generic [Codable]s.
  final Codable<Box<Uri>> boxUriCodable = Box.codable(UriCodable());

  doSomething<Box<Uri>>(box, boxUriCodable);
}

// Accepts a value and codable of the same type.
void doSomething<T>(T value, Codable<T> codable) {
  // Here we don't know (or care) if the codable was originally a generic codable.
}
```
