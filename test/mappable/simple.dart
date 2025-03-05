import 'package:codable_dart/core.dart';

import 'mapper.dart';

abstract class SimpleMapper<T> extends Mapper<T> implements CodableMapper<T>, Codable<T> {
  const SimpleMapper();

  @override
  Codable<T> get codable => this;

  @override
  T decode(Decoder decoder);
  @override
  void encode(T value, Encoder encoder);
}

abstract class SimpleMapper1<T> extends Mapper<T> implements CodableMapper1<T> {
  const SimpleMapper1();

  @override
  Codable<T> codable<A>([Codable<A>? codableA]) => Codable.fromHandlers(
        decode: (d) => decode<A>(d, codableA),
        encode: (v, e) => encode<A>(v, e, codableA),
      );

  T decode<A>(Decoder decoder, [Decodable<A>? decodableA]);
  void encode<A>(covariant T value, Encoder encoder, [Encodable<A>? encodableA]);

  @override
  Function get typeFactory;
}

abstract class SimpleMapper2<T> extends Mapper<T> implements CodableMapper2<T> {
  const SimpleMapper2();

  @override
  Codable<T> codable<A, B>([Codable<A>? codableA, Codable<B>? codableB]) {
    return Codable.fromHandlers(
      decode: (d) => decode<A, B>(d, codableA, codableB),
      encode: (v, e) => encode<A, B>(v, e, codableA, codableB),
    );
  }

  T decode<A, B>(Decoder decoder, [Decodable<A>? decodableA, Decodable<B>? decodableB]);
  void encode<A, B>(covariant T value, Encoder encoder, [Encodable<A>? encodableA, Encodable<B>? encodableB]);

  @override
  Function get typeFactory;
}
