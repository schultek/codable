import 'package:codable_dart/core.dart';

class Box<T> implements SelfEncodable {
  Box(this.label, this.data);

  final String label;
  final T data;

  static Codable<Box<T>> codable<T>([Codable<T>? codable]) => BoxCodable(codable);

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

class BoxCodable<T> extends Codable<Box<T>> {
  const BoxCodable([Codable<T>? codableT])
      : encodableT = codableT,
        decodableT = codableT;

  const BoxCodable.of({this.encodableT, this.decodableT});

  final Encodable<T>? encodableT;
  final Decodable<T>? decodableT;

  @override
  void encode(Box<T> value, Encoder encoder) {
    value.encode(encoder, encodableT);
  }

  @override
  Box<T> decode(Decoder decoder) {
    // For simplicity, we don't check the decoder.whatsNext() here. Don't do this for real implementations.
    final mapped = decoder.decodeMapped();
    return Box(
      mapped.decodeString('label'),
      mapped.decodeObject('data', using: decodableT),
    );
  }
}