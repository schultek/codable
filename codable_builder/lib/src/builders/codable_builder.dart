import 'package:code_builder/code_builder.dart';

import '../../codable_builder.dart';
import '../models/urls.dart';

part 'class_builder_mixin.dart';
part 'enum_builder_mixin.dart';
part 'encode_mixin.dart';
part 'decode_mixin.dart';

class CodableBuilderImpl with ClassBuilderMixin, EnumBuilderMixin, EncodeMixin, DecodeMixin implements CodableBuilder {
  const CodableBuilderImpl();

  @override
  Spec buildStaticCodableMember(CodableClassNode node) {
    if (node.typeParameters.isEmpty) {
      return Field((b) {
        b.static = true;
        b.modifier = FieldModifier.constant;
        b.type = TypeReference((b) {
          b.symbol = 'Codable';
          b.url = codableCoreUrl;
          b.types.add(refer(node.name, node.url));
        });
        b.name = 'codable';
        b.assignment = Code('${node.name}Codable()');
      });
    } else {
      return Method((b) {
        b.static = true;
        b.returns = TypeReference((b) {
          b.symbol = 'Codable';
          b.url = codableCoreUrl;
          b.types.add(TypeReference((b) {
            b.symbol = node.name;
            b.url = node.url;
            b.types.addAll(node.typeParameters.map((t) => refer(t.name)));
          }));
        });
        b.name = 'codable';
        b.types.addAll(node.typeParameters.map((t) => TypeReference((b) {
              b.symbol = t.name;
              b.bound = t.bound?.reference;
            })));
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
        b.body = Code('return ${node.name}Codable(${node.typeParameters.map((t) => 'codable${t.name}').join(', ')});');
      });
    }
  }

  @override
  Extension? buildGenericUseExtension(CodableClassNode node) {
    if (node.typeParameters.isEmpty) {
      return null;
    }

    return Extension((b) {
      b.name = '${node.name}EncodableExtension';
      b.types.addAll(node.typeParameters.map((t) => TypeReference((b) {
            b.symbol = t.name;
            b.bound = t.bound?.reference;
          })));
      b.on = TypeReference((b) {
        b.symbol = node.name;
        b.url = node.url;
        b.types.addAll(node.typeParameters.map((t) => refer(t.name)));
      });
      b.methods.add(Method((b) {
        b.returns = TypeReference((b) {
          b.symbol = 'SelfEncodable';
          b.url = codableCoreUrl;
          
        });
        b.name = 'use';
        b.optionalParameters.addAll(node.typeParameters.map((t) {
          return Parameter((b) {
            b.name = 'encodable${t.name}';
            b.type = TypeReference((b) {
              b.symbol = 'Encodable';
              b.url = codableCoreUrl;
              b.types.add(refer(t.name));
              b.isNullable = true;
            });
          });
        }));
        b.body = Code('return SelfEncodable.fromHandler((e) => encode(e, ${node.typeParameters.map((t) => 'encodable${t.name}').join(', ')}));');
      }));
    });
  }
}
