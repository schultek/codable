import 'package:codable_builder/codable_builder.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

void main() {
  group('codable member', () {
    final builder = const CodableBuilder();
    final emitter = DartEmitter(useNullSafetySyntax: true);

    test('should build field for basic class', () {
      final code = builder.buildStaticCodableMember(
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

    test('should build method for generic class', () {
      final code = builder.buildStaticCodableMember(
        CodableClassNode(
          name: 'TestClass',
          url: 'package:test/test_class.dart',
          typeParameters: [
            CodableTypeParameter(name: 'T'),
            CodableTypeParameter(name: 'U'),
          ],
          isSelfEncodable: true,
          constructorName: 'TestClass',
          fields: [],
        ),
      );

      expect(
        code.accept(emitter).toString(),
        equals(
            'static Codable<TestClass<T,U>> codable<T,U>([Codable<T>? codableT, Codable<U>? codableU, ]) { return TestClassCodable(codableT, codableU); } '),
      );
    });
  });
}
