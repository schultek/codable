import 'package:code_builder/code_builder.dart';

import 'builders/codable_builder.dart';
import 'models/nodes.dart';

abstract class CodableBuilder {
  const factory CodableBuilder() = CodableBuilderImpl;

  Field buildStaticCodableField(CodableClassNode node);

  Method buildSelfEncodeMethod(CodableClassNode node);

  Class buildCodableClass(CodableClassNode node);

  Class buildCodableEnumClass(CodableEnumNode node);
}
