import 'package:codable_builder/codable_builder.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

void main() {
  group('codable field', () {
    final builder = const CodableBuilder();
    final emitter = DartEmitter(useNullSafetySyntax: true);

    test('should build correct code', () {
      final code = builder.buildStaticCodableField(
        CodableClassNode(
          name: 'TestClass',
          url: 'package:test/test_class.dart',
          isSelfEncodable: true,
          constructorName: 'TestClass',
          fields: [],
        ),
      );

      expect(
        code.accept(emitter).toString(),
        equals('static const Codable<TestClass> codable = TestClassCodable();\n'),
      );
    });
  });
}
