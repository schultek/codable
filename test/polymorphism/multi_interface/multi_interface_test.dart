import 'package:codable_dart/standard.dart';
import 'package:test/test.dart';

import 'model/material.dart';

final woodMap = {'type': 'wood'};
final ironMap = {'type': 'iron', 'symbol': 'Fe'};
final goldMap = {'type': 'gold', 'symbol': 'Au'};
final heliumMap = {'symbol': 'He'};

void main() {
  group('multi polymorphism', () {
    test('decodes single discriminated subtype', () {
      Material material = Material.decodable.fromMap(woodMap);
      expect(material, isA<Wood>());

      PeriodicElement element = PeriodicElement.decodable.fromMap(heliumMap);
      expect(element, isA<Helium>());
    });

    test('decodes multi discriminated subtype', () {
      Material material = Material.decodable.fromMap(ironMap);
      PeriodicElement element = PeriodicElement.decodable.fromMap(ironMap);
      expect(material, isA<Iron>());
      expect(element, isA<Iron>());

      Material material2 = Material.decodable.fromMap(goldMap);
      PeriodicElement element2 = PeriodicElement.decodable.fromMap(goldMap);
      expect(material2, isA<Gold>());
      expect(element2, isA<Gold>());
    });
  });
}
