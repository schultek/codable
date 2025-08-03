part of 'codable_builder.dart';

abstract mixin class EncodeMixin implements CodableBuilder {
  @override
  Method buildSelfEncodeMethod(CodableClassNode node) {
    return Method((b) {
      b.name = 'encode';
      b.returns = refer('void');
      b.annotations.add(refer('override', dartCoreUrl));
      b.requiredParameters.add(Parameter((b) {
        b.name = 'encoder';
        b.type = refer('Encoder', codableCoreUrl);
      }));
      b.body = Block((b) {
        b.statements.add(Code('''
          final keyed = encoder.encodeKeyed();
          ${node.fields.map((f) => 'keyed.${_buildEncodingInvocation(f)};').join('\n')}
          keyed.end();
        '''));
      });
    });
  }

  String _buildEncodingInvocation(CodableFieldNode node, {String? value}) {
    final suffix = node.type.isNullable ? 'OrNull' : '';
    final name = switch (node.type) {
      ObjectCodableType t when t.using != null => 'encodeObject$suffix',
      ObjectCodableType t when t.name == 'String' => 'encodeString$suffix',
      ObjectCodableType t when t.name == 'int' => 'encodeInt$suffix',
      ObjectCodableType t when t.name == 'double' => 'encodeDouble$suffix',
      ObjectCodableType t when t.name == 'num' => 'encodeNum$suffix',
      ObjectCodableType t when t.name == 'bool' => 'encodeBool$suffix',
      ObjectCodableType() => 'encodeObject$suffix',
      ListCodableType() => 'encodeIterable$suffix',
      MapCodableType() => 'encodeMap$suffix',
    };
    final args = switch (node.type) {
      ObjectCodableType t when t.using != null => ['using: ${t.using}'],
      ListCodableType t when t.itemType.using != null => ['using: ${t.itemType.using}'],
      MapCodableType t => [
          if (t.keyType.using != null) 'keyUsing: ${t.keyType.using}',
          if (t.valueType.using != null) 'valueUsing: ${t.valueType.using}'
        ],
      _ => [],
    };
    return '$name(${[
      '\'${node.key}\'',
      '${value != null ? '$value.' : ''}${node.name}',
      if (node.id case int id) 'id: $id',
      ...args
    ].join(', ')})';
  }
}
