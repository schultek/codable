import 'decoder.dart';
import 'encoder.dart';

/// An object that can encode itself to various data formats.
///
/// The interface can be used like this:
///
/// ```dart
/// class Person implements SelfEncodable {
///   /* ... */
///
///   @override
///   void encode(Encoder encoder) {
///     /* ... */
///   }
/// }
/// ```
///
/// Objects implementing [SelfEncodable] can be encoded to various data formats using the respective `to<Format>()`
/// extension method. A particular method is available by importing the appropriate library or package:
///
/// ```dart
/// final Person person = ...;
///
/// // From 'package:codable/json.dart'
/// final String json = person.toJson();
///
/// // From 'package:codable/standard.dart'
/// final Map<String, dynamic> map = person.toMap();
///
/// // From imaginary 'package:x/x.dart'
/// final X x = person.toX();
/// ```
///
/// See also:
/// - [Encodable] for encoding values of some type to various data formats.
/// - [Decodable] for decoding values of some type from various data formats.
/// - [Codable] for combining both encoding and decoding of types.
abstract interface class SelfEncodable {
  /// Encodes itself using the [encoder].
  ///
  /// The implementation should use one of the typed [Encoder]s `.encode...()` methods to encode the value.
  /// It is expected to call exactly one of the encoding methods a single time. Never more or less.
  void encode(Encoder encoder);
}

/// An object that can encode a value of type [T] to various data formats.
///
/// The interface can be used like this:
///
/// ```dart
/// class UriEncodable implements Encodable<Uri> {
///   const UriEncodable();
///
///   @override
///   void encode(Uri value, Encoder encoder) {
///     /* ... */
///   }
/// }
/// ```
///
/// The [Encodable] interface can be used for any type, especially ones that cannot be modified to implement [SelfEncodable]
/// instead, like core or third-party types. It can also be used to separate the encoding logic from the type definition.
///
/// Objects implementing [Encodable] can encode values to various data formats using the respective `to<Format>(T value)`
/// extension method. A particular method is available by importing the appropriate library or package:
///
/// ```dart
/// final Encodable<Uri> uriEncodable = const UriEncodable();
/// final Uri uri = ...;
///
/// // From 'package:codable/json.dart'
/// final String json = uriEncodable.toJson(uri);
///
/// // From 'package:codable/standard.dart'
/// final Object value = uriEncodable.toValue(uri);
///
/// // From imaginary 'package:x/x.dart'
/// final X x = uriEncodable.toX(uri);
/// ```
///
/// See also:
/// - [SelfEncodable] for self-encoding objects to various data formats.
/// - [Decodable] for decoding values of some type from various data formats.
/// - [Codable] for combining both encoding and decoding of types.
abstract interface class Encodable<T> {
  /// Encodes the [value] using the [encoder].
  ///
  /// The implementation must use one of the typed [Encoder]s `.encode...()` methods to encode the value.
  /// It is expected to call exactly one of the encoding methods a single time. Never more or less.
  void encode(T value, Encoder encoder);

  /// A default [Encodable] implementation for [SelfEncodable] types.
  ///
  /// This should be used where an [Encodable] object is expected and the value is an [SelfEncodable].
  ///
  /// ```dart
  /// final Person person = ...;
  /// final Encoder encoder = ...;
  ///
  /// encoder.encodeObject<Person>(person, using: Encodable.self());
  /// ```
  static Encodable<T> self<T extends SelfEncodable>() => _SelfEncodable<T>();
}

class _SelfEncodable<T extends SelfEncodable> implements Encodable<T> {
  const _SelfEncodable();

  @override
  void encode(T value, Encoder encoder) {
    value.encode(encoder);
  }
}

/// An object that can decode a value of type [T] from various data formats.
///
/// The interface can be used like this:
///
/// ```dart
/// class PersonDecodable implements Decodable<Person> {
///   const PersonDecodable();
///
///   @override
///   Person decode(Decoder decoder) {
///     /* ... */
///   }
/// }
/// ```
///
/// The [Decodable] interface can be used for any type, including first-party types, core or third-party types.
///
/// Objects implementing [Decodable] can decode values to various data formats using the respective `T from<Format>(data)`
/// extension method. A particular method is available by importing the appropriate library or package:
///
/// ```dart
/// final Decodable<Person> personDecodable = const PersonDecodable();
///
/// // From 'package:codable/json.dart'
/// final Person person = personDecodable.fromJson('...');
///
/// // From 'package:codable/standard.dart'
/// final Person person = personDecodable.fromMap({...});
///
/// // From imaginary 'package:x/x.dart'
/// final Person person = personDecodable.fromX(x);
/// ```
///
/// See also:
/// - [Encodable] for encoding values to various data formats.
/// - [Codable] for combining both encoding and decoding of types.
abstract interface class Decodable<T> {
  /// Decodes a value of type [T] using the [decoder].
  ///
  /// The implementation should first use [Decoder.whatsNext] to determine the type of the encoded data.
  /// Then it should use one of the [Decoder]s `.decode...()` methods to decode into its target type.
  /// If the returned [DecodingType] is not supported, the implementation can use [Decoder.expect] to throw a detailed error.
  T decode(Decoder decoder);
}

/// An object that can both encode and decode a value of type [T] to/from various data formats.
///
/// It combines both [Encodable] and [Decodable] into a single interface and can be used like this:
///
/// ```dart
/// class PersonCodable implements Codable<Person> {
///   const PersonCodable();
///
///   @override
///   void encode(Person value, Encoder encoder) {
///     /* ... */
///   }
///
///   @override
///   Person decode(Decoder decoder) {
///     /* ... */
///   }
/// }
/// ```
///
/// Objects implementing [Codable] can encode and decode values to various data formats using the respective
/// `to<Format>(T value)` and `T from<Format>(data)` extension methods. A particular method is available by
/// importing the appropriate library or package:
///
/// ```dart
/// final Codable<Person> codable = const PersonCodable();
///
/// // From 'package:codable/json.dart'
/// final Person person = codable.fromJson('...');
/// final String json = codable.toJson(person);
///
/// // From 'package:codable/standard.dart'
/// final Person person = codable.fromMap({...});
/// final Map<String, dynamic> map = codable.toMap(person);
///
/// // From imaginary 'package:x/x.dart'
/// final Person person = codable.fromX(x);
/// final X x = codable.toX(person);
/// ````
///
/// See also:
/// - [Encodable] for encoding values of some type to various data formats.
/// - [Decodable] for decoding values of some type from various data formats.
abstract class Codable<T> implements Encodable<T>, Decodable<T> {
  const Codable();
}

/// A default [Codable] implementation for [SelfEncodable] types.
///
/// This should be used as the base class for creating a [Codable] implementation for an [SelfEncodable] type.
/// Only the [decode] method needs to be implemented, as the [encode] method has a default implementation.
///
/// ```dart
/// class PersonCodable extends SelfCodable<Person> {
///   const PersonCodable();
///
///   @override
///   Person decode(Decoder decoder) {
///     /* ... */
///   }
/// }
abstract class SelfCodable<T extends SelfEncodable> extends _SelfEncodable<T> implements Codable<T> {
  const SelfCodable();
}
