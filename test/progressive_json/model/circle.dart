import 'package:codable_dart/core.dart';
import 'package:codable_dart/src/extended/reference.dart';

class Circle implements SelfEncodable {
  Circle(this.radius, Reference<Circle> center) {
    center.get((v) => this.center = v);
  }

  final int radius;
  late final Circle center;

  @override
  void encode(Encoder encoder) {
    encoder.encodeKeyed()
      ..encodeInt('radius', radius)
      ..encodeReference('center', center)
      ..end();
  }
}

class CircleCodable extends SelfCodable<Circle> {
  const CircleCodable();

  @override
  Circle decode(Decoder decoder) {
    return switch (decoder.whatsNext()) {
      // If the format prefers mapped decoding, use mapped decoding.
      DecodingType.mapped || DecodingType.map => decodeMapped(decoder.decodeMapped()),
      // If the format prefers keyed decoding or is non-self describing, use keyed decoding.
      DecodingType.keyed || DecodingType.unknown => decodeKeyed(decoder.decodeKeyed()),
      _ => decoder.expect('mapped or keyed'),
    };
  }

  Circle decodeKeyed(KeyedDecoder keyed) {
    late int radius;
    late Reference<Circle> center;

    for (Object? key; (key = keyed.nextKey()) != null;) {
      switch (key) {
        case 'radius':
          radius = keyed.decodeInt();
        case 'center':
          center = keyed.decodeReference(using: this);
        default:
          keyed.skipCurrentValue();
      }
    }

    return Circle(radius, center);
  }

  Circle decodeMapped(MappedDecoder mapped) {
    return Circle(
      mapped.decodeInt('radius'),
      mapped.decodeReference('center', using: this),
    );
  }
}
