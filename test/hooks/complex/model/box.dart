import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';

import '../../proxy_hook.dart';

abstract class Box<T> implements SelfEncodable {
  const Box(this.content);

  final T content;

  static Codable<Box<T>> codable<T>([Codable<T>? codable]) => BoxCodable(codable);

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

class BoxHook with ProxyHook {
  const BoxHook();
}

class BoxCodable<T> extends CodableWithHooks<Box<T>> {
  BoxCodable([Codable<T>? codable]) : super(_BoxCodable(codable), const BoxHook());

  BoxCodable.of({Encodable<T>? encodable, Decodable<T>? decodable})
      : super(_BoxCodable.of(encodable: encodable, decodable: decodable), const BoxHook());
}

class _BoxCodable<T> with SuperDecodable<Box<T>> implements Codable<Box<T>>, ComposedDecodable1<Box<T>> {
  const _BoxCodable([Codable<T>? codable])
      : encodable = codable,
        decodable = codable;

  const _BoxCodable.of({this.encodable, this.decodable});

  final Encodable<T>? encodable;
  final Decodable<T>? decodable;

  @override
  String get discriminatorKey => 'type';

  @override
  List<Discriminator<Box>> get discriminators => [
        Discriminator.arg1Bounded<NumberBox, num>('number', <T extends num>(Decodable<T>? decodableT) {
          return NumberBoxCodable<T>.of(decodable: decodableT);
        }),
      ];

  @override
  Decodable<Box<T>> resolveDiscriminator(Discriminator discriminator) {
    return discriminator.resolve1<Box<T>, T>(decodable);
  }

  @override
  void encode(Box<T> value, Encoder encoder) {
    value.encode(encoder, encodable);
  }

  @override
  R extract<R>(R Function<A>(Decodable<A>? decodableA) fn) {
    return fn<T>(decodable);
  }
}

class NumberBoxCodable<T extends num> extends CodableWithHooks<NumberBox<T>> {
  NumberBoxCodable([Codable<T>? codable]) : super(_NumberBoxCodable(codable), const BoxHook());

  NumberBoxCodable.of({Encodable<T>? encodable, Decodable<T>? decodable})
      : super(_NumberBoxCodable.of(encodable: encodable, decodable: decodable), const BoxHook());

  NumberBoxCodable.inherited([Codable<T>? codable]) : super.inherited(_NumberBoxCodable(codable), const BoxHook());

  NumberBoxCodable.inheritedOf({Encodable<T>? encodable, Decodable<T>? decodable})
      : super.inherited(_NumberBoxCodable.of(encodable: encodable, decodable: decodable), const BoxHook());
}

class _NumberBoxCodable<T extends num> implements Codable<NumberBox<T>> {
  const _NumberBoxCodable([Codable<T>? codable])
      : encodable = codable,
        decodable = codable;

  const _NumberBoxCodable.of({this.encodable, this.decodable});

  final Encodable<T>? encodable;
  final Decodable<T>? decodable;

  @override
  NumberBox<T> decode(Decoder decoder) {
    final mapped = decoder.decodeMapped();
    return NumberBox<T>(
      mapped.decodeObject('content', using: decodable),
    );
  }

  @override
  void encode(NumberBox<T> value, Encoder encoder) {
    value.encode(encoder, encodable);
  }
}
