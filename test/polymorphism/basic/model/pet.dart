import 'package:codable/core.dart';
import 'package:codable/extended.dart';

class Pet implements SelfEncodable {
  Pet({required this.type});

  static const Codable<Pet> codable = PetCodable();

  final String type;

  @override
  void encode(Encoder encoder) {
    encoder.encodeKeyed()
      ..encodeString('type', type)
      ..end();
  }
}

class Cat extends Pet {
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

class Dog extends Pet {
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

// Pet

class PetCodable extends SelfCodable<Pet> with SuperDecodable<Pet> {
  const PetCodable();

  @override
  String get discriminatorKey => 'type';

  @override
  List<Discriminator<Pet>> get discriminators => [
        Discriminator<Cat>('cat', CatCodable.new),
        Discriminator<Dog>('dog', DogCodable.new),
      ];

  @override
  Pet decodeFallback(Decoder decoder) {
    return Pet(type: decoder.decodeMapped().decodeString('type'));
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
