import 'package:codable/core.dart';
import 'package:codable/extended.dart';

abstract class Material {
  Material();

  static const Decodable<Material> decodable = MaterialDecodable();
}

abstract class PeriodicElement {
  PeriodicElement();

  static const Decodable<PeriodicElement> decodable = PeriodicElementDecodable();
}

class Wood extends Material {
  Wood();
}

class Iron extends Material implements PeriodicElement {
  Iron();
}

class Gold extends PeriodicElement implements Material {
  Gold();
}

class Helium extends PeriodicElement {
  Helium();
}

// Decodable implementations
// ----------------------
// For this test we only care about decoding, so we only create
// Decodable implementations instead of Codable implementations.

class MaterialDecodable with SuperDecodable<Material> {
  const MaterialDecodable();

  @override
  String get discriminatorKey => 'type';

  @override
  List<Discriminator<Material>> get discriminators => [
        Discriminator<Material>('wood', WoodDecodable.new),
        Discriminator<Material>('iron', IronDecodable.new),
        Discriminator<Material>('gold', GoldDecodable.new),
      ];
}

class PeriodicElementDecodable with SuperDecodable<PeriodicElement> {
  const PeriodicElementDecodable();

  @override
  String get discriminatorKey => 'symbol';

  @override
  List<Discriminator<PeriodicElement>> get discriminators => [
        Discriminator<PeriodicElement>('Fe', IronDecodable.new),
        Discriminator<PeriodicElement>('Au', GoldDecodable.new),
        Discriminator<PeriodicElement>('He', HeliumDecodable.new),
      ];
}

class WoodDecodable implements Decodable<Wood> {
  @override
  Wood decode(Decoder decoder) {
    return Wood();
  }
}

class IronDecodable implements Decodable<Iron> {
  @override
  Iron decode(Decoder decoder) {
    return Iron();
  }
}

class GoldDecodable implements Decodable<Gold> {
  @override
  Gold decode(Decoder decoder) {
    return Gold();
  }
}

class HeliumDecodable implements Decodable<Helium> {
  @override
  Helium decode(Decoder decoder) {
    return Helium();
  }
}
