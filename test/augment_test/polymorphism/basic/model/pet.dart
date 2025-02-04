import 'package:codable/core.dart';
import 'package:codable/extended.dart';

part 'pet.codable.dart';

//@Codable()  //!(Constructor not defined, created in augmentation)
class Pet {
  final String type;
}

//@Codable()  //!(Here we define constructor)
class Cat extends Pet {
  Cat({required this.name, this.lives = 7}) : super(type: 'cat');

  final String name;
  final int lives;
}

//@Codable()  //!(Here we define constructor)
class Dog extends Pet {
  Dog({required this.name, required this.breed}) : super(type: 'dog');

  final String name;
  final String breed;
}

