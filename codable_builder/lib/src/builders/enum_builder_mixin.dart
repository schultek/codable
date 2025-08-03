part of 'codable_builder.dart';

abstract mixin class EnumBuilderMixin implements CodableBuilder {
  @override
  Class buildCodableEnumClass(CodableEnumNode node) {
    return Class((b) {
      b.name = '${node.name}Codable';
      b.extend = TypeReference((b) {
        b.symbol = node.isSelfEncodable ? 'SelfCodable' : 'Codable';
        b.url = codableCoreUrl;
        b.types.add(refer(node.name, node.url));
      });
      b.constructors.add(Constructor((b) {
        b.constant = true;
      }));

      b.methods.add(Method((b) {
        b.name = 'decode';
        b.returns = refer(node.name, node.url);
        b.annotations.add(refer('override', dartCoreUrl));
        b.requiredParameters.add(Parameter((b) {
          b.name = 'decoder';
          b.type = refer('Decoder', codableCoreUrl);
        }));
        b.body = Block((b) {
          b.statements.add(Code.scope((a) => 'return switch (decoder.whatsNext()) {\n'
              '${node.nullValue != null ? '  DecodingType.nil => ${a(refer(node.name, node.url))}.${node.nullValue},\n' : ''}'
              '  DecodingType.string => _decodeString(decoder.decodeStringOrNull(), decoder),\n'
              '  DecodingType.num || DecodingType.int => _decodeInt(decoder.decodeIntOrNull(), decoder),\n'
              '  DecodingType.unknown when decoder.isHumanReadable() => _decodeString(decoder.decodeStringOrNull(), decoder),\n'
              '  DecodingType.unknown => _decodeInt(decoder.decodeIntOrNull(), decoder),\n'
              '  _ => decoder.expect(\'${node.name} as String or int\'),\n'
              '};'));
        });
      }));

      Block buildDecodeBody(List<(String, String)> cases) {
        return Block((b) {
          b.statements.add(Code.scope((a) {
            String buildCase(String value, String name) {
              return '  $value => ${a(refer(node.name, node.url))}.$name,\n';
            }

            final fallback = node.fallbackValue != null
                ? buildCase('_', node.fallbackValue!)
                : '  _ => decoder.expect(\'${node.name} of ${cases.map((v) => v.$1).join(', ').replaceAll("'", '')}\'),\n';

            return 'return switch (value) {\n'
                '${cases.map((v) => buildCase(v.$1, v.$2)).join()}'
                '$fallback'
                '};';
          }));
        });
      }

      b.methods.add(Method((b) {
        b.name = '_decodeString';
        b.returns = refer(node.name, node.url);
        b.requiredParameters.add(Parameter((b) {
          b.name = 'value';
          b.type = refer('String?', dartCoreUrl);
        }));
        b.requiredParameters.add(Parameter((b) {
          b.name = 'decoder';
          b.type = refer('Decoder', codableCoreUrl);
        }));
        b.body = buildDecodeBody([
          ...node.values.where((v) => v.stringValue != null).map((v) => ('\'${v.stringValue!}\'', v.name)),
          if (node.nullValue != null) ('null', node.nullValue!),
        ]);
      }));

      b.methods.add(Method((b) {
        b.name = '_decodeInt';
        b.returns = refer(node.name, node.url);
        b.requiredParameters.add(Parameter((b) {
          b.name = 'value';
          b.type = refer('int?', dartCoreUrl);
        }));
        b.requiredParameters.add(Parameter((b) {
          b.name = 'decoder';
          b.type = refer('Decoder', codableCoreUrl);
        }));
        b.body = buildDecodeBody([
          ...node.values.map((v) => (v.intValue.toString(), v.name)),
          if (node.nullValue != null) ('null', node.nullValue!),
        ]);
      }));

      if (!node.isSelfEncodable) {
        b.methods.add(Method((b) {
          b.name = 'encode';
          b.returns = refer('void');
          b.annotations.add(refer('override', dartCoreUrl));
          b.requiredParameters.add(Parameter((b) {
            b.name = 'value';
            b.type = refer(node.name, node.url);
          }));
          b.requiredParameters.add(Parameter((b) {
            b.name = 'encoder';
            b.type = refer('Encoder', codableCoreUrl);
          }));
          b.body = Block((b) {
            b.statements.add(Code.scope((a) => '''
            if (encoder.isHumanReadable()) {
              encoder.encodeStringOrNull(switch (value) {
                ${node.values.map((v) => '  ${a(refer(node.name, node.url))}.${v.name} => \'${v.stringValue}\';').join('\n')}
                ${node.nullValue != null ? 'case ${a(refer(node.name, node.url))}.${node.nullValue!}: return null;' : ''}
                default: throw Exception('Unknown value for ${node.name}');
              });
            } else {
              encoder.encodeIntOrNull(switch (value) {
                ${node.values.map((v) => 'case ${node.name}.${v.name}: return ${v.intValue};').join('\n')}
                ${node.nullValue != null ? 'case ${node.name}.${node.nullValue!}: return null;' : ''}
                default: throw Exception('Unknown value for ${node.name}');
              });
            }
          '''));
          });
        }));
      }
    });
  }
}
