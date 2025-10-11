import 'package:analyzer/dart/element/element2.dart';

import '../analyzer/nodes.dart';
import 'types.dart';

class CodableClassNode {
  CodableClassNode({
    required this.name,
    required this.url,
    this.isSelfEncodable = false,
    this.constructorName,
    this.typeParameters = const [],
    required this.fields,
  });

  factory CodableClassNode.fromElement(ClassElement2 e) => e.toNode();

  final String name;
  final String url;
  final bool isSelfEncodable;

  final String? constructorName;
  final List<CodableTypeParameter> typeParameters;
  final List<CodableFieldNode> fields;
}

class CodableFieldNode {
  CodableFieldNode({
    required this.name,
    required this.key,
    required this.type,
    this.id,
    this.isNamed = false,
  });

  final String name;
  final String key;
  final CodableType type;
  final int? id;
  final bool isNamed;
}

class CodableTypeParameter {
  CodableTypeParameter({
    required this.name,
    this.bound,
  });

  final String name;
  final CodableType? bound;

  String get declaration => bound != null ? '$name extends ${bound!.reference}' : name;
}

class CodableEnumNode {
  CodableEnumNode({
    required this.name,
    required this.url,
    this.isSelfEncodable = false,
    required this.values,
    this.nullValue,
    this.fallbackValue,
  });

  final String name;
  final String url;
  final bool isSelfEncodable;
  final List<CodableEnumValue> values;
  final String? nullValue;
  final String? fallbackValue;
}

class CodableEnumValue {
  CodableEnumValue({
    required this.name,
    required this.stringValue,
    required this.intValue,
  });

  final String name;
  final String? stringValue;
  final int intValue;
}
