import 'package:codable_dart/core.dart';

/// The format to encode and decode a [DateTime].
enum DateTimeFormat {
  auto,
  iso8601,
  unixMilliseconds,
}

/// A [DateTime] codable that can encode and decode a date in different formats.
class DateTimeCodable implements Codable<DateTime> {
  const DateTimeCodable({
    this.preferredFormat = DateTimeFormat.auto,
    this.convertUtc = false,
  });

  /// The preferred format to encode and decode the date.
  /// If [DateTimeFormat.auto] is used, the format will be determined based on the decoder / encoder.
  /// If [DateTimeFormat.iso8601] is used, the date will be encoded as an ISO8601 string.
  /// If [DateTimeFormat.unixMilliseconds] is used, the date will be encoded as a unix milliseconds integer.
  ///
  /// If the format supports custom de/encoding of [DateTime], this is ignored.
  final DateTimeFormat preferredFormat;

  /// Whether to convert the date
  /// - from local to UTC before encoding.
  /// - from UTC to local after decoding.
  final bool convertUtc;

  @override
  DateTime decode(Decoder decoder) {
    final decodingType = decoder.whatsNext();

    final value = switch (decodingType) {
      DecodingType<DateTime>() => decoder.decodeObject<DateTime>(),
      _ => switch (preferredFormat) {
          DateTimeFormat.auto => switch (decoder.whatsNext()) {
              DecodingType.string => DateTime.parse(decoder.decodeString()),
              DecodingType.int || DecodingType.num => DateTime.fromMillisecondsSinceEpoch(decoder.decodeInt()),
              DecodingType.unknown when decoder.isHumanReadable() => DateTime.parse(decoder.decodeString()),
              DecodingType.unknown => DateTime.fromMillisecondsSinceEpoch(decoder.decodeInt()),
              _ => decoder.expect('string, int or custom date'),
            },
          DateTimeFormat.iso8601 => DateTime.parse(decoder.decodeString()),
          DateTimeFormat.unixMilliseconds => DateTime.fromMillisecondsSinceEpoch(decoder.decodeInt()),
        }
    };
    if (convertUtc) {
      return value.toLocal();
    }
    return value;
  }

  @override
  void encode(DateTime value, Encoder encoder) {
    if (convertUtc) {
      value = value.toUtc();
    }
    if (encoder.canEncodeCustom<DateTime>()) {
      encoder.encodeObject<DateTime>(value);
    } else {
      switch (preferredFormat) {
        case DateTimeFormat.auto:
          if (encoder.isHumanReadable()) {
            encoder.encodeString(value.toIso8601String());
          } else {
            encoder.encodeInt(value.millisecondsSinceEpoch);
          }
        case DateTimeFormat.iso8601:
          encoder.encodeString(value.toIso8601String());

        case DateTimeFormat.unixMilliseconds:
          encoder.encodeInt(value.millisecondsSinceEpoch);
      }
    }
  }
}
