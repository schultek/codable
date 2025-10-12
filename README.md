
# Codable

Codable is a modular, data-format agnostic serialization API for Dart. It provides a fast, flexible way to serialize and deserialize Dart objects to different wire formats (JSON, MessagePack, CSV and more) without forcing an intermediate and slow Map-based representation.

This package contains the core API as well as implementations for common data formats (like JSON) and Dart types (like DateTime).

The design and initial implementation originated as an RFC; see [`docs/rfc.md`](docs/rfc.md) for the original RFC.

## Key features

- Data-format agnostic core API — model implementations are independent from concrete formats.
- Efficient serialization paths that avoid allocating intermediate `Map` objects when possible.
- Extensible: optional extended features for enums, generics, polymorphism, lazy/async values and more.
- Reference format implementations included: JSON, MessagePack, CSV, and a compact standard format.
- Utilities for common Dart types (DateTime, Uri, Map, Iterable) and advanced features such as hooks and references.

## Why Codable?

Many Dart serialization solutions focus on converting models to `Map<String, dynamic>` and rely on `jsonEncode`/`jsonDecode`. That approach ties code to JSON, forces intermediate allocations and lacks a format-agnostic API surface. Codable provides a clean, minimal core API that lets different formats implement efficient, direct serialization and deserialization for the same models.

Codable is designed to be usable across codebases, packages, generators and tools. It aims to make it easy to add or change data formats without rewriting model code.


## Getting started

Add codable to your `pubspec.yaml`:

```yaml
dependencies:
	codable: ^0.1.0
```

## Usage

This section shows a condensed example of how to consume the API from an end-developer perspective. It demonstrates encoding and decoding a `Person` model with different data formats.

First, define a model by implementing `SelfEncodable` and providing a `static const Codable<T> codable` instance:

```dart
import 'package:codable/core.dart';

class Person implements SelfEncodable {
	Person(this.name, this.age);

	final String name;
	final int age;

	static const Codable<Person> codable = PersonCodable();

	@override
	void encode(Encoder encoder) {
		/* We skip the implementation for now ... */
	}
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

With these definitions you can decode and encode `Person` to any available data format, for example JSON, like this:

```dart
// Imports the JSON format implementation
import 'package:codable/json.dart';

void main() {
	final String source = '{"name":"Kilian Schulte","age":27}';

	// Deserialize Person from JSON
	final Person person = Person.codable.fromJson(source);

	// Serialize Person to JSON
	final String json = person.toJson();

	assert(json == source);
}
```

The `fromJson()` and `toJson()` methods are **extension methods** on `Codable` and `SelfEncodable`.
The convention is that all data format implementations define these extensions. This makes it possible to change formats and methods simply by changing one import:

```dart
// Imports the MessagePack format
import 'package:codable/msgpack.dart';

void main() {
	final Uint8List source = /* binary data */ Uint8List(0);

	// Deserialize Person from MessagePack
	final Person person = Person.codable.fromMsgPack(source);

	// Serialize Person to MessagePack
	final Uint8List msgpack = person.toMsgPack();

	assert(msgpack == source);
}
```

Note that the implementations of `Person` and `PersonCodable` stay untouched.

### Standard format

The API also includes a 'standard' format that converts models to Dart `Map`/`List`/primitive values. _This is the equivalent to what the `toJson()` method of `json_serializable` does._ Use `toValue`/`fromValue` or the convenience `toMap`/`fromMap` methods.

```dart
import 'package:codable/standard.dart';

final Map<String, dynamic> source = {'name': 'Jasper the Dog', 'age': 3};

final Person person = Person.codable.fromMap(source);
final Map<String, dynamic> map = person.toMap();

assert(map == source);
```

## Documentation

See the full documentation here or jump directly to the topic you are looking for:

- [Codable]() explains how to implement the `Codable` and `SelfCodable` interfaces and work with `Decoder`s and `Encoders`.
- [Collections]() show how to work with `List`s and `Map`s.
- [Third-Party Types]() show how to work with third-party types like `Uri`, `DateTime` etc.
- [Formats]() gives an overview of the available data formats.
- [Enums]() show how to work with enums.
- [Generics]() describe how to work with generic classes.
- [Polymorphism & Inheritance]() describe how inherited classes work with the codable API.
- [Hooks]() explain how to use hooks while decoding and encoding.

## Package libraries

Top-level libraries you can import from the package:

- `package:codable/core.dart` — core API surface: encoders, decoders, interfaces and common errors.
- `package:codable/extended.dart` — optional extended features (generics, polymorphism, hooks, lazy/async, references).
- `package:codable/standard.dart` — compact, standard format implementation used by the core API.
- `package:codable/common.dart` — helpers and adapters for built-in Dart types (DateTime, Uri, Map, Iterable, Object helpers).

Internals and additional helpers live under `lib/src/` and code generation tooling is provided in the `codable_builder/` folder.

## Formats

The repository includes multiple reference formats:

- JSON — a straightforward implementation with stream-based encoding/decoding.
- Progressive JSON — a compact, token-based JSON variant used for incremental or streaming scenarios.
- MessagePack — a binary format with smaller wire size for performance-sensitive uses.
- CSV — a tabular format implementation useful for spreadsheets and row-based data export/import.
- Standard — a compact, API-oriented format used by the core implementation.

Each format implements the same core encoder/decoder interfaces so models and adapters are portable between formats.

## Advanced features

Codable provides optional, extended features for real-world modeling needs:

- Generics support — adapters and helpers to preserve and serialize generic type information.
- Polymorphism & inheritance — configuration helpers to encode and decode concrete subtypes.
- Enums and custom type mappings — flexible enum handling and custom value representations.
- Hooks and lifecycle — pre/post hooks to transform or validate values during (de)serialization.
- Lazy / async values — built-in support for values that are resolved asynchronously or on-demand.
- Reference handling — encode/decode references to the same object to preserve graph structure.

These are implemented in `lib/src/extended` and demonstrated in the `test/` suite.

## Performance

Codable focuses on efficient serialization by avoiding extra intermediate allocations and by allowing format implementations to serialize model fields directly to the target representation. Benchmarks and performance tests live under `test/benchmark` and the `performance_test.dart` files.

## Contributing

Contributions are welcome. If you want to extend formats, add tests or improve the core API, please open an issue first to discuss the plan. Helpful contributions include:

- New test cases covering edge cases and complex model shapes.
- Additional format implementations (CBOR, Protobuf, YAML, etc.).
- Documentation and examples for advanced features.

Before submitting a PR, run the test suite and make sure new tests pass.

## License

This project is licensed under the MIT license. See the `LICENSE` file for details.

## Where to learn more

- RFC and design notes: `docs/rfc.md`
- Tests: `test/` (good place to see the package in action)

If you have questions or want to discuss the API, open an issue on the repository.
