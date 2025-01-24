import 'dart:convert';
import 'dart:typed_data';

import 'package:codable/core.dart';
import 'package:codable/csv.dart';

import 'converter.dart';

class CsvCodableCodec<T, C extends Codable<T>> extends Codec<List<T>, String> {
  final C codable;

  CsvCodableCodec(this.codable);

  @override
  Converter<String, List<T>> get decoder =>
      CallbackConverter((input) => CsvDecoder.decode(input, codable));

  @override
  Converter<List<T>, String> get encoder =>
      CallbackConverter((input) => CsvEncoder.encode<T>(input, using: codable));

  @override
  Codec<List<T>, To> fuse<To>(Codec<String, To> other) {
    if (other is Utf8Codec) {
      return _CsvUtf8CodableCodec<T, Codable<T>>(codable) as Codec<List<T>, To>;
    }
    return super.fuse<To>(other);
  }
}

class _CsvUtf8CodableCodec<T, C extends Codable<T>>
    extends Codec<List<T>, Uint8List> {
  final C codable;

  _CsvUtf8CodableCodec(this.codable);

  @override
  Converter<Uint8List, List<T>> get decoder =>
      CallbackConverter((input) => CsvDecoder.decodeBytes(input, codable));

  @override
  Converter<List<T>, Uint8List> get encoder => CallbackConverter(
      (input) => CsvEncoder.encodeBytes<T>(input, using: codable));
}

extension CsvCodec<T> on Codable<T> {
  Codec<List<T>, String> get csvCodec => CsvCodableCodec<T, Codable<T>>(this);
}
