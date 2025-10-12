Different data formats included in the package.

# Standard

The "standard" format de/encodes models to Dart `Map`s, `List`s and primitive value types.

_This is the equivalent to what the `toJson()` method of `json_serializable` does._ As explained in the beginning, this technically is not serialization, but since its a very common thing to do, this protocol of course also has support for it.

The format can be used by importing `package:codable_dart/standard.dart`, which provides the `fromValue()`, `toValue()` and `fromMap()`, `toMap()` extension methods.

# JSON

An implementation for JSON, a human-readable self-describing serial data format.

This supports de/encoding models to both a `String` as well as a `List<int>` of bytes.

The format can used by importing `package:codable_dart/json.dart` and provides the `fromJson()`, `toJson()` and `fromJsonBytes()`, `toJsonBytes()` extension methods.

_The implementation is largely based on the [`crimson`](https://pub.dev/packages/crimson) package.\_

# CSV

An implementation for CSV serialization, a human-readable non-self-describing serial data format.

This is limited to simple values only, no nested objects or lists. Values are separated by ",".

Different to other formats, this implementation operates exclusively on lists of models, since all CSV data consists of a number of rows.

The format can used by importing `package:codable_dart/csv.dart` and provides the `fromCsv()`, `toCsv()` and `fromCsvBytes()`, `toCsvBytes()` extension methods.

# MessagePack

An implementation for MessagePack, a binary self-describing serial data format.

The format can used by importing `package:codable_dart/json.dart` and provides the `fromMsgPack()` and `toMsgPack()` extension methods.

_The implementation is largely based on the [`messagepack`](https://pub.dev/packages/messagepack) package.\_
