import 'package:codable/msgpack.dart';
import 'package:codable/src/core/interface.dart';

import 'codec.dart';

const MsgPackCodec msgPack = MsgPackCodec();

class MsgPackCodec extends CodableCodec<List<int>> {
  const MsgPackCodec();

  @override
  T performDecode<T>(List<int> value, {required Decodable<T> using}) {
    return MsgPackDecoder.decode(value, using);
  }

  @override
  List<int> performEncode<T>(T value, {required Encodable<T> using}) {
    return MsgPackEncoder.encode(value, using: using);
  }
}
