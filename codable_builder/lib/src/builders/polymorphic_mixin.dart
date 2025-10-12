part of 'codable_builder.dart';

abstract mixin class PolymorphicMixin implements CodableBuilder {
  Method _buildDiscriminatorKey(CodableClassNode node) {
    return Method((b) {
      b.name = 'discriminatorKey';
      b.type = MethodType.getter;
      b.returns = refer('String', dartCoreUrl);
      b.annotations.add(refer('override', dartCoreUrl));
      b.lambda = true;
      b.body = Code('\'type\'');
    });
  }

  Method _buildDiscriminators(CodableClassNode node) {
    return Method((b) {
      b.name = 'discriminators';
      b.type = MethodType.getter;
      b.returns = TypeReference((b) {
        b.symbol = 'List';
        b.url = dartCoreUrl;
        b.types.add(TypeReference((b) {
          b.symbol = 'Discriminator';
          b.url = codableExtendedUrl;
          b.types.add(refer(node.name, node.url));
        }));
      });
      b.annotations.add(refer('override', dartCoreUrl));
      b.lambda = true;
      b.body = Code.scope((s) {
        final buffer = StringBuffer();
        buffer.writeln('[\n');

        for (final sub in node.subclasses) {
          final ref = refer(sub.name, sub.url);
          final val = '\'${sub.name.toLowerCase()}\'';

          if (node.typeParameters.isEmpty) {
            buffer.write('  Discriminator<${s(ref)}>($val, ${sub.name}Codable.new),\n');
          } else if (node.typeParameters.length <= 2) {
            final bounded = sub.typeParameterMapping.any((m) => m.derivedIndex != -1 && m.bound != null);

            if (!bounded) {
              buffer.write(
                  '  Discriminator.arg${node.typeParameters.length}<${s(ref)}>($val, <${node.typeParameters.map((t) => t.name).join(', ')}>(');
            } else {
              final bounds = node.typeParameters.indexed.map((v) {
                final m = sub.typeParameterMapping.where((m) => m.derivedIndex == v.$1).firstOrNull;
                return m != null ? s(m.bound!.reference) : 'dynamic';
              }).toList();
              buffer.write(
                  '  Discriminator.arg1Bounded<${s(ref)}, ${bounds.join(', ')}>($val, <${node.typeParameters.indexed.map((v) => '${v.$2.name} extends ${bounds[v.$1]}').join(', ')}>(');
            }
            buffer.write(
                '${node.typeParameters.map((t) => '${s(refer('Decodable', codableCoreUrl))}<${t.name}>? decodable${t.name}').join(', ')}) {\n');

            buffer.write('    return ');
            if (sub.typeParameterMapping.isEmpty) {
              buffer.write('${sub.name}Codable();\n');
            } else {
              buffer.write(
                  '${sub.name}Codable<${sub.typeParameterMapping.map((m) => m.derivedIndex != -1 ? node.typeParameters[m.derivedIndex].name : 'dynamic').join(', ')}>.of(');
              buffer.write(sub.typeParameterMapping.where((m) => m.derivedIndex != -1).map((m) {
                return 'decodable${m.name}: decodable${node.typeParameters[m.derivedIndex].name}';
              }).join(', '));
              buffer.write(');\n');
            }

            buffer.write('  }),\n');
          }

          if (sub.chainable) {
            // TODO add chainable discriminators
          }
        }

        buffer.writeln('  ]');
        return buffer.toString();
      });
    });
  }
}
