import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:codable_dart/src/helpers/binary_tokens.dart';
import 'package:test/test.dart';

void chunked(List<int> bytes, Sink<List<int>> sink, {int chunkSize = 0xFF}) {
  int count = (bytes.length / chunkSize).ceil();

  final Uint8List buffer = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

  for (var i = 0; i < count; i++) {
    final offset = i * chunkSize;
    sink.add(Uint8List.view(buffer.buffer, buffer.offsetInBytes + offset, min(chunkSize, buffer.length - offset)));
  }

  sink.close();
}

Future<void> chunkedAsync(List<int> bytes, Sink<List<int>> sink,
    {int chunkSize = 0xFFFF, Duration delay = const Duration(microseconds: 2000)}) async {
  int count = (bytes.length / chunkSize).ceil();

  final Uint8List buffer = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  final List<Uint8List> chunks = [];

  for (var i = 0; i < count; i++) {
    final offset = i * chunkSize;
    final chunk = Uint8List.view(buffer.buffer, buffer.offsetInBytes + offset, min(chunkSize, buffer.length - offset));
    chunks.add(chunk);
  }

  final completer = Completer<void>();

  int i = 0;
  Timer.periodic(delay, (t) {
    sink.add(chunks[i]);
    i++;
    if (i >= count) {
      t.cancel();
      sink.close();
      completer.complete();
    }
  });

  await completer.future;
}

class CallbackSink<T> implements Sink<T> {
  CallbackSink(this._add, [this._done]);
  final void Function(T) _add;
  final void Function()? _done;

  @override
  void add(T data) {
    _add(data);
  }

  @override
  void close() {
    _done?.call();
  }
}

Stream<List<int>> streamData(List<int> data, {int? splitEveryN, bool Function(int)? split}) async* {
  split ??= _makeSplit(splitEveryN);
  var chunk = <int>[];
  for (final char in data) {
    chunk.add(char);
    if (split(char)) {
      // print("--- Sending chunk: ${utf8.decode(chunk).trim()}");
      yield chunk;
      chunk = <int>[];
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
  if (chunk.isNotEmpty) {
    // print("--- Sending final chunk: ${utf8.decode(chunk).trim()}");
    yield chunk;
  }
}

bool Function(int) _makeSplit(int? splitEveryN) {
  if (splitEveryN == null || splitEveryN <= 0) {
    return (int char) => char == tokenLineFeed;
  } 
  int count = 0;
  return (int char) {
    count++;
    if (count >= splitEveryN) {
      count = 0;
      return true;
    }
    return false;
  };
}

class AsyncTester {
  final _controller = StreamController<(int, Object?)>();

  final List<Future> _locks = [];

  void addStream(int tag, Stream s) {
    final lock = s.listen((value) {
      _controller.add((tag, value));
    }, onError: (error) {
      _controller.addError(error);
    }).asFuture();
    _addLock(lock);
  }

  void addFuture(int tag, Future f) {
    _addLock(f.then((value) {
      _controller.add((tag, value));
    }).catchError((error) {
      _controller.addError(error);
    }));
  }

  void _addLock(Future lock) {
    if (_controller.isClosed) {
      throw StateError('Cannot add to a closed AsyncTester.');
    }
    _locks.add(lock);
    lock.whenComplete(() {
      _locks.remove(lock);
      if (_locks.isEmpty) {
        _controller.close();
      }
    });
  }

  Future<void> match(List<dynamic> values) async {
    int n = 0;

    (int, Object?) current = (-1, Object());
    await for (final actual in _controller.stream) {
      if (identical(actual.$1, current.$1) && identical(actual.$2, current.$2)) {
        continue; // Skip duplicates
      }

      if (n >= values.length) {
        expect(n, values.length, reason: 'More values received than expected.');
      }

      var expected = values[n];

      if (expected is Function(Object?)) {
        expected(actual.$2);
      } else if (expected is Function(int, Object?)) {
        expected(actual.$1, actual.$2);
      } else if (expected is (int, Object?)) {
        expect(actual, expected);
      } else {
        expect(actual.$2, expected);
      }
      n++;
      current = actual;
    }

    if (n < values.length) {
      expect(n, values.length, reason: 'Less values received than expected.');
    }
  }
}
