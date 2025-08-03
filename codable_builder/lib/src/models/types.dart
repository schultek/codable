import 'dart:core';
import 'dart:core' as core;

import 'package:code_builder/code_builder.dart';

import 'urls.dart';

sealed class CodableType {
  const CodableType(this.isNullable, [this.using]);

  final core.bool isNullable;
  final String? using;

  Reference get reference;

  static const CodableType string = ObjectCodableType.core('String');
  static const CodableType stringNullable = ObjectCodableType.core('String', true);
  static const CodableType int = ObjectCodableType.core('int');
  static const CodableType intNullable = ObjectCodableType.core('int', true);
  static const CodableType double = ObjectCodableType.core('double');
  static const CodableType doubleNullable = ObjectCodableType.core('double', true);
  static const CodableType num = ObjectCodableType.core('num');
  static const CodableType numNullable = ObjectCodableType.core('num', true);
  static const CodableType bool = ObjectCodableType.core('bool');
  static const CodableType boolNullable = ObjectCodableType.core('bool', true);
  static const CodableType object = ObjectCodableType.core('Object');
  static const CodableType objectNullable = ObjectCodableType.core('Object', true);
}

class ObjectCodableType extends CodableType {
  final String name;
  final String url;

  const ObjectCodableType(this.name, this.url, super.isNullable, super.using);

  const ObjectCodableType.core(this.name, [super.isNullable = false]) : url = dartCoreUrl;

  @override
  Reference get reference => refer(name, url);
}

class ListCodableType extends CodableType {
  final CodableType itemType;

  const ListCodableType(this.itemType, super.isNullable);

  @override
  Reference get reference => TypeReference((b) {
        b.symbol = 'List';
        b.url = dartCoreUrl;
        b.types.add(itemType.reference);
      });
}

class MapCodableType extends CodableType {
  final CodableType keyType;
  final CodableType valueType;

  const MapCodableType(this.keyType, this.valueType, super.isNullable);

  @override
  Reference get reference => TypeReference((b) {
        b.symbol = 'Map';
        b.url = dartCoreUrl;
        b.types.addAll([keyType.reference, valueType.reference]);
      });
}
