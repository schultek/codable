import 'dart:convert' hide json;

import 'package:codable_dart/core.dart';
import 'package:codable_dart/src/codec/codec.dart';
import 'package:codable_dart/standard.dart';

import '../../json.dart';


class _StandardCodableCodec<T, C extends Codable<T>> extends CodableCodec<T, Object?> {
  const _StandardCodableCodec(C codable) : super(const _StandardDelegate(), codable);

  @override
  Codec<T, R> fuse<R>(Codec<Object?, R> other) {
    if (other is JsonCodec) {
      return (json as CodableCodec<Object?, String>).fuseCodable(codable) as Codec<T, R>;
    } else if (other is CodableCompatibleCodec<dynamic, R>) {
      return other.fuseCodable(codable) ?? super.fuse(other);
    } else {
      return super.fuse(other);
    }
  }
}

class _StandardDelegate extends CodableCodecDelegate<Object?> {
  const _StandardDelegate();

  @override
  T decode<T>(Object? input, Decodable<T> using) => StandardDecoder.decode(input, using: using);

  @override
  Object? encode<T>(T input, Encodable<T> using) => StandardEncoder.encode(input, using: using);
}

abstract interface class CodableCompatibleCodec<In, Out> implements Codec<In, Out> {
  Codec<T, Out>? fuseCodable<T>(Codable<T> codable);
}

extension StandardCodec<T> on Codable<T> {
  Codec<T, Object?> get codec => _StandardCodableCodec<T, Codable<T>>(this);
}
