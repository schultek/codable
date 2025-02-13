import 'dart:convert';

import 'package:codable/standard.dart';

import '../../core.dart';
import 'converter.dart';

typedef DecodeCallback<T> = R Function<R>(T value, Decodable<R> using);
typedef EncodeCallback<T> = T Function<R>(R value, Encodable<R> using);

abstract class CodableBaseCodec<In extends Object?, Out> extends Codec<In, Out> with CodableCompatibleCodec<In, Out> {
  const CodableBaseCodec();

  In performDecode(Out value);
  Out performEncode(In value);

  @override
  Converter<Out, In> get decoder => CallbackConverter(performDecode);

  @override
  Converter<In, Out> get encoder => CallbackConverter(performEncode);
}

abstract class CodableCodec<In, Out> extends Codec<In, Out> {
  const CodableCodec(this.codable);

  final Codable<In> codable;

  In performDecode(Out value);
  Out performEncode(In value);

  @override
  Converter<Out, In> get decoder {
    return CallbackConverter(performDecode);
  }

  @override
  Converter<In, Out> get encoder {
    return CallbackConverter(performEncode);
  }
}
