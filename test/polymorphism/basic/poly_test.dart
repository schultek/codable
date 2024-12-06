import 'package:codable/standard.dart';
import 'package:test/test.dart';

import 'model/animal.dart';

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
      Animal animal = Animal.codable.fromMap(dogMap);
      expect(animal, isA<Dog>());
      expect((animal as Dog).name, "Jasper");
    });

    test('decodes default on unknown key', () {
      Animal animal = Animal.codable.fromMap(birdMap);
      expect(animal.runtimeType, Animal);
      expect(animal.type, 'bird');
    });
  });
}
