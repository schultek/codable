import 'package:codable_builder/codable_builder.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('codable class', () {
    test('should build normal class', () {
      final code = builder.buildCodableClass(
        CodableClassNode(
          name: 'TestClass',
          url: 'package:test/test_class.dart',
          fields: [
            CodableFieldNode(name: 'name', key: 'name', type: CodableType.string),
            CodableFieldNode(name: 'age', key: 'age', type: CodableType.int),
            CodableFieldNode(name: 'isActive', key: 'isActive', type: CodableType.bool),
          ],
        ),
      );

      expect(
        emit(code),
        equals('class TestClassCodable extends Codable<TestClass> {\n'
            '  const TestClassCodable();\n'
            '\n'
            '  @override\n'
            '  TestClass decode(Decoder decoder) {\n'
            '    return switch (decoder.whatsNext()) {\n'
            '      DecodingType.mapped ||\n'
            '      DecodingType.map => _decodeMapped(decoder.decodeMapped()),\n'
            '      DecodingType.keyed ||\n'
            '      DecodingType.unknown => _decodeKeyed(decoder.decodeKeyed()),\n'
            '      _ => decoder.expect(\'mapped or keyed\'),\n'
            '    };\n'
            '  }\n'
            '\n'
            '  TestClass _decodeMapped(MappedDecoder mapped) {\n'
            '    return TestClass(\n'
            '      mapped.decodeString(\'name\'),\n'
            '      mapped.decodeInt(\'age\'),\n'
            '      mapped.decodeBool(\'isActive\'),\n'
            '    );\n'
            '  }\n'
            '\n'
            '  TestClass _decodeKeyed(KeyedDecoder keyed) {\n'
            '    late String name;\n'
            '    late int age;\n'
            '    late bool isActive;\n'
            '    for (Object? key; (key = keyed.nextKey()) != null;) {\n'
            '      switch (key) {\n'
            '        case \'name\':\n'
            '          name = keyed.decodeString();\n'
            '        case \'age\':\n'
            '          age = keyed.decodeInt();\n'
            '        case \'isActive\':\n'
            '          isActive = keyed.decodeBool();\n'
            '        default:\n'
            '          keyed.skipCurrentValue();\n'
            '      }\n'
            '    }\n'
            '\n'
            '    return TestClass(name, age, isActive);\n'
            '  }\n'
            '\n'
            '  @override\n'
            '  void encode(TestClass value, Encoder encoder) {\n'
            '    final keyed = encoder.encodeKeyed();\n'
            '    keyed.encodeString(\'name\', value.name);\n'
            '    keyed.encodeInt(\'age\', value.age);\n'
            '    keyed.encodeBool(\'isActive\', value.isActive);\n'
            '    keyed.end();\n'
            '  }\n'
            '}\n'
            ''),
      );
    });

    test('should build self-encodable class', () {
      final code = builder.buildCodableClass(
        CodableClassNode(
          name: 'SelfEncodableClass',
          url: 'package:test/self_encodable_class.dart',
          fields: [
            CodableFieldNode(name: 'name', key: 'name', type: CodableType.string),
            CodableFieldNode(name: 'age', key: 'age', type: CodableType.int),
          ],
          isSelfEncodable: true,
        ),
      );

      expect(
        emit(code),
        equals('class SelfEncodableClassCodable extends SelfCodable<SelfEncodableClass> {\n'
            '  const SelfEncodableClassCodable();\n'
            '\n'
            '  @override\n'
            '  SelfEncodableClass decode(Decoder decoder) {\n'
            '    return switch (decoder.whatsNext()) {\n'
            '      DecodingType.mapped ||\n'
            '      DecodingType.map => _decodeMapped(decoder.decodeMapped()),\n'
            '      DecodingType.keyed ||\n'
            '      DecodingType.unknown => _decodeKeyed(decoder.decodeKeyed()),\n'
            '      _ => decoder.expect(\'mapped or keyed\'),\n'
            '    };\n'
            '  }\n'
            '\n'
            '  SelfEncodableClass _decodeMapped(MappedDecoder mapped) {\n'
            '    return SelfEncodableClass(\n'
            '      mapped.decodeString(\'name\'),\n'
            '      mapped.decodeInt(\'age\'),\n'
            '    );\n'
            '  }\n'
            '\n'
            '  SelfEncodableClass _decodeKeyed(KeyedDecoder keyed) {\n'
            '    late String name;\n'
            '    late int age;\n'
            '    for (Object? key; (key = keyed.nextKey()) != null;) {\n'
            '      switch (key) {\n'
            '        case \'name\':\n'
            '          name = keyed.decodeString();\n'
            '        case \'age\':\n'
            '          age = keyed.decodeInt();\n'
            '        default:\n'
            '          keyed.skipCurrentValue();\n'
            '      }\n'
            '    }\n'
            '\n'
            '    return SelfEncodableClass(name, age);\n'
            '  }\n'
            '}\n'
            ''),
      );
    });

    test('should build class with constructor name', () {
      final code = builder.buildCodableClass(
        CodableClassNode(
          name: 'TestClassWithConstructor',
          url: 'package:test/test_class_with_constructor.dart',
          constructorName: 'custom',
          isSelfEncodable: true,
          fields: [
            CodableFieldNode(name: 'name', key: 'name', type: CodableType.string),
          ],
        ),
      );

      expect(
        emit(code),
        equals('class TestClassWithConstructorCodable\n'
            '    extends SelfCodable<TestClassWithConstructor> {\n'
            '  const TestClassWithConstructorCodable();\n'
            '\n'
            '  @override\n'
            '  TestClassWithConstructor decode(Decoder decoder) {\n'
            '    return switch (decoder.whatsNext()) {\n'
            '      DecodingType.mapped ||\n'
            '      DecodingType.map => _decodeMapped(decoder.decodeMapped()),\n'
            '      DecodingType.keyed ||\n'
            '      DecodingType.unknown => _decodeKeyed(decoder.decodeKeyed()),\n'
            '      _ => decoder.expect(\'mapped or keyed\'),\n'
            '    };\n'
            '  }\n'
            '\n'
            '  TestClassWithConstructor _decodeMapped(MappedDecoder mapped) {\n'
            '    return TestClassWithConstructor.custom(mapped.decodeString(\'name\'));\n'
            '  }\n'
            '\n'
            '  TestClassWithConstructor _decodeKeyed(KeyedDecoder keyed) {\n'
            '    late String name;\n'
            '    for (Object? key; (key = keyed.nextKey()) != null;) {\n'
            '      switch (key) {\n'
            '        case \'name\':\n'
            '          name = keyed.decodeString();\n'
            '        default:\n'
            '          keyed.skipCurrentValue();\n'
            '      }\n'
            '    }\n'
            '\n'
            '    return TestClassWithConstructor.custom(name);\n'
            '  }\n'
            '}\n'
            ''),
      );
    });

    test('should build class with nullable fields', () {
      final code = builder.buildCodableClass(
        CodableClassNode(
          name: 'NullableFieldsClass',
          url: 'package:test/nullable_fields_class.dart',
          fields: [
            CodableFieldNode(name: 'name', key: 'name', type: CodableType.stringNullable),
            CodableFieldNode(name: 'age', key: 'age', type: CodableType.intNullable, isNamed: true),
          ],
        ),
      );

      expect(
        emit(code),
        equals('class NullableFieldsClassCodable extends Codable<NullableFieldsClass> {\n'
            '  const NullableFieldsClassCodable();\n'
            '\n'
            '  @override\n'
            '  NullableFieldsClass decode(Decoder decoder) {\n'
            '    return switch (decoder.whatsNext()) {\n'
            '      DecodingType.mapped ||\n'
            '      DecodingType.map => _decodeMapped(decoder.decodeMapped()),\n'
            '      DecodingType.keyed ||\n'
            '      DecodingType.unknown => _decodeKeyed(decoder.decodeKeyed()),\n'
            '      _ => decoder.expect(\'mapped or keyed\'),\n'
            '    };\n'
            '  }\n'
            '\n'
            '  NullableFieldsClass _decodeMapped(MappedDecoder mapped) {\n'
            '    return NullableFieldsClass(\n'
            '      mapped.decodeStringOrNull(\'name\'),\n'
            '      age: mapped.decodeIntOrNull(\'age\'),\n'
            '    );\n'
            '  }\n'
            '\n'
            '  NullableFieldsClass _decodeKeyed(KeyedDecoder keyed) {\n'
            '    String? name;\n'
            '    int? age;\n'
            '    for (Object? key; (key = keyed.nextKey()) != null;) {\n'
            '      switch (key) {\n'
            '        case \'name\':\n'
            '          name = keyed.decodeStringOrNull();\n'
            '        case \'age\':\n'
            '          age = keyed.decodeIntOrNull();\n'
            '        default:\n'
            '          keyed.skipCurrentValue();\n'
            '      }\n'
            '    }\n'
            '\n'
            '    return NullableFieldsClass(name, age: age);\n'
            '  }\n'
            '\n'
            '  @override\n'
            '  void encode(NullableFieldsClass value, Encoder encoder) {\n'
            '    final keyed = encoder.encodeKeyed();\n'
            '    keyed.encodeStringOrNull(\'name\', value.name);\n'
            '    keyed.encodeIntOrNull(\'age\', value.age);\n'
            '    keyed.end();\n'
            '  }\n'
            '}\n'
            ''),
      );
    });

    test('should build generic class', () {
      final code = builder.buildCodableClass(
        CodableClassNode(
          name: 'Box',
          url: 'package:test/box.dart',
          fields: [
            CodableFieldNode(name: 'content', key: 'content', type: ObjectCodableType('T')),
          ],
          typeParameters: [CodableTypeParameter(name: 'T')],
        ),
      );

      expect(
        emit(code),
        equals('class BoxCodable<T> extends Codable<Box<T>> {\n'
            '  const BoxCodable([Codable<T>? codableT])\n'
            '    : encodableT = codableT,\n'
            '      decodableT = codableT;\n'
            '\n'
            '  const BoxCodable.of({\n'
            '    Encodable<T>? this.encodableT,\n'
            '    Decodable<T>? this.decodableT,\n'
            '  });\n'
            '\n'
            '  final Encodable<T>? encodableT;\n'
            '\n'
            '  final Decodable<T>? decodableT;\n'
            '\n'
            '  @override\n'
            '  Box decode(Decoder decoder) {\n'
            '    return switch (decoder.whatsNext()) {\n'
            '      DecodingType.mapped ||\n'
            '      DecodingType.map => _decodeMapped(decoder.decodeMapped()),\n'
            '      DecodingType.keyed ||\n'
            '      DecodingType.unknown => _decodeKeyed(decoder.decodeKeyed()),\n'
            '      _ => decoder.expect(\'mapped or keyed\'),\n'
            '    };\n'
            '  }\n'
            '\n'
            '  Box _decodeMapped(MappedDecoder mapped) {\n'
            '    return Box(mapped.decodeObject(\'content\', using: decodableT));\n'
            '  }\n'
            '\n'
            '  Box _decodeKeyed(KeyedDecoder keyed) {\n'
            '    late T content;\n'
            '    for (Object? key; (key = keyed.nextKey()) != null;) {\n'
            '      switch (key) {\n'
            '        case \'content\':\n'
            '          content = keyed.decodeObject(using: decodableT);\n'
            '        default:\n'
            '          keyed.skipCurrentValue();\n'
            '      }\n'
            '    }\n'
            '\n'
            '    return Box(content);\n'
            '  }\n'
            '\n'
            '  @override\n'
            '  void encode(Box value, Encoder encoder) {\n'
            '    final keyed = encoder.encodeKeyed();\n'
            '    keyed.encodeObject(\'content\', value.content, using: encodableT);\n'
            '    keyed.end();\n'
            '  }\n'
            '}\n'
            ''),
      );
    });
  });
}
