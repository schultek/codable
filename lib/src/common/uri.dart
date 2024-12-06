import 'package:codable/core.dart';

/// A [Uri] codable that can encode and decode an uri as a string.
class UriCodable implements Codable<Uri> {
  const UriCodable();

  @override
  Uri decode(Decoder decoder) {
    return switch (decoder.whatsNext()) {
      DecodingType.string || DecodingType.unknown => Uri.parse(decoder.decodeString()),
      DecodingType<Uri>() => decoder.decodeCustom<Uri>(),
      _ => decoder.expect('string or custom uri'),
    };
  }

  @override
  void encode(Uri value, Encoder encoder) {
    if (encoder.canEncodeCustom<Uri>()) {
      encoder.encodeCustom<Uri>(value);
    } else {
      encoder.encodeString(value.toString());
    }
  }
}