import 'package:codable/standard.dart';
import 'package:test/test.dart';

import 'model/color.dart';

void main() {
  group('enums', () {
    test('decode from string', () {
      final Color decoded = Color.codable.fromValue('green');
      expect(decoded, Color.green);
    });

    test('encode to string', () {
      final Object? encoded = Color.green.toValue();
      expect(encoded, isA<String>());
      expect(encoded, 'green');
    });

    test('decode from null', () {
      final Color decoded = Color.codable.fromValue(null);
      expect(decoded, Color.none);
    });

    test('encode to null', () {
      final Object? encoded = Color.none.toValue();
      expect(encoded, isNull);
    });

    test('decode from int', () {
      final Color decoded = StandardDecoder.decode(1, Color.codable, isHumanReadable: false);
      expect(decoded, Color.blue);
    });

    test('encode to int', () {
      final Object? encoded = StandardEncoder.encode(Color.blue, Color.codable, isHumanReadable: false);
      expect(encoded, isA<int>());
      expect(encoded, 1);
    });
  });
}
