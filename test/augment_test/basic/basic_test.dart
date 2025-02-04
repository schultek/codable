import 'package:codable/json.dart';
import 'package:codable/src/formats/msgpack.dart';
import 'package:codable/standard.dart';
import 'package:test/test.dart';

import 'model/person.dart';
import 'test_data.dart';

void main() {
  group("basic model", () {
    // Person to compare against.
    final expectedPerson = PersonRaw.fromMapRaw(personTestData);

    test("decodes from map", () {
      // Uses the fromMap extension on Decodable to decode the map.
      Person p = Person.codable.fromMap(personTestData);
      expect(p, equals(expectedPerson));
    });

    test("encodes to map", () {
      // Uses the toMap extension on SelfEncodable to encode the map.
      final Map<String, dynamic> encoded = expectedPerson.toMap();
      expect(encoded, equals(personTestData));
    });

    test("decodes from json", () {
      // Uses the fromJson extension on Decodable to decode the json string.
      Person p = Person.codable.fromJson(personTestJson);
      expect(p, equals(expectedPerson));
    });

    test("encodes to json", () {
      // Uses the toJson extension on SelfEncodable to encode the json string.
      final String encoded = expectedPerson.toJson();
      expect(encoded, equals(personTestJson));
    });

    test("decodes from json bytes", () {
      // Uses the fromJsonBytes extension on Decodable to decode the json bytes.
      Person p = Person.codable.fromJsonBytes(personTestJsonBytes);
      expect(p, equals(expectedPerson));
    });

    test("encodes to json bytes", () {
      // Uses the toJsonBytes extension on SelfEncodable to encode the json bytes.
      final List<int> encoded = expectedPerson.toJsonBytes();
      expect(encoded, equals(personTestJsonBytes));
    });

    test('decodes from msgpack bytes', () {
      // Uses the fromMsgPackBytes extension on Decodable to decode the msgpack bytes.
      Person p = Person.codable.fromMsgPack(personTestMsgpackBytes);
      expect(p, equals(expectedPerson));
    });

    test('encodes to msgpack bytes', () {
      // Uses the toMsgPackBytes extension on SelfEncodable to encode the msgpack bytes.
      final List<int> encoded = expectedPerson.toMsgPack();
      expect(encoded, equals(personTestMsgpackBytes));
    });
  });
}
