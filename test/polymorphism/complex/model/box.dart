import 'package:codable/core.dart';
import 'package:codable/extended.dart';

abstract class Box<T> {
  const Box(this.content);

  final T content;
}

// For testing fixed type parameters.
class LabelBox extends Box<String> {
  const LabelBox(super.content);
}

// For testing reduced type parameters.
class AnyBox extends Box {
  const AnyBox(super.content);
}

// For testing bounded type parameters.
class NumberBox<T extends num> extends Box<T> {
  const NumberBox(super.content);
}

// For testing nested type parameters.
class Boxes<T> extends Box<List<T>> {
  const Boxes(super.content);
}

// For testing additional type parameters.
class MetaBox<V, T> extends Box<T> {
  const MetaBox(this.metadata, super.content);

  final V metadata;
}

// For testing self-dependent type parameters.
class HigherOrderBox<T, B extends Box<T>> extends MetaBox<T, B> {
  const HigherOrderBox(super.metadata, super.content);
}

// Decodable implementations
// ----------------------
// For this test we only care about decoding, so we only create
// Decodable implementations instead of Codable implementations.

class BoxDecodable<T> with SuperDecodable1<Box<T>, T> {
  const BoxDecodable();

  @override
  String get discriminatorKey => 'type';

  @override
  List<Discriminator<Box>> get discriminators => [
        Discriminator.arg1<LabelBox>('label', <_>(_) {
          return LabelBoxDecodable();
        }),
        Discriminator.arg1<AnyBox>('any', <_>(_) {
          return AnyBoxDecodable();
        }),
        Discriminator.arg1Bounded<NumberBox, num>('number', <T extends num>(Decodable<T>? decodableT) {
          return NumberBoxDecodable<T>().use(decodableT);
        }),
        Discriminator.arg1Bounded<Boxes, List>('boxes', <T extends List>(Decodable<T>? decodableLT) {
          if (decodableLT case ComposedDecodable1 d) {
            return d.extract<Decodable<Boxes>>(<T>(decodableT) => BoxesDecodable<T>().use(decodableT));
          } else {
            return BoxesDecodable<dynamic>();
          }
        }),
        Discriminator.arg1<MetaBox>('meta', <T>(decodableT) {
          return MetaBoxDecodable<dynamic, T>().use(null, decodableT);
        }),
        ...Discriminator.chain1<MetaBox>(MetaBoxDecodable().discriminators, <T>(d, decodableT) {
          return d.resolve2<MetaBox<dynamic, T>, dynamic, T>(null, decodableT);
        }),
      ];
}

class LabelBoxDecodable implements Decodable<LabelBox> {
  @override
  LabelBox decode(Decoder decoder) {
    final mapped = decoder.decodeMapped();
    return LabelBox(
      mapped.decodeString('content'),
    );
  }
}

class AnyBoxDecodable implements Decodable<AnyBox> {
  @override
  AnyBox decode(Decoder decoder, [Decodable<dynamic>? decodableT]) {
    final mapped = decoder.decodeMapped();
    return AnyBox(
      mapped.decodeDynamic('content'),
    );
  }
}

class NumberBoxDecodable<T extends num> implements Decodable1<NumberBox<T>, T> {
  @override
  NumberBox<T> decode(Decoder decoder, [Decodable<T>? decodableT]) {
    final mapped = decoder.decodeMapped();
    return NumberBox<T>(
      decodableT != null //
          ? mapped.decodeObject('content', using: decodableT)
          : mapped.decodeDynamic('content') as T,
    );
  }
}

class BoxesDecodable<T> implements Decodable1<Boxes<T>, T> {
  @override
  Boxes<T> decode(Decoder decoder, [Decodable<T>? decodableT]) {
    final mapped = decoder.decodeMapped();
    return Boxes<T>(
      mapped.decodeList('content', using: decodableT),
    );
  }
}

class MetaBoxDecodable<V, T> with SuperDecodable2<MetaBox<V, T>, V, T> {
  @override
  String? get discriminatorKey => 'type';

  @override
  List<Discriminator<MetaBox>> get discriminators => [
        Discriminator.arg2Bounded<HigherOrderBox, dynamic, Box>(
          'higher_order',
          <T, B extends Box<T>>(Decodable<T>? decodableT, Decodable<B>? decodableB) {
            return HigherOrderBoxDecodable<T, B>().use(decodableT, decodableB);
          },
        ),
      ];

  @override
  MetaBox<V, T> decodeFallback(Decoder decoder, [Decodable<V>? decodableV, Decodable<T>? decodableT]) {
    final mapped = decoder.decodeMapped();
    return MetaBox<V, T>(
      decodableV != null //
          ? mapped.decodeObject('metadata', using: decodableV)
          : mapped.decodeDynamic('metadata') as V, //
      decodableT != null //
          ? mapped.decodeObject('content', using: decodableT)
          : mapped.decodeDynamic('content') as T,
    );
  }
}

class HigherOrderBoxDecodable<T, B extends Box<T>> implements Decodable2<HigherOrderBox<T, B>, T, B> {
  @override
  HigherOrderBox<T, B> decode(Decoder decoder, [Decodable<T>? decodableT, Decodable<B>? decodableB]) {
    final mapped = decoder.decodeMapped();
    return HigherOrderBox<T, B>(
      decodableT != null //
          ? mapped.decodeObject('metadata', using: decodableT)
          : mapped.decodeDynamic('metadata') as T,
      decodableB != null //
          ? mapped.decodeObject('content', using: decodableB)
          : mapped.decodeObject<Box<T>>('content', using: BoxDecodable<T>()) as B,
    );
  }
}

// For testing nested decoding with explicit decodes.
class Data {
  const Data(this.value);

  final dynamic value;

  static const Decodable<Data> decodable = DataDecodable();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Data && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Data{value: $value}';
}

class DataDecodable implements Decodable<Data> {
  const DataDecodable();

  @override
  Data decode(Decoder decoder) {
    return Data(decoder.decodeMapped().decodeDynamic('value'));
  }
}
