part of 'box.dart';

/* CAUSING ANALYZER CRASHES

augment class Box<T> implements SelfEncodable {
  const Box(this.content);

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    encoder.encodeKeyed()
      ..encodeObject('content', content, using: encodableT)
      ..end();
  }
}



// For testing fixed type parameters.
augment class LabelBox {
  @override
  void encode(Encoder encoder, [_]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'label')
      ..encodeString('content', content)
      ..end();
  }
}

// For testing reduced type parameters.
augment class AnyBox {
  @override
  void encode(Encoder encoder, [_]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'any')
      ..encodeObject('content', content)
      ..end();
  }
}

// For testing bounded type parameters.
augment class NumberBox<T extends num> {
  @override
  void encode(Encoder encoder, [_]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'number')
      ..encodeNum('content', content)
      ..end();
  }
}

// For testing nested type parameters.
augment class Boxes<T> {
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


CAUSING ANALYZER CRASHES */

extension BoxEncodableExtension<T> on Box<T> {
  SelfEncodable use([Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, encodableT));
  }
}

extension BoxesEncodableExtension<T> on Boxes<T> {
  SelfEncodable use([Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, null, encodableT));
  }
}


/* USING THIS AUGMENT does not cause crash but does cause the weird error below on MetaBoxEncodableExtension

// For testing additional type parameters.
augment class MetaBox<V, T> {
  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT, Encodable<V>? encodableV]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'meta')
      ..encodeObject('metadata', metadata, using: encodableV)
      ..encodeObject('content', content, using: encodableT)
      ..end();
  }
}

CAUSES ERROR BELOW */

/* FOLLOWING GETS ERROR:

The argument type 'Encodable<T>?' can't be assigned to the parameter type 'Encodable<T>?'. dartargument_type_not_assignable
interface.dart(89, 26): Encodable is defined in C:\src\codable_workspace\packages\codable\lib\src\core\interface.dart
interface.dart(89, 26): Encodable is defined in C:\src\codable_workspace\packages\codable\lib\src\core\interface.dart
[Encodable<T>? encodableT]
Type: Encodable<T>?

when using augment version

*/

extension MetaBoxEncodableExtension<V, T> on MetaBox<V, T> {
  SelfEncodable use([Encodable<V>? encodableV, Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, encodableT, encodableV));
  }
}

/* WE GET ANALYZER ERROR:class
The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
Try changing the augmentation to match the declaration type parameters.dart(augmentation_type_parameter_bound)
T
test/augment_test/polymorphism/complex/model/box.dart




// For testing self-dependent type parameters.
//augment class HigherOrderBox<T, B extends Box<T>> {
augment class HigherOrderBox<T, B extends Box<T>> {
  @override
  void encode(Encoder encoder, [Encodable<B>? encodableB, Encodable<T>? encodableT]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'higher_order')
      ..encodeObject('metadata', metadata, using: encodableT)
      ..encodeObject('content', content, using: encodableB)
      ..end();
  }
}

END VERSION THAT CREATES ERROR WHEN using augment */


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
augment class Data implements SelfEncodable {
  const Data(this.value);

  static const Codable<Data> codable = DataCodable();

  @override
  void encode(Encoder encoder) {
    encoder.encodeKeyed()
      ..encodeObject('value', value)
      ..end();
  }
}

// Additional augmentation for equatable
augment class Data {
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Data && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

// Additional augmentation for toString
augment class Data {
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
