import 'package:codable/common.dart';
import 'package:codable/core.dart';
import 'package:codable/extended.dart';
import 'package:codable/standard.dart';
import 'package:test/test.dart';

import 'model/box.dart';

final labelBoxMap = {'type': 'label', 'content': "some label"};
final anyBoxMap = {
  'type': 'any',
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
    group("with reduced type parameter", () {
      test('decodes LabelBox as Box<String>', () {
        final Codable<Box<String>> boxCodable = BoxCodable<String>();
        final Box<String> box = boxCodable.fromMap(labelBoxMap);
        expect(box, isA<LabelBox>());
        expect(box.content, 'some label');
      });

      test('decodes LabelBox as Box<dynamic>', () {
        final Codable<Box<dynamic>> boxCodable = BoxCodable<dynamic>();
        final Box<dynamic> box = boxCodable.fromMap(labelBoxMap);
        expect(box, isA<LabelBox>());
        expect(box.content, 'some label');
      });

      test('decodes LabelBox not as Box<int>', () {
        final Codable<Box<int>> boxCodable = BoxCodable<int>();
        expect(
          () {
            // ignore: unused_local_variable
            final Box<int> box = boxCodable.fromMap(labelBoxMap);
          },
          throwsA(isA<CodableException>().having(
            (e) => e.message,
            'message',
            'Failed to decode Box<int>: Cannot resolve discriminator to decode type Box<int>. Got LabelBoxCodable.',
          )),
        );
      });

      test('encodes LabelBox', () {
        final LabelBox box = LabelBox('some label');
        final Map map = box.toMap();
        expect(map, labelBoxMap);
      });

      test('decodes AnyBox as Box<dynamic>', () {
        final Codable<Box<dynamic>> boxCodable = BoxCodable<dynamic>();
        final Box<dynamic> box = boxCodable.fromMap(anyBoxMap);
        expect(box, isA<AnyBox>());
        expect(box.content, {'value': 'some value'});
      });

      test('encodes AnyBox', () {
        final AnyBox box = AnyBox({'value': 'some value'});
        final Map map = box.toMap();
        expect(map, anyBoxMap);
      });
    });

    group("with bounded type parameter", () {
      test('decodes NumberBox as Box<dynamic>', () {
        final Codable<Box<dynamic>> boxCodable = BoxCodable<dynamic>();
        final Box<dynamic> box = boxCodable.fromMap(numberBoxMap);
        expect(box, isA<NumberBox>());
        expect(box.content, 2.5);
      });
      test('decodes NumberBox as Box<num>', () {
        final Codable<Box<num>> boxCodable = BoxCodable<num>();
        final Box<num> box = boxCodable.fromMap(numberBoxMap);
        expect(box, isA<NumberBox>());
        expect(box.content, 2.5);
      });
      test('decodes NumberBox as Box<double>', () {
        final Codable<Box<double>> boxCodable = BoxCodable<double>();
        final Box<double> box = boxCodable.fromMap(numberBoxMap);
        expect(box, isA<NumberBox<double>>());
        expect(box.content, 2.5);
      });

      test('decodes NumberBox not as Box<String>', () {
        final Codable<Box<String>> boxCodable = BoxCodable<String>();
        expect(
          () {
            // ignore: unused_local_variable
            final Box<String> box = boxCodable.fromMap(numberBoxMap);
          },
          throwsA(isA<CodableException>().having(
            (e) => e.message,
            'message',
            'Failed to decode Box<String>: Cannot resolve discriminator to decode type Box<String>. Got _UseDecodable1<NumberBox<num>, num>.',
          )),
        );
      });

      test('encodes NumberBox', () {
        final NumberBox box = NumberBox(2.5);
        final Map map = box.toMap();
        expect(map, numberBoxMap);
      });
    });

    group("with composed type parameter", () {
      test('decodes Boxes as Box<dynamic>', () {
        final Codable<Box<dynamic>> boxCodable = BoxCodable<dynamic>();
        final Box<dynamic> box = boxCodable.fromMap(boxesMap);
        expect(box, isA<Boxes<dynamic>>());
        expect(box.content, [
          {'value': 1},
          {'value': 2},
          {'value': 3}
        ]);
      });

      test('decodes Boxes as Box<List<dynamic>>', () {
        final Codable<Box<List>> boxCodable = BoxCodable<List>();
        final Box<List> box = boxCodable.fromMap(boxesMap);
        expect(box, isA<Boxes<dynamic>>());
        expect(box.content, [
          {'value': 1},
          {'value': 2},
          {'value': 3}
        ]);
      });

      test('decodes Boxes as Box<List<Data>> with explicit child decode', () {
        final Codable<Box<List<Data>>> boxCodable = BoxCodable<List<Data>>().use(Data.codable.list());
        final Box<List<Data>> box = boxCodable.fromMap(boxesMap);
        expect(box, isA<Boxes<Data>>());
        expect(box.content, [
          Data(1),
          Data(2),
          Data(3),
        ]);
      });

      test('decodes Boxes not as Box<List<String>> without explicit child decode', () {
        final Codable<Box<List<String>>> boxCodable = BoxCodable<List<String>>().use();

        expect(
          () {
            // ignore: unused_local_variable
            final Box<List<String>> box = boxCodable.fromMap(boxesMap);
          },
          throwsA(isA<CodableException>().having(
            (e) => e.message,
            'message',
            'Failed to decode Box<List<String>>: Cannot resolve discriminator to decode type Box<List<String>>. Got BoxesCodable<dynamic>.',
          )),
        );
      });

      test('encodes Boxes<dynamic> without explicit inner encodable', () {
        final Boxes box = Boxes([
          {'value': 1},
          {'value': 2},
          {'value': 3}
        ]);
        final Map map = box.toMap();
        expect(map, boxesMap);
      });

      test('encodes Boxes<Data> with explicit inner encodable', () {
        final Boxes<Data> box = Boxes([
          Data(1),
          Data(2),
          Data(3),
        ]);
        final Map map = box.use(Data.codable).toMap();
        expect(map, boxesMap);
      });

      test('encodes Boxes<Data> as Box<List<Data>> with explicit inner encodable', () {
        final Box<List<Data>> box = Boxes([
          Data(1),
          Data(2),
          Data(3),
        ]);
        final Map map = box.use(Data.codable.list()).toMap();
        expect(map, boxesMap);
      });
    });

    group("with additional type parameter", () {
      test('decodes MetaBox as Box<dynamic>', () {
        final Codable<Box<dynamic>> boxCodable = BoxCodable<dynamic>();
        final Box<dynamic> box = boxCodable.fromMap(metaBoxMap);
        expect(box, isA<MetaBox<dynamic, dynamic>>());
        expect((box as MetaBox).metadata, 2);
        expect(box.content, 'test');
      });

      test('decodes MetaBox as Box<String> ', () {
        final Codable<Box<String>> boxCodable = BoxCodable<String>();
        final Box<String> box = boxCodable.fromMap(metaBoxMap);
        expect(box, isA<MetaBox<dynamic, String>>());
        expect((box as MetaBox).metadata, 2);
        expect(box.content, 'test');
      });

      test('decodes MetaBox as Box<Data> with explicit child decode', () {
        final Codable<Box<Data>> boxCodable = BoxCodable<Data>().use(Data.codable);
        final Box<Data> box = boxCodable.fromMap(metaDataBoxMap);
        expect(box, isA<MetaBox<dynamic, Data>>());
        expect((box as MetaBox).metadata, 2);
        expect(box.content, Data('test'));
      });

      test('encodes MetaBox with explicit inner encodable', () {
        final MetaBox<int, Data> box = MetaBox(2, Data('test'));
        final Map map = box.use(null, Data.codable).toMap();
        expect(map, metaDataBoxMap);
      });

      test('decodes HigherOrderBox as Box<dynamic>', () {
        final Codable<Box<dynamic>> boxCodable = BoxCodable<dynamic>();
        final Box<dynamic> box = boxCodable.fromMap(higherOrderLabelBoxMap);
        expect(box, isA<HigherOrderBox<dynamic, Box>>());
        expect((box as HigherOrderBox).metadata, 'some metadata');
        expect(box.content, isA<LabelBox>());
        expect(box.content.content, 'some label');
      });

      test('decodes HigherOrderBox as Box<Box<dynamic>>', () {
        final Codable<Box<Box<dynamic>>> boxCodable = BoxCodable<Box<dynamic>>();
        final Box<Box<dynamic>> box = boxCodable.fromMap(higherOrderLabelBoxMap);
        expect(box, isA<HigherOrderBox<dynamic, Box>>());
        expect((box as HigherOrderBox).metadata, 'some metadata');
        expect(box.content, isA<LabelBox>());
        expect(box.content.content, 'some label');
      });

      test('decodes HigherOrderBox as Box<Box<String>>', () {
        final Codable<Box<Box<String>>> boxCodable = BoxCodable<Box<String>>();
        final Box<Box<String>> box = boxCodable.fromMap(higherOrderLabelBoxMap);
        expect(box, isA<HigherOrderBox<dynamic, Box<String>>>());
        expect((box as HigherOrderBox).metadata, 'some metadata');
        expect(box.content, isA<LabelBox>());
        expect(box.content.content, 'some label');
      });

      test('decodes HigherOrderBox as Box<LabelBox>', () {
        final Codable<Box<LabelBox>> boxCodable = BoxCodable<LabelBox>();
        final Box<LabelBox> box = boxCodable.fromMap(higherOrderLabelBoxMap);
        expect(box, isA<HigherOrderBox<dynamic, LabelBox>>());
        expect((box as HigherOrderBox).metadata, 'some metadata');
        expect(box.content, isA<LabelBox>());
        expect(box.content.content, 'some label');
      });

      test('decodes HigherOrderBox as Box<NumberBox>', () {
        final Codable<Box<NumberBox>> boxCodable = BoxCodable<NumberBox>();
        final Box<NumberBox> box = boxCodable.fromMap(higherOrderNumberBoxMap);
        expect(box, isA<HigherOrderBox<dynamic, NumberBox>>());
        expect((box as HigherOrderBox).metadata, 100);
        expect(box.content, isA<NumberBox>());
        expect(box.content.content, 2.5);
      });
    });
  });
}
