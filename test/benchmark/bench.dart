import 'package:test/test.dart';

import '../utils.dart' show CallbackSink;

void compare(
  String name, {
  required void Function() self,
  required void Function()? other,
}) {
  test(name, () {
    print('== $name ==');
    bench('codable', self);
    if (other != null) {
      bench('baseline', other);
    }
  });
}

Future<void> benchAsync(String name, Future<void> Function() f, {int times = 10, bool sum = false}) async {
  for (var i = 0; i < times / 2; i++) {
    await f();
  }
  final s = Stopwatch()..start();
  for (var i = 0; i < times; i++) {
    await f();
  }
  s.stop();
  var time = formatTime(s.elapsedMicroseconds ~/ (sum ? 1 : times));
  print('$name: $time');
}

Future<void> benchSink(String name, Future<void> Function(Sink<T> Function<T>(Sink<T>)) run, {int times = 10}) async {
  for (var i = 0; i < times / 2; i++) {
    await run(<T>(s) => s);
  }
  final s = Stopwatch()..start();
  final sc = Stopwatch()..start();
  int t = 0, l = 0, n = 0;
  await run(<T>(sink) {
    return CallbackSink((value) {
      sc.reset();
      sink.add(value);
      t += (l = sc.elapsedMicroseconds);
      n++;
    }, () {
      sc.reset();
      sink.close();
      sc.stop();
      if (n > 0) {
        print('$name (avg chunk of $n): ${formatTime(t ~/ n)}');
        print('$name (last chunk): ${formatTime(l)}');
      }
      print('$name (closing): ${formatTime(sc.elapsedMicroseconds)}');
    });
  });
  s.stop();
  var time = formatTime(s.elapsedMicroseconds);
  print('$name: $time');
}

void bench(String name, void Function() f, {int times = 10, bool sum = false}) {
  for (var i = 0; i < times / 2; i++) {
    f();
  }
  final s = Stopwatch()..start();
  for (var i = 0; i < times; i++) {
    f();
  }
  s.stop();
  var time = formatTime(s.elapsedMicroseconds ~/ (sum ? 1 : times));
  print('$name: $time');
}

String formatTime(int microseconds) {
  if (microseconds < 5000) {
    return '$microsecondsµs';
  } else if (microseconds < 1000000) {
    return '${microseconds / 1000}ms';
  } else {
    return '${microseconds / 1000000}s';
  }
}
