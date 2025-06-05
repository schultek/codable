import 'dart:async';
import 'dart:convert';

import 'package:codable_dart/extended.dart';
import 'package:codable_dart/src/common/object.dart';
import 'package:codable_dart/src/extended/reference.dart';
import 'package:codable_dart/src/formats/progressive_json.dart';
import 'package:test/test.dart';

import 'model/async_value.dart';
import 'model/circle.dart';
import 'model/person.dart';
import 'utils.dart';

void main() {
  group("progressive json", () {
    group("async", () {
      test("decodes from stream", () async {
        final stream = Person.codable.fromProgressiveJsonStream(streamData(r'''
{"name": "Alice Smith", "age": 30, "parent": $1, "friends": $2, "comments": $4}
$2:[$1, $3]
$1:{"name": "Carol Smith", "age": 55, "parent": null, "friends": [$3], "comments": null}
$4:"This is the first comment."
$3:{"name": "Bob Johnson", "age": 32, "parent": null, "friends": [$0], "comments": null}
$4:"This is the second comment."
$4:"This is the third comment."
$4:"This is the fourth comment."
'''));

        final tester = AsyncTester()..addStream(0, stream);

        late Person alice;
        late List<AsyncValue<Person>> friends;
        late Person carol;
        late Person bob;

        await tester.match([
          (p) {
            alice = p;
            expect(alice.name, 'Alice Smith');
            expect(alice.age, 30);
            expect(alice.parent.isPending, isTrue);
            expect(alice.friends.isPending, isTrue);
            tester.addFuture(1, alice.parent.value as Future<Person?>);
            tester.addFuture(2, alice.friends.value as Future<List<AsyncValue<Person>>>);
            tester.addStream(4, alice.comments!);
          },
          (f) {
            friends = f;
            expect(friends.length, 2);
            expect(friends[0].isPending, isTrue);
            expect(friends[1].isPending, isTrue);
            tester.addFuture(1, friends[0].value as Future<Person>);
            tester.addFuture(3, friends[1].value as Future<Person>);
          },
          (c) {
            carol = c;
            expect(carol.name, 'Carol Smith');
            expect(alice.parent.isPending, isFalse);
            expect(alice.parent.requireValue, carol);
            expect(friends[0].isPending, isFalse);
            expect(friends[0].requireValue, carol);
          },
          'This is the first comment.',
          (b) {
            bob = b;
            expect(bob.name, 'Bob Johnson');
            expect(friends[1].isPending, isFalse);
            expect(friends[1].requireValue, bob);
            expect(bob.friends.requireValue.first.requireValue, alice);
          },
          'This is the second comment.',
          'This is the third comment.',
          'This is the fourth comment.',
        ]);
      });

      test("decodes from simple stream", () async {
        Stream<dynamic> stream = ObjectCodable().fromProgressiveJsonStream(streamData(r'''
0 
"Hello, World!" 
2 
{"test": $1} 
4 
5 
$1: 6 
$1: 7 
8 
'''));

        final tester = AsyncTester()..addStream(0, stream);

        await tester.match([
          0,
          'Hello, World!',
          2,
          (map) {
            expect(map['test'], isA<Stream>());
            tester.addStream(1, map['test'] as Stream);
          },
          4,
          5,
          (1, 6),
          (1, 7),
          8,
        ]);
      });

      test('encodes stream of data', () async {
        final bobCompleter = Completer<Person>();
        final carolCompleter = Completer<Person>();

        final streamController = StreamController<Person>();

        final encodedStream = streamController.stream.toProgressiveJson();

        var streamData = encodedStream.map(utf8.decode).join('');

        print("Sending Alice Smith...");
        streamController.add(Person(
            'Alice Smith',
            30,
            AsyncValue.future(bobCompleter.future),
            AsyncValue.value([AsyncValue.future(carolCompleter.future)]),
            Stream.fromIterable([
              'This is the first comment.',
              'This is the second comment.',
              'This is the third comment.',
              'This is the fourth comment.'
            ])));

        await Future.delayed(const Duration(milliseconds: 100));

        print("Sending Carol Smith...");
        carolCompleter.complete(Person(
            'Carol Smith',
            55,
            AsyncValue.value(null),
            AsyncValue.value([
              AsyncValue.future(bobCompleter.future),
            ]),
            null));

        await Future.delayed(const Duration(milliseconds: 100));

        print("Sending Bob Johnson...");
        bobCompleter.complete(Person(
            'Bob Johnson',
            32,
            AsyncValue.value(null),
            AsyncValue.value([
              AsyncValue.future(carolCompleter.future),
            ]),
            null));

        await Future.delayed(const Duration(milliseconds: 100));

        print("Sending Dave Brown...");
        streamController.add(Person('Dave Brown', 40, AsyncValue.value(null), AsyncValue.value([]),
            Stream.fromIterable(['This is a comment from Dave.'])));

        streamController.close();

        expect(await streamData, equals(r'''
{"name":"Alice Smith","age":30,"parent":$1,"friends":[$2],"comments":$3}
$3:"This is the first comment."
$3:"This is the second comment."
$3:"This is the third comment."
$3:"This is the fourth comment."
$2:{"name":"Carol Smith","age":55,"parent":null,"friends":[$1],"comments":null}
$1:{"name":"Bob Johnson","age":32,"parent":null,"friends":[$2],"comments":null}
{"name":"Dave Brown","age":40,"parent":null,"friends":[],"comments":$4}
$4:"This is a comment from Dave."
'''));
      });

      test('encodes stream of strings', () async {
        final streamController = StreamController<String>();

        final encodedStream = ObjectCodable().stream().toProgressiveJsonStream(streamController.stream);

        final tester = AsyncTester();
        tester.addStream(0, encodedStream.map(utf8.decode));

        streamController.add("one");
        await Future.delayed(const Duration(milliseconds: 100));
        
        streamController.add("two");
        await Future.delayed(const Duration(milliseconds: 100));
        
        streamController.add("three");
        await Future.delayed(const Duration(milliseconds: 100));
        
        streamController.add("four");
        await Future.delayed(const Duration(milliseconds: 100));

        await streamController.close();

        tester.match([
          '"one"\n',
          '"two"\n',
          '"three"\n',
          '"four"\n',
        ]);
      });

      test('encodes map with future', () async {
        final encodedStream =
            ProgressiveJsonEncoder.encode({'test': Future.delayed(Duration(milliseconds: 100), () => 'data')});

        final tester = AsyncTester();
        tester.addStream(0, encodedStream.map(utf8.decode));

        await tester.match([
          '{"test":\$1}\n',
          '\$1:"data"\n',
        ]);
      });

      test('encodes circle reference', () async {
        final completer0 = Completer();
        final future0 = completer0.future;

        final completer1 = Completer();
        final future1 = completer1.future;

        final encodedStream = ProgressiveJsonEncoder.encode(future0);

        final tester = AsyncTester();
        tester.addStream(0, encodedStream.map(utf8.decode));

        completer0.complete({'this': future1});
        completer1.complete({'that': future0});

        await tester.match([
          '{"this":\$1}\n',
          '\$1:{"that":\$0}\n',
        ]);
      });

      test('encodes self reference', () async {
        final completer0 = Completer();
        final future0 = completer0.future;

        final encodedStream = ProgressiveJsonEncoder.encode(future0);

        final tester = AsyncTester();
        tester.addStream(0, encodedStream.map(utf8.decode));

        completer0.complete({'this': future0});

        await tester.match([
          '{"this":\$0}\n',
        ]);
      });
    });

    group("sync", () {
      test('decodes circular reference sync', () async {
        final circle = CircleCodable().fromProgressiveJson(utf8.encode(r'''
{"radius": 5, "center": $1}
$1:{"radius": 10, "center": $0}
'''));

        expect(circle.radius, 5);
        expect(circle.center.radius, 10);
        expect(circle.center.center, circle);
      });

      test('decodes self reference sync', () async {
        final circle = CircleCodable().fromProgressiveJson(utf8.encode(r'''
{"radius": 5, "center": $0}
'''));

        expect(circle.radius, 5);
        expect(circle.center.radius, 5);
        expect(circle.center, circle);
      });

      test('decodes map with reference sync', () async {
        final map = ObjectCodable().fromProgressiveJson(utf8.encode(r'''
{"radius": 5, "center": $1}
$1:{"radius": 10, "center": $0}
''')) as Map<String, dynamic>;

        expect(map['radius'], 5);
        expect(map['center'], isA<Reference>());
        (map['center'] as Reference).get((v) {
          expect(v['radius'], 10);
          expect(v['center'], equals(Reference<dynamic>(map)));
        });
      });

      test('encodes circular reference sync', () async {
        final ref = Reference<Circle>.late();
        final circle = Circle(10, ref);
        ref.set(Circle(5, Reference(circle)));

        final out = circle.toProgressiveJson();
        final lines = utf8.decode(out).split('\n').where((line) => line.isNotEmpty).toList();

        expect(lines, hasLength(2));
        expect(lines[0], equals(r'{"radius":10,"center":$1}'));
        expect(lines[1], equals(r'$1:{"radius":5,"center":$0}'));
      });

      test('encodes self reference sync', () async {
        final ref = Reference<Circle>.late();
        final circle = Circle(10, ref);
        ref.set(circle);

        final out = circle.toProgressiveJson();
        final lines = utf8.decode(out).split('\n').where((line) => line.isNotEmpty).toList();

        expect(lines, hasLength(1));
        expect(lines[0], equals(r'{"radius":10,"center":$0}'));
      });
    });
  });
}
