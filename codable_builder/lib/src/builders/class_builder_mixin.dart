part of 'codable_builder.dart';

abstract mixin class ClassBuilderMixin implements EncodeMixin, DecodeMixin, CodableBuilder {
  @override
  Class buildCodableClass(CodableClassNode node) {
    return Class((b) {
      b.name = '${node.name}Codable';
      b.extend = TypeReference((b) {
        b.symbol = node.isSelfEncodable ? 'SelfCodable' : 'Codable';
        b.url = codableCoreUrl;
        b.types.add(TypeReference((b) {
          b.symbol = node.name;
          b.url = node.url;
          b.types.addAll(node.typeParameters.map((t) => refer(t.name)));
        }));
      });
      b.constructors.add(Constructor((b) {
        b.constant = true;
        if (node.typeParameters.isNotEmpty) {
          b.optionalParameters.addAll(node.typeParameters.map((t) {
            return Parameter((b) {
              b.name = 'codable${t.name}';
              b.type = TypeReference((b) {
                b.symbol = 'Codable';
                b.url = codableCoreUrl;
                b.types.add(refer(t.name));
                b.isNullable = true;
              });
            });
          }));
          b.initializers.addAll(node.typeParameters.expand((t) {
            return [
              Code('encodable${t.name} = codable${t.name}'),
              Code('decodable${t.name} = codable${t.name}'),
            ];
          }));
        }
      }));

      if (node.typeParameters.isNotEmpty) {
        b.constructors.add(Constructor((b) {
          b.name = 'of';
          b.constant = true;
          b.optionalParameters.addAll(node.typeParameters.expand((t) {
            return [
              Parameter((b) {
                b.name = 'encodable${t.name}';
                b.type = TypeReference((b) {
                  b.symbol = 'Encodable';
                  b.url = codableCoreUrl;
                  b.types.add(refer(t.name));
                  b.isNullable = true;
                });
                b.named = true;
                b.toThis = true;
              }),
              Parameter((b) {
                b.name = 'decodable${t.name}';
                b.type = TypeReference((b) {
                  b.symbol = 'Decodable';
                  b.url = codableCoreUrl;
                  b.types.add(refer(t.name));
                  b.isNullable = true;
                });
                b.named = true;
                b.toThis = true;
              })
            ];
          }));
        }));

        b.types.addAll(node.typeParameters.map((t) {
          return TypeReference((b) {
            b.symbol = t.name;
            b.bound = t.bound?.reference;
          });
        }));

        b.fields.addAll(node.typeParameters.expand((t) {
          return [
            Field((b) {
              b.name = 'encodable${t.name}';
              b.type = TypeReference((b) {
                b.symbol = 'Encodable';
                b.url = codableCoreUrl;
                b.types.add(refer(t.name));
                b.isNullable = true;
              });
              b.modifier = FieldModifier.final$;
            }),
            Field((b) {
              b.name = 'decodable${t.name}';
              b.type = TypeReference((b) {
                b.symbol = 'Decodable';
                b.url = codableCoreUrl;
                b.types.add(refer(t.name));
                b.isNullable = true;
              });
              b.modifier = FieldModifier.final$;
            })
          ];
        }));
      }

      b.methods.add(Method((b) {
        b.name = 'decode';
        b.returns = refer(node.name, node.url);
        b.annotations.add(refer('override', dartCoreUrl));
        b.requiredParameters.add(Parameter((b) {
          b.name = 'decoder';
          b.type = refer('Decoder', codableCoreUrl);
        }));
        b.body = Block((b) {
          b.statements.add(Code(
            'return switch (decoder.whatsNext()) {\n'
            '  DecodingType.mapped || DecodingType.map => _decodeMapped(decoder.decodeMapped()),\n'
            '  DecodingType.keyed || DecodingType.unknown => _decodeKeyed(decoder.decodeKeyed()),\n'
            '  _ => decoder.expect(\'mapped or keyed\'),\n'
            '};',
          ));
        });
      }));

      b.methods.add(Method((b) {
        b.name = '_decodeMapped';
        b.returns = refer(node.name, node.url);
        b.requiredParameters.add(Parameter((b) {
          b.name = 'mapped';
          b.type = refer('MappedDecoder', codableCoreUrl);
        }));
        b.body = Block((b) {
          final constructor = node.constructorName != null ? '${node.name}.${node.constructorName}' : node.name;
          final returnStatement = 'return $constructor(${node.fields.map((f) {
            return '${f.isNamed ? '${f.name}: ' : ''}mapped.${_buildDecodingInvocation(f, node, includeKey: true)}';
          }).join(', ')});';
          b.statements.add(Code(returnStatement));
        });
      }));

      b.methods.add(Method((b) {
        b.name = '_decodeKeyed';
        b.returns = refer(node.name, node.url);
        b.requiredParameters.add(Parameter((b) {
          b.name = 'keyed';
          b.type = refer('KeyedDecoder', codableCoreUrl);
        }));
        b.body = Block((b) {
          for (final field in node.fields) {
            b.statements.add(Code.scope((a) {
              return '${field.type.isNullable ? '' : 'late '}${a(field.type.reference)}${field.type.isNullable ? '?' : ''} ${field.name};';
            }));
          }

          b.statements.add(Code('''
            for (Object? key; (key = keyed.nextKey()) != null;) {
              switch (key) {
                ${node.fields.map((f) {
            return 'case \'${f.key}\'${f.id != null ? ' || ${f.id}' : ''}: ${f.name} = keyed.${_buildDecodingInvocation(f, node, includeKey: false)};';
          }).join('\n')}
                default:
                  keyed.skipCurrentValue();
              }
            }
          '''));

          final constructor = node.constructorName != null ? '${node.name}.${node.constructorName}' : node.name;
          b.statements.add(Code('return $constructor(${node.fields.map((f) {
            return '${f.isNamed ? '${f.name}: ' : ''}${f.name}';
          }).join(', ')});'));
        });
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
            b.statements.add(Code('''
            final keyed = encoder.encodeKeyed();
            ${node.fields.map((f) {
              return 'keyed.${_buildEncodingInvocation(f, node, value: 'value')};';
            }).join('\n')}
            keyed.end();
          '''));
          });
        }));
      }
    });
  }
}
