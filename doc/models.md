This section goes over how to consume the package from an end-developer perspective. This skips over some details on how the used interfaces are implemented, which is explained in more detail [here]().

The following shows an example of for de/encoding a `Person` model from different data formats.

First we define the model by implementing `SelfEncodable`:

```dart
import 'package:codable_dart/core.dart';

class Person implements SelfEncodable {
  Person(this.name, this.age);

  final String name;
  final int age;

  @override
  void encode(Encoder encoder) {
    /* We skip the implementation for now ... */
  }
}
```

We also define a `static const Codable<Person> codable` on the `Person` class, which is defined like this:

```dart
import 'package:codable_dart/core.dart';

class Person implements SelfEncodable {
  /* ... */

  static const Codable<Person> codable = PersonCodable();

  /* ... */
}

class PersonCodable extends SelfCodable<Person> {
  const PersonCodable();

  @override
  Person decode(Decoder decoder) {
    return Person(
      /* We skip the implementation for now ... */
    );
  }
}
```

The `SelfCodable<T>` class extends `Codable<T>` and therefore implements both the `Encodable<T>` and `Decodable<T>` interfaces. It also uses the `Person`s `encode()` implementation by default and therefore only requires subclasses to implement the `decode()` method. More on this later.

This is already all we need for the `Person` model to be decoded and encoded to any available data format. We can now deserialize and serialize `Person` like this:

```dart
import 'package:codable_dart/json.dart';

void main() {
  final String source = '{"name":"Kilian Schulte","age":27}';

  // Deserialize Person from JSON
  final Person person = Person.codable.fromJson(source);

  // Serialize Person to JSON
  final String json = person.toJson();

  assert(json == source);
}
```

This works because the `fromJson()` and `toJson()` methods are **extension methods** on `Codable` and `SelfEncodable`.
The convention is that all data format implementations define these extensions. This makes it possible to change formats and methods simply by changing one import:

```dart
// Changed from '/json.dart' to '/msgpack.dart'
import 'package:codable_dart/msgpack.dart';

void main() {
  final Uint8List source = /* binary data */;

  // Deserialize Person from MessagePack
  final Person person = Person.codable.fromMsgPack(source);

  // Serialize Person to MessagePack
  final Uint8List msgpack = person.toMsgPack();

  assert(msgpack == source);
}
```

Again, the definitions and implementations of `Person` and `PersonCodable` stay untouched.

The extension method system of course also works for third-party packages:

```dart
// Assuming this uses the codable protocol.
import 'package:yaml/yaml.dart';

void main() {
  final String source = /* yaml string */;

  // Deserialize Person from Yaml
  final Person person = Person.codable.fromYaml(source);

  // Serialize Person to Yaml
  final String yaml = person.toYaml();

  assert(yaml == source);
}
```

# Third-party Types

Implementing the `SelfEncodable` interface is only possible when you define the model class yourself, which is not the case for core types or third-party types. However you can still add serialization capabilities to these or any type by defining a `Codable<T>` class like this:

```dart
class UriCodable extends Codable<Uri> {
  const UriCodable();

  @override
  void encode(Uri value, Encoder encoder) {
    /* ... */
  }

  @override
  Uri decode(Decoder decoder) {
    /* ... */
  }
}
```

The [`UriCodable`](https://github.com/schultek/codable/blob/main/lib/src/common/uri.dart) makes the `Uri` class from `dart:core` serializable using the same extension methods as above:

```dart
import 'package:codable_dart/json.dart';

void main() {
  final String source = '"https://schultek.dev"';

  // Deserialize Uri from JSON
  final Uri uri = const UriCodable().fromJson(source);

  // Serialize Uri to JSON
  final String json = const UriCodable().toJson(uri);

  assert(json == source);
}
```

# Collections (List, Set, Map)

When dealing with collections, the package defines some convenient extension methods that makes working with `List`s, `Set`s and `Map`s of models a lot easier.

To decode a `List` of models, use the `.list()` extension method on `Codable<T>`. This will return a `Codable<List<T>>`, which you can use as normal to decode from any data format:

```dart
// In one line:
final List<Person> persons = Person.codable.list().fromJson('...');

// Step by step:
final Codable<Person> personCodable = Person.codable;
final Codable<List<Person> personListCodable = personCodable.list();
final List<Person> persons = personListCodable.fromJson('...');
```

To encode a `List` (or any `Iterable`) of models, use the `.encode` extension getter on `List<T extends SelfEncodable>`. This will return a new `SelfEncodable`, which you can use as normal to encode to any data format:

```dart
final List<Person> persons = ...;

// In one line:
final String json = persons.encode.toJson();

// Step by step:
final SelfEncodable listEncodable = persons.encode;
final String json = listEncodable.toJson();
```

This works also with `Set`s and `Map`s:

```dart
final Set<Person> personsSet = Person.codable.set().fromJson('...');
final Map<String, Person> personsMap = Person.codable.map().fromJson('...');

final String jsonSet = personsSet.encode.toJson();
final String jsonMap = personsMap.encode.toJson();
```

Additionally for `Map`s, you can specify a `Codable<Key>` to de/encode non-primitive map keys:

```dart
final Codable<Map<Uri, Person>> personMapCodable = Person.codable.map(UriCodable());

final Map<Uri, Person> personByUriMap = personMapCodable.fromJson('...');
final String json = personMapCodable.toJson(personByUriMap);
```

# Standard Format

In addition to serial data formats like `JSON`, the protocol also supports a special 'standard' format, that can be used to de/encode models to Dart `Map`s, `List`s and primitive value types.

_This is the equivalent to what the `toJson()` method of `json_serializable` does._ As explained in the beginning, this is technically not serialization, but since its a very common thing to do, this protocol of course also has support for it.

The usage is the same as with any other data format, and the methods are named `fromValue()` and `toValue()`. Additionally, because of the common use-case, there is an additional `fromMap()` and `toMap()` that simply cast the value:

```dart
import 'package:codable_dart/standard.dart';

void main() {
  final Map<String, dynamic> source = {'name': 'Jasper the Dog', 'age': 3};

  // Decode Person from a Map<String, dynamic>.
  final Person person = Person.codable.fromMap(source);
  // Encode Person and cast to a Map<String, dynamic>.
  final Map<String, dynamic> map = person.toMap();

  assert(map == source);

  final String url = 'schultek.dev';

  // Decode Uri from a Dart standard object (e.g. String).
  final Uri uri = UriCodable().fromValue(source);
  // Encode Uri to a Dart standard object.
  final Object? object = UriCodable().toValue(uri);

  assert(object == url);
}
```
