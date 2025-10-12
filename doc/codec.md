The package also defines optional APIs for working with the `Codec` API from `dart:covert`.

Any `Codable<T>` can be converted to a `Codec<T, Object?>` like this:

```dart
// Import the 'standard' format, including the `.codec` extension.
import 'package:codable_dart/standard.dart';

void main() {
  final Codec<Person, Object?> codec = Person.codable.codec;
}
```

This gives the default codec to decode and encode a model using the 'standard' format, usually to a `Map` of its properties.

Further working with different data formats is enabled by fusing other codecs:

```dart
// Imports the core 'json' codec.
import 'dart:convert';
// Imports the packages 'msgPack' codec.
import 'package:codable_dart/msgpack.dart';

// Import the '.codec' extension.
import 'package:codable_dart/standard.dart';

final Codec<Person, String> personToJsonCodec = Person.codable.codec.fuse(json);

final Codec<Person, List<int>> personToMsgPackCodec = Person.codable.codec.fuse(msgPack);
```

Fusing codecs like this will be as performant as using the codable API directly, as it still optimizes out the intermediate `Map` allocation.

---

Some formats, like JSON and CSV also supports fusing with the `utf8` codec for efficient binary de/encoding.

```dart
final Codec<Person, List<int> personToJsonBytesCodec = Person.codable.codec.fuse(json).fuse(utf8);
```

---

The binary JSON codec also supports chunked decoding, given that the models `Codable` implements the `LazyDecodable` interface.

```dart
final Stream<List<int>> byteStream = ...;
final Future<Person> personStream = Person.codable.codec.fuse(json).fuse(utf8).decoder.bind(byteStream).single;
```

