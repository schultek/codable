import 'package:codable_dart/core.dart';

abstract class RecursiveDelegatingDecoder implements Decoder {
  RecursiveDelegatingDecoder(this.delegate);
  final Decoder delegate;

  RecursiveDelegatingDecoder wrap(Decoder decoder);

  @override
  DecodingType whatsNext() => delegate.whatsNext();

  @override
  bool decodeBool() => delegate.decodeBool();

  @override
  bool? decodeBoolOrNull() => delegate.decodeBoolOrNull();

  @override
  int decodeInt() => delegate.decodeInt();

  @override
  int? decodeIntOrNull() => delegate.decodeIntOrNull();

  @override
  double decodeDouble() => delegate.decodeDouble();

  @override
  double? decodeDoubleOrNull() => delegate.decodeDoubleOrNull();

  @override
  num decodeNum() => delegate.decodeNum();

  @override
  num? decodeNumOrNull() => delegate.decodeNumOrNull();

  @override
  String decodeString() => delegate.decodeString();

  @override
  String? decodeStringOrNull() => delegate.decodeStringOrNull();

  @override
  bool decodeIsNull() => delegate.decodeIsNull();

  @override
  T decodeObject<T>({Decodable<T>? using}) => delegate.decodeObject(using: using?.wrap(this));

  @override
  T? decodeObjectOrNull<T>({Decodable<T>? using}) => delegate.decodeObjectOrNull(using: using?.wrap(this));

  @override
  List<E> decodeList<E>({Decodable<E>? using}) => delegate.decodeList(using: using?.wrap(this));

  @override
  List<E>? decodeListOrNull<E>({Decodable<E>? using}) => delegate.decodeListOrNull(using: using?.wrap(this));

  @override
  Map<K, V> decodeMap<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) =>
      delegate.decodeMap(keyUsing: keyUsing?.wrap(this), valueUsing: valueUsing?.wrap(this));

  @override
  Map<K, V>? decodeMapOrNull<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) =>
      delegate.decodeMapOrNull(keyUsing: keyUsing?.wrap(this), valueUsing: valueUsing?.wrap(this));

  @override
  IteratedDecoder decodeIterated() => delegate.decodeIterated();

  @override
  KeyedDecoder decodeKeyed() => delegate.decodeKeyed();

  @override
  MappedDecoder decodeMapped() => delegate.decodeMapped();

  @override
  bool isHumanReadable() => delegate.isHumanReadable();
  
  @override
  Never expect(String expect) => delegate.expect(expect);
}

extension _Wrap<T> on Decodable<T> {
  Decodable<T> wrap(RecursiveDelegatingDecoder decoder) => _WrappedDecodable(this, decoder);
}

class _WrappedDecodable<T> implements Decodable<T> {
  _WrappedDecodable(this._decodable, this._parent);

  final Decodable<T> _decodable;
  final RecursiveDelegatingDecoder _parent;

  @override
  T decode(Decoder decoder) {
    return _decodable.decode(_parent.wrap(decoder));
  }
}
