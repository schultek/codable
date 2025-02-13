import 'dart:convert' hide JsonDecoder, JsonEncoder;

import '../../json.dart';
import 'codec.dart';

class JsonCodableCodec<T> extends CodableCodec<T, String> {
  const JsonCodableCodec(super.codable);

  @override
  T performDecode(String value) {
    return JsonDecoder.decode(utf8.encode(value), codable);
  }

  @override
  String performEncode(T value) {
    return utf8.decode(JsonEncoder.encode(value, using: codable));
  }

  @override
  Codec<T, R> fuse<R>(Codec<String, R> other) {
    if (other is Utf8Codec) {
      return _JsonBytesCodableCodec<T>(codable) as Codec<T, R>;
    } else {
      return super.fuse(other);
    }
  }
}

class _JsonBytesCodableCodec<T> extends CodableCodec<T, List<int>> {
  const _JsonBytesCodableCodec(super.codable);

  @override
  T performDecode(List<int> value) {
    return JsonDecoder.decode(value, codable);
  }

  @override
  List<int> performEncode(T value) {
    return JsonEncoder.encode(value, using: codable);
  }
}
