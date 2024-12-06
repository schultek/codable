import 'package:codable/core.dart';
import 'package:codable/extended.dart';

class Box<T> implements SelfEncodable1<T> {
  Box(this.label, this.data);

  final String label;
  final T data;

  static const Codable1<Box, dynamic> codable = BoxCodable();

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    final keyed = encoder.encodeKeyed();
    keyed.encodeString('label', label);
    if (encodableT != null) {
      // Use the encodableT to encode the value of type T.
      keyed.encodeObject('data', data, using: encodableT);
    } else if (data case SelfEncodable data) {
      // If data is self-encodable, simply use Encodable.self().
      keyed.encodeObject('data', data, using: Encodable.self());
    } else {
      // If no explicit encodableT is provided, we assume the data is a primitive type.
      keyed.encodeDynamic('data', data);
    }
    keyed.end();
  }
}

class BoxCodable<T> extends SelfCodable1<Box<T>, T> {
  const BoxCodable();

  @override
  Box<T> decode(Decoder decoder, [Decodable<T>? decodableA]) {
    // For simplicity, we don't check the decoder.whatsNext() here.
    final mapped = decoder.decodeMapped();
    return Box(
      mapped.decodeString('label'),
      decodableA == null // If no decodable is provided, we assume the data is a primitive type.
          ? mapped.decodeDynamic('data') as T
          : mapped.decodeObject('data', using: decodableA),
    );
  }
}

extension BoxCodableExtension on Codable1<Box, dynamic> {
  // This is a convenience method for creating a BoxCodable with an explicit child codable.
  Codable<Box<$A>> call<$A>([Codable<$A>? codableA]) => BoxCodable<$A>().use(codableA);
}
