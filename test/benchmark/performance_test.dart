import 'dart:convert';
import 'dart:typed_data';

import 'package:codable_dart/json.dart';
import 'package:codable_dart/standard.dart';
import 'package:test/test.dart';

import '../basic/model/person.dart';
import '../basic/test_data.dart';
import '../utils.dart';
import 'bench.dart';

final personDeepData = {
  ...personTestData,
  'parent': personTestData,
  'friends': List.filled(50, personTestData),
};
final personBenchData = {
  ...personDeepData,
  'friends': List.filled(200, personDeepData),
};
final personBenchJson = jsonEncode(personBenchData);
final personBenchJsonBytes = utf8.encode(personBenchJson);

void main() {
  Person p = PersonRaw.fromMapRaw(personBenchData);

  group('benchmark', tags: 'benchmark', () {
    compare(
      'STANDARD DECODING (Map -> Person)',
      self: () => p = Person.codable.fromMap(personBenchData),
      other: () => p = PersonRaw.fromMapRaw(personBenchData),
    );
    compare(
      'STANDARD ENCODING (Person -> Map)',
      self: () => p.toMap(),
      other: () => p.toMapRaw(),
    );

    print('');

    compare(
      'JSON STRING DECODING (String -> Person)',
      self: () => p = Person.codable.fromJson(personBenchJson),
      other: () => p = PersonRaw.fromJsonRaw(personBenchJson),
    );
    compare(
      'JSON STRING ENCODING (Person -> String)',
      self: () => p.toJson(),
      other: () => p.toJsonRaw(),
    );

    print('');

    compare(
      'JSON BYTE DECODING (List<int> -> Person)',
      self: () => p = Person.codable.fromJsonBytes(personBenchJsonBytes),
      other: () => p = PersonRaw.fromJsonBytesRaw(personBenchJsonBytes),
    );
    compare(
      'JSON BYTE ENCODING (Person -> List<int>)',
      self: () => p.toJsonBytes(),
      other: () => p.toJsonBytesRaw(),
    );
  });

  test('lazy benchmark', () async {
    final chunkSize = 0xFFFF;
    final data = personBenchJsonBytes;
    await benchSink('stream', (t) async {
      await chunkedAsync(data, t(CallbackSink((value) {})), chunkSize: chunkSize);
    });

    bench('sync', () {
      p = Person.codable.fromJsonBytes(data);
    }, times: 4);

    bench('single chunk', () {
      var sink = Person.codable.codec.fuse(json).fuse(utf8).decoder.startChunkedConversion(CallbackSink((person) {
        p = person;
      }));
      sink.add(data);
    });

    await benchSink('chunked', (t) async {
      var sink = Person.codable.codec.fuse(json).fuse(utf8).decoder.startChunkedConversion(CallbackSink((person) {
        p = person;
      }));
      await chunkedAsync(data, t(sink), chunkSize: chunkSize);
    });


    await benchSink('collected', (t) async {
      final builder = BytesBuilder();
      await chunkedAsync(
        data,
        t(CallbackSink((value) {
          builder.add(value);
        }, () {
          p = Person.codable.fromJsonBytes(builder.takeBytes());
        })),
        chunkSize: chunkSize,
      );
    });
  });
}
