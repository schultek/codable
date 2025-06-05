import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';


Stream<List<int>> streamData(String data) async* {
  final chars = data.split(RegExp(r''));
  var chunk = '';
  for (final char in chars) {
    chunk += char;
    if (char == '\n') {
      print("--- Sending chunk: ${chunk.trim()}");
      yield utf8.encode(chunk);
      chunk = '';
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
  if (chunk.isNotEmpty) {
    print("--- Sending final chunk: $chunk");
    yield utf8.encode(chunk);
  }
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
