import 'dart:convert';

import 'package:codable/json.dart';
import 'package:codable/standard.dart';
import 'package:test/test.dart';

import '../basic/model/person.dart';
import '../basic/test_data.dart';
import 'bench.dart';

final personDeepData = {
  ...personTestData,
  'parent': personTestData,
  'friends': List.filled(100, personTestData),
};
final personBenchData = {
  ...personDeepData,
  'friends': List.filled(500, personDeepData),
};
final personBenchJson = jsonEncode(personBenchData);
final personBenchJsonBytes = utf8.encode(personBenchJson);

void main() {
  Person p = PersonRaw.fromMapRaw(personBenchData);

  group('benchmark', tags: 'benchmark', () {
   compare(
      'STANDARD DECODING (Map -> Person)',
      self: () => p = Person.codable.fromMap(personBenchData),
      other: () => p = PersonRaw.fromMapRaw(personBenchData),
    );
    compare(
      'STANDARD ENCODING (Person -> Map)',
      self: () => p.toMap(),
      other: () => p.toMapRaw(),
    );

    print('');

    compare(
      'JSON STRING DECODING (String -> Person)',
      self: () => p = Person.codable.fromJson(personBenchJson),
      other: () => p = PersonRaw.fromJsonRaw(personBenchJson),
    );
    compare(
      'JSON STRING ENCODING (Person -> String)',
      self: () => p.toJson(),
      other: () => p.toJsonRaw(),
    );

    print('');

    compare(
      'JSON BYTE DECODING (List<int> -> Person)',
      self: () => p = Person.codable.fromJsonBytes(personBenchJsonBytes),
      other: () => p = PersonRaw.fromJsonBytesRaw(personBenchJsonBytes),
    );
    compare(
      'JSON BYTE ENCODING (Person -> List<int>)',
      self: () => p.toJsonBytes(),
      other: () => p.toJsonBytesRaw(),
    );

  });
}
