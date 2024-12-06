import 'package:codable/common.dart';
import 'package:codable/core.dart';
import 'package:codable/extended.dart';
import 'package:codable/standard.dart';
import 'package:test/test.dart';

import 'model/box.dart';

final labelBoxMap = {'type': 'label', 'content': "some label"};
final anyBoxMap = {
  'name': 'any',
  'content': {'value': 'some value'}
};
final numberBoxMap = {'type': 'number', 'content': 2.5};
final boxesMap = {
  'type': 'boxes',
  'content': [
    {'value': 1},
    {'value': 2},
    {'value': 3}
  ]
};
final metaBoxMap = {'type': 'meta', 'metadata': 2, 'content': 'test'};
final metaDataBoxMap = {
  'type': 'meta',
  'metadata': 2,
  'content': {'value': 'test'}
};
final higherOrderLabelBoxMap = {'type': 'higher_order', 'metadata': 'some metadata', 'content': labelBoxMap};
final higherOrderNumberBoxMap = {'type': 'higher_order', 'metadata': 100, 'content': numberBoxMap};

void main() {
  group('complex polymorphism', () {
    test('decodes LabelBox as Box<String>', () {
      final Decodable<Box<String>> boxDecodable = BoxDecodable<String>();
      final Box<String> box = boxDecodable.fromMap(labelBoxMap);
      expect(box, isA<LabelBox>());
      expect(box.content, 'some label');
    });

    test('decodes LabelBox as Box<dynamic>', () {
      final Decodable<Box<dynamic>> boxDecodable = BoxDecodable<dynamic>();
      final Box<dynamic> box = boxDecodable.fromMap(labelBoxMap);
      expect(box, isA<LabelBox>());
      expect(box.content, 'some label');
    });

    test('decodes LabelBox not as Box<int>', () {
      final Decodable<Box<int>> boxDecodable = BoxDecodable<int>();
      expect(() {
        // ignore: unused_local_variable
        final Box<int> box = boxDecodable.fromMap(labelBoxMap);
      }, throwsA('Cannot resolve discriminator to decode type Box<int>. Got LabelBoxDecodable.'));
    });

    test('decodes AnyBox as Box<dynamic>', () {
      final Decodable<Box<dynamic>> boxDecodable = BoxDecodable<dynamic>();
      final Box<dynamic> box = boxDecodable.fromMap(anyBoxMap);
      expect(box, isA<AnyBox>());
      expect(box.content, {'value': 'some value'});
    });

    test('decodes NumberBox as Box<num>', () {
      final Decodable<Box<num>> boxDecodable = BoxDecodable<num>();
      final Box<num> box = boxDecodable.fromMap(numberBoxMap);
      expect(box, isA<NumberBox>());
      expect(box.content, 2.5);
    });

    test('decodes NumberBox as Box<dynamic>', () {
      final Decodable<Box<dynamic>> boxDecodable = BoxDecodable<dynamic>();
      final Box<dynamic> box = boxDecodable.fromMap(numberBoxMap);
      expect(box, isA<NumberBox>());
      expect(box.content, 2.5);
    });

    test('decodes Boxes as Box<List<dynamic>>', () {
      final Decodable<Box<List>> boxDecodable = BoxDecodable<List>();
      final Box<List> box = boxDecodable.fromMap(boxesMap);
      expect(box, isA<Boxes<dynamic>>());
      expect(box.content, [
        {'value': 1},
        {'value': 2},
        {'value': 3}
      ]);
    });

    test('decodes Boxes as Box<List<Data>> with explicit child decode', () {
      final Decodable<Box<List<Data>>> boxDecodable = BoxDecodable<List<Data>>().use(Data.decodable.list());
      final Box<List<Data>> box = boxDecodable.fromMap(boxesMap);
      expect(box, isA<Boxes<Data>>());
      expect(box.content, [
        Data(1),
        Data(2),
        Data(3),
      ]);
    });

    test('decodes MetaBox as Box<dynamic>', () {
      final Decodable<Box<dynamic>> boxDecodable = BoxDecodable<dynamic>();
      final Box<dynamic> box = boxDecodable.fromMap(metaBoxMap);
      expect(box, isA<MetaBox<dynamic, dynamic>>());
      expect((box as MetaBox).metadata, 2);
      expect(box.content, 'test');
    });

    test('decodes MetaBox as Box<String> ', () {
      final Decodable<Box<String>> boxDecodable = BoxDecodable<String>();
      final Box<String> box = boxDecodable.fromMap(metaBoxMap);
      expect(box, isA<MetaBox<dynamic, String>>());
      expect((box as MetaBox).metadata, 2);
      expect(box.content, 'test');
    });

    test('decodes MetaBox as Box<Data> with explicit child decode', () {
      final Decodable<Box<Data>> boxDecodable = BoxDecodable<Data>().use(Data.decodable);
      final Box<Data> box = boxDecodable.fromMap(metaDataBoxMap);
      expect(box, isA<MetaBox<dynamic, Data>>());
      expect((box as MetaBox).metadata, 2);
      expect(box.content, Data('test'));
    });

    test('decodes HigherOrderBox as Box<dynamic>', () {
      final Decodable<Box<dynamic>> boxDecodable = BoxDecodable<dynamic>();
      final Box<dynamic> box = boxDecodable.fromMap(higherOrderLabelBoxMap);
      expect(box, isA<HigherOrderBox<dynamic, Box>>());
      expect((box as HigherOrderBox).metadata, 'some metadata');
      expect(box.content, isA<LabelBox>());
      expect(box.content.content, 'some label');
    });

    test('decodes HigherOrderBox as Box<Box<dynamic>>', () {
      final Decodable<Box<Box<dynamic>>> boxDecodable = BoxDecodable<Box<dynamic>>();
      final Box<Box<dynamic>> box = boxDecodable.fromMap(higherOrderLabelBoxMap);
      expect(box, isA<HigherOrderBox<dynamic, Box>>());
      expect((box as HigherOrderBox).metadata, 'some metadata');
      expect(box.content, isA<LabelBox>());
      expect(box.content.content, 'some label');
    });

    test('decodes HigherOrderBox as Box<Box<String>>', () {
      final Decodable<Box<Box<String>>> boxDecodable = BoxDecodable<Box<String>>();
      final Box<Box<String>> box = boxDecodable.fromMap(higherOrderLabelBoxMap);
      expect(box, isA<HigherOrderBox<dynamic, Box<String>>>());
      expect((box as HigherOrderBox).metadata, 'some metadata');
      expect(box.content, isA<LabelBox>());
      expect(box.content.content, 'some label');
    });

    test('decodes HigherOrderBox as Box<LabelBox>', () {
      final Decodable<Box<LabelBox>> boxDecodable = BoxDecodable<LabelBox>();
      final Box<LabelBox> box = boxDecodable.fromMap(higherOrderLabelBoxMap);
      expect(box, isA<HigherOrderBox<dynamic, LabelBox>>());
      expect((box as HigherOrderBox).metadata, 'some metadata');
      expect(box.content, isA<LabelBox>());
      expect(box.content.content, 'some label');
    });

    test('decodes HigherOrderBox as Box<NumberBox>', () {
      final Decodable<Box<NumberBox>> boxDecodable = BoxDecodable<NumberBox>();
      final Box<NumberBox> box = boxDecodable.fromMap(higherOrderNumberBoxMap);
      expect(box, isA<HigherOrderBox<dynamic, NumberBox>>());
      expect((box as HigherOrderBox).metadata, 100);
      expect(box.content, isA<NumberBox>());
      expect(box.content.content, 2.5);
    });
  });
}
