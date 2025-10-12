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
    this.subclasses = const [],
  });

  factory CodableClassNode.fromElement(ClassElement2 e) => e.toNode();

  final String name;
  final String url;
  final bool isSelfEncodable;

  final String? constructorName;
  final List<CodableTypeParameter> typeParameters;
  final List<CodableFieldNode> fields;

  final List<CodableSubclassNode> subclasses;
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
}

class CodableSubclassNode {
  CodableSubclassNode({
    required this.name,
    required this.url,
    this.chainable = false,
    this.typeParameterMapping = const [],
  });

  final String name;
  final String url;
  final bool chainable;
  final List<CodableTypeParameterMapping> typeParameterMapping;
}

class CodableTypeParameterMapping {
  CodableTypeParameterMapping({
    required this.name,
    this.bound,
    this.derivedIndex = -1,
    this.compoundIndex = -1,
  });

  final String name;
  final CodableType? bound;

  // What index of the superclass type param this maps to, or -1 if none.
  final int derivedIndex;
  // What index of the compound type params this maps to, or -1 if none.
  final int compoundIndex;
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
