import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';

abstract class Box<T> implements SelfEncodable {
  const Box(this.content);

  final T content;

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    encoder.encodeKeyed()
      ..encodeObject('content', content, using: encodableT)
      ..end();
  }
}

extension BoxEncodableExtension<T> on Box<T> {
  SelfEncodable use([Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, encodableT));
  }
}

// For testing fixed type parameters.
class LabelBox extends Box<String> {
  const LabelBox(super.content);

  @override
  void encode(Encoder encoder, [_]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'label')
      ..encodeString('content', content)
      ..end();
  }
}

// For testing reduced type parameters.
class AnyBox extends Box {
  const AnyBox(super.content);

  @override
  void encode(Encoder encoder, [_]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'any')
      ..encodeObject('content', content)
      ..end();
  }
}

// For testing bounded type parameters.
class NumberBox<T extends num> extends Box<T> {
  const NumberBox(super.content);

  @override
  void encode(Encoder encoder, [_]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'number')
      ..encodeNum('content', content)
      ..end();
  }
}

// For testing nested type parameters.
class Boxes<T> extends Box<List<T>> {
  const Boxes(super.content);

  @override
  void encode(Encoder encoder, [Encodable<List<T>>? encodableT, Encodable<T>? encodableT2]) {
    final keyed = encoder.encodeKeyed();
    keyed.encodeString('type', 'boxes');
    if (encodableT2 == null && encodableT != null) {
      keyed.encodeObject('content', content, using: encodableT);
    } else {
      keyed.encodeIterable('content', content, using: encodableT2);
    }
    keyed.end();
  }
}

extension BoxesEncodableExtension<T> on Boxes<T> {
  SelfEncodable use([Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, null, encodableT));
  }
}

// For testing additional type parameters.
class MetaBox<V, T> extends Box<T> {
  const MetaBox(this.metadata, super.content);

  final V metadata;

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT, Encodable<V>? encodableV]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'meta')
      ..encodeObject('metadata', metadata, using: encodableV)
      ..encodeObject('content', content, using: encodableT)
      ..end();
  }
}

extension MetaBoxEncodableExtension<V, T> on MetaBox<V, T> {
  SelfEncodable use([Encodable<V>? encodableV, Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, encodableT, encodableV));
  }
}

// For testing self-dependent type parameters.
class HigherOrderBox<T, B extends Box<T>> extends MetaBox<T, B> {
  const HigherOrderBox(super.metadata, super.content);

  @override
  void encode(Encoder encoder, [Encodable<B>? encodableB, Encodable<T>? encodableT]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'higher_order')
      ..encodeObject('metadata', metadata, using: encodableT)
      ..encodeObject('content', content, using: encodableB)
      ..end();
  }
}

// Codable implementations
// =======================

class BoxCodable<T> with SuperDecodable1<Box<T>, T> implements Codable1<Box<T>, T> {
  const BoxCodable();

  @override
  String get discriminatorKey => 'type';

  @override
  List<Discriminator<Box>> get discriminators => [
        Discriminator.arg1<LabelBox>('label', <_>(_) {
          return LabelBoxCodable();
        }),
        Discriminator.arg1<AnyBox>('any', <_>(_) {
          return AnyBoxCodable();
        }),
        Discriminator.arg1Bounded<NumberBox, num>('number', <T extends num>(Decodable<T>? decodableT) {
          return NumberBoxCodable<T>().useDecodable(decodableT);
        }),
        Discriminator.arg1Bounded<Boxes, List>('boxes', <T extends List>(Decodable<T>? decodableLT) {
          if (decodableLT case ComposedDecodable1 d) {
            return d.extract<Decodable<Boxes>>(<T>(decodableT) => BoxesCodable<T>().useDecodable(decodableT));
          } else {
            return BoxesCodable<dynamic>();
          }
        }),
        Discriminator.arg1<MetaBox>('meta', <T>(decodableT) {
          return MetaBoxCodable<dynamic, T>().useDecodable(null, decodableT);
        }),
        ...Discriminator.chain1<MetaBox>(MetaBoxCodable().discriminators, <T>(d, decodableT) {
          return d.resolve2<MetaBox<dynamic, T>, dynamic, T>(null, decodableT);
        }),
      ];

  @override
  void encode(Box<T> value, Encoder encoder, [Encodable<T>? encodableT]) {
    value.encode(encoder, encodableT);
  }
}

class LabelBoxCodable implements Codable<LabelBox> {
  @override
  LabelBox decode(Decoder decoder) {
    final mapped = decoder.decodeMapped();
    return LabelBox(
      mapped.decodeString('content'),
    );
  }

  @override
  void encode(LabelBox value, Encoder encoder) {
    value.encode(encoder);
  }
}

class AnyBoxCodable implements Codable<AnyBox> {
  @override
  AnyBox decode(Decoder decoder, [Decodable<dynamic>? decodableT]) {
    final mapped = decoder.decodeMapped();
    return AnyBox(
      mapped.decodeObject('content'),
    );
  }

  @override
  void encode(AnyBox value, Encoder encoder) {
    value.encode(encoder);
  }
}

class NumberBoxCodable<T extends num> implements Codable1<NumberBox<T>, T> {
  @override
  NumberBox<T> decode(Decoder decoder, [Decodable<T>? decodableT]) {
    final mapped = decoder.decodeMapped();
    return NumberBox<T>(
      mapped.decodeObject('content', using: decodableT),
    );
  }

  @override
  void encode(NumberBox<T> value, Encoder encoder, [Encodable<T>? encodableT]) {
    value.encode(encoder, encodableT);
  }
}

class BoxesCodable<T> implements Codable1<Boxes<T>, T> {
  @override
  Boxes<T> decode(Decoder decoder, [Decodable<T>? decodableT]) {
    final mapped = decoder.decodeMapped();
    return Boxes<T>(
      mapped.decodeList('content', using: decodableT),
    );
  }

  @override
  void encode(Boxes<T> value, Encoder encoder, [Encodable<T>? encodableT]) {
    value.encode(encoder, null, encodableT);
  }
}

class MetaBoxCodable<V, T> with SuperDecodable2<MetaBox<V, T>, V, T> implements Codable2<MetaBox<V, T>, V, T> {
  @override
  String? get discriminatorKey => 'type';

  @override
  List<Discriminator<MetaBox>> get discriminators => [
        Discriminator.arg2Bounded<HigherOrderBox, dynamic, Box>(
          'higher_order',
          <T, B extends Box<T>>(Decodable<T>? decodableT, Decodable<B>? decodableB) {
            return HigherOrderBoxCodable<T, B>().useDecodable(decodableT, decodableB);
          },
        ),
      ];

  @override
  MetaBox<V, T> decodeFallback(Decoder decoder, [Decodable<V>? decodableV, Decodable<T>? decodableT]) {
    final mapped = decoder.decodeMapped();
    return MetaBox<V, T>(
      mapped.decodeObject('metadata', using: decodableV),
      mapped.decodeObject('content', using: decodableT),
    );
  }

  @override
  void encode(MetaBox<V, T> value, Encoder encoder, [Encodable<V>? encodableV, Encodable<T>? encodableT]) {
    value.encode(encoder, encodableT, encodableV);
  }
}

class HigherOrderBoxCodable<T, B extends Box<T>> implements Codable2<HigherOrderBox<T, B>, T, B> {
  @override
  HigherOrderBox<T, B> decode(Decoder decoder, [Decodable<T>? decodableT, Decodable<B>? decodableB]) {
    final mapped = decoder.decodeMapped();
    return HigherOrderBox<T, B>(
      mapped.decodeObject('metadata', using: decodableT),
      decodableB != null //
          ? mapped.decodeObject('content', using: decodableB)
          : mapped.decodeObject<Box<T>>('content', using: BoxCodable<T>()) as B,
    );
  }

  @override
  void encode(HigherOrderBox<T, B> value, Encoder encoder, [Encodable<T>? encodableT, Encodable<B>? encodableB]) {
    value.encode(encoder, encodableB, encodableT);
  }
}

// For testing nested types.
class Data implements SelfEncodable {
  const Data(this.value);

  final dynamic value;

  static const Codable<Data> codable = DataCodable();

  @override
  void encode(Encoder encoder) {
    encoder.encodeKeyed()
      ..encodeObject('value', value)
      ..end();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Data && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Data{value: $value}';
}

class DataCodable extends SelfCodable<Data> {
  const DataCodable();

  @override
  Data decode(Decoder decoder) {
    return Data(decoder.decodeMapped().decodeObject('value'));
  }
}
