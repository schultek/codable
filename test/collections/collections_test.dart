import 'package:codable_dart/common.dart';
import 'package:codable_dart/core.dart';
import 'package:codable_dart/json.dart';
import 'package:test/test.dart';

import '../basic/model/person.dart';
import '../basic/test_data.dart';

void main() {
  group("collections", () {
    final List<Person> personList = [
      for (int i = 0; i < 10; i++) PersonRaw.fromMapRaw({...personTestData, 'name': 'Person $i'}),
    ];
    final String personListJson = '[${personList.map((p) => p.toJsonRaw()).join(',')}]';

    test("decodes as list", () {
      // Get the codable for a list of persons.
      final Codable<List<Person>> codable = Person.codable.list();
      // Use the fromJson extension method to decode the list.
      List<Person> list = codable.fromJson(personListJson);
      expect(list, equals(personList));
    });

    test("encodes to list", () {
      // Use the encode.toJson extension method to encode the list.
      final encoded = personList.encode.toJson();
      expect(encoded, equals(personListJson));
    });

    final Set<Person> personSet = personList.toSet();

    test("decodes as set", () {
      // Get the codable for a set of persons.
      final Codable<Set<Person>> codable = Person.codable.set();
      // Use the fromJson extension method to decode the set.
      Set<Person> set = codable.fromJson(personListJson);
      expect(set, equals(personSet));
    });

    test("encodes to set", () {
      // Use the encode.toJson extension method to encode the set.
      final encoded = personSet.encode.toJson();
      expect(encoded, equals(personListJson));
    });

    final Map<String, Person> personMap = {
      for (final p in personList) p.name: p,
    };
    final String personMapJson = '{${personMap.entries.map((e) {
      return '"${e.key}":${e.value.toJsonRaw()}';
    }).join(',')}}';

    test("decodes as map", () {
      // Get the codable for a map of strings to persons.
      final Codable<Map<String, Person>> codable = Person.codable.map<String>();
      // Use the fromJson extension method to decode the map.
      Map<String, Person> map = codable.fromJson(personMapJson);
      expect(map, equals(personMap));
    });

    test("encodes to map", () {
      // Use the encode.toJson extension method to encode the map.
      final encoded = personMap.encode.toJson();
      expect(encoded, equals(personMapJson));
    });

    final Map<Uri, Person> personUriMap = {
      for (final p in personList) Uri.parse('example.com/person/${p.name}'): p,
    };
    final String personUriMapJson = '{${personUriMap.entries.map((e) {
      return '"${e.key}":${e.value.toJsonRaw()}';
    }).join(',')}}';

    test("decodes as uri map", () {
      // Construct the codable for a map of uris to persons.
      // Provide the explicit codable for the key type.
      final Codable<Map<Uri, Person>> codable = Person.codable.map<Uri>(UriCodable());
      // Use the fromJson method to decode the map.
      Map<Uri, Person> map = codable.fromJson(personUriMapJson);
      expect(map, equals(personUriMap));
    });

    test("encodes to uri map", () {
      // Construct the codable for a map of uris to persons.
      // Provide the explicit codable for the key type.
      final Codable<Map<Uri, Person>> codable = Person.codable.map<Uri>(UriCodable());
      // Use the toJson method to encode the map.
      final encoded = codable.toJson(personUriMap);
      expect(encoded, equals(personUriMapJson));
    });
  });
}
