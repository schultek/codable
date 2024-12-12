import 'package:codable/json.dart';
import 'package:test/test.dart';

import '../../basic/model/person.dart';
import 'model/box.dart';

final boxStringJson = '{"label":"name","data":"John"}';
final boxIntJson = '{"label":"count","data":3}';
final boxPersonJson =
    '{"label":"person","data":{"name":"John","age":30,"height":5.6,"isDeveloper":true,"parent":null,"hobbies":[],"friends":[]}}';

void main() {
  group('generics', () {
    group('basic', () {
      test('decodes a box of dynamic', () {
        // By default, the codable for a generic class is dynamic.
        final Box<dynamic> decoded = Box.codable.fromJson(boxStringJson);
        expect(decoded.label, 'name');
        expect(decoded.data, 'John');
      });

      test('encodes a box of dynamic', () {
        final Box<dynamic> box = Box('name', 'John');
        final String encoded = box.toJson();
        expect(encoded, boxStringJson);
      });

      test('decodes a box of string', () {
        // The codable for a generic class can be explicitly set to a specific type.
        final Box<String> decoded = Box.codable<String>().fromJson(boxStringJson);
        expect(decoded.label, 'name');
        expect(decoded.data, 'John');
      });

      test('encodes a box of string', () {
        final Box<String> box = Box('name', 'John');
        final String encoded = box.toJson();
        expect(encoded, boxStringJson);
      });

      test('decodes a box of int', () {
        // The codable for a generic class can be explicitly set to a specific type.
        final Box<int> decoded = Box.codable<int>().fromJson(boxIntJson);
        expect(decoded.label, 'count');
        expect(decoded.data, 3);
      });

      test('encodes a box of int', () {
        final Box<int> box = Box('count', 3);
        final String encoded = box.toJson();
        expect(encoded, boxIntJson);
      });

      test('decodes a box of person', () {
        // For a non-primitive type, the child codable must be explicitly provided.
        final Box<Person> decoded = Box.codable<Person>(Person.codable).fromJson(boxPersonJson);
        expect(decoded.label, 'person');
        expect(decoded.data, Person('John', 30, 5.6, true, null, [], []));
      });

      test('encodes a box of person', () {
        final Box<Person> box = Box('person', Person('John', 30, 5.6, true, null, [], []));
        // For encoding a non-primitive type, the child codable must be explicitly provided.
        final String encoded = box.use(Person.codable).toJson();
        expect(encoded, boxPersonJson);
      });
    });
  });
}
