import 'interface.dart';

/// A data format that can encode different types of data.
///
/// The role of this interface is to convert the supported types into encoded data.
/// Different implementations of this interface can support different data types and encoding strategies.
///
/// Encoding is performed by an [SelfEncodable] or [Encodable] implementation calling one of the typed 
/// [Encoder].encode...() methods of this interface.
///
/// ```dart
/// /// Example of a [Encodable.encode] implementation:
/// @override
/// void encode(Data value, Encoder encoder) {
///   encoder.encodeString(value.stringProperty);
/// }
/// ```
///
/// A data format may only support a subset of the encoding types. If the [Encoder] is not able to encode the
/// provided data, it should throw an exception with a detailed message.
///
/// An [SelfEncodable] or [Encodable] implementation is expected to call exactly one of the encoding methods a single time.
/// Never more or less.
abstract interface class Encoder {
  /// Encodes a boolean value.
  void encodeBool(bool value);

  /// Encodes a nullable boolean value.
  void encodeBoolOrNull(bool? value);

  /// Encodes an integer value.
  void encodeInt(int value);

  /// Encodes a nullable integer value.
  void encodeIntOrNull(int? value);

  /// Encodes a double value.
  void encodeDouble(double value);

  /// Encodes a nullable double value.
  void encodeDoubleOrNull(double? value);

  /// Encodes a num value.
  void encodeNum(num value);

  /// Encodes a nullable num value.
  void encodeNumOrNull(num? value);

  /// Encodes a string value.
  void encodeString(String value);

  /// Encodes a nullable string value.
  void encodeStringOrNull(String? value);

  /// Encodes 'null'.
  void encodeNull();

  /// Checks if the encoder can encode the custom type [T].
  ///
  /// When this method returns `true`, the [encodeObject] method can be called with the type [T].
  bool canEncodeCustom<T>();

  /// Encodes an object of type [T].
  ///
  /// This tries to encode the object using one of the following ways:
  /// 1. If the [using] parameter is provided, it forwards the encoding to the provided [Encodable] implementation.
  /// 2. If the object is a [SelfEncodable], it calls [SelfEncodable.encode] on the object.
  /// 3. If the object is a supported primitive value, it encodes it as such.
  /// 4. If none of the above applies, an error is thrown.
  /// 
  /// This should only be called if the format returned `true` from [canEncodeCustom]<T> or
  /// is otherwise known to support [T] as a custom type.
  void encodeObject<T>(T value, {Encodable<T>? using});

  /// Encodes a nullable object of type [T].
  ///
  /// When the value is not null, this behaves the same as [encodeObject].
  void encodeObjectOrNull<T>(T? value, {Encodable<T>? using});

  /// Encodes an iterable of [E].
  ///
  /// Optionally takes an [Encodable] function to encode each element.
  void encodeIterable<E>(Iterable<E> value, {Encodable<E>? using});

  /// Encodes a nullable iterable of [E].
  ///
  /// Optionally takes an [Encodable] function to encode each element.
  void encodeIterableOrNull<E>(Iterable<E>? value, {Encodable<E>? using});

  /// Encodes a map of [K] and [V].
  ///
  /// Optionally takes [Encodable] functions to encode each key and value.
  void encodeMap<K, V>(Map<K, V> value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing});

  /// Encodes a nullable map of [K] and [V].
  ///
  /// Optionally takes [Encodable] functions to encode each key and value.
  void encodeMapOrNull<K, V>(Map<K, V>? value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing});

  /// Starts encoding an iterated collection or nested values.
  ///
  /// The returned [IteratedEncoder] should be used to encode the items in the collection.
  /// The [IteratedEncoder.end] method should be called when all items have been encoded.
  IteratedEncoder encodeIterated();

  /// Starts encoding a keyed collection or key-value pairs.
  ///
  /// The returned [KeyedEncoder] should be used to encode the key-value pairs.
  /// The [KeyedEncoder.end] method should be called when all key-value pairs have been encoded.
  KeyedEncoder encodeKeyed();

  /// Whether a [Encodable] implementation should prefer to encode their human-readable form.
  ///
  /// Some types have both a human-readable form that may be somewhat expensive to construct, as well as a more
  /// compact and efficient form. Generally text-based formats like JSON and YAML will prefer to use the
  /// human-readable one and binary formats like MessagePack will prefer the compact one.
  bool isHumanReadable();
}

/// An encoder that supports encoding iterated collections.
///
/// An [SelfEncodable] or [Encodable] implementation can encode each item by repeatedly calling a encoding method.
/// Some data formats may not support encoding different types of items in the same collection.
///
/// The [end] method should be called when all items have been encoded.
abstract interface class IteratedEncoder implements Encoder {
  /// Ends encoding the iterated collection.
  ///
  /// No more items should be encoded after this method has been called.
  void end();
}

/// An encoder that supports encoding key-value pairs.
///
/// An [SelfEncodable] or [Encodable] implementation can encode each key-value pair by repeatedly calling a encoding method.
/// All data formats should support encoding different types of values in the same collection.
///
/// Formats may choose to use either the [key] or [id] parameter for encoding, as some formats use
/// [String] keys like JSON and others use [int] ids like Protobuf. The [Encodable] implementation should
/// provide values for both. If no id is provided, formats like Protobuf may not work.
///
/// The [end] method should be called when all key-value pairs have been encoded.
abstract interface class KeyedEncoder {
  /// Encodes a boolean value for the given key or id.
  void encodeBool(String key, bool value, {int? id});

  /// Encodes a nullable boolean value for the given key or id.
  void encodeBoolOrNull(String key, bool? value, {int? id});

  /// Encodes an integer value for the given key or id.
  void encodeInt(String key, int value, {int? id});

  /// Encodes a nullable integer value for the given key or id.
  void encodeIntOrNull(String key, int? value, {int? id});

  /// Encodes a double value for the given key or id.
  void encodeDouble(String key, double value, {int? id});

  /// Encodes a nullable double value for the given key or id.
  void encodeDoubleOrNull(String key, double? value, {int? id});

  /// Encodes a num value for the given key or id.
  void encodeNum(String key, num value, {int? id});

  /// Encodes a nullable num value for the given key or id.
  void encodeNumOrNull(String key, num? value, {int? id});

  /// Encodes a string value for the given key or id.
  void encodeString(String key, String value, {int? id});

  /// Encodes a nullable string value for the given key or id.
  void encodeStringOrNull(String key, String? value, {int? id});

  /// Encodes 'null' for the given key or id.
  void encodeNull(String key, {int? id});

  /// Checks if the encoder can encode the custom type [T].
  ///
  /// When this method returns `true`, the [encodeObject] method can be called with the type [T].
  bool canEncodeCustom<T>();

  /// Encodes an object of type [T] for the given key or id.
  /// 
  /// This tries to encode the object using one of the following ways:
  /// 1. If the [using] parameter is provided, it forwards the encoding to the provided [Encodable] implementation.
  /// 2. If the object is a [SelfEncodable], it calls [SelfEncodable.encode] on the object.
  /// 3. If the object is a supported primitive value, it encodes it as such.
  /// 4. If none of the above applies, an error is thrown.
  /// 
  /// This should only be called if the format returned `true` from [canEncodeCustom]<T> or
  /// is otherwise known to support [T] as a custom type.
  void encodeObject<T>(String key, T value, {int? id, Encodable<T>? using});

  /// Encodes a nullable object of type [T] for the given key or id.
  ///
  /// When the value is not null, this behaves the same as [encodeObject].
  void encodeObjectOrNull<T>(String key, T? value, {int? id, Encodable<T>? using});

  /// Encodes an iterable of [E] for the given key or id.
  ///
  /// Optionally takes an [Encodable] function to encode each element.
  void encodeIterable<E>(String key, Iterable<E> value, {int? id, Encodable<E>? using});

  /// Encodes a nullable iterable of [E] for the given key or id.
  ///
  /// Optionally takes an [Encodable] function to encode each element.
  void encodeIterableOrNull<E>(String key, Iterable<E>? value, {int? id, Encodable<E>? using});

  /// Encodes a map of [K] and [V] for the given key or id.
  ///
  /// Optionally takes [Encodable] functions to encode each key and value.
  void encodeMap<K, V>(String key, Map<K, V> value, {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing});

  /// Encodes a nullable map of [K] and [V] for the given key or id.
  ///
  /// Optionally takes [Encodable] functions to encode each key and value.
  void encodeMapOrNull<K, V>(String key, Map<K, V>? value, {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing});

  /// Starts encoding an iterated collection or nested values for the given key or id.
  ///
  /// The returned [IteratedEncoder] should be used to encode the items in the collection.
  /// The [IteratedEncoder.end] method should be called when all items have been encoded.
  IteratedEncoder encodeIterated(String key, {int? id});

  /// Starts encoding a keyed collection or key-value pairs for the given key or id.
  ///
  /// The returned [KeyedEncoder] should be used to encode the key-value pairs.
  /// The [KeyedEncoder.end] method should be called when all key-value pairs have been encoded.
  KeyedEncoder encodeKeyed(String key, {int? id});

  /// Whether a [Encodable] implementation should prefer to encode their human-readable form.
  ///
  /// Some types have a human-readable form that may be somewhat expensive to construct, as well as a more
  /// compact and efficient form. Generally text-based formats like JSON and YAML will prefer to use the
  /// human-readable one and binary formats like MessagePack will prefer the compact one.
  bool isHumanReadable();

  /// Ends encoding the keyed collection.
  ///
  /// No more key-value pairs should be encoded after this method has been called.
  void end();
}
