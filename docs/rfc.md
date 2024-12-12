# RFC: New Serialization Protocol for Dart

This RFC outlines a new serialization protocol for Dart. Designed to be flexible, data-format agnostic and performant. Usable across codebases, packages, generators and tools.

_by [@schultek](https://schultek.dev)_

# Preface

Over the last three years, I created one of the most powerful and feature-complete mapping and serialization package for Dart, called dart_mappable. It is uniquely focused on idiomatic class definitions, support for complex features (like generics, polymorphism or inheritance) and flexibility. Through this work I learned a lot about serialization, API design and the state of Darts ecosystem around this topic. I've seen many many use-cases and equally many edge-cases of how developers define their models, what requirements they have and ultimately what a holistic serialization system would require.

> Originally, I planned this as part of a new dart_mappable v5 release, but I was inspired to make this a separate proposal as it is potentially usable for a lot more. dart_mappable would in the end just use this protocol for its own implementations.

This proposal is the result of all these learnings and tries to bring forward a new take on a unified serialization protocol for the Dart ecosystem. Aside from [dart_mappable](https://pub.dev/packages/dart_mappable), it took inspiration from Rusts [serde](https://serde.rs/) package, Swifts [Codable](https://developer.apple.com/documentation/swift/codable) protocol, and the [crimson](https://pub.dev/packages/crimson) package, while still trying to be "Darty" (whatever that means).

> Big thanks to [Pascal](https://bsky.app/profile/pascalwelsch.com), [Viktor](https://bsky.app/profile/viktorious.com) and [Majid](https://bsky.app/profile/mhadaily.bsky.social) for their early feedback and suggestions.

## The Problem with Serialization

Serialization, aka **transforming a data class into a serialized data format and back to be sent, received or stored**, is a key part of almost all applications. And a key problem to figure out for every programming language and ecosystem. Python has pydantic, Swift has Codable, Kotlin has kotlinx.serialization, Rust has serde. Dart has ...?

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

### 2. Implicit `toJson` method

The `toJson()` method is a convention both `jsonEncode` and `json_serializable` have in common. Because of the positioning of `json_serializable` as the (semi-)official or "standard" solution, many other packages follow this convention to support serialization, like `freezed`, `retrofit` or `serverpod`. On the one hand this locks users in, without having much control over serialization. On the other hand packages are [kind of forced](https://github.com/schultek/dart_mappable/issues/82) to be compatible to it if they want to be adopted in the ecosystem. This causes a negative feedback loop.

Ignoring the misleading naming, the convention of having an implicit `Map<String, dynamic> toJson()` method on a modal has several other disadvantages:

1. There exists no interface that defines this method. Code that wants to use this method (like `jsonEncode` or third-party packages) have to do a dynamic invocation, usually wrapped in a `try catch` block in case the method does not exist. There is no compile-time safety or type inference.

   While there have been several [discussions](https://github.com/dart-lang/language/issues/3192#issuecomment-1621369798) and [issues](https://github.com/dart-lang/sdk/issues/53758) around improving this API, none were successful. Instead, members from the Dart team called this behavior of `jsonEncode` ["legacy support [...] not intended to be used"](https://github.com/dart-lang/sdk/issues/54479#issuecomment-1872584317) or even a ["mistake [...] we regret"](https://bsky.app/profile/mrale.ph/post/3lcrxdeersk25).

2. Using `toJson()` to serialize a model (or `fromJson` for deserialization) has generally quite bad performance. This is because it is allocating and constructing an intermediate `Map` object, before passing it to to `jsonEncode`, which iterates over the map and serializes it.

   Instead, a much more efficient implementation would go directly from model to serialized data without the intermediate `Map` object. And this is true for _any_ serialization format, not [just JSON](https://github.com/dart-lang/sdk/issues/35693).

### 3. Real world impact

While the above points do matter, it would be dishonest at this point to suggest that everybody experiences this as a big problem in everyday use. Most Flutter and Dart developers today probably are not even aware of these issues, and are happily using `json_serializable`, since they only ever deal with moderate amounts of JSON data.

The problem this proposal addresses is more of a systemic nature. For the Dart ecosystem to grow and become more mature, I strongly believe it needs to have a better and more coherent story around serialization. This is not just about JSON or achieving some performance gains, but about the ecosystem as a whole. It is about enabling developers to write more efficient, more maintainable and more interoperable code. And it is about enabling package authors to create more powerful and more flexible packages.

---

> [!IMPORTANT]  
> **It is time we rethink serialization in Dart and aim for a standard that is modular, performant and allows to convert to and from any data format efficiently.**

# Why now?

> **“We can’t become what we need to be by remaining what we are.”** - Oprah Winfrey

It's never bad to improve things, but now specifically there are some movements in the Dart ecosystem that would benefit from a better story around serialization:

### Macros

With macros on the horizon, we can already anticipate the great impact they will have on the language and ecosystem. It is likely that there will be a surge of new efforts and packages around traditional code-gen topics like data classes and serialization.

We can already see a glimpse of that with the experimental `json` macro package created by the Dart team. While it is a great showcase of the new macro capabilities, it very much inherits the same problems regarding serialization as outlined above.

But the shift to macros is also a great opportunity. A chance to not just improve _how_ we generate code, but also _what_ we generate. With the right timing, we could leverage the migration process many packages will go through to also migrate them to a better underlying implementation.

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

# Design Goals

The goal of the protocol is to have a **modular** and **universally usable** protocol for serializing and deserializing Dart classes in a **performant** way.

**[1] "Modular"** means that the protocol is flexible in how it is used. Developers may use as much or as little of it as they need, have control over its parts and extend it. Data format implementations should be separated from models. The core protocol should be encapsulated and independent of extended features (such as support for generics).

**[2] "Universally usable"** means that the protocol can be used for **any** serialized data format (e.g. human-readable formats like JSON, CSV or YAML, or binary formats like [MessagePack](https://msgpack.org/), [CBOR](https://cbor.io/) or [Protobuf](https://protobuf.dev/)) as well as structured objects (like Map). It also means that it can be used by both app developers, package authors or as a generation target for build_runner, or (in the future) macros or other tools (like ide extensions or cli tools).

**[3] "Performant"** means that it should be designed for efficiency, as serialization is a performance critical part of many apps and often a bottleneck. Specifically, its performance should be in the same range as format-specific implementations while still having all the usability benefits from being a agnostic protocol.

## Non-goals

**No macros or builders:** It is (for now) not a goal of this proposal to define macros or builders for generating the serialization implementation of a modal. Rather it defines the underlying interfaces and conventions of an implementation, agnostic to how the implementation comes to be (generated, manually written, something else). 
*Macros are a great next step though when the proposal becomes more mature!*

**No sdk or language proposal:** This proposal is specifically not made as a part of the Dart language or SDK repository, and does not aim to become part of the core SDK, nor override existing APIs. It is designed to work as its own independent package, which is a lot more flexible in terms of versioning. Whether the ownership of the package should be transferred to the Dart team is up for discussion.

# Core Protocol

The core protocol consists of the following interfaces:

| Interface | Purpose | Example Use |
| --- | --- | --- |
| `Encodable<T>` and `Decodable<T>` | Encoding and decoding a specific type `T` | `class PersonEncodable implements Encodable<Person>` |
| `Encoder` and `Decoder` | Implementing a data format | `class JsonEncoder implements Encoder` |

As you see this separates the _How?_ from the _What?_ in terms of encoding and decoding:

- the `Encoder` / `Decoder` defines **how** to en/decode something (e.g. as Map, JSON, CSV, MessagePack, etc.)
- the `Encodable` / `Decodable` defines **what** to en/decode (your own models, core or external types, e.g. Person, Color, Uri, DateTime, etc.)

This separation of interfaces (-`er` and -`able`) allows for a modular approach to serialization. The implementation of the format no longer needs to know (or make implicit assumptions) about the target models. As well as the other way around, where the model does not need to know about the format.

In addition to these, there are two more interfaces, which will be explained later:

| Interface | Purpose | Example Use |
| --- | --- | --- |
| `Codable<T>` | Combines both `Encodable` and `Decodable` | `class PersonCodable implements Codable<Person>` |
| `SelfEncodable` | Self-encoding a model type | `class Person implements SelfEncodable` |

> [!NOTE]
> This repository also includes reference implementations for some data formats ([Map](https://github.com/schultek/codable/blob/main/lib/src/formats/standard.dart), [JSON](https://github.com/schultek/codable/blob/main/lib/src/formats/json.dart), [CSV](https://github.com/schultek/codable/blob/main/lib/src/formats/csv.dart) and [MessagePack](https://github.com/schultek/codable/blob/main/lib/src/formats/msgpack.dart)) and models ([Person](https://github.com/schultek/codable/blob/main/test/basic/model/person.dart), [DateTime](https://github.com/schultek/codable/blob/main/lib/src/common/datetime.dart), [Uri](https://github.com/schultek/codable/blob/main/lib/src/common/uri.dart), ...), as well as the [extended protocol](#extended-protocol) for laying out more complex use-cases. Mainly for proof-of-concept and benchmarking, but this could also ship as a default set of implementations alongside the protocol.

Before going into how to use the protocol, let's look at some implications and use-cases of this system:

1. Any code-gen tool or package (using build_runner, macros or other) would only need to care about creating `Encodable`s/`Decodable`s, not handle the actual serialization. Meaning less work for the tool or package author, and more flexibility for the consumer.
2. Packages like `yaml`, `csv` or `messagepack` could expose a custom de/encoder (e.g. `YamlEncoder`) and directly de/encode to any compatible model.
3. Packages that need to serialize user data (like `dio` or `firebase`) could accept any compatible model without needing separate generation systems (like `retrofit` or `cloud_firestore_odm`).
4. Packages defining custom models could directly interop with any other package or codebase using the protocol.
5. Frameworks like Serverpod or Jaspr could interop with models using the protocol without needing to ship their own serialization solution.

## Usage

This section goes over how to consume the protocol from an end-developer perspective. This skips over some details on how the used objects are implemented, which will be explained further down.

The following shows an example of for de/encoding a [`Person`](https://github.com/schultek/codable/blob/main/test/basic/model/person.dart) model from different data formats.

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

We also define a `static const Codable<Person> codable` on the `Person` class, which is defined like this:

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

> [!NOTE]
> Keep in mind this proposal is agnostic to how the above implementations are created. They could easily be generated using build_runner, macros or ide tools, or written by hand. You can even mix and match different approaches for different models.

This is already all we need for the `Person` model to be decoded and encoded to any available data format. We can now deserialize and serialize `Person` like this:

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
The convention is that all data format implementations define these extensions. This makes it possible to change formats and methods simply by changing one import:

```dart
// Changed from '/json.dart' to '/msgpack.dart'
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

The [`UriCodable`](https://github.com/schultek/codable/blob/main/lib/src/common/uri.dart) makes the `Uri` class from `dart:core` serializable using the same extension methods as above:

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

### Standard Format

In addition to serial data formats like `JSON`, the protocol also supports a special 'standard' format, that can be used to de/encode models to Dart `Map`s, `List`s and primitive value types.

_This is the equivalent to what the `toJson()` method of `json_serializable` does._ As explained in the beginning, this is technically not serialization, but since its a very common thing to do, this protocol of course also has support for it.

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

> [!NOTE]
> Note that in most cases these implementations will probably be generated by some codegen solution (build_runner, macros, other tools). **You won't have to write the following code by hand (except if you want to).**

### Encode Implementation

The `encode()` method is defined by both the [Encodable](https://github.com/schultek/codable/blob/main/lib/src/core/interface.dart#L86) and [SelfEncodable](https://github.com/schultek/codable/blob/main/lib/src/core/interface.dart#L39) interface in a slightly different way:

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

The `encode()` method implementation must use the provided `Encoder encoder` like this:

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

The `Encoder` comes with a number of different methods for different types. All available `encoder.encode...()` methods can be seen [here](https://github.com/schultek/codable/blob/main/lib/src/core/encoder.dart#L24) and exist for:

- Primitive types like `String`, `int`, `double`, `bool` or `null`.
- Collection types like `Iterable` and `Map`.
- Complex types like `Keyed` and `Iterated` (explained below).
- Nested objects or custom types (explained below).

The `encoder` object should never be stored, passed around or otherwise be used outside of the scope of the `encode()` function. It is meant only to be used in the method body it is provided to.

#### Complex Types

"Complex types" simply refers to objects that want to be encoded not as a single value, but as a collection of values, i.e. properties. The collection can be either keyed (commonly used for normal models with properties) or iterated (for custom collection types, think custom lists).

Calling `encodeKeyed()` or `encodeIterated()` will return a new specific [`KeyedEncoder`](https://github.com/schultek/codable/blob/main/lib/src/core/encoder.dart#L153) or [`IteratedEncoder`](https://github.com/schultek/codable/blob/main/lib/src/core/encoder.dart#L136) respectively, which again has all the typed `.encode...()` methods as above.

Collection encoding needs to be explicitly finished by calling `.end()`.

#### Keyed Encoding

The [`KeyedEncoder`] interface extends all methods of the normal `Encoder` with an additional `String key` and `int id` parameter.

For example `Encoder.encodeString(String value)` becomes `KeyedEncoder.encodeString(String key, String value, {int? id})`.

As you can see the `key` parameter is required, while the `id` parameter is optional. Both fulfill the same purpose of identifying the value in a key-value collection. A data formats implementation of `KeyedEncoder` may choose whether it uses the `key` parameter, or the `id` parameter (if provided). Some formats, like MessagePack, may choose the `id` parameter for a more concise binary representation. Other formats, like Protobuf, may _only_ work with integer ids and therefore require the `id` parameter to be provided.

When using ids for encoding, the model also has to handle ids when decoding (explained later).

#### Nested Objects

Often models contain properties that are another model, e.g. `class Person { final Uri website; final Person friend; }`.

These can be encoded with the `encodeObject<T>(T value, {Encodable<T>? using})` method:

```dart
class Person implements SelfEncodable {
  /* ...*/

  @override
  void encode(Encoder encoder) {
    // Starts encoding a collection of key-value pairs.
    final KeyedEncoder keyed = encoder.encodeKeyed();

    // Encodes a nested object that is a [SelfEncodable].
    keyed.encodeObject<Person>('friend', friend);

    // Encodes a nested object of any type using an explicit encodable implementation.
    keyed.encodeObject<Uri>('website', website, using: const UriCodable());

    // Finalizes the collection.
    keyed.end();
  }
}
```

#### Custom Types

Some data formats may support custom data types as scalar values. For example many binary formats have support for scalar timestamp values.

Because we don't want to bloat the interface with too many `.encode...()` variants for every possible type, the `encodeObject<T>(T value)` method can also be used for custom scalar types.

The implementation should check `canEncodeCustom<T>()` before attempting to decode a value as a custom type. For example, [`DateTimeCodable`](https://github.com/schultek/codable/blob/main/lib/src/common/datetime.dart) is implemented like this:

```dart
/* Simplified version of the actual implementation. */
class DateTimeCodable implements Codable<DateTime> {
  /* ... */

  @override
  void encode(DateTime value, Encoder encoer) {
    if (encoder.canEncodeCustom<DateTime>()) {
      encoder.encodeObject<DateTime>(value);
    } else {
      encoder.encodeString(value.toIso8601String());
    }
  }
}
```

This allows for leveraging a formats custom type capabilities, while falling back to another implementation for other formats.

#### Human Readable

Some types have both a human-readable form, as well as a more compact and efficient form. Generally text-based formats like JSON and YAML will prefer to use the human-readable one and binary formats like MessagePack will prefer the compact one.

For example `DateTime` can both be encoded as an ISO String, or Unix int.

Types that have both forms should ask the `Encoder` implementation for the preferred form using the `isHumanReadable()` method.

For example, [`DateTimeCodable`](https://github.com/schultek/codable/blob/main/lib/src/common/datetime.dart) is further implemented like this:

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

The `decode()` method is defined by the [Decodable](https://github.com/schultek/codable/blob/main/lib/src/core/interface.dart#L151) interface:

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

- First it uses `decoder.whatsNext()` to determine the [`DecodingType`](https://github.com/schultek/codable/blob/main/lib/src/core/decoder.dart#L183) of the encoded data.
- Then it must use one of the typed `decoder.decode...()` methods of this interface to decode into its target type (Parallel to how `encode()` is implemented).
- If the returned `DecodingType` is not supported, the implementation can use `decoder.expect()` to throw a [detailed error](#error-handling).

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

Before decoding a value by calling one of the `decoder.decode...()` methods, the implementation should first request the [DecodingType](https://github.com/schultek/codable/blob/main/lib/src/core/decoder.dart#L183) of the next value.

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

If the `Decoder` is not able to decode the requested type, it should throw an exception with a detailed message (see [Error Handling](#error-handling) section).

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

Decoding custom types works in the same way as encoding custom types. First by checking if the formats supports decoding a custom type, and then using `decodeObject<T>()`.

However, there is no explicit `canDecodeCustom<T>()` method on `Decoder`. Instead the decoder can announce its support for a custom type by returning `DecodingType<T>.custom()` from `whatsNext()`.

For example, [`DateTimeCodable`](https://github.com/schultek/codable/blob/main/lib/src/common/datetime.dart) is implemented like this:

```dart
/* Simplified version of the actual implementation. */
class DateTimeCodable implements Codable<DateTime> {
  /* ... */

  @override
  DateTime decode(Decoder decoder) {
    if (decoder.whatsNext() is DecodingType<DateTime>) {
      return decoder.decodeObject<DateTime>();
    } else {
      return DateTime.parse(decoder.decodeString());
    }
  }
}
```

#### Human Readable

For decoding, checking if the format prefers the human-readable form of a value works in the same way as it does for encoding.

However, this is only needed when the format is not self-describing.

For example, [`DateTimeCodable`](https://github.com/schultek/codable/blob/main/lib/src/common/datetime.dart) is implemented like this:

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

  static T decode<T>(String json, {Decodable<T>? using}) {
    // Implement the decoding, usually:
    // 1. Create a new instance:
    final decoder = JsonDecoder._(json);
    // 2. Call `decodeObject`:
    return decoder.decodeObject(using: using);
  }
}

class JsonEncoder implements Encoder {
  JsonEncoder._();

  final StringBuffer _jsonBuffer = StringBuffer();

  static String encode<T>(T value, {Encodable<T>? using}) {
    // Implement the encoding, usually:
    // 1. Create a new instance:
    final encoder = JsonEncoder._();
    // 2. Call `encodeObject`:
    encoder.encodeObject(using: using);
    // 3. Return encoded value:
    return encoder._jsonBuffer.toString();
  }
}
```

Others can then manually use the data format like this:

```dart
final Person person = JsonDecoder.decode(json, using: Person.codable);

final String json = JsonEncoder.encode(person, using: Person.codable);
```

#### `toX()` / `fromX()` Extension Methods

As you've seen in the [Usage](#usage) section, the recommended way of using the codable protocol is with `toX()` and `fromX()` extension methods. These allow for a convenient and familiar (de)serialization experience, and should be created by each data format.

For example the JSON format defines its extension methods like this:

```dart
// For decoding a value from JSON.
extension JsonDecodable<T> on Decodable<T> {
  T fromJson(String json) {
    // Simply call the static decoding method.
    return JsonDecoding.decode<T>(json, using: this);
  }
}

// For encoding a value to JSON.
extension JsonEncodable<T> on Encodable<T> {
  String toJson(T value) {
    return JsonEncoder.encode<T>(value, using: this);
  }
}

// For encoding a self-encodable model to JSON.
extension JsonSelfEncodable<T extends SelfEncodable> on T {
  String toJson() {
    return JsonEncoder.encode<T>(this);
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

An important part of the core protocol is also error handling. It comes with a custom [`CodableException`](https://github.com/schultek/codable/blob/main/lib/src/core/errors.dart) that can be thrown by `Encoder`s and `Decoder`s.

It has (currently) two variants:

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

- **Core protocol:** [/lib/src/core](https://github.com/schultek/codable/tree/main/lib/src/core)

- **Use Cases:**

  - Basic: [/test/basic](https://github.com/schultek/codable/tree/main/test/basic)
  - Collections: [/test/collections](https://github.com/schultek/codable/tree/main/test/collections)
  - Error Handling: [/test/error_handling](https://github.com/schultek/codable/tree/main/test/error_handling)

- **Formats:**
  - Standard: [/lib/src/formats/standard](https://github.com/schultek/codable/blob/main/lib/src/formats/standard.dart)
  - Json: [/lib/src/formats/json](https://github.com/schultek/codable/blob/main/lib/src/formats/json.dart)

**Next up: Benchmark, Reference Implementations and Extended Protocol**

---

# Performance Benchmark

Lets look at what performance we can expect from this protocol. For this benchmark, I compared the implementation of the protocol ("codable") to the "common" way of serializing objects ("baseline").

> The "baseline" implementation uses `.toJson()` with an additional `jsonEncode()` or `utf8.encode()` call.

As with any benchmark, this is not a definitive answer to how good or bad the protocol performs in all cases, but it should give a rough idea of what to expect.

```text
== STANDARD DECODING (Map -> Person) ==
codable: 51.152ms
baseline: 49.152ms
== STANDARD ENCODING (Person -> Map) ==
codable: 114.683ms
baseline: 136.541ms

== JSON STRING DECODING (String -> Person) ==
codable: 227.877ms
baseline: 512.527ms
== JSON STRING ENCODING (Person -> String) ==
codable: 210.664ms
baseline: 572.955ms

== JSON BYTE DECODING (List<int> -> Person) ==
codable: 142.93ms
baseline: 491.833ms
== JSON BYTE ENCODING (Person -> List<int>) ==
codable: 177.105ms
baseline: 619.368ms
```

**Key takeaways:**

- For standard decoding, the performance is a bit slower but not significant. This mainly comes from the added interfaces, abstraction layer and error handling of the protocol implementation. Encoding is a bit faster due to more efficient map operations. For both the difference is negligible in real-world applications.

- For JSON de/encoding, the protocol implementation is significantly faster than the baseline. This is because it avoids the overhead of converting to a Map first and it de/encodes the data sequentially.

See the implementation [here](https://github.com/schultek/codable/tree/main/test/benchmark). You can run the benchmark yourself using `dart test -P benchmark`.

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

The model is implemented in [test/basic/model/person.dart](https://github.com/schultek/codable/blob/main/test/basic/model/person.dart)

### Color

The `Color` model is an enum that can be encoded and decoded in two ways. For human-readable formats (e.g. JSON) it is encoded as a `String` representing its name. For other formats (e.g. MessagePack) it is encoded as an `int` representing its index.

It also shows how to deal with `null` and default values.

The model is implemented in [test/enum/model/color.dart](https://github.com/schultek/codable/blob/main/test/enum/model/color.dart)

### DateTime

The `DateTimeCodable` is a codable implementation for the core `DateTime` type. It shows how to de/encode a core type and combines several encoding strategies.

1. If the data format supports `DateTime` as a [custom type](#custom-types), it is encoded as a custom scalar value.
2. It uses a custom configuration option `preferredFormat` which the user can use to specify one of three formats.

   - `iso8601` will encode the value as an ISO8601 `String`.
   - `unixMilliseconds` will encode the value as a unix milliseconds `int`.
   - `auto` will let the data format determine how the value is encoded. For human-readable formats it is encoded as a `String` and for others as an `int`.

3. It uses a custom configuration option `convertUtc` which controls whether the date value will be converted to UTC before encoding and to local time when decoding.

The codable is implemented in [lib/src/common/datetime.dart](https://github.com/schultek/codable/blob/main/lib/src/common/datetime.dart)

### Uri

The `UriCodable` is a codable implementation for the core `Uri` type.

If the data format supports `Uri` as a [custom type](#custom-types), the value is encoded as a custom scalar value. Else, it is encoded as a `String`.

The codable is implemented in [lib/src/common/uri.dart](https://github.com/schultek/codable/blob/main/lib/src/common/uri.dart)

## Formats

Different data formats to showcase the flexibility of the protocol.

### Standard

The "standard" format de/encodes models to Dart `Map`s, `List`s and primitive value types.

_This is the equivalent to what the `toJson()` method of `json_serializable` does._ As explained in the beginning, this technically is not serialization, but since its a very common thing to do, this protocol of course also has support for it.

The format is implemented in [lib/src/formats/standard.dart](https://github.com/schultek/codable/blob/main/lib/src/formats/standard.dart).

### JSON

A reference implementation for JSON, a human-readable self-describing serial data format.

This supports de/encoding models to both a `String` as well as a `List<int>` of bytes.

To decrease the effort for the reference implementation, this is based largely on the [`crimson`](https://pub.dev/packages/crimson) package. A "real" implementation would probably be fully custom for optimal performance.\_

The format is implemented in [lib/src/formats/json.dart](https://github.com/schultek/codable/blob/main/lib/src/formats/json.dart).

### CSV

A reference implementation for CSV serialization, a human-readable non-self-describing serial data format.

This is limited to simple values only, no nested objects or lists. Values are separated by ",".

Different to other formats, this implementation operates exclusively on lists of models, since all CSV data consists of a number of rows.

The format is implemented in [lib/src/formats/csv.dart](https://github.com/schultek/codable/blob/main/lib/src/formats/csv.dart).

### MessagePack

A reference implementation for MessagePack, a binary self-describing serial data format.

_To decrease the effort for the reference implementation, this uses modified code from the [`messagepack`](https://pub.dev/packages/messagepack) package. A "real" implementation would probably be fully custom for optimal performance._

The format is implemented in [lib/src/formats/msgpack.dart](https://github.com/schultek/codable/blob/main/lib/src/formats/msgpack.dart).

# Extended protocol

The sections below make up the **extended protocol** including special considerations and implementations for things like enums, generics, polymorphism (inheritance) and hooks.

## Enums

For the protocol, enums work exactly as normal models work. Therefore, an enum model should implement `SelfEncodable` and define a static `Codable<MyEnum> codable`.

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

## Generics

To support generic classes, the extended protocol defines additional interfaces `DecodableN`, `EncodableN` and `CodableN`, where `N` denotes the number of type parameters of the implementing class.

_The reference implementation for [generics](https://github.com/schultek/codable/blob/main/lib/src/extended/generics.dart) defines these interfaces for up to 2 type parameters, however this can be easily extended to any number or type parameters._

For example the generic class `Box<T>` uses a `class BoxCodable<T> extends Codable1<Box<T>, T>` codable.

The `encode()` and `decode()` methods of these interfaces accept (besides the standard `encoder` and `decoder` parameters) additional `encodableX` and `decodableX` parameters for each type parameter (with `X` being the name of the type parameter).

For example, the `BoxCodable` implementation for [`Box<T>`](https://github.com/schultek/codable/blob/main/test/generics/basic/model/box.dart) looks like this:

```dart
class BoxCodable<T> implements Codable1<Box<T>, T> {
  const BoxCodable();

  @override
  Box<T> decode(Decoder decoder, [Decodable<T>? decodableT]) {
    // For simplicity, we don't check the decoder.whatsNext() here. Don't do this for real implementations.
    final mapped = decoder.decodeMapped();
    return Box(
      mapped.decodeString('label'),
      mapped.decodeObject<T>('data', using: decodableT),
    );
  }

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    /* ... Discussed later */
  }
}
```

If we now simply call any `.fromX()`/`.toX()` method on `Box.codable`, the `decodableT`/`encodableT` parameter would be null. If `T` is a primitive type this works fine. If `T` is any other type, we have to explicitly provide an `Decodable`/`Encodable` for that type.

To do that, the protocol defines a `.use()` extension methods on all generic interfaces, which can be used like this:

```dart
final Codable<Box<dynamic>> boxUriCodable = Box.codable.use(UriCodable());

final Box<dynamic> box = boxUriCodable.fromJson('...');
final String json = boxUriCodable.toJson(box);
```

Unfortunately, this will only give us a `Box<dynamic>` instead of the concrete `Box<Uri>` type, since extension methods cannot construct new types from only generic parameters. To fix that we need to add a small extension ourselves that wraps the `use()` method like this:

```dart
extension BoxCodableExtension on Codable1<Box, dynamic> {
  // This is a convenience method for creating a BoxCodable with an explicit inner codable.
  Codable<Box<$A>> call<$A>([Codable<$A>? codableA]) => BoxCodable<$A>().use(codableA);
}
```

_Keep in mind that this extension, together with the rest of the model implementation, can and probably will be generated. And even if no code-gen is used, the boilerplate is still tiny._

With this we can change the above example to:

```dart
final Codable<Box<Uri>> boxUriCodable = Box.codable(UriCodable());

final Box<Uri> box = boxUriCodable.fromJson('...');
final String json = boxUriCodable.toJson(box);
```

---

The self-encoding of a generic type using `SelfEncodable` requires a small additional setup.

We can define the `encode` method on `Box<T>` like this:

```dart
class Box<T> implements SelfEncodable {
  Box(this.label, this.data);

  final String label;
  final T data;

  /* ... */

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    encoder.encodeKeyed()
      ..encodeString('label', label)
      ..encodeObject<T>('data', data, using: encodableT)
      ..end();
  }
}

class BoxCodable<T> implements Codable1<Box<T>, T> {
  const BoxCodable();

  @override
  void encode(T value, Encoder encoder, [Encodable<T>? encodableT]) {
    value.encode(encoder, encodableT);
  }

  /* ... */
}
```

Here the `encode` method on `Box<T>` also take an additional `encodableT` parameter parallel to the other methods. If we again simply call any `.toX()` method on `Box<T>`, the `encodableT` parameter would be null. If `T` is either a self-encodable model or a primitive type this works fine. If `T` is any other type, we have to explicitly provide an `Encodable` for that type.

Notice however that we don't implement a `SelfEncodable1` interface but instead still use the base `SelfEncodable` interface. The reason for this will become more clear later, but for now: a generic `SelfEncodableN` can't exist because of how generic inheritance works.

The outcome is that there is also no `.use` extension method on `SelfEncodable` that we could use to provide an instance of `Encodable<T>` while encoding. Instead, we have to define this ourselves _(or generate it)_:

```dart
extension BoxEncodableExtension<T> on Box<T> {
  // Returns a new [SelfEncodable] that uses [encodableT] for the inner type [T].
  SelfEncodable use([Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, encodableT));
  }
}
```

With this we now can do:

```dart
final Box<Person> box = ...
final String json = box.use(Person.codable).toJson();
```

See the full implementation for `Box<T>` [here](https://github.com/schultek/codable/blob/main/test/generics/basic/model/box.dart).

### Reusing Codables

The `.use()` system lets us provide explicit de/encodables for inner types.

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

## Polymorphism & Inheritance

A common pattern that you might want to use for your models is **polymorphism** by **inheritance**.

Take this class structure for example:

```dart
abstract class Pet {
  Pet(this.name);

  final String name;
}

class Cat extends Pet {
  Cat(super.name, this.color);

  final String color;
}

class Dog extends Pet {
  Dog(super.name, this.breed);

  final int breed;
}
```

Here the abstract `Pet` class can either be a `Cat` or a `Dog`, which can inherit some properties but also introduce new ones. Alternatively, `Pet` could also be `sealed`.

### Encoding

Encoding of polymorphic models works exactly the same as normal encoding, though only the base class needs to implement `SelfEncodable`.

```dart
abstract class Pet implements SelfEncodable {
  /* ... */
}

class Cat extends Pet {
  /* ... */

  @override
  void encode(Encoder encoder) {
    encoder.encodeKeyed()
      ..encodeString('name', name)
      ..encodeInt('lives', lives)
      ..end();
  }
}

class Dog extends Pet {
  /* ... */

  @override
  Object? encode(Encoder encoder) {
    return encoder.encodeKeyed()
      ..encodeString('name', name)
      ..encodeString('breed', breed)
      ..end();
  }
}
```

Which can be encoded like this:

```dart
final Dog dog = Dog(name: 'Jasper', breed: 'Australian Shepherd');
final String json = dog.toJson();

// Alternatively, encoding from the base type.
final Pet pet = dog;
assert(json == pet.toJson());
```

### Decoding & Discrimination

Decoding of polymorphic subclasses works exactly the same as normal decoding. Each subtype defines a `codable` instance which can be used explicitly with any data format.

However, we sometimes only know the supertype to decode from. Consider the following class:

```dart
class Person {
  Person(this.pet);

  final Pet pet;
}
```

When we want to decode a `Person` object, the `pet` property can either be a `Cat` or a `Dog`, but we don't know the exact subtype statically. Therefore, we need a way to distinguish between the subtypes and select one during decoding. This process is called **discrimination**.

The common way to discriminate between subtypes is by using a **discriminator property**. This is an additional property on the encoded data, that uniquely identifies the target subtype.

For example `{"name": "Jasper", "breed": "Australian Shepherd", "type": "dog"}` uses the additional `type` property as a discriminator. In our case, we define this to be either "dog" or "cat". To use this during decoding, we could modify our `PetCodable` class to something like this:

```dart
class PetCodable extends SelfCodable<Pet> {
  const PetCodable();

  @override
  Pet decode(Decoder decoder) {
    var discriminator = decoder.decodeKeyed().decodeStringOrNull('type');
    return switch (type) {
      'dog' => decoder.decodeObject(using: Cat.codable),
      'cat' => decoder.decodeObject(using: Dog.codable),
      _ => decoder.expect('discriminator "type" of "dog" or "cat"'),
    };
  }
}
```

However, as you might already have guessed, this won't work. Mainly because in the `decode` method, only a single `decoder.decode...()` call is allowed to be made, but here we do two (first `decoder.decodeKeyed()` and then `decoder.decodeObject()`). Additionally, there are other problematic things, which will be addressed later.

To make working with discriminators more convenient and safe, the extended protocol comes with a [`SuperDecodable`](https://github.com/schultek/codable/blob/main/lib/src/extended/inheritance.dart#L8) mixin, which can be used like this:

```dart
class PetCodable extends SelfCodable<Pet> with SuperDecodable<Pet> {
  const PetCodable();

  // The discriminator property key.
  @override
  String? get discriminatorKey => 'type';

  // A list of discriminators to choose from.
  @override
  List<Discriminator<Pet>> get discriminators => [
        // A [Discriminator] has the expected discriminator value and a function for creating a decodable instance for the target subtype. This example assumes we have [static Codable<T> codable] properties for each subtype.
        Discriminator<Cat>('cat', () => Cat.codable),
        Discriminator<Dog>('dog', () => Dog.codable)),
      ];
}
```

The `SuperDecodable` mixin defines a default `decode()` method that chooses the correct discriminator in a safe way. The `PetCodable` can then be used as any other codable, but it will always decode to a concrete subtype (or fail):

```dart
final String json = '{"name": "Jasper", "breed": "Australian Shepherd", "type": "dog"}';
final Pet pet = Pet.codable.fromJson(json);

assert(pet is Dog);
```

#### Fallback Decode

For some cases, you want a **default object** to be decoded when the discriminator matches no subtype. This can either be another subtype, or the super class itself (if it is not abstract).

To add such an object, implement the `decodeFallback()` method of the `SuperDecodable` mixin. This has the same signature and rules of the normal `decode()` method.

```dart
class SomeDefaultPet extends Pet {
  /* ... */
}

class PetCodable extends SelfCodable<Pet> with SuperDecodable<Pet> {
  /* ... */

  @override
  Pet decodeFallback(Decoder decoder) {
    return SomeDefaultPet(type: decoder.decodeMapped().decodeString('type'));
  }
}
```

#### Custom Discriminators

Using a **discriminator property** works for the majority of use-cases, but sometimes need some custom discrimination logic that does not depend on a single property.

Therefore, the `Discriminator` value can also be a `bool Function(Decoder)`, which then is used as a predicate to determine if a given subtype should be chosen.

Lets assume we have these classes, and also can't use a discriminator property (e.g. because we don't control the backend API this is returned from):

```dart
sealed class Result {}

class ResultData extends Result {
  ResultData(this.data);
  final String data;
}

class ResultError extends Result {
  ResultError(this.error);
  final Object? error;
}
```

A `Decodable` implementation can look like this:

```dart
class ResultDecodable with SuperDecodable<Result> {
  ResultDecodable();

  // Signals that we don't have a discriminator property.
  @override
  String? get discriminatorKey => null;

  // A list of discriminators using a predicate function.
  @override
  List<Discriminator<Result>> get discriminators => [
        Discriminator<ResultData>((decoder) {
          // Check for the existance of the "data" property.
          return decoder.decodeMapped().keyed.contains("data");
        }, () => ResultData.codable),
        Discriminator<ResultError>((decoder) {
          // Check for the existance of the "error" property.
          return decoder.decodeMapped().keyed.contains("error");
        }, () => ResultError.codable),
      ];
}
```

With predicate functions we can of course do a lot more than checking for the existence of properties, but this is up to the developer. The provided `decoder` is always sandboxed, which means it doesn't affect the original decoder and can safely be used to inspect the encoded data.

### Generic Polymorphism

Classes can of course also combine both **generics** and **polymorphism**. For example, the `Result` class would more likely be a `Result<T>` class with a generic `T data` property. Here we need to make sure that any type parameter is correctly passed to the subclass during decoding (which can get very tricky sometimes, but more on that later).

For this case, the extended protocol includes generic `SuperDecodableN` interfaces, where `N` is the number of type parameters the target class has. Similarly, there are `Discriminator.argN` variants for generic classes.

Both together can be used like this:

```dart
sealed class Result<T> { /* ... */ }
class ResultData<T> extends Result<T> { /* ... */ }
class ResultError<T> extends Result<T> { /* ... */ }

class ResultCodable<T> implements Codable1<Result<T>, T> with SuperDecodable1<Result<T>, T> {
  ResultCodable();

  // For simplicity we use a discriminator property again, but generics also works with predicate functions.
  @override
  String get discriminatorKey => 'type';

  @override
  List<Discriminator<Pet>> get discriminators => [
        // Uses the 'arg1' variant to specify a discriminator for a generic class.
        Discriminator.arg1<ResultData>(
          "data",
          // Receives the type parameter and its decodable, and needs to construct the subclass decodable.
          // This uses the alternative [useDecodable] extension on [Codable], since [use] here would expect a full [Codable].
          <T>(Decodable<T>? decodableT) => ResultDataCodable<T>().useDecodable(decodableT),
        ),
        Discriminator.arg1<ResultError>(
          "error",
          <T>(Decodable<T>? decodableT) => ResultErrorCodable<T>().useDecodable(decodableT),
        ),
      ];
}
```

The `ResultCodable` can then be used as any other generic codable (assuming we did the proper setup for generic classes as shown in the [Generics](#generics) section):

```dart
final String json = '{"data": "https://schultek.dev", "type": "data"}';
final Result<Uri> result = Result.codable(UriCodable()).fromJson(json);

assert(result is ResultData<Uri>);
```

---

The setup for self-encodable generic polymorphic classes is for simple cases the same as with normal generic classes, as described in the [Generics](#generics) section.

To recap, here is the setup we would need to the `Result` classes:

```dart
abstract class Result<T> implements SelfEncodable {
  /* ... */

  // Extend the signature to include the [encodableT] parameter.
  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]);
}

extension ResultEncodableExtension<T> on Result<T> {
  // Returns a new [SelfEncodable] that uses [encodableT] for the inner type [T].
  SelfEncodable use([Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, encodableT));
  }
}

class ResultData<T> extends Result<T> {
  /* ... */

  final T data;

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    final keyed = encoder.encodeKeyed();
    // Here we also encode the discriminator property. Whether to do this is up to the implementation.
    keyed.encodeString('type', 'data');
    keyed.encodeObject<T>('data', data, using: encodableT);
    keyed.end();
  }
}

class ResultError<T> extends Result<T> {
  /* ... */

  final Object? error;

  // This can safely ignore the [encodableT] parameter since it doesn't need it.
  @override
  void encode(Encoder encoder, [_]) {
    encoder.encodeKeyed()
      // Here we also encode the discriminator property. Whether to do this is up to the implementation.
      ..encodeString('type', 'error')
      ..encodeObject('error', error)
      ..end();
  }
}
```

As discussed in the [Generics](#generics) section, there is no `SelfEncodableN` interface, so we have to extend the signature of the `encode` method manually. Also, we only need to define the `ResultEncodableExtension` once for the base type as the subtypes can also use it.

The usage of these classes looks as usual:

```dart
final Result<Person> result = ResultData(...);
final String json = result.use(Person.codable)).toJson();
```

### Complex Generic Polymorphism

Now it gets even more complex. Class structures using both generics and inheritance are not limited to a fixed number of type parameters and can take on many forms. We need to be aware of things like additional type parameters, reduced type parameters, bounded type parameters, modified type parameters, or any combination of those.

> You won't believe how many super duper complex class structures I have seen while developing dart_mappable. I'm trying to cluster them into some common categories here. These categories are not disjoint though and classes can combine the criteria from multiple categories.

The below cases assume the following base class:

```dart
abstract class Box<T> implements SelfEncodable {
  /* ... */

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]);
}
```

#### Additional Type Parameters

A subclass might add additional type parameters to its definition.

```dart
class MetaBox<V, T> extends Box<T> {}
```

In this case, the `Discriminator` for `MetaBox` needs to be adjusted like this:

```dart
Discriminator.arg1<MetaBox>(
  "meta",
  <T>(Decodable<T>? decodableT) => MetaBoxCodable<dynamic, T>().useDecodable(null, decodableT),
),
```

Here we can only provide the `T` type parameter and decodable, and need to use `dynamic` and `null` for any additional one.

---

The `encode` method also needs adjusting.

```dart
class MetaBox<V, T> extends Box<T> {
  /* ... */

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT, Encodable<V>? encodableV]) {
    /* ... */
  }
}
```

Since the method must be a valid override of the `Box.encode` method, we cannot change the position of the `encodableT` parameter here (which comes first in the method, but `T` comes second in the class definition). Any additional encodable parameter must be added to the end of the parameter list.

However, the order of the parameters can stay an implementation detail, as we can define the encodable extension with parameters in the correct order:

```dart
extension MetaBoxEncodableExtension<V, T> on MetaBox<V, T> {
  SelfEncodable use([Encodable<V>? encodableV, Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, encodableT, encodableV));
  }
}
```

And subsequently use it like this:

```dart
final MetaBox<int, Person> box = MetaBox(42, ...);
final String json = box.use(null, Person.codable).toJson();
```

#### Reduced Type Parameters

A subclass might reduce, or 'fix' the type parameters of its superclass.

```dart
class LabelBox extends Box<String> {}
```

In this case, the `Discriminator` for `LabelBox` needs to look like this:

```dart
Discriminator.arg1<LabelBox>(
  "label",
  <_>(_) => LabelBox.codable,
),
```

Here we simply ignore the provided type parameter and decodable instance. However this also means, that we now limit the possible static type of `Box` we can decode to this subtype:

```dart
// Works fine, since [LabelBox] is assignable to [Box<dynamic>]
final Box<dynamic> box = Box.codable.fromJson('{"type": "label"}');
assert(box is LabelBox);

// Also works fine, since [LabelBox] is assignable to [Box<String>]
final Box<String> box = Box.codable<String>().fromJson('{"type": "label"}');
assert(box is LabelBox);

// Does not work, since [LabelBox] is not assignable to [Box<int>]
// This will report an error (assuming we don't have another discriminator for "label" that supports [Box<int>]).
final Box<int> box = Box.codable<int>().fromJson('{"type": "label"}');
```

---

For encoding this case there is generally no additional change we need to make. But since for `LabelBox` the value is always a `String`, the `encode` method can simply ignore the `encodableT` parameter and call `encodeString` directly:

```dart
class LabelBox extends Box<String> {
  /* ... */

  @override
  void encode(Encoder encoder, [_]) {
    encoder.encodeKeyed()
      ..encodeString('content', content)
      ..end();
  }
}
```

#### Bounded Type Parameters

A subclass might add a new (or more specific) bound to the type parameters of its superclass.

```dart
class NumberBox<T extends num> extends Box<T> {}
```

In this case, the `Discriminator` for `NumberBox` needs to look like this:

```dart
Discriminator.arg1Bounded<NumberBox, num>(
  "number",
  <T extends num>(Decodable<T>? decodableT) => NumberBox.codable<T>(decodableT),
),
```

The `Discriminator.arg1Bounded` will make sure the type parameter can be assigned to the bound before calling the function. Similar to [Reduced Type Parameters](#reduced-type-parameters) this of course limits the possible static type of `Box` we can decode to this subtype:

```dart
// Works fine, since [NumberBox] is assignable to [Box<dynamic>]
final Box<dynamic> box = Box.codable.fromJson('{"type": "number"}');
assert(box is NumberBox);

// Also works fine, since [NumberBox] is assignable to [Box<num>]
final Box<num> box = Box.codable<num>().fromJson('{"type": "number"}');
assert(box is NumberBox);

// Also works fine, since [NumberBox] is assignable to [Box<int>]
final Box<int> box = Box.codable<int>().fromJson('{"type": "number"}');
assert(box is NumberBox<int>);

// Does not work, since [NumberBox] is not assignable to [Box<String>]
// This will report an error (assuming we don't have another discriminator for "number" that supports [Box<String>]).
final Box<String> box = Box.codable<String>().fromJson('{"type": "number"}');
```

---

For encoding this case there is no additional change we need to make. But since for `NumberBox` the type bound is num, the `encode` method can simply ignore the `encodableT` parameter and call `encodeNum` directly:

```dart
class NumberBox<T extends num> extends Box<T> {
  /* ... */

  @override
  void encode(Encoder encoder, [_]) {
    encoder.encodeKeyed()
      ..encodeNum('content', content)
      ..end();
  }
}
```

#### Modified Type Parameters

A subclass can also change the type parameter in a way that it uses the original type parameter in a modified way, for example by wrapping it in another generic type.

```dart
class Boxes<T> extends Box<List<T>> {}
```

This is a bit more tricky to get right during decoding, as essentially we have to get from `T extends List` to whatever the element type of `List` is. So we would need to extract inner type parameters from a generic type `T`, which is not directly possible in Dart.

```dart
void main() {
  doSomething<List<int>>();
}

void doSomething<T>() {
  // How would we extract E here from just T (== List<E>)?
  // Its not possible (without tricks).
}
```

To work around this limitation, the extended protocol comes with an interface `ComposedDecodableN<T, A, ...> implements Decodable<T>`. Again `N` denotes the number of type parameters the class `T` has, and `A`, `B`, etc. are those type parameters.

This interface is secretly used by all returned instances from the `.use()` extension methods, as well as the common implementations of `ListCodable`, `SetCodable` and `MapCodable`. So if a user implementation followed the protocol so far and properly used collections and defined generic codables, chances are very good the provided `decodableT` is already a `ComposedDecodableN`.

```dart
Discriminator.arg1Bounded<Boxes, List>(
  "boxes",
  <T extends List>(Decodable<T>? decodableT) {
    // Here [decodableT] is very likely a [ComposedDecodable1].
    // In this case specifically its very likely a [ListCodable], which implements [ComposedDecodable1].
  },
),
```

Now the "trick" is, that `ComposedDecodable1` defines a special `extract()` method, that allows the user to extract the inner type parameter of its generic type. It is defined like this:

```dart
R extract<R>(R Function<A>(Decodable<A>? decodableA) fn);
```

and can be used like this:

```dart
Discriminator.arg1Bounded<Boxes, List>(
  "boxes",
  <T extends List>(Decodable<T>? decodableT) {
    if (decodableT case ComposedDecodable1 d) {
      // Use the special [extract] method to get the inner type parameter of [T].
      return d.extract<Decodable<Boxes>>(<E>(Decodable<E>? decodableE) => BoxesCodable<E>().useDecodable<E>(decodableE));
    } else {
      // Fallback to decoding [Boxes<dynamic>] when we cannot extract the type parameter.
      return Boxes.codable;
    }
  },
),
```

As with the other cases, this again limits the possible static type of `Box` we can decode to this subtype:

```dart
// Works fine, since [Boxes<dynamic>] is assignable to [Box<dynamic>].
// This will fallback to the non-extraction case.
final Box<dynamic> box = Box.codable.fromJson('{"type": "boxes"}');
assert(box is Boxes);

// Also works fine, since [Boxes<dynamic>] is assignable to [Box<List>].
// This will also fallback to the non-extraction case because we didn't provide an inner codable for [List].
final Box<List> box = Box.codable<List>().fromJson('{"type": "boxes"}');
assert(box is Boxes);

// Also works fine, since [Boxes<Person>] is assignable to [Box<List<Person>>].
// This will extract the inner [Person] type from the provided [ListCodable].
final Box<List<Person>> box = Box.codable<List<Person>>(Person.codable.list()).fromJson('{"type": "boxes"}');
assert(box is Boxes<Person>);

// Does not work, since no inner codable is provided and [Boxes<dynamic>] is not assignable to [Box<List<String>>]
// This will report an error (assuming we don't have another discriminator for "boxes" that supports [Box<List<String>>]).
final Box<List<String>> box = Box.codable<List<String>>().fromJson('{"type": "boxes"}');
```

---

For this case the `encode` method needs adjusting again:

```dart
class Boxes<T> extends Box<List<T>> {
  /* ... */

  @override
  void encode(Encoder encoder, [Encodable<List<T>>? encodableT, Encodable<T>? encodableT2]) {
    final keyed = encoder.encodeKeyed();
    if (encodableT2 == null && encodableT != null) {
      // Encode as an object and use the codable for the whole list.
      keyed.encodeObject('content', content, using: encodableT);
    } else {
      // Encode as a normal iterable, optionally use the codable for the elements.
      keyed.encodeIterable('content', content, using: encodableT2);
    }
    keyed.end();
  }
}
```

Since the method must be a valid override of the `Box.encode` method, we cannot change the inherited `encodableT` parameter here. Instead, we must add an additional parameter.

However, the exact parameters can stay an implementation detail, as we can define the encodable extension with the correct parameter:

```dart
extension BoxesEncodableExtension<T> on Boxes<T> {
  SelfEncodable use([Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, null, encodableT));
  }
}
```

This will let us encode the object as either a `Boxes<T>` or a `Box<List<T>>` and provide the correct inner codable:

```dart
final Boxes<Person> boxes = Boxes([...]);
// This refers to the [use] method from [BoxesEncodableExtension] and
// therefore expects a Codable<Person>.
final String json = boxes.use(Person.codable).toJson();

final Box<List<Person>> box = boxes;
// This refers to the [use] method from [BoxEncodableExtension] and
// therefore expects a Codable<List<Person>>.
final String json2 = box.use(Person.codable.list()).toJson();
```

---

To see the complete implementation for all of the above cases, see [test/polymorphism/complex/model/box.dart](https://github.com/schultek/codable/blob/main/test/polymorphism/complex/model/box.dart).
