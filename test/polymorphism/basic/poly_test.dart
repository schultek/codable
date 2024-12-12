import 'package:codable/standard.dart';
import 'package:test/test.dart';

import 'model/pet.dart';

final dogMap = {'name': 'Jasper', 'breed': 'Australian Shepherd', 'type': 'dog'};
final catMap = {'name': 'Whiskers', 'lives': 5, 'type': 'cat'};
final birdMap = {'color': 'red', 'type': 'bird'};

void main() {
  group('polymorphism', () {
    test('decodes explicit subtype', () {
      Dog dog = Dog.codable.fromMap(dogMap);
      expect(dog.name, 'Jasper');
    });

    test('encodes explicit subtype', () {
      Dog dog = Dog(name: 'Jasper', breed: 'Australian Shepherd');
      Map<String, dynamic> map = dog.toMap();
      expect(map, dogMap);
    });

    test('decodes discriminated subtype', () {
      Pet pet = Pet.codable.fromMap(dogMap);
      expect(pet, isA<Dog>());
      expect((pet as Dog).name, "Jasper");
    });

    test('encodes base type', () {
      Pet pet = Dog(name: 'Jasper', breed: 'Australian Shepherd');
      Map<String, dynamic> map = pet.toMap();
      expect(map, dogMap);
    });

    test('decodes default on unknown key', () {
      Pet pet = Pet.codable.fromMap(birdMap);
      expect(pet.runtimeType, Pet);
      expect(pet.type, 'bird');
    });
  });
}
