# Codable Protocol for Dart

# 🚨 WIP 🚨 If you read this, the proposal is not finished yet. Come back later.

This repository contains the RFC and reference implementation for a new serialization protocol for Dart.

👉 **Read the RFC:** [RFC: Codable Protocol for Dart](TODO)

💬 **Discuss & Give Feedback** [Github Issue](TODO) / [Flutter Forum Post](TODO)

---

### Codabase Overview

- **Core Protocol:** [/lib/src/core](TODO)

- **Use cases:**

  - Basic: [/test/basic](TODO)
  - Collections: [/test/collections](TODO)
  - Error Handling: [/test/error_handling](TODO)
  - Generics: [/test/generics](TODO)
  - Polymorphism: [/test/polymorphism](TODO)

- **Format Implementations:**

  - Standard: [/lib/src/formats/standard](TODO)
  - JSON: [/src/formats/json](TODO)
  - MessagePack: [/src/formats/msgpack](TODO)
  - CSV: [/src/formats/csv](TODO)

- **Type Implementations:**

  - Person: [/test/basic/model/person](TODO)
  - Color: [/test/enum/model/color](TODO)
  - List & Set: [/lib/src/common/iterable](TODO)
  - Map: [/lib/src/common/map](TODO)
  - DateTime: [/lib/src/common/datetime](TODO)
  - Uri: [/lib/src/common/uri](TODO)

- **Extended Protocol:** [/lib/src/extended](TODO)

---

### How to contribute?

If you would like to contribute, there are several ways to do so.

First, just **[read the RFC](TODO)** and give feedback by commenting on the [issue](TODO) or the [forum post](TODO).

A ⭐️ is also very appreciated, and you can help by spreading the word about this proposal.

Finally, you can contribute code for the following things:

- **Test Cases**: Have a special case or unique problem you need to solve? Contribute a test case and we can make sure it is supported by the protocol.
- **Formats**: Add a new data format implementation or improve the existing ones.
- **Code Generation**: Create a build_runner, macros or other codegen implementation for generating model implementations.

_For all of these, please **open an issue first** so others can see what is being worked, discuss ideas, and combine efforts._
