# RFC: New Serialization Protocol for Dart

This repository contains the RFC and reference implementation for a new serialization protocol for Dart.

👉 **Read the RFC:** [RFC: New Serialization Protocol for Dart](https://github.com/schultek/codable/blob/main/docs/rfc.md)

💬 **Discuss & Give Feedback** [Github Issue](https://github.com/schultek/codable/issues/1) / [Flutter Forum Post](https://forum.itsallwidgets.com/t/rfc-new-serialization-protocol-for-dart/2355)

---

### Codebase Overview

- **Core Protocol:** [/lib/src/core](https://github.com/schultek/codable/tree/main/lib/src/core)

- **Use cases:**

  - Basic: [/test/basic](https://github.com/schultek/codable/tree/main/test/basic)
  - Collections: [/test/collections](https://github.com/schultek/codable/tree/main/test/collections)
  - Error Handling: [/test/error_handling](https://github.com/schultek/codable/tree/main/test/error_handling)
  - Generics: [/test/generics](https://github.com/schultek/codable/tree/main/test/generics)
  - Polymorphism: [/test/polymorphism](https://github.com/schultek/codable/tree/main/test/polymorphism)

- **Benchmark**: [/test/benchmark](https://github.com/schultek/codable/tree/main/test/benchmark)

- **Format Implementations:**

  - Standard: [/lib/src/formats/standard](https://github.com/schultek/codable/tree/main/lib/src/formats/standard.dart)
  - JSON: [/src/formats/json](https://github.com/schultek/codable/tree/main/lib/src/formats/json.dart)
  - MessagePack: [/src/formats/msgpack](https://github.com/schultek/codable/tree/main/lib/src/formats/msgpack.dart)
  - CSV: [/src/formats/csv](https://github.com/schultek/codable/tree/main/lib/src/formats/csv.dart)

- **Type Implementations:**

  - Person: [/test/basic/model/person](https://github.com/schultek/codable/tree/main/test/basic/model/person.dart)
  - Color: [/test/enum/model/color](https://github.com/schultek/codable/tree/main/test/enum/model/color.dart)
  - List & Set: [/lib/src/common/iterable](https://github.com/schultek/codable/tree/main/lib/src/common/iterable.dart)
  - Map: [/lib/src/common/map](https://github.com/schultek/codable/tree/main/lib/src/common/map.dart)
  - DateTime: [/lib/src/common/datetime](https://github.com/schultek/codable/tree/main/lib/src/common/datetime.dart)
  - Uri: [/lib/src/common/uri](https://github.com/schultek/codable/tree/main/lib/src/common/uri)

- **Extended Protocol:** [/lib/src/extended](https://github.com/schultek/codable/tree/main/lib/src/extended)

---

### How to contribute?

If you would like to contribute, there are several ways to do so.

First, just **[read the RFC](https://github.com/schultek/codable/blob/main/docs/rfc.md)** and give feedback by commenting on the [issue](https://github.com/schultek/codable/issues/1) or the [forum post](https://forum.itsallwidgets.com/t/rfc-new-serialization-protocol-for-dart/2355).

A ⭐️ is also very appreciated, and you can help by spreading the word about this proposal.

Finally, you can contribute code for the following things:

- **Test Cases**: Have a special case or unique problem you need to solve? Contribute a test case and we can make sure it is supported by the protocol.
- **Formats**: Add a new data format implementation or improve the existing ones.

> [!IMPORTANT]  
> Before contributing, please **open an issue first** so others can see what is being worked, discuss ideas, and combine efforts.
