import 'dart:core' as core;
import 'dart:core';

import 'interface.dart';

/// A data format that can decode different types of data.
///
/// The role of this interface is to convert the encoded data into the supported types.
/// Different implementations of this interface can support different data types and decoding strategies.
///
/// Decoding is performed by mutual interaction between the [Decoder] and the [Decodable] implementation.
///
/// - The [Decoder] can provide the actual or preferred [DecodingType] of the encoded data using [whatsNext].
/// - The [Decodable] implementation can call decoding methods for the requested or expected type, e.g. [decodeString].
///
/// A [Decodable] implementation should first use [whatsNext] to determine the type of the encoded data.
/// Then it should use one of the typed `.decode...()` methods of this interface to decode into its target type.
/// If the returned [DecodingType] is not supported, the implementation can use [expect] to throw a detailed error.
///
/// ```dart
/// /// Example of a [Decodable.decode] implementation:
/// @override
/// Data decode(Decoder decoder) {
///   switch (decoder.whatsNext()) {
///     case DecodingType.string:
///       final value = decoder.decodeString();
///       return Data.fromString(value);
///     case DecodingType.double:
///       final value = decoder.decodeDouble();
///       return Data.fromDouble(value);
///     default:
///       decoder.expect('string or double');
///   }
/// }
/// ```
///
/// What possible [DecodingType]s are returned by [whatsNext] depends on the type of data format:
///
/// - A self-describing format (i.e. the encoded data includes information about the type and shape of the data) can
///   return [DecodingType]s for all supported types. The [Decodable] implementation may choose to call the appropriate
///   decoding method based on the returned [DecodingType]. However, it is not required to do so.
///
///   Self-describing formats include JSON, YAML, or binary formats like MessagePack and CBOR.
///
/// - A non-self-describing format may only return [DecodingType.unknown] for all types. In this case, the [Decodable]
///   implementation must choose a appropriate decoding method based on its expected type.
///
///   Non-self-describing formats include CSV or binary formats like Protobuf or Avro (when separated from schema).
///
/// Independent of the formats preferred [DecodingType], it should try to decode other types if requested by
/// the [Decodable]. This allows for more flexible decoding strategies and better error handling.
/// For example, a [Decodable] implementation may choose to call [decodeInt] even if [whatsNext] returns [DecodingType.num].
///
/// If the [Decoder] is not able to decode the requested type, it should throw an exception with a detailed message.
///
/// Calling a decoding method is expected to consume the encoded data. Therefore, a [Decodable] implementation should
/// call exactly one of the decoding methods a single time. Never more or less.
abstract interface class Decoder {
  /// Returns the actual or preferred [DecodingType] of the encoded data.
  ///
  /// Self-describing formats may return a [DecodingType] that indicates the type of the encoded data,
  /// or the preferred way of decoding it.
  ///
  /// Non-self-describing formats may only return [DecodingType.unknown] for all types. In this case, the [Decodable]
  /// implementation must try the appropriate decoding method based on the expected type.
  DecodingType whatsNext();

  /// Decodes the data as a boolean value.
  bool decodeBool();

  /// Decodes the data as a nullable boolean value.
  bool? decodeBoolOrNull();

  /// Decodes the data as an integer value.
  int decodeInt();

  /// Decodes the data as a nullable integer value.
  int? decodeIntOrNull();

  /// Decodes the data as a double value.
  double decodeDouble();

  /// Decodes the data as a nullable double value.
  double? decodeDoubleOrNull();

  /// Decodes the data as a num value.
  num decodeNum();

  /// Decodes the data as a nullable num value.
  num? decodeNumOrNull();

  /// Decodes the data as a string value.
  String decodeString();

  /// Decodes the data as a nullable string value.
  String? decodeStringOrNull();

  /// Checks if the data is null.
  bool decodeIsNull();

  /// Decodes the data as an object of type [T].
  ///
  /// This forwards the decoding to the provided [Decodable] implementation.
  /// Otherwise tries to decode the data to a supported primitive type [T].
  /// 
  /// This should only be called if the format returned a `DecodingType<T>` from [whatsNext] or
  /// is otherwise known to support [T] as a custom type.
  T decodeObject<T>({Decodable<T>? using});

  /// Decodes the data as a nullable object of type [T].
  ///
  /// When the data is not null behaves like [decodeObject].
  T? decodeObjectOrNull<T>({Decodable<T>?using});

  /// Decodes the data as a list of elements.
  ///
  /// Optionally takes a [Decodable] to decode the elements of the list.
  List<E> decodeList<E>({Decodable<E>? using});

  /// Decodes the data as a nullable list of elements.
  ///
  /// Optionally takes a [Decodable] to decode the elements of the list.
  List<E>? decodeListOrNull<E>({Decodable<E>? using});

  /// Decodes the data as a map of key-value pairs.
  ///
  /// Optionally takes [Decodable]s to decode the keys and values of the map.
  Map<K, V> decodeMap<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing});

  /// Decodes the data as a nullable map of key-value pairs.
  ///
  /// Optionally takes [Decodable]s to decode the keys and values of the map.
  Map<K, V>? decodeMapOrNull<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing});

  /// Decodes the data as an iterated collection of nested data.
  IteratedDecoder decodeIterated();

  /// Decodes the data as a collection of key-value pairs.
  /// The pairs are decoded in order of appearance in the encoded data.
  KeyedDecoder decodeKeyed();

  /// Decodes the data as a collection of key-value pairs.
  /// The values are accessed and decoded based on the provided key.
  MappedDecoder decodeMapped();

  /// Whether a [Decodable] implementation should expect to decode their human-readable form.
  ///
  /// Some types have a human-readable form that may be somewhat expensive to construct, as well as a more
  /// compact and efficient form. Generally text-based formats like JSON and YAML will prefer to use the
  /// human-readable one and binary formats like MessagePack will prefer the compact one.
  bool isHumanReadable();

  /// Creates a new [Decoder] that is a copy of this one.
  ///
  /// This is useful when a [Decodable] implementation needs to decode data without consuming the original data.
  /// For example when checking if a key exists or decoding a value conditionally.
  Decoder clone();

  /// Throws an exception with a detailed message.
  Never expect(String expected);
}

/// A type of data that can be decoded by a [Decoder].
///
/// Self-describing formats may return a [DecodingType] from [whatsNext] that indicates the type of the encoded data,
/// or the preferred way of decoding it.
///
/// Non-self-describing formats may only return [DecodingType.unknown] for all types. In this case, the [Decodable]
/// implementation must try the appropriate decoding method based on the expected type.
final class DecodingType<T> {
  const DecodingType._();

  /// Hints that the data is null.
  static const nil = DecodingType<Null>._();

  /// Hints that the data is of type bool.
  static const bool = DecodingType<core.bool>._();

  /// Hints that the data is of type int.
  ///
  /// [Decoder]s that return this type should also allow calling [decodeNum].
  static const int = DecodingType<core.int>._();

  /// Hints that the data is of type double.
  ///
  /// [Decoder]s that return this type should also allow calling [decodeNum].
  static const double = DecodingType<core.double>._();

  /// Hints that the data is of type num.
  ///
  /// [Decoder]s that return this type should also allow calling [decodeInt] and [decodeDouble].
  static const num = DecodingType<core.num>._();

  /// Hints that the data is of type String.
  static const string = DecodingType<core.String>._();

  /// Hints that the data is a list of elements.
  ///
  /// [Decoder]s that return this type should also allow calling [decodeIterated].
  static const list = DecodingType<core.List>._();

  /// Hints that the data is a map of key-value pairs.
  ///
  /// [Decoder]s that return this type should also allow calling [decodeKeyed] and [decodeMapped].
  static const map = DecodingType<core.Map>._();

  /// Hints that the data is an iterated collection of nested data.
  ///
  /// [Decoder]s that return this type should also allow calling [decodeList].
  static const iterated = DecodingType<IteratedDecoder>._();

  /// Hints that the data is an iterated collection of key-value pairs of nested data.
  ///
  /// [Decoder]s that return this type should also allow calling [decodeMap] and [decodeMapped].
  static const keyed = DecodingType<KeyedDecoder>._();

  /// Hints that the data is a direct-access collection of key-value pairs of nested data.
  ///
  /// [Decoder]s that return this type should also allow calling [decodeMap] and [decodeKeyed].
  static const mapped = DecodingType<MappedDecoder>._();

  /// Hints that the data is a custom type [T].
  ///
  /// [Decoder]s that return this type should allow calling [decodeCustom] with [T].
  const DecodingType.custom();

  /// Hints that the type of the data is unknown.
  static const unknown = DecodingType<_Unknown>._();
}

class _Unknown {}

/// A decoder that can decode iterated collections of data.
///
/// A [Decodable] implementation can iterate over the collection and decode each item individually.
/// Before each item, the implementation must call [nextItem] to move to the next (or initial) item.
/// The implementation must either call a decoding method, or call [skipCurrentItem] before calling [nextItem] again.
///
/// A [Decodable] implementation can also skip the remaining items in the collection by calling [skipRemainingItems].
abstract class IteratedDecoder implements Decoder {
  /// Moves to the next item in the collection.
  ///
  /// Returns `true` if there is another item to decode, otherwise `false`.
  bool nextItem();

  /// Skips the current item in the collection.
  ///
  /// This is useful when the [Decodable] implementation is not interested in the current item.
  /// It must be called before calling [nextItem] again if no decoding method is called instead.
  void skipCurrentItem();

  /// Skips the remaining items in the collection.
  ///
  /// This is useful when the [Decodable] implementation is not interested in the remaining items.
  /// It must be called when [nextItem] is not used exhaustively.
  void skipRemainingItems();

  @override
  IteratedDecoder clone();
}

/// A decoder that can decode iterated collections of key-value pairs of data.
///
/// A [Decodable] implementation can iterate over the collection and decode each value individually.
/// Before each value, the implementation must call [nextKey] to get the next (or initial) key.
/// The implementation must either call a decoding method, or call [skipCurrentValue] before calling [nextKey] again.
///
/// A [Decodable] implementation can also skip the remaining key-value pairs in the collection by calling [skipRemainingKeys].
abstract class KeyedDecoder implements Decoder {
  /// Moves to the next key-value pair in the collection and returns the key.
  ///
  /// Returns `null` if there are no more key-value pairs to decode.
  ///
  /// The key can be of type [String] or [int] depending on the format.
  Object /* String | int */ ? nextKey();

  /// Skips the current value in the collection.
  ///
  /// This is useful when the [Decodable] implementation is not interested in the current value.
  /// It must be called before calling [nextKey] again if no decoding method is called instead.
  void skipCurrentValue();

  /// Skips the remaining key-value pairs in the collection.
  ///
  /// This is useful when the [Decodable] implementation is not interested in the remaining key-value pairs.
  /// It must be called when [nextKey] is not used exhaustively.
  void skipRemainingKeys();

  @override
  KeyedDecoder clone();
}

/// A decoder that can decode direct-access collections of key-value pairs of data.
///
/// A [Decodable] implementation can access and decode each value based on the provided key or id.
///
/// Formats may choose to use either the [key] or [id] parameter to access the value, as some formats use
/// [String] keys like JSON and others use [int] ids like Protobuf. The [Decodable] implementation should
/// provide values for both. If no id is provided, formats like Protobuf may not work.
///
/// A [Decodable] implementation can also get all keys of the collection using the [keys] property.
abstract class MappedDecoder {
  /// Returns the actual or preferred [DecodingType] of the encoded data for the given key or id.
  ///
  /// Self-describing formats may return a [DecodingType] that indicates the type of the encoded data,
  /// or the preferred way of decoding it.
  ///
  /// Non-self-describing formats may only return [DecodingType.unknown] for all types. In this case, the [Decodable]
  /// implementation must try the appropriate decoding method based on the expected type.
  DecodingType whatsNext(String key, {int? id});

  /// Decodes the data for the given key or id as a boolean value.
  bool decodeBool(String key, {int? id});

  /// Decodes the data for the given key or id as a nullable boolean value.
  bool? decodeBoolOrNull(String key, {int? id});

  /// Decodes the data for the given key or id as an integer value.
  int decodeInt(String key, {int? id});

  /// Decodes the data for the given key or id as a nullable integer value.
  int? decodeIntOrNull(String key, {int? id});

  /// Decodes the data for the given key or id as a double value.
  double decodeDouble(String key, {int? id});

  /// Decodes the data for the given key or id as a nullable double value.
  double? decodeDoubleOrNull(String key, {int? id});

  /// Decodes the data for the given key or id as a num value.
  num decodeNum(String key, {int? id});

  /// Decodes the data for the given key or id as a nullable num value.
  num? decodeNumOrNull(String key, {int? id});

  /// Decodes the data for the given key or id as a string value.
  String decodeString(String key, {int? id});

  /// Decodes the data for the given key or id as a nullable string value.
  String? decodeStringOrNull(String key, {int? id});

  /// Checks if the data for the given key or id is null.
  bool decodeIsNull(String key, {int? id});

  /// Decodes the data for the given key or id as an object of type [T].
  ///
  /// This forwards the decoding to the provided [Decodable] implementation.
  /// Otherwise tries to decode the data to a supported primitive type [T].
  T decodeObject<T>(String key, {int? id, Decodable<T>? using});

  /// Decodes the data for the given key or id as a nullable object of type [T].
  ///
  /// When the data is not null, this behaves like [decodeObject].
  T? decodeObjectOrNull<T>(String key, {int? id, Decodable<T>? using});

  /// Decodes the data for the given key or id as a list of elements.
  ///
  /// Optionally takes a [Decodable] to decode the elements of the list.
  List<E> decodeList<E>(String key, {int? id, Decodable<E>? using});

  /// Decodes the data for the given key or id as a nullable list of elements.
  ///
  /// Optionally takes a [Decodable] to decode the elements of the list.
  List<E>? decodeListOrNull<E>(String key, {int? id, Decodable<E>? using});

  /// Decodes the data for the given key or id as a map of key-value pairs.
  ///
  /// Optionally takes [Decodable]s to decode the keys and values of the map.
  Map<K, V> decodeMap<K, V>(String key, {int? id, Decodable<K>? keyUsing, Decodable<V>? valueUsing});

  /// Decodes the data for the given key or id as a nullable map of key-value pairs.
  ///
  /// Optionally takes [Decodable]s to decode the keys and values of the map.
  Map<K, V>? decodeMapOrNull<K, V>(String key, {int? id, Decodable<K>? keyUsing, Decodable<V>? valueUsing});

  /// Decodes the data for the given key or id as an iterated collection of nested data.
  IteratedDecoder decodeIterated(String key, {int? id});

  /// Decodes the data for the given key or id as a iterated collection of key-value pairs of nested data.
  KeyedDecoder decodeKeyed(String key, {int? id});

  /// Decodes the data for the given key or id as a direct-access collection of key-value pairs of nested data.
  MappedDecoder decodeMapped(String key, {int? id});

  /// Whether a [Decodable] implementation should expect to decode their human-readable form.
  ///
  /// Some types have a human-readable form that may be somewhat expensive to construct, as well as a more
  /// compact and efficient form. Generally text-based formats like JSON and YAML will prefer to use the
  /// human-readable one and binary formats like MessagePack will prefer the compact one.
  bool isHumanReadable();

  /// Returns the keys (or ids) of the collection.
  Iterable<Object /*String | int */ > get keys;

  /// Throws an exception with a detailed message.
  Never expect(String key, String expect, {int? id});
}
