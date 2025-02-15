/* 
//!USING `augment` causes analyzer to produce weird errors:

The argument type 'Encodable<T>?' can't be assigned to the parameter type 'Encodable<T>?'. dartargument_type_not_assignable
interface.dart(89, 26): Encodable is defined in C:\src\codable_workspace\packages\codable\lib\src\core\interface.dart
interface.dart(89, 26): Encodable is defined in C:\src\codable_workspace\packages\codable\lib\src\core\interface.dart
[Encodable<T>? encodableT]
Type: Encodable<T>?

*/
//! Augmentation version produces strange `The argument type 'Encodable<T>?' can't be assigned to the parameter type 'Encodable<T>?'.`
//!  errors.

class Box<T> {
  Box(this.label, this.data);

  final String label;
  final T data;
}

augment class Box<T> implements SelfEncodable {
  static const Codable1<Box, dynamic> codable = BoxCodable();

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
  }
}

/*
//! THIS VERSION without augmentation produces NO ERROR:
class Box<T> implements SelfEncodable {
  Box(this.label, this.data);

  final String label;
  final T data;

  static const Codable1<Box, dynamic> codable = BoxCodable();

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
  }
}
//! END VERSION without augmentation produces NO ERROR:
*/


extension BoxEncodableExtension<T> on Box<T> {
  SelfEncodable use([Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, encodableT));     //! <<The argument type 'Encodable<T>?' can't be assigned to the parameter type 'Encodable<T>?'.
  }
}

class BoxCodable<T> extends Codable1<Box<T>, T> {
  const BoxCodable();

  @override
  void encode(Box<T> value, Encoder encoder, [Encodable<T>? encodableA]) {
    value.encode(encoder, encodableA);   //! <<The argument type 'Encodable<T>?' can't be assigned to the parameter type 'Encodable<T>?'.
  }

  @override
  external Box<T> decode(Decoder decoder, [Decodable<T>? decodableT]);
}




// SUPPORTING CLASSES 


abstract interface class Decodable<T> {
  /// Decodes a value of type [T] using the [decoder].
  ///
  /// The implementation should first use [Decoder.whatsNext] to determine the type of the encoded data.
  /// Then it should use one of the [Decoder]s `.decode...()` methods to decode into its target type.
  /// If the returned [DecodingType] is not supported, the implementation can use [Decoder.expect] to throw a detailed error.
  T decode(Decoder decoder);

  /// Creates a [Decodable] from a handler function.
  factory Decodable.fromHandler(T Function(Decoder decoder) decode) => _DecodableFromHandler(decode);
}
abstract interface class Decoder {
}

/// Variant of [Decodable] that decodes a generic value of type [T] with one type parameter [A].
abstract interface class Decodable1<T, A> implements Decodable<T> {
  /// Decodes a value of type [T] using the [decoder].
  ///
  /// The implementation should first use [Decoder.whatsNext] to determine the type of the encoded data.
  /// Then it should use one of the typed [Decoder].decode...() methods to decode into its target type.
  /// If the returned [DecodingType] is not supported, the implementation can use [Decoder.expect] to throw a detailed error.
  ///
  /// The [decodableA] parameter should be used to decode nested values of type [A]. When it is `null` the
  /// implementation may choose to throw an error or use a fallback way of decoding values of type [A].
  @override
  T decode(Decoder decoder, [Decodable<A>? decodableA]);
}


abstract interface class Encodable1<T, A> implements Encodable<T> {
  @override
  void encode(T value, Encoder encoder, [Encodable<A>? encodableA]);
}


abstract class Codable<T> implements Encodable<T>, Decodable<T> {
  const Codable();

  /// Creates a [Codable] from a pair of handler functions.
  factory Codable.fromHandlers({
    required T Function(Decoder decoder) decode,
    required void Function(T value, Encoder encoder) encode,
  }) =>
      _CodableFromHandlers(decode, encode);
}

/// Variant of [Codable] that can encode and decode a generic value of type [T] with one type parameter [A].
abstract class Codable1<T, A> implements Codable<T>, Decodable1<T, A>, Encodable1<T, A> {
  const Codable1();
}

final class _DecodableFromHandler<T> implements Decodable<T> {
  const _DecodableFromHandler(this._decode);

  final T Function(Decoder decoder) _decode;

  @override
  T decode(Decoder decoder) => _decode(decoder);
}

final class _EncodableFromHandler<T> implements Encodable<T> {
  const _EncodableFromHandler(this._encode);

  final void Function(T value, Encoder encoder) _encode;

  @override
  void encode(T value, Encoder encoder) => _encode(value, encoder);
}

final class _CodableFromHandlers<T> implements Codable<T> {
  const _CodableFromHandlers(this._decode, this._encode);

  final T Function(Decoder decoder) _decode;
  final void Function(T value, Encoder encoder) _encode;

  @override
  T decode(Decoder decoder) => _decode(decoder);
  @override
  void encode(T value, Encoder encoder) => _encode(value, encoder);
}

abstract interface class Encodable<T> {
  /// Encodes the [value] using the [encoder].
  ///
  /// The implementation must use one of the typed [Encoder]s `.encode...()` methods to encode the value.
  /// It is expected to call exactly one of the encoding methods a single time. Never more or less.
  void encode(T value, Encoder encoder);

  /// Creates an [Encodable] from a handler function.
  factory Encodable.fromHandler(void Function(T value, Encoder encoder) encode) => _EncodableFromHandler(encode);
}

abstract interface class Encoder {
}

final class _SelfEncodableFromHandler implements SelfEncodable {
  const _SelfEncodableFromHandler(this._encode);

  final void Function(Encoder encoder) _encode;

  @override
  void encode(Encoder encoder) => _encode(encoder);
}

abstract interface class SelfEncodable {
  /// Encodes itself using the [encoder].
  ///
  /// The implementation should use one of the typed [Encoder]s `.encode...()` methods to encode the value.
  /// It is expected to call exactly one of the encoding methods a single time. Never more or less.
  void encode(Encoder encoder);

  /// Creates a [SelfEncodable] from a handler function.
  factory SelfEncodable.fromHandler(void Function(Encoder encoder) encode) => _SelfEncodableFromHandler(encode);
}


