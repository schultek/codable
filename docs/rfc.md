# RFC: Codable Protocol for Dart

This RFC outlines a new serialization protocol for Dart. Designed to be flexible, data-format agnostic, performant and usable across codebases, packages, generators and tools.

> Originally, I planned this as part of a new dart_mappable v5 release, but I was inspired to make this a separate proposal as it is potentially usable for a lot more. dart_mappable would in the end just use this protocol for its own implementations.

_by [@schultek](schultek.dev)_

# Preface

Over the last three years, I created one of the most powerful and feature-complete mapping and serialization package for Dart, called dart_mappable. It is uniquely focused on idiomatic class definitions, support for complex features (like generics, polymorphism or inheritance) and flexibility. Through this work I learned a lot about serialization, API design and the state of Darts ecosystem around this topic. I've seen many many use-cases and equally many edge-cases of how developers define their models, what requirements they have and ultimately what a holistic serialization system would require.

This proposal is the result of all these learnings and tries to bring forward a new take on a unified serialization protocol for the Dart ecosystem. I also took inspiration from other languages, mainly Swifts [Codable](https://developer.apple.com/documentation/swift/codable) protocol, and Rusts [serde](https://serde.rs/) package.

## The Problem with Serialization

Serialization, aka transforming a data class into a serialized data format and back to be sent, received or stored, is a key part of almost all applications. And a key problem to figure out for every programming language and ecosystem. Python has pydantic, Swift has Codable, Kotlin has kotlinx.serialization, Rust has serde. Dart has ...?

Currently, the Dart ecosystem around serialization is in a bad state. There is no coherent story around general serialization at all. Before approaching this problem head on, let's first look at the current state of the ecosystem in more detail:

### 1. Singular focus on JSON

When looking at serialization solutions in Dart, the most popular and often discussed contenders are the `json_serializable` package and the `jsonEncode`/`jsonDecode` methods from `dart:convert`. This presents a core challenge of the Dart ecosystem:

Everything is (seemingly) about JSON. There is no general, data-format agnostic solution to serialization here.

- There is no API similar to `jsonEncode` for other data formats in the core libraries, nor are there shared interfaces that would allow other libraries to define custom data formats themselves.

- `json_serializables` positioning as a package for _serializing json_ is misleading. When looking beyond its name, the package is neither doing actual serialization, nor handling actual JSON. It is instead **converting** a model to a **Map**.

  _While the Dart syntax for a `Map` does have similarities to it, this is **not JSON**. It is a structured in-memory representation of your data. JSON on the other hand is a **serial data format**, where the information is stored as a
  series of bytes. A `String` in Dart._

  To perform the actual serialization, this `Map` needs to be passed to another method, usually `jsonEncode`.

- You can of course find various packages for other data formats on pub (e.g. [csv](https://pub.dev/packages/csv), [messagepack](https://pub.dev/packages/messagepack), [protobuf](https://pub.dev/packages/protobuf), [yaml](https://pub.dev/packages/yaml), [cbor](https://pub.dev/packages/cbor)), however each of these have their own way of serializing or deserializing a model. So you end up rewriting (or re-generating) the serialization code for each data format or package.

### 2. Implicit `toJson` method.

The `toJson()` method is a convention both `jsonEncode` and `json_serializable` have in common. Because of the positioning of `json_serializable` as the (semi-)official or "standard" solution, many other packages follow this convention to support serialization, like `freezed`, `retrofit` or `serverpod`. On the one hand this locks users in, without having much control over serialization. On the other hand packages are [kind of forced](https://github.com/schultek/dart_mappable/issues/82) to be compatible to it if they want to be adopted in the ecosystem. This causes a negative feedback loop.

Ignoring the misleading naming, the convention of having an implicit `Map<String, dynamic> toJson()` method on a modal has several other disadvantages:

1. There exists no interface that defines this method. Code that wants to use this method (like `jsonEncode` or third-party packages) have to do a dynamic invocation, usually wrapped in a `try catch` block in case the method does not exist. There is no compile-time safety or type inference.

   While there have been several [discussions](https://github.com/dart-lang/language/issues/3192#issuecomment-1621369798) and [issues](https://github.com/dart-lang/sdk/issues/53758) around improving this API, none were successful. Instead, members from the Dart team called this behavior of `jsonEncode` ["legacy support [...] not intended to be used"](https://github.com/dart-lang/sdk/issues/54479#issuecomment-1872584317) or even a ["mistake [...] we regret"](https://bsky.app/profile/mrale.ph/post/3lcrxdeersk25).

2. Using `toJson()` to serialize a model (or `fromJson` for deserialization) has generally quite bad performance. This is because it is allocating and constructing an intermediate `Map` object, before passing it to to `jsonEncode`, which iterates over the map and serializes it.

   Instead, a much more efficient implementation would go directly from model to serialized data without the intermediate `Map` object. And this is true for _any_ serialization format, not [just JSON](https://github.com/dart-lang/sdk/issues/35693).

**It is time we rethink serialization in Dart and aim for a standard that is modular, performant and allows to convert to and from any data format efficiently.**

# Why now?

> **“We can’t become what we need to be by remaining what we are.”** - Oprah Winfrey

It's never bad to improve things, but now specifically there are some movements in the Dart ecosystem that would benefit from a better story around serialization:

### Macros

With macros on the horizon, we can already anticipate the great impact they will have on the language and ecosystem. It is likely that there will be a surge of new efforts and packages around traditional code-gen topics like data classes and serialization.

We can already see a glimpse of that with the experimental `json` macro package created by the Dart team. While it is a great showcase of the new macro capabilities, it very much inherits the same problems as outlined above.

But the shift to macros is also a great opportunity. A chance to not just improve _how_ we generate code, but also _what_ we generate. With the right timing, we could leverage the migration process many packages will go through to also migrate them to a new protocol.

> Put bluntly, with macros we are going to have a lot of breaking changes and codebase migrations anyway. We can either 'slip in' some much-needed improvements now, or have a very hard time doing so afterward.

### Server-side Dart

As the Dart ecosystem is evolving, so is it's adoption for server-side applications. Backends and fullstack applications require efficient serialization for many tasks, like client-server communication, database access or file io. They might also want to use more time and memory efficient data formats, e.g. binary formats like [MessagePack](https://msgpack.org/) or [Protobuf](https://protobuf.dev/).

For servers, more performant serialization does not only improve the user experience, but actually safes money. Additionally, a data-format agnostic protocol would allow them to seamlessly switch formats without rewriting all of the models.

# Outline

- [Design Goals](#design-goals)
- [Core Protocol](#core-protocol)
  - [Usage](#usage)
    - [Third-Party Types](#third-party-types)
    - [Collections](#collections-list-set-map)
    - [Standard Format](#standard-format)
  - [Model Implementation](#model-implementation)
    - [Encode Implementation](#encode-implementation)
    - [Decode Implementation](#decode-implementation)
  - [Data Format Implementation](#data-format-implementation)
  - [Error Handling](#error-handling)
- [Performance Benchmark](#performance-benchmark)
- [Reference Implementations](#reference-implementations)
  - [Formats](#formats)
    - [Standard](#standard)
    - [JSON](#json)
    - [CSV](#csv)
    - [MessagePack](#messagepack)
  - [Types](#types)
    - [Person](#person)
    - [Color](#color)
    - [DateTime](#datetime)
    - [Uri](#uri)
- [Extended Protocol](#extended-protocol)
  - [Enums](#enums)
  - [Generics](#generics)
  - [Polymorphism & Inheritance](#polymorphism--inheritance)
  - [Hooks](#hooks)

# Design Goals

The goal of the protocol is to have a **modular** and **universally usable** protocol for serializing and deserializing Dart classes in a **performant** way.

**[1] "Modular"** means that the protocol is flexible in how it is used. Developers may use as much or as little of it as they need, have control over its parts and extend it. Data format implementations should be separated from models and extended features (such as support for generics) should be separated from the core protocol.

**[2] "Universally usable"** means that the protocol can be used for **any** serialized data format (e.g. human-readable formats like JSON, CSV or YAML, or binary formats like [MessagePack](https://msgpack.org/), [CBOR](https://cbor.io/) or [Protobuf](https://protobuf.dev/)) as well as structured objects (like Map). It also means that it can be used by both app developers, package authors or as a generation target for build_runner, or (in the future) macros or other tools (like ide extensions or cli tools).

**[3] "Performant"** means that it should be designed for efficiency, as serialization is a performance critical part of many apps and often a bottleneck. Specifically, its performance should be in the same range as format-specific implementations while
still having all the usability benefits from being a agnostic protocol.

## Non-goals

This proposal is specifically not made as a part of the dart language or sdk repo, and does not aim to become part of the core sdk, nor override existing APIs. As a separate package it is a lot more flexible and not bound to sdk versioning.

> But of course an effort like this can only be done with support from the community (and maybe even the Dart team). Therefore, spread the word about the proposal and let's discuss.

# Core Protocol

The core protocol consists of the following interfaces:

- `Encoder` & `Decoder`
  - for implementing a data format
  - e.g. `class JsonEncoder implements Encoder`
- `Encodable<T>` & `Decodable<T>`
  - for encoding & decoding a specific type `T`
  - e.g. `class UriEncodable implements Encodable<Uri>`
  - as well as `Codable<T>` combining both these interfaces
- `SelfEncodable`
  - for self-encoding a model type
  - e.g. `class Person implements SelfEncodable`

As you see this separates the _How?_ from the _What?_ in terms of encoding and decoding:

- the `Encoder` / `Decoder` defines **how** to en/decode something (e.g. as [Map](TODO), [JSON](TODO), [CSV](TODO), [MessagePack](TODO), ...)
- the `(Self)Encodable` / `Decodable` defines **what** to en/decode (your own models, core or external types, e.g. [Person](TODO), [Uri](TODO), [DateTime](TODO), ...)

The core protocol only defines the interfaces here, the actual implementation is up to the consumer (developer or packages).

> The extended protocol includes (reference) implementations for [Map](TODO), [JSON](TODO), [CSV](TODO) and [MessagePack](TODO). Mainly for proof-of-concept and benchmarking, but this could also ship as a default set of implementations alongside the protocol.

This separation of interfaces (-`er` and -`able`) allows for a modular approach to serialization. The implementation of the format no longer needs to know (or make implicit assumptions) about the target models. As well as the other way around, where the model does not need to know about the format.

Let's look at some implications and use-cases of this:

1. Any code-gen tool (using build_runner, macros or other) would only need to care about creating `Encodable`s/`Decodable`s, not handle the actual serialization. Meaning less work for the author, and more flexibility for the consumer.
2. Packages like `yaml`, `csv` or `messagepack` could expose a custom de/encoder (e.g. `YamlEncoder`) and directly work with any model using the protocol.
3. Packages that need to serialize user data (like `dio` or `firebase`) could accept arbitrary models using the protocol without needing separate generation systems (like `retrofit` or `cloud_firestore_odm`).
4. Packages defining custom models could directly interop with any other package or codebase using the protocol.
5. Frameworks like Serverpod or Jaspr could interop with models using the protocol without needing to ship their own serialization solution.

## Usage

This section goes over how to consume the protocol from an end-developer perspective. This skips over some details on
how the used objects are implemented, which will be explained further down.

The following shows an example usage for de/encoding a [`Person`](TODO) model from different data formats.

First we define the model by implementing `SelfEncodable`:

```dart
import 'package:codable/core.dart';

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

We also defines a `static const Codable<Person> codable` on the `Person` class, which is defined like this:

```dart
import 'package:codable/core.dart';

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

> This proposal is agnostic to how the above implementations are created. They can easily be generated using build_runner, macros or ide tools, or written by hand. You can even mix and match different approaches for different models.

This is already all we need for the `Person` model to be decoded and encoded to any available data format. We can now
deserialize and serialize `Person` like this:

```dart
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

This works because the `fromJson()` and `toJson()` methods are **extension methods** on `Codable` and `SelfEncodable`.
The convention is that all data format implementations define these extensions. This makes it possible to change formats
and methods simply by changing one import:

```dart
import 'package:codable/msgpack.dart';

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

### Third-party Types

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

This makes the [`Uri`](TODO) class from `dart:core` serializable using the same extension methods as above:

```dart
import 'package:codable/json.dart';

void main() {
  final String source = '"https://schultek.dev"';

  // Deserialize Uri from JSON
  final Uri uri = const UriCodable().fromJson(source);

  // Serialize Uri to JSON
  final String json = const UriCodable().toJson(uri);

  assert(json == source);
}
```

### Collections (List, Set, Map)

When dealing with collections, the protocol defines some convenient extension methods that makes working with `List`s, `Set`s and `Map`s of models a lot easier.

To decode a `List` of models, use the `.list()` extension method on `Codable<T>`. This will return a `Codable<List<T>>`, which you can use as normal do decode from any data format:

```dart
// In one line:
final List<Person> persons = Person.codable.list().fromJson('...');

// Step by step:
final Codable<Person> personCodable = Person.codable;
final Codable<List<Person> personListCodable = personCodable.list();
final List<Person> persons = personListCodable.fromJson('...');
```

To encode a `List` (or any `Iterable`) of models, use the `.encode` extension getter on `T extends SelfEncodable`. This will return a new `SelfEncodable`, which you can use as normal to encode to any data format:

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

### Standard Format

In addition to serial data formats like `JSON`, the protocol also supports a special 'standard' format, that can be used to de/encode models to Dart `Map`s, `List`s and primitive value types.

_This is the equivalent to what the `toJson()` method of `json_serializable` does._ As explained in the beginning, this technically is not serialization, but since its a very common thing to do, this protocol of course also has support for it.

The usage is the same as with any other data format, and the methods are named `fromValue()` and `toValue()`. Additionally, because of the common use-case, there is an additional `fromMap()` and `toMap()` that simply cast the value:

```dart
import 'package:codable/standard.dart';

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

## Model Implementation

Let's look at how to actually implement the `encode()` and `decode()` methods we have already seen above.

> Note that the full implementations would probably be generated by some codegen solution (build_runner, macros, other tools). **You won't have to write the following code by hand (except if you want to).**

### Encode Implementation

The `encode()` method is defined by both the [Encodable](TODO) and [SelfEncodable](TODO) interface in a slightly different way:

```dart
abstract interface class Encodable<T> {
  /// Encodes the [value] using the [encoder].
  void encode(T value, Encoder encoder);
}

abstract interface class SelfEncodable {
  /// Encodes itself using the [encoder].
  void encode(Encoder encoder);
}
```

While the `Encodable`s job is to encode `value`, the `SelfEncodable`s job is to encode `this` (itself). The rest works the same for the two interfaces.

The `encode()` method implementation must use one of the `Encoder`s `.encode...()` methods to encode its value like this:

```dart
class Person implements SelfEncodable {
  /* ...*/

  @override
  void encode(Encoder encoder) {
    // Starts encoding a collection of key-value pairs.
    final KeyedEncoder keyed = encoder.encodeKeyed();

    // Encodes each property of the class.
    keyed.encodeString('name', name);
    keyed.encodeInt('age', age);

    // Finalizes the collection.
    keyed.end();
  }
}
```

All available methods can be seen [here](TODO) and exist for:

- Primitive types like `String`, `int`, `double`, `bool` or `null`.
- Collection types like `Iterable` and `Map`.
- Complex types like `Keyed` and `Iterated` (explained below).
- Nested objects (explained below).
- Custom types (explained below).

The `encoder` object should never be stored, passed around or otherwise be used outside of the scope of the `encode()` function. It is meant only to be used in the method body it is provided to.

#### Complex Types

"Complex types" simply refers to objects that want to be encoded not as a single value, but as a collection of values, i.e. properties. The collection can be either keyed (commonly used for normal models with properties) or iterated (for custom collection types, think custom lists).

Calling `encodeKeyed()` or `encodeIterated()` will return a new specific [`KeyedEncoder`](TODO) or [`IteratedEncoder`](TODO) respectively, which again has all the typed `.encode...()` methods as above.

Collection encoding needs to be explicitly finished by calling `.end()`.

#### Keyed Encoding

The [`KeyedEncoder`] interface extends all methods of the normal `Encoder` with an additional `String key` and `int id` parameter.

For example `Encoder.encodeString(String value)` becomes `KeyedEncoder.encodeString(String key, String value, {int? id})`.

As you can see the `key` parameter is required, while the `id` parameter is optional. Both fulfill the same purpose of identifying the value in a key-value collection. A data formats implementation of `KeyedEncoder` may choose whether it uses the `key` parameter, or the `id` parameter (if provided). Some formats, like MessagePack, may choose the `id` parameter for a more concise binary representation. Other formats, like Protobuf, may _only_ work with integer ids and therefore require the `id` parameter to be provided.

When using ids for encoding, the model also has to handle ids when decoding (explained later).

#### Nested Objects

Often models contain properties that are another model, e.g. `class Person { final Uri website; final Person mother; }`.

These can be encoded with the `encodeObject<T>(T value, {Encodable<T> using})` method:

```dart
class Person implements SelfEncodable {
  /* ...*/

  @override
  void encode(Encoder encoder) {
    // Starts encoding a collection of key-value pairs.
    final KeyedEncoder keyed = encoder.encodeKeyed();

    // Encodes a nested object of any type using an explicit encodable implementation.
    keyed.encodeObject<Uri>('website', website, using: const UriCodable());

    // Encodes a nested object that is a [SelfEncodable].
    keyed.encodeObject<Person>('mother', mother, using: Encodable.self());

    // Finalizes the collection.
    keyed.end();
  }
}
```

#### Custom Types

Some data formats may support custom data types as scalar values. For example many binary formats have support for scalar timestamp values.

Because we don't want to bloat the interface with too many `.encode...()` variants for every possible type, there exists a `encodeCustom<T>(T value)` variant meant for custom scalar types.

The implementation should check `canEncodeCustom<T>()` before attempting to decode a value as a custom type. For example, [`DateTimeCodable`](TODO) is implemented like this:

```dart
/* Simplified version of the actual implementation. */
class DateTimeCodable implements Codable<DateTime> {
  /* ... */

  @override
  void encode(DateTime value, Encoder encoer) {
    if (encoder.canEncodeCustom<DateTime>()) {
      encoder.encodeCustom<DateTime>(value);
    } else {
      encoder.encodeString(value.toIso8601String());
    }
  }
}
```

This allows for leveraging a formats type capabilities, while falling back to another implementation for other formats.

#### Human Readable

Some types have both a human-readable form, as well as a more compact and efficient form. Generally text-based formats like JSON and YAML will prefer to use the human-readable one and binary formats like MessagePack will prefer the compact one.

For example `DateTime` can both be encoded as an ISO String, or Unix int.

Types that have both forms should ask the `Encoder` implementation for the preferred form using the `isHumanReadable()` method.

For example, [`DateTimeCodable`](TODO) is implemented like this:

```dart
/* Simplified version of the actual implementation. */
class DateTimeCodable implements Codable<DateTime> {
  /* ... */

  @override
  void encode(DateTime value, Encoder encoer) {
    if (encoder.isHumanReadable()) {
      encoder.encodeString(value.toIso8601String());
    } else {
      encoder.encodeInt(value.millisecondsSinceEpoch);
    }
  }
}
```

### Decode Implementation

The `decode()` method is defined by the [Decodable](TODO) interface:

```dart
abstract interface class Decodable<T> {
  /// Decodes a value of type [T] using the [decoder].
  T decode(Decoder decoder);
}
```

Note there is no `SelfDecodable` interface, as it is not possible in Dart to define [interfaces for constructors or static methods](https://github.com/dart-lang/language/issues/723) (as opposed to e.g. [Swift protocols](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/protocols/#Initializer-Requirements)).

This is also the reason why it is required to have a `static const Codable<T>` on your model. This gives you an object that is typed and can be passed around freely, which is much more flexible than for example defining a factory constructor.

---

A `decode()` method implementation generally should do three things:

- First it uses `decoder.whatsNext()` to determine the [`DecodingType`](TODO) of the encoded data.
- Then it must use one of the typed `decoder.decode...()` methods of this interface to decode into its target type (Parallel to how `encode()` is implemented).
- If the returned `DecodingType` is not supported, the implementation can use `decoder.expect()` to throw a [detailed error](TODO):

```dart
class UriCodable implements Codable<Uri> {
  /* ...*/

  @override
  Uri decode(Decoder decoder) {
    return switch (decoder.whatsNext()) {
      DecodingType.string => Uri.parse(decoder.decodeString()),
      _ => decoder.expect('string'),
    };
  }
}
```

The available `decoder.decode...()` methods are exactly mirroring the `encoder.encode...()` methods (with 1 exception explained below).

#### Decoding Types and `whatsNext()`

Before decoding a value by calling one of the `decoder.decode...()` methods, the implementation should first request the [DecodingType](TODO) of the next value.

What possible `DecodingType`s are returned by `decoder.whatsNext()` depends on the type of data format:

- A **self-describing format** (i.e. the encoded data includes information about the type and shape of the data) can return `DecodingType`s for all supported types. The `Decodable` implementation may choose to call the appropriate decoding method based on the returned `DecodingType`.

  For example if `decoder.whatsNext()` returns `DecodingType.string`, the implementation should call `decoder.decodeString()`.

  Self-describing formats include JSON, YAML, or binary formats like MessagePack and CBOR.

- A **non-self-describing** format may only return `DecodingType.unknown` for all types. In this case, the `Decodable` implementation must choose a decoding method based on its expected type.

  Non-self-describing formats include CSV or binary formats like Protobuf or Avro (when separated from the schema).

The `Decodable` implementation may still choose a different `decoder.decode...()` method than what was returned by the `whatsNext()` call, if the methods are **interoperable**. This allows for more flexible decoding strategies and better error handling.

For example, an implementation may choose to call `decodeInt()` even if `whatsNext()` returned `DecodingType.num`.

The interoperable methods are:

- `int` and `num`
- `double` and `num`
- `List` and `Iterated`
- `Map`, `Keyed` and `Mapped` (explained below)

If the `Decoder` is not able to decode the requested type, it should throw an exception with a detailed message (see [Error Handling](TODO) section).

#### Keyed vs Mapped Decoding

The `Decoder` interface has **two** methods for decoding a collection of key-value pairs: `encodeKeyed()` and `encodeMapped()`, which return an instance of `KeyedDecoder` and `MappedDecoder`, respectively.

Their difference is in how a key-value pair is accessed

- For `KeyedDecoder`, keys and values can only be read sequentially, where the data format specifies the order in which they appear.
  The API is similar to an `Iterator`, where you have to repeatedly alternate between calling `nextKey()` and `decode...()` (which decodes the current value), until `nextKey()` returns null.

- For `MappedDecoder`, values can be accessed randomly by their `key`, similar to a `Map`. All `decode...()` methods accept a key, e.g. `decodeString(key: 'name')`.

As with any other decoding type, the data format will return the preferred way of decoding through the `whatsNext()` method, and the implementation should respect the result. For example, a serial data format like `JSON` will prefer `DecodingType.keyed`, while the 'standard' format will prefer `DecodingType.mapped`.

In both cases, the preferred type is a lot more efficient than the alternative type. Therefore, a normal model implementation should support both types:

```dart
class PersonCodable implements SelfCodable<Person>  {

  @override
  Person decode(Decoder decoder) {
    return switch (decoder.whatsNext()) {
      // If the format prefers mapped decoding, use mapped decoding.
      DecodingType.mapped || DecodingType.map => decodeMapped(decoder.decodeMapped()),
      // If the format prefers keyed decoding or is not self-describing, use keyed decoding.
      DecodingType.keyed || DecodingType.unknown => decodeKeyed(decoder.decodeKeyed()),
      _ => decoder.expect('mapped or keyed'),
    };
  }

  Person decodeKeyed(KeyedDecoder keyed) {
    late String name;
    late int age;

    // Iterate over all keys sequentially, and decode the respective values.
    for (Object? key; (key = keyed.nextKey()) != null;) {
      switch (key) {
        case 'name':
          name = keyed.decodeString();
        case 'age':
          age = keyed.decodeInt();
        default:
          // Skip any other values.
          keyed.skipCurrentValue();
      }
    }

    return Person(name, age);
  }

  Person decodeMapped(MappedDecoder mapped) {
    return Person(
      // Access and decode values by their keys.
      mapped.decodeString('name'),
      mapped.decodeInt('age'),
    );
  }
}
```

Remember again, that this seemingly double implementation effort is not an issue, as all of this will be generated.

If you still want to implement a model manually and don't care about performance, choosing keyed decoding for both cases is the best choice, as the performance loss from mapped to keyed is less strong as from keyed to mapped. Thats also the reason why it is chosen for not self-describing formats.

#### Nested Objects

Decoding nested objects works in the same way as encoding nested objects, by providing an explicit decodable implementation:

```dart
Person mother = decoder.decodeObject<Person>('mother', using: Person.codable);
```

#### Custom Types

Decoding custom types works in the same way as encoding custom types. First by checking if the formats supports decoding a custom type, and then using `decodeCustom<T>()`.

However, there is no explicit `canDecodeCustom<T>()` method. Instead the decoder can announce its support for a custom type by returning `DecodingType<T>.custom()` from `whatsNext()`.

For example, [`DateTimeCodable`](TODO) is implemented like this:

```dart
/* Simplified version of the actual implementation. */
class DateTimeCodable implements Codable<DateTime> {
  /* ... */

  @override
  DateTime decode(Decoder decoder) {
    if (decoder.whatsNext() is DecodingType<DateTime>) {
      return decoder.decodeCustom<DateTime>();
    } else {
      return DateTime.parse(decoder.decodeString());
    }
  }
}
```

#### Human Readable

For decoding, checking if the format prefers the human-readable form of a value works in the same way as it does for encoding.

However, this is only needed when the format is not self-describing.

For example, [`DateTimeCodable`](TODO) is implemented like this:

```dart
/* Simplified version of the actual implementation. */
class DateTimeCodable implements Codable<DateTime> {
  /* ... */

  @override
  DateTime decode(Decoder decoder) {
    if (decoder.whatsNext() == DecodingType.unknown) {
      if (decoder.isHumanReadable()) {
        return DateTime.parse(decoder.decodeString());
      } else {
        return DateTime.fromMillisecondsSinceEpoch(decoder.decodeInt());
      }
    } else {
      /* ... check code for full implementation */
    }
  }
}
```

---

## Data Format Implementation

A data format should create an implementation for the `Encoder` and `Decoder` interfaces (e.g. `JsonEncoder implements Encoder`) and provide extension methods on `Encodable` and `Decodable` (e.g. `.toJson()`).

How a data format implements the various `.encode...()` and `.decode()` methods is very dependent on the format itself, however there are some general guidelines that implementations should follow.

#### Accessing Encoders and Decoders

`Encoder` and `Decoder` instances are not meant to be created by code outside of the defining library. Therefore the constructors should be made private.

The main reason for this is that data formats need to do some additional work before or after such an instance is used by the model implementation. Additionally, `encoder` and `decoder` instances are meant to be strictly scoped to the models `encode` and `decode` implementation, where they are provided as parameters.

Instead of using constructors, data format implementations should expose static methods that act as the access point for other code.

For example the JSON format is implemented roughly like this:

```dart
class JsonDecoder implements Decoder {
  JsonDecoder._(this._json);

  final String _json;

  static T decode<T>(String json, Decodable<T> decodable) {
    // Implement the decoding, usually:
    // 1. Create a new instance:
    final decoder = JsonDecoder._(json);
    // 2. Call `decodeObject`:
    return decoder.decodeObject(using: decodable);
  }
}

class JsonEncoder implements Encoder {
  JsonEncoder._();

  final StringBuffer _jsonBuffer = StringBuffer();

  static String encode<T>(T value, Encodable<T> encodable) {
    // Implement the encoding, usually:
    // 1. Create a new instance:
    final encoder = JsonEncoder._();
    // 2. Call `encodeObject`:
    encoder.encodeObject(using: encodable);
    // 3. Return encoded value:
    return encoder._jsonBuffer.toString();
  }
}
```

Others can then manually use the data format like this:

```dart
final Person person = JsonDecoder.decode(json, Person.codable);

final String json = JsonEncoder.encode(person, Person.codable);
```

#### `toX()` / `fromX()` Extension Methods

As you've seen in the [Usage](#usage) section, the recommended way of using the codable protocol is with `toX()` and `fromX()` extension methods. These allow for a convenient and familiar (de)serialization experience, and should be created by each data format.

For example the JSON format is implemented roughly like this:

```dart
// For decoding a value from JSON.
extension JsonDecodable<T> on Decodable<T> {
  T fromJson(String json) {
    // Simply call the static decoding method.
    return JsonDecoding.decode<T>(json, decoder());
  }
}

// For encoding a value to JSON.
extension JsonEncodable<T> on Encodable<T> {
  String toJson(T value) {
    return JsonEncoder.encode<T>(value, this);
  }
}

// For encoding a model to JSON.
extension JsonSelfEncodable<T extends SelfEncodable> on T {
  String toJson() {
    return JsonEncoder.encode<T>(this, Encodable.self());
  }
}
```

To reiterate, having extension methods like this has a lot of advantages:

1. Separate methods for each used format, e.g. `toMap()`, `toJson()`, `toYaml()`, etc.
2. You can control access to these methods simply by importing the formats, and without modifying each model (e.g. importing `package:yaml` would instantly add `.toYaml()` to all your models).
3. You can create your own extensions if you prefer a different naming (e.g. the legacy `Map<String, dynamic> toJson()` instead of `Map<String, dynamic> toMap()`).
4. You can freely and without conflict add methods to your models, as instance methods override extensions (e.g. adding a `toX()` directly to the model is still possible).
5. Adding a `fromX()` factory constructor to the model class is of course also still possible, but not required.

## Error Handling

An important part of the core protocol is also error handling. It comes with a custom [`CodableException`](TODO) that can be thrown by `Encoder`s and `Decoder`s.

It that has (currently) two variants:

#### CodableFormatException

Thrown by a `Decoder` when either the `Decodable` implementation calls `decoder.expect()`, or when an unexpected token is encountered by a `decoder.decode...()` call.

For example, when a `Decodable`implementation calls `decoder.decodeString()` but the next token is `42`, the error would read:

```none
Unexpected type: Expected string but got number "42" at offset 123.
```

The `CodableFormatException` type both implements `CodableException` and `FormatException`.

#### CodableUnsupportedError

Thrown by a `Decoder` or `Encoder` when the called `decoder.decode...()` or `encoder.encode...()` method is not supported by the used data format _(as not all formats necessarily support all methods)_.

For example, when a `Decodable` implementation calls `decoder.decodeList()` on a `CsvDecoder`, the error would read:

```none
Unsupported method: 'CsvDecoder.decodeList()'. The csv format does not support nested lists.
```

#### Model Paths

Apart from displaying a detailed message, the `CodableException` can also track the model path of a decoding or encoding call. This helps the developer to pinpoint a problem without needing to step through the implementation manually.

For example take the following model structure:

```dart
class Person { final Car car; }
class Car { final String brand; }
```

When decoding the json data `{"car": {"brand": 42}}` the full error, including the decoding path, would read:

```none
Failed to decode Person->["car"]->Car->["brand"]: Unexpected type: Expected string but got num "42" at offset 18.
```

## Thanks for reading

Thanks for reading this far. You've reached the end of the **core protocol**. There is still more, but if you already want to dive into the code here are some things to check out:

- **Core protocol:** [/lib/src/core](TODO)

- **Use Cases:**

  - Basic: [/test/basic](TODO)
  - Collections: [/test/collections](TODO)
  - Error Handling: [/test/error_handling](TODO)

- **Formats:**
  - Standard: [/lib/src/formats/standard](TODO)
  - Json: [/lib/src/formats/json](TODO)

**Next up: Benchmark, Reference Implementations and Extended Protocol**

---

# Performance Benchmark

Lets look at what performance we can expect from this protocol. For this benchmark, I compared the JSON implementation of the protocol ("codable") to the "common" way of serializing objects ("baseline").

See the implementation [here](TODO).

```text
// Interpret as:
// - This encodes / decodes around 10MB of sample data, running in JIT mode
// - The absolute values are less important, the difference is what counts
// - The "baseline" way does not have a specialized implementation for json en/decoding, it uses `.toJson()` with an additional `jsonEncode()` call.

TODO
```

**Key takeaways:**

- The protocol is always equally as fast (within margins) or several times faster.
- For map de/encoding, the performance difference is negligible. The added interfaces and abstraction layer of the protocol does not have significant negative impact on the performance.
- For json de/encoding, the protocol implementation is significantly faster than the baseline, since it avoids the overhead of converting to a Map first and it de/encodes the data sequentially.

---

# Reference Implementations

Below are some reference implementation for types and data formats. You can check out the implementation to get a better feel for how the protocol would work in real codebases.

## Types

Some common models and core types to showcase the versatility of the protocol.

### Person

The `Person` model is a basic model with properties of various types, including primitive types, nested objects, lists and lists of nested objects.

```dart
class Person implements SelfEncodable {
  final String name;
  final int age;
  final double height;
  final bool isDeveloper;
  final Person? parent;
  final List<String> hobbies;
  final List<Person> friends;
}
```

The model is implemented in [test/basic/model/person.dart](TODO)

### Color

The `Color` model is an enum that can be encoded and decoded in two ways. For human-readable formats (e.g. JSON) it is encoded as a `String` representing its name. For other formats (e.g. MessagePack) it is encoded as an `int` representing its index.

It also shows how to deal with `null` and default values.

The model is implemented in [test/enum/model/color.dart](TODO)

### DateTime

The `DateTimeCodable` is a codable implementation for the core `DateTime` type. It shows how to de/encode a core type and combines several encoding strategies.

1. If the data format supports `DateTime` as a [custom type](TODO), it is encoded as a custom scalar value.
2. It uses a custom configuration option `preferredFormat` which the user can use to specify one of three formats.

   - `iso8601` will encode the value as an ISO8601 `String`.
   - `unixMilliseconds` will encode the value as a unix milliseconds `int`.
   - `auto` will let the data format determine how the value is encoded. For human-readable formats it is encoded as a `String` and for others as an `int`.

3. It uses a custom configuration option `convertUtc` which controls whether the date value will be converted to UTC before encoding and to local time when decoding.

The codable is implemented in [lib/src/common/datetime.dart](TODO)

### Uri

The `UriCodable` is a codable implementation for the core `Uri` type.

If the data format supports `Uri` as a [custom type](TODO), the value is encoded as a custom scalar value. Else, it is encoded as a `String`.

The codable is implemented in [lib/src/common/uri.dart](TODO)

## Formats

Different data formats to showcase the flexibility of the protocol.

### Standard

The "standard" format de/encodes models to Dart `Map`s, `List`s and primitive value types.

_This is the equivalent to what the `toJson()` method of `json_serializable` does._ As explained in the beginning, this technically is not serialization, but since its a very common thing to do, this protocol of course also has support for it.

The format is implemented in [lib/src/formats/standard.dart](TODO).

### JSON

A reference implementation for JSON, a human-readable self-describing serial data format.

This supports de/encoding models to both a `String` as well as a `List<int>` of bytes.

To decrease the effort for the reference implementation, this is based largely on the [`crimson`](https://pub.dev/packages/crimson) package. A "real" implementation would probably be fully custom for optimal performance.\_

The format is implemented in [lib/src/formats/json.dart](TODO).

### CSV

A reference implementation for CSV serialization, a human-readable non-self-describing serial data format.

This is limited to simple values only, no nested objects or lists. Values are separated by ",".

Different to other formats, this implementation operates exclusively on lists of models, since all CSV data consists of a number of rows.

The format is implemented in [lib/src/formats/csv.dart](TODO).

### MessagePack

A reference implementation for MessagePack, a binary self-describing serial data format.

_To decrease the effort for the reference implementation, this uses modified code from the [`messagepack`](https://pub.dev/packages/messagepack) package. A "real" implementation would probably be fully custom for optimal performance._

The format is implemented in [lib/src/formats/msgpack.dart](TODO).

# Extended protocol

The sections below make up the **extended protocol** including special considerations and implementations for things like enums, generics, polymorphism (inheritance) and hooks.

## Enums

For the protocol, enums work exactly as normal models work. Therefore, an enum model should implement `SelfEncodable` and define a static `Codable<MyEnum> codable`.

For example, a `Color` enum can be implemented like this:

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

## Generics

To support generic classes, the extended protocol defines additional interfaces `DecodableN`, `EncodableN` and `SelfEncodableN`, where `N` denotes the number of type parameters of the implementing class. Similarly, there are `CodableN` and `SelfCodableN` interfaces.

_The reference implementation defines these interfaces for up to 2 type parameters, however this can be easily extended to any number or type parameters._

For example the generic `Box<T>` class is defined as `class Box<T> implements SelfEncodable1<T>` and uses a `class BoxCodable<T> extends SelfCodable1<Box<T>, T>` codable.

The `encode()` and `decode()` methods of these interfaces accept (besides the standard `encoder` and `decoder` parameters) additional `encodableX` and `decodableX` parameters for each type parameter (with `X` being the name of the type parameter).

For example, the `encode()` implementation for `Box<T>` looks like this:

```dart
class Box<T> implements SelfEncodable1<T> {
  Box(this.label, this.data);

  final String label;
  final T data;

  /* ... */

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    final keyed = encoder.encodeKeyed();
    keyed.encodeString('label', label);

    if (encodableT != null) {
      // Use the encodableT to encode the value of type T.
      keyed.encodeObject('data', data, using: encodableA);
    } else if (data case SelfEncodable data) {
      // If data is self-encodable, simply use Encodable.self().
      keyed.encodeObject('data', data, using: Encodable.self());
    } else {
      // If no explicit encodableT is provided, we assume the data is a primitive type.
      keyed.encodeDynamic('data', data);
    }

    keyed.end();
  }
}
```

If we now simply call any `.toX()` method on a box, the `encodableT` parameter would be null. If `T` is either a self-encodable model or a primitive type this works fine. If `T` is any other type, we have to explicitly provide an `Encodable` for that type.

To do that, the protocol defines a `.use()` extension methods for all generic interfaces, which can be used like this:

```dart
final Box<Uri> box = ...
final String json = box.use(UriCodable()).toJson();
```

The `.use()` method takes as many `Encodable`s as the type has type parameters.

---

The decoding of a generic types works in the same way:

```dart

class Box<T> implements SelfEncodable1<T> {
  /* ...*/

  static const Codable1<Box, dynamic> codable = BoxCodable();

  /* ... */
}

class BoxCodable<T> extends SelfCodable1<Box<T>, T> {
  const BoxCodable();

  @override
  Box<T> decode(Decoder decoder, [Decodable<T>? decodableT]) {
    // For simplicity, we don't check the decoder.whatsNext() here. Don't do this for real implementations.
    final mapped = decoder.decodeMapped();
    return Box(
      mapped.decodeString('label'),
      decodableT == null // If no decodable is provided, we assume the data is a primitive type.
          ? mapped.decodeDynamic('data') as T
          : mapped.decodeObject('data', using: decodableT),
    );
  }
}
```

If we now call any `.fromX()` method on a box, the `decodableT` parameter would be null. Only if `T` is a primitive type this works fine. If `T` is any other type, we have to explicitly provide a `Decodable` for that type.

_You see how this is a bit different to encoding, as we don't have a `SelfDecodable` interface. An explicit `Decodable` needs to be provided for all models and non-primitive types._

The `.use()` extension methods also works on `Decodable` (and therefore `Codable`) objects, anc can be used like this:

```dart
final Box<dynamic> box = Box.codable.use(UriCodable()).fromJson();
```

Unfortunately, this will only give us a `Box<dynamic>`, since extension methods cannot construct new types from only generic parameters. To fix that we need to add a small extension ourselves that wraps the `use()` method like this:

```dart
extension BoxCodableExtension on Codable1<Box, dynamic> {
  // This is a convenience method for creating a BoxCodable with an explicit child codable.
  Codable<Box<$A>> call<$A>([Codable<$A>? codableA]) => BoxCodable<$A>().use(codableA);
}
```

With this we can change the above example to:

```dart
final Box<Uri> box = Box.codable(UriCodable()).fromJson();
```

_Keep in mind that this extension, together with the rest of the model implementation, can be generated anyways. And even if no code-gen is used, the boilerplate is still tiny._

### Reusing Codables

Another benefit of this system is that we can construct non-generic interfaces that can be passed around freely.

```dart
void main() {
  final Box<Uri> box = ...;
  final Codable<Box<Uri>> boxUriCodable = Box.codable(UriCodable());

  doSomething<Box<Uri>>(box, boxUriCodable);
}

// Accepts a value and codable of the same type.
void doSomething<T>(T value, Codable<T> codable) {
  // Here we don't know (or care) if the codable was originally a generic codable.
}
```

## Polymorphism & Inheritance

TODO

## Hooks

TODO
