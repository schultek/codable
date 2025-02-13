import 'dart:convert';

import 'package:codable/common.dart';
import 'package:codable/csv.dart';
import 'package:codable/json.dart';
import 'package:codable/standard.dart';
import 'package:test/test.dart';

import 'model/measures.dart';
import 'test_data.dart';

void main() {
  group('csv', () {
    // Since CSV always deals with rows of data, the fromCsv and toCsv methods deal directly
    // with Lists of objects instead of single objects.

    test('decodes', () {
      // Use the fromCsv extension method to decode the data.
      List<Measures> measures = Measures.codable.fromCsv(measuresCsv);
      expect(measures, equals(measuresObjects));
    });

    test('encodes', () {
      // Use the toCsv extension method to encode the data.
      final encoded = measuresObjects.toCsv();
      expect(encoded, equals(measuresCsv));
    });

    // This shows how to easily switch between data formats given the same model implementation.
    test('interop with json', () {
      // Use the fromCsv extension method to decode the data from csv.
      List<Measures> measures = Measures.codable.fromCsv(measuresCsv);
      // Use the encode.toJson extension method to encode the data to json.
      final json = measures.encode.toJson();

      expect(json, equals(measuresJson));

      // Use the fromJson extension method to decode the data from json.
      List<Measures> measures2 = Measures.codable.list().fromJson(json);
      // Use the toCsv extension method to encode the data to csv.
      final csv = measures2.toCsv();

      expect(csv, equals(measuresCsv));
    });

    group('codec', () {
      test('decodes string', () {
        // Use the fromCsv extension method to decode the data.
        List<Measures> measures = Measures.codable.list().codec.fuse(csv).decode(measuresCsv);
        expect(measures, equals(measuresObjects));
      });

      test('encodes string', () {
        // Use the toCsv extension method to encode the data.
        final encoded = Measures.codable.list().codec.fuse(csv).encode(measuresObjects);
        expect(encoded, equals(measuresCsv));
      });

      test('special cases fusing with utf8', () {
        expect(Measures.codable.list().codec.fuse(csv).fuse(utf8).runtimeType.toString(),
            contains('_CodableCodec<List<Measures>, List<int>>'));
      });

      test('decodes bytes fused', () {
        // Use the csvCodec extension fused with the utf8 codec to decode bytes.
        List<Measures> measures = Measures.codable.list().codec.fuse(csv).fuse(utf8).decode(measuresCsvBytes);
        expect(measures, equals(measuresObjects));
      });

      test('encodes bytes fused', () {
        // Use the csvCodec extension fused with the utf8 codec to encode bytes.
        final encoded = Measures.codable.list().codec.fuse(csv).fuse(utf8).encode(measuresObjects);
        expect(encoded, equals(measuresCsvBytes));
      });
    });
  });
}
