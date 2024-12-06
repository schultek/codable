import 'package:codable/core.dart';
import 'package:codable/extended.dart';
import 'package:codable/standard.dart';
import 'package:test/test.dart';

class Data {
  const Data(this.value);
  final Object? value;
}

void main() {
  group('error handling', () {
    test('throws unexpected type error on wrong token', () {
      expect(
        () => DecodableUtils.fromHandler<Uri>(decode: (decoder) {
          return Uri.parse(decoder.decodeString());
        }).fromMap({}),
        throwsA(isA<CodableException>().having(
          (e) => e.message,
          'message',
          'Failed to decode Uri: Unexpected type: Expected String but got _Map<String, dynamic>.',
        )),
      );
    });

    test('throws unexpected type error on expect call', () {
      expect(
        () => DecodableUtils.fromHandler<DateTime>(decode: (decoder) {
          return decoder.expect('String or int');
        }).fromMap({}),
        throwsA(isA<CodableException>().having(
          (e) => e.message,
          'message',
          'Failed to decode DateTime: Unexpected type: Expected String or int but got _Map<String, dynamic>.',
        )),
      );
    });

    test('throws wrapped exception with decoding path', () {
      expect(
        () => DecodableUtils.fromHandler<Data>(decode: (decoder) {
          return Data(decoder.decodeMapped().decodeObject<Uri>(
            'value',
            using: DecodableUtils.fromHandler(decode: (decoder) {
              return Uri.parse(decoder.decodeMapped().decodeString('path'));
            }),
          ));
        }).fromMap({
          'value': {'path': 42}
        }),
        throwsA(isA<CodableException>().having(
          (e) => e.message,
          'message',
          'Failed to decode Data->["value"]->Uri->["path"]: Unexpected type: Expected String but got int.',
        )),
      );

      expect(
        () => DecodableUtils.fromHandler<Data>(decode: (decoder) {
          return Data(decoder.decodeMapped().decodeList<Uri>(
            'values',
            using: DecodableUtils.fromHandler(decode: (decoder) {
              return Uri.parse(decoder.decodeMapped().decodeString('path'));
            }),
          ));
        }).fromMap({
          'values': [
            {'path': 42}
          ]
        }),
        throwsA(isA<CodableException>().having(
          (e) => e.message,
          'message',
          'Failed to decode Data->["values"]->[0]->Uri->["path"]: Unexpected type: Expected String but got int.',
        )),
      );
    });
  });
}
