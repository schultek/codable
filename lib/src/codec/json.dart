import 'dart:convert' hide JsonDecoder, JsonEncoder;

import 'package:codable/core.dart';

import '../../json.dart';
import 'codec.dart';

class JsonCodableCodec extends CodableCodec<String> {
  const JsonCodableCodec();

  @override
  T performDecode<T>(String value, Decodable<T> using) {
    return JsonDecoder.decode(utf8.encode(value), using);
  }

  @override
  String performEncode<T>(T value, Encodable<T> using) {
    return utf8.decode(JsonEncoder.encode(value, using: using));
  }

  @override
  Codec<Object?, R> fuse<R>(Codec<String, R> other) {
    if (other is Utf8Codec) {
      return _JsonBytesCodableCodec() as Codec<Object?, R>;
    } else {
      return super.fuse(other);
    }
  }
}

class _JsonBytesCodableCodec extends CodableCodec<List<int>> {
  const _JsonBytesCodableCodec();

  @override
  T performDecode<T>(List<int> value, Decodable<T> using) {
    return JsonDecoder.decode(value, using);
  }

  @override
  List<int> performEncode<T>(T value, Encodable<T> using) {
    return JsonEncoder.encode(value, using: using);
  }
}
