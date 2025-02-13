
import 'dart:convert';

import 'package:codable/msgpack.dart';
import 'package:codable/src/core/interface.dart';

import 'codec.dart';
import 'converter.dart';

const MsgPackCodec msgPack = MsgPackCodec();

class MsgPackCodec extends CodableBaseCodec<Object?, List<int>> {
  const MsgPackCodec();

  @override
  Object? performDecode(List<int> value) {
    return MsgPackDecoder.decode(value, const ObjectCodable());
  }

  @override
  List<int> performEncode(Object? value) {
    return MsgPackEncoder.encode(value, using: const ObjectCodable());
  }
  
  @override
  Codec<T, List<int>>? fuseCodable<T>(Codable<T> codable) {
    return MsgPackCodableCodec<T>(codable);
  }

}

class MsgPackCodableCodec<In> extends CodableCodec<In, List<int>> {
 const MsgPackCodableCodec(super.codable);

  @override
  In performDecode(List<int> value) {
    return MsgPackDecoder.decode(value, codable);
  }

  @override
  List<int> performEncode(In value) {
    return MsgPackEncoder.encode(value, using: codable);
  }

}