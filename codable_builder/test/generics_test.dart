
import 'package:codable_builder/codable_builder.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('generics', () {
    test('should build generic class with one param', () {
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
        equals('class BoxCodable<T> extends Codable<Box<T>>\n'
            '    implements ComposedDecodable1<Box<T>> {\n'
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
            '  R extract<R>(R Function<A>(Decodable<A>?) fn) {\n'
            '    return fn<T>(decodableT);\n'
            '  }\n'
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

    test('should build generic class with two params', () {
      final code = builder.buildCodableClass(
        CodableClassNode(
          name: 'Box',
          url: 'package:test/box.dart',
          fields: [
            CodableFieldNode(name: 'content', key: 'content', type: ObjectCodableType('B')),
            CodableFieldNode(name: 'data', key: 'data', type: ObjectCodableType('A')),
          ],
          typeParameters: [CodableTypeParameter(name: 'A'),
            CodableTypeParameter(name: 'B')],
        ),
      );

      expect(
        emit(code),
        equals('class BoxCodable<A, B> extends Codable<Box<A, B>>\n'
            '    implements ComposedDecodable2<Box<A, B>> {\n'
            '  const BoxCodable([Codable<A>? codableA, Codable<B>? codableB])\n'
            '    : encodableA = codableA,\n'
            '      decodableA = codableA,\n'
            '      encodableB = codableB,\n'
            '      decodableB = codableB;\n'
            '\n'
            '  const BoxCodable.of({\n'
            '    Encodable<A>? this.encodableA,\n'
            '    Decodable<A>? this.decodableA,\n'
            '    Encodable<B>? this.encodableB,\n'
            '    Decodable<B>? this.decodableB,\n'
            '  });\n'
            '\n'
            '  final Encodable<A>? encodableA;\n'
            '\n'
            '  final Decodable<A>? decodableA;\n'
            '\n'
            '  final Encodable<B>? encodableB;\n'
            '\n'
            '  final Decodable<B>? decodableB;\n'
            '\n'
            '  @override\n'
            '  R extract<R>(R Function<A, B>(Decodable<A>?, Decodable<B>?) fn) {\n'
            '    return fn<A, B>(decodableA, decodableB);\n'
            '  }\n'
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
            '    return Box(\n'
            '      mapped.decodeObject(\'content\', using: decodableB),\n'
            '      mapped.decodeObject(\'data\', using: decodableA),\n'
            '    );\n'
            '  }\n'
            '\n'
            '  Box _decodeKeyed(KeyedDecoder keyed) {\n'
            '    late B content;\n'
            '    late A data;\n'
            '    for (Object? key; (key = keyed.nextKey()) != null;) {\n'
            '      switch (key) {\n'
            '        case \'content\':\n'
            '          content = keyed.decodeObject(using: decodableB);\n'
            '        case \'data\':\n'
            '          data = keyed.decodeObject(using: decodableA);\n'
            '        default:\n'
            '          keyed.skipCurrentValue();\n'
            '      }\n'
            '    }\n'
            '\n'
            '    return Box(content, data);\n'
            '  }\n'
            '\n'
            '  @override\n'
            '  void encode(Box value, Encoder encoder) {\n'
            '    final keyed = encoder.encodeKeyed();\n'
            '    keyed.encodeObject(\'content\', value.content, using: encodableB);\n'
            '    keyed.encodeObject(\'data\', value.data, using: encodableA);\n'
            '    keyed.end();\n'
            '  }\n'
            '}\n'
            ''),
      );
    });
  });
}