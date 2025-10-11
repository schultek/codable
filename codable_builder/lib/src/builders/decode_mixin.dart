part of 'codable_builder.dart';

abstract mixin class DecodeMixin implements CodableBuilder {
  String _buildDecodingInvocation(CodableFieldNode node, CodableClassNode clazz, {required bool includeKey}) {
    final suffix = node.type.isNullable ? 'OrNull' : '';
    final name = switch (node.type) {
      ObjectCodableType t when t.using != null => 'decodeObject$suffix',
      ObjectCodableType t when t.name == 'String' => 'decodeString$suffix',
      ObjectCodableType t when t.name == 'int' => 'decodeInt$suffix',
      ObjectCodableType t when t.name == 'double' => 'decodeDouble$suffix',
      ObjectCodableType t when t.name == 'num' => 'decodeNum$suffix',
      ObjectCodableType t when t.name == 'bool' => 'decodeBool$suffix',
      ObjectCodableType() => 'decodeObject$suffix',
      ListCodableType() => 'decodeList$suffix',
      MapCodableType() => 'decodeMap$suffix',
    };
    final args = switch (node.type) {
      ObjectCodableType t when t.using != null => ['using: ${t.using}'],
      ObjectCodableType t when clazz.typeParameters.any((tp) => tp.name == t.name) => ['using: decodable${t.name}'],
      ListCodableType t when t.itemType.using != null => ['using: ${t.itemType.using}'],
      MapCodableType t => [
          if (t.keyType.using != null) 'keyUsing: ${t.keyType.using}',
          if (t.valueType.using != null) 'valueUsing: ${t.valueType.using}'
        ],
      _ => [],
    };
    return '$name(${[
      if (includeKey) '\'${node.key}\'',
      if (includeKey && node.id != null) 'id: ${node.id}',
      ...args
    ].join(', ')})';
  }
}
