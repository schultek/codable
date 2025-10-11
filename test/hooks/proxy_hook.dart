import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';

import 'delegate.dart';

abstract mixin class ProxyHook implements Hook {
  @override
  T decode<T>(Decoder decoder, Decodable<T> decodable) {
    return decodable.decode(ProxyDecoder(decoder, this));
  }

  String visitString(String value) => value;
  String? visitStringOrNull(String? value) => value;

  @override
  void encode<T>(T value, Encoder encoder, Encodable<T> encodable) {
    encoder.encodeObject(value, using: encodable);
  }
}

class ProxyDecoder extends RecursiveDelegatingDecoder {
  ProxyDecoder(super.wrapped, this.hook);

  final ProxyHook hook;

  @override
  String decodeString() {
    return hook.visitString(super.decodeString());
  }

  @override
  String? decodeStringOrNull() {
    return hook.visitStringOrNull(super.decodeStringOrNull());
  }

  @override
  Decoder clone() {
    return ProxyDecoder(delegate.clone(), hook);
  }

  @override
  ProxyDecoder wrap(Decoder decoder) {
    return ProxyDecoder(decoder, hook);
  }
}
