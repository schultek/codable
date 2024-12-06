import 'package:codable/core.dart';
import 'package:codable/extended.dart';

class Animal implements SelfEncodable {
  Animal({required this.type});

  static const Codable<Animal> codable = AnimalCodable();

  final String type;

  @override
  void encode(Encoder encoder) {
    encoder.encodeKeyed()
      ..encodeString('type', type)
      ..end();
  }
}

class Cat extends Animal {
  Cat({required this.name, this.lives = 7}) : super(type: 'cat');

  static const Codable<Cat> codable = CatCodable();

  final String name;
  final int lives;

  @override
  void encode(Encoder encoder) {
    encoder.encodeKeyed()
      ..encodeString('type', type)
      ..encodeString('name', name)
      ..encodeInt('lives', lives)
      ..end();
  }
}

class Dog extends Animal {
  Dog({required this.name, required this.breed}) : super(type: 'dog');

  static const Codable<Dog> codable = DogCodable();

  final String name;
  final String breed;

  @override
  Object? encode(Encoder encoder) {
    return encoder.encodeKeyed()
      ..encodeString('type', type)
      ..encodeString('name', name)
      ..encodeString('breed', breed)
      ..end();
  }
}

// Animal

class AnimalCodable extends SelfCodable<Animal> with SuperDecodable<Animal> {
  const AnimalCodable();

  @override
  String get discriminatorKey => 'type';

  @override
  List<Discriminator<Animal>> get discriminators => [
        Discriminator<Cat>('cat', CatCodable.new),
        Discriminator<Dog>('dog', DogCodable.new),
      ];

  @override
  Animal decodeFallback(Decoder decoder) {
    return Animal(type: decoder.decodeMapped().decodeString('type'));
  }
}

class CatCodable extends SelfCodable<Cat> {
  const CatCodable();

  @override
  Cat decode(Decoder decoder) {
    final keyed = decoder.decodeMapped();
    return Cat(
      name: keyed.decodeString('name'),
      lives: keyed.decodeInt('lives'),
    );
  }
}

class DogCodable extends SelfCodable<Dog> {
  const DogCodable();

  @override
  Dog decode(Decoder decoder) {
    final keyed = decoder.decodeMapped();
    return Dog(
      name: keyed.decodeString('name'),
      breed: keyed.decodeString('breed'),
    );
  }
}
