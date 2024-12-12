import 'package:codable/core.dart';
import 'package:codable/extended.dart';

class Box<T> implements SelfEncodable {
  Box(this.label, this.data);

  final String label;
  final T data;

  static const Codable1<Box, dynamic> codable = BoxCodable();

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    encoder.encodeKeyed()
      ..encodeString('label', label)
      ..encodeObject('data', data, using: encodableT)
      ..end();
  }
}

extension BoxEncodableExtension<T> on Box<T> {
  SelfEncodable use([Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, encodableT));
  }
}

class BoxCodable<T> extends Codable1<Box<T>, T> {
  const BoxCodable();

  @override
  void encode(Box<T> value, Encoder encoder, [Encodable<T>? encodableA]) {
    value.encode(encoder, encodableA);
  }

  @override
  Box<T> decode(Decoder decoder, [Decodable<T>? decodableT]) {
    // For simplicity, we don't check the decoder.whatsNext() here. Don't do this for real implementations.
    final mapped = decoder.decodeMapped();
    return Box(
      mapped.decodeString('label'),
      mapped.decodeObject('data', using: decodableT),
    );
  }
}

extension BoxCodableExtension on Codable1<Box, dynamic> {
  // This is a convenience method for creating a BoxCodable with an explicit child codable.
  Codable<Box<$A>> call<$A>([Codable<$A>? codableA]) => BoxCodable<$A>().use(codableA);
}
