import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import '../../codable_builder.dart';
import '../models/urls.dart';

extension ClassElement2Extension on ClassElement2 {
  CodableClassNode toNode() {
    final isSelfEncodable = allSupertypes.any((t) =>
        t.element3.name3 == 'SelfEncodable' &&
        t.element3.library2.uri.toString() == 'package:codable/src/core/interfaces.dart');

    // TODO: Support choosing a different constructor.
    var constructorName = constructors2.firstOrNull?.name3;
    if (constructorName == 'new') {
      constructorName = null;
    }

    return CodableClassNode(
      name: name3 ?? '',
      url: firstFragment.libraryFragment.source.uri.toString(),
      isSelfEncodable: isSelfEncodable,
      constructorName: constructorName,
      typeParameters: typeParameters2.map((t) => t.toNode()).toList(),
      fields: fields2.map((f) => f.toNode()).toList(),
    );
  }
}

extension FieldElement2Extension on FieldElement2 {
  CodableFieldNode toNode() {
    return CodableFieldNode(
      name: name3 ?? '',
      key: (name3 ?? '').toLowerCase(), // TODO: Handle case styles and custom keys.
      type: type.toCodableType(),
      id: null, // TODO: Handle field IDs.
      isNamed: true, // TODO: Get this from the constructor.
    );
  }
}

extension TypeParameterElement2Extension on TypeParameterElement2 {
  CodableTypeParameter toNode() {
    return CodableTypeParameter(
      name: name3 ?? '',
      bound: bound?.toCodableType(),
    );
  }
}

extension TypeExtension on DartType {
  CodableType toCodableType() {
    bool isNullable = isDartCoreNull || nullabilitySuffix == NullabilitySuffix.question;

    if (isDartCoreString) {
      return isNullable ? CodableType.stringNullable : CodableType.string;
    } else if (isDartCoreInt) {
      return isNullable ? CodableType.intNullable : CodableType.int;
    } else if (isDartCoreDouble) {
      return isNullable ? CodableType.doubleNullable : CodableType.double;
    } else if (isDartCoreBool) {
      return isNullable ? CodableType.boolNullable : CodableType.bool;
    } else if (isDartCoreNum) {
      return isNullable ? CodableType.numNullable : CodableType.num;
    } else if (isDartCoreObject) {
      return isNullable ? CodableType.objectNullable : CodableType.object;
    }

    if (isDartCoreList) {
      return ListCodableType(
        (this as InterfaceType).typeArguments.first.toCodableType(),
        isNullable,
      );
    }
    if (isDartCoreMap) {
      final typeArgs = (this as InterfaceType).typeArguments;
      return MapCodableType(
        typeArgs[0].toCodableType(),
        typeArgs[1].toCodableType(),
        isNullable,
      );
    }

    if (this case InterfaceType type) {
      final element = type.element3;
      return ObjectCodableType(
        element.name3 ?? '',
        element.library2.uri.toString(),
        isNullable,
        null, // TODO: Handle 'using' if needed.
      );
    }

    return ObjectCodableType(
      'Object',
      dartCoreUrl,
      isNullable,
      null, // TODO: Handle 'using' if needed.
    );
  }
}
