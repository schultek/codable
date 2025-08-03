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
  Field buildStaticCodableField(CodableClassNode node) {
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
  }
}
