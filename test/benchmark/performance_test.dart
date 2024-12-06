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

  group('benchmark', () {
    compare(
      'MAP DECODING',
      self: () => p = Person.codable.fromMap(personBenchData),
      other: () => p = PersonRaw.fromMapRaw(personBenchData),
    );
    compare(
      'JSON STRING DECODING',
      self: () => p = Person.codable.fromJson(personBenchJson),
      other: () => p = PersonRaw.fromJsonRaw(personBenchJson),
    );
    compare(
      'JSON BYTE DECODING',
      self: () => p = Person.codable.fromJsonBytes(personBenchJsonBytes),
      other: () => p = PersonRaw.fromJsonBytesRaw(personBenchJsonBytes),
    );

    print('');

    compare(
      'MAP ENCODING',
      self: () => p.toMap(),
      other: () => p.toMapRaw(),
    );
    compare(
      'JSON STRING ENCODING',
      self: () => p.toJson(),
      other: () => p.toJsonRaw(),
    );
    compare(
      'JSON BYTE ENCODING',
      self: () => p.toJsonBytes(),
      other: () => p.toJsonBytesRaw(),
    );
  });
}
