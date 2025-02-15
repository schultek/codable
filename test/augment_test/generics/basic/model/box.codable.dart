part of 'box.dart';

//CAUSES_ANALYZER_CRASH?//augment class Box<T> implements SelfEncodable {
//CAUSES_ANALYZER_CRASH?//  Box(this.label, this.data);
//CAUSES_ANALYZER_CRASH?//
//CAUSES_ANALYZER_CRASH?//  static const Codable1<Box, dynamic> codable = BoxCodable();
//CAUSES_ANALYZER_CRASH?//
//CAUSES_ANALYZER_CRASH?//  @override
//CAUSES_ANALYZER_CRASH?//  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
//CAUSES_ANALYZER_CRASH?//    encoder.encodeKeyed()
//CAUSES_ANALYZER_CRASH?//      ..encodeString('label', label)
//CAUSES_ANALYZER_CRASH?//      ..encodeObject('data', data, using: encodableT)
//CAUSES_ANALYZER_CRASH?//      ..end();
//CAUSES_ANALYZER_CRASH?//  }
//CAUSES_ANALYZER_CRASH?//}

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
