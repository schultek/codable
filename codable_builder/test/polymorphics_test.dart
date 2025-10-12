import 'package:codable_builder/codable_builder.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('polymorphics', () {
    test('should build polymorphic class', () {
      final code = builder.buildCodableClass(
        CodableClassNode(
          name: 'Pet',
          url: 'package:test/box.dart',
          fields: [],
          subclasses: [
            CodableSubclassNode(
              name: 'Dog',
              url: 'package:test/dog.dart',
            ),
            CodableSubclassNode(
              name: 'Cat',
              url: 'package:test/cat.dart',
            ),
          ],
        ),
      );

      expect(
        emit(code),
        equals('class PetCodable extends Codable<Pet> with SuperDecodable<Pet> {\n'
            '  const PetCodable();\n'
            '\n'
            '  @override\n'
            '  String get discriminatorKey => \'type\';\n'
            '\n'
            '  @override\n'
            '  List<Discriminator<Pet>> get discriminators => [\n'
            '    Discriminator<Dog>(\'dog\', DogCodable.new),\n'
            '    Discriminator<Cat>(\'cat\', CatCodable.new),\n'
            '  ];\n'
            '\n'
            '  @override\n'
            '  Pet decode(Decoder decoder) {\n'
            '    return switch (decoder.whatsNext()) {\n'
            '      DecodingType.mapped ||\n'
            '      DecodingType.map => _decodeMapped(decoder.decodeMapped()),\n'
            '      DecodingType.keyed ||\n'
            '      DecodingType.unknown => _decodeKeyed(decoder.decodeKeyed()),\n'
            '      _ => decoder.expect(\'mapped or keyed\'),\n'
            '    };\n'
            '  }\n'
            '\n'
            '  Pet _decodeMapped(MappedDecoder mapped) {\n'
            '    return Pet();\n'
            '  }\n'
            '\n'
            '  Pet _decodeKeyed(KeyedDecoder keyed) {\n'
            '    for (Object? key; (key = keyed.nextKey()) != null;) {\n'
            '      switch (key) {\n'
            '        default:\n'
            '          keyed.skipCurrentValue();\n'
            '      }\n'
            '    }\n'
            '\n'
            '    return Pet();\n'
            '  }\n'
            '\n'
            '  @override\n'
            '  void encode(Pet value, Encoder encoder) {\n'
            '    final keyed = encoder.encodeKeyed();\n'
            '\n'
            '    keyed.end();\n'
            '  }\n'
            '}\n'
            ''),
      );
    });

    test('should build polymorphic class with one type arg', () {
      final code = builder.buildCodableClass(
        CodableClassNode(
          name: 'Pet',
          url: 'package:test/box.dart',
          fields: [],
          typeParameters: [CodableTypeParameter(name: 'T')],
          subclasses: [
            CodableSubclassNode(
              name: 'Dog',
              url: 'package:test/dog.dart',
              typeParameterMapping: [CodableTypeParameterMapping(name: 'D', derivedIndex: 0)],
            ),
            CodableSubclassNode(
              name: 'Cat',
              url: 'package:test/cat.dart',
            ),
            CodableSubclassNode(
              name: 'Snake',
              url: 'package:test/snake.dart',
              typeParameterMapping: [CodableTypeParameterMapping(name: 'S', derivedIndex: 0, bound: CodableType.num)],
            ),
            CodableSubclassNode(
              name: 'Lizard',
              url: 'package:test/lizard.dart',
              typeParameterMapping: [
                CodableTypeParameterMapping(name: 'L', derivedIndex: -1, bound: CodableType.int),
                CodableTypeParameterMapping(name: 'T', derivedIndex: 0),
              ],
            ),
          ],
        ),
      );

      expect(
        emit(code),
        equals('class PetCodable<T> extends Codable<Pet<T>>\n'
            '    with SuperDecodable<Pet<T>>\n'
            '    implements ComposedDecodable1<Pet<T>> {\n'
            '  const PetCodable([Codable<T>? codableT])\n'
            '    : encodableT = codableT,\n'
            '      decodableT = codableT;\n'
            '\n'
            '  const PetCodable.of({\n'
            '    Encodable<T>? this.encodableT,\n'
            '    Decodable<T>? this.decodableT,\n'
            '  });\n'
            '\n'
            '  final Encodable<T>? encodableT;\n'
            '\n'
            '  final Decodable<T>? decodableT;\n'
            '\n'
            '  @override\n'
            '  R extract<R>(R Function<A>(Decodable<A>?) fn) {\n'
            '    return fn<T>(decodableT);\n'
            '  }\n'
            '\n'
            '  @override\n'
            '  String get discriminatorKey => \'type\';\n'
            '\n'
            '  @override\n'
            '  List<Discriminator<Pet>> get discriminators => [\n'
            '    Discriminator.arg1<Dog>(\'dog\', <T>(Decodable<T>? decodableT) {\n'
            '      return DogCodable<T>.of(decodableD: decodableT);\n'
            '    }),\n'
            '    Discriminator.arg1<Cat>(\'cat\', <T>(Decodable<T>? decodableT) {\n'
            '      return CatCodable();\n'
            '    }),\n'
            '    Discriminator.arg1Bounded<Snake, num>(\'snake\', <T extends num>(\n'
            '      Decodable<T>? decodableT,\n'
            '    ) {\n'
            '      return SnakeCodable<T>.of(decodableS: decodableT);\n'
            '    }),\n'
            '    Discriminator.arg1<Lizard>(\'lizard\', <T>(Decodable<T>? decodableT) {\n'
            '      return LizardCodable<dynamic, T>.of(decodableT: decodableT);\n'
            '    }),\n'
            '  ];\n'
            '\n'
            '  @override\n'
            '  Pet decode(Decoder decoder) {\n'
            '    return switch (decoder.whatsNext()) {\n'
            '      DecodingType.mapped ||\n'
            '      DecodingType.map => _decodeMapped(decoder.decodeMapped()),\n'
            '      DecodingType.keyed ||\n'
            '      DecodingType.unknown => _decodeKeyed(decoder.decodeKeyed()),\n'
            '      _ => decoder.expect(\'mapped or keyed\'),\n'
            '    };\n'
            '  }\n'
            '\n'
            '  Pet _decodeMapped(MappedDecoder mapped) {\n'
            '    return Pet();\n'
            '  }\n'
            '\n'
            '  Pet _decodeKeyed(KeyedDecoder keyed) {\n'
            '    for (Object? key; (key = keyed.nextKey()) != null;) {\n'
            '      switch (key) {\n'
            '        default:\n'
            '          keyed.skipCurrentValue();\n'
            '      }\n'
            '    }\n'
            '\n'
            '    return Pet();\n'
            '  }\n'
            '\n'
            '  @override\n'
            '  void encode(Pet value, Encoder encoder) {\n'
            '    final keyed = encoder.encodeKeyed();\n'
            '\n'
            '    keyed.end();\n'
            '  }\n'
            '}\n'
            ''),
      );
    });
  });
}
