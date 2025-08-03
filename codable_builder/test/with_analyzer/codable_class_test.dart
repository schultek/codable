import 'package:codable_builder/codable_builder.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  group('codable class (analyzer)', () {
    test('should build normal class', () async {
      final element = await getElementFrom('basic_class.dart');

      final node = CodableClassNode.fromElement(element);
      final code = builder.buildCodableClass(node);

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
            '      name: mapped.decodeString(\'name\'),\n'
            '      age: mapped.decodeInt(\'age\'),\n'
            '      isActive: mapped.decodeBool(\'isactive\'),\n'
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
            '        case \'isactive\':\n'
            '          isActive = keyed.decodeBool();\n'
            '        default:\n'
            '          keyed.skipCurrentValue();\n'
            '      }\n'
            '    }\n'
            '\n'
            '    return TestClass(name: name, age: age, isActive: isActive);\n'
            '  }\n'
            '\n'
            '  @override\n'
            '  void encode(TestClass value, Encoder encoder) {\n'
            '    final keyed = encoder.encodeKeyed();\n'
            '    keyed.encodeString(\'name\', value.name);\n'
            '    keyed.encodeInt(\'age\', value.age);\n'
            '    keyed.encodeBool(\'isactive\', value.isActive);\n'
            '    keyed.end();\n'
            '  }\n'
            '}\n'
            ''),
      );
    });
  });
}
