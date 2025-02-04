import 'package:codable/core.dart';
import 'package:codable/extended.dart';

part 'material.codable.dart';

// Decodable implementations
// ----------------------
// For this test we only care about decoding, so we only create
// Decodable implementations instead of Codable implementations.

//@Decodable()
abstract class Material {
  Material();
}

//@Decodable()
abstract class PeriodicElement {
  PeriodicElement();
}

//@Decodable()
class Wood extends Material {
  Wood();
}

//@Decodable()
class Iron extends Material implements PeriodicElement {
  Iron();
}

//@Decodable()
class Gold extends PeriodicElement implements Material {
  Gold();
}

//@Decodable()
class Helium extends PeriodicElement {
  Helium();
}
