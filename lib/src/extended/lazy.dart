import 'package:codable_dart/core.dart';

abstract class LazyDecoder {
  void whatsNext(void Function(DecodingType type) onType);

  void decodeEager(void Function(Decoder decoder) onDecode);

  void decodeObject<T>(void Function(T value) onValue, {Decodable<T>? using});
  void decodeObjectOrNull<T>(void Function(T? value) onValue, {Decodable<T>? using});

  void decodeIterated(void Function(LazyIteratedDecoder decoder) onItem, {required void Function() done});

  void decodeKeyed(void Function(Object /* String | int */ key, LazyKeyedDecoder decoder) onEntry,
      {required void Function() done});

  void decodeList<T>(void Function(List<T> value) onValue, {Decodable<T>? using});
}

abstract class LazyKeyedDecoder implements LazyDecoder {
  void skipCurrentValue();
}

abstract class LazyIteratedDecoder implements LazyDecoder {
  /// Skips the current item in the collection.
  ///
  /// This is useful when the [Decodable] implementation is not interested in the current item.
  /// It must be called before calling [nextItem] again if no decoding method is called instead.
  void skipCurrentItem();
}

abstract class LazyDecodable<T> implements Decodable<T> {
  void decodeLazy(LazyDecoder decoder, void Function(T value) resolve);
}

abstract class LazyCodable<T> extends Codable<T> implements LazyDecodable<T> {
  const LazyCodable();
}
