import 'package:codable_dart/core.dart';

class CompatMappedDecoder implements MappedDecoder {
  CompatMappedDecoder._(this.wrapped, this.decoders);

  static MappedDecoder wrap<T>(KeyedDecoder decoder) {
    final map = <Object, KeyedDecoder>{};
    for (Object? key; (key = decoder.nextKey()) != null;) {
      map[key!] = decoder.clone();
      decoder.skipCurrentValue();
    }
    return CompatMappedDecoder._(decoder, map);
  }

  final KeyedDecoder wrapped;
  final Map<Object, KeyedDecoder> decoders;

  @override
  DecodingType whatsNext(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().whatsNext();
  }

  @override
  bool decodeBool(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().decodeBool();
  }

  @override
  bool? decodeBoolOrNull(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d?.clone().decodeBoolOrNull();
  }

  @override
  int decodeInt(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().decodeInt();
  }

  @override
  int? decodeIntOrNull(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d?.clone().decodeIntOrNull();
  }

  @override
  double decodeDouble(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().decodeDouble();
  }

  @override
  double? decodeDoubleOrNull(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d?.clone().decodeDoubleOrNull();
  }

  @override
  num decodeNum(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().decodeNum();
  }

  @override
  num? decodeNumOrNull(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d?.clone().decodeNumOrNull();
  }

  @override
  String decodeString(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().decodeString();
  }

  @override
  String? decodeStringOrNull(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d?.clone().decodeStringOrNull();
  }

  @override
  bool decodeIsNull(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d != null && d.clone().decodeIsNull();
  }

  @override
  T decodeObject<T>(String key, {int? id, Decodable<T>? using}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().decodeObject(using: using);
  }

  @override
  T? decodeObjectOrNull<T>(String key, {int? id, Decodable<T>? using}) {
    var d = decoders[key] ?? decoders[id];
    return d?.clone().decodeObjectOrNull(using: using);
  }

  @override
  List<T> decodeList<T>(String key, {int? id, Decodable<T>? using}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().decodeList(using: using);
  }

  @override
  List<T>? decodeListOrNull<T>(String key, {int? id, Decodable<T>? using}) {
    var d = decoders[key] ?? decoders[id];
    return d?.clone().decodeListOrNull(using: using);
  }

  @override
  Map<K, V> decodeMap<K, V>(String key, {int? id, Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().decodeMap(keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @override
  Map<K, V>? decodeMapOrNull<K, V>(String key, {int? id, Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    var d = decoders[key] ?? decoders[id];
    return d?.clone().decodeMapOrNull(keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @override
  IteratedDecoder decodeIterated(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().decodeIterated();
  }

  @override
  KeyedDecoder decodeKeyed(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().decodeKeyed();
  }

  @override
  MappedDecoder decodeMapped(String key, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().decodeMapped();
  }

  @override
  Iterable<Object> get keys => decoders.keys;

  @override
  Never expect(String key, String expect, {int? id}) {
    var d = decoders[key] ?? decoders[id];
    return d!.clone().expect(expect);
  }

  @override
  bool isHumanReadable() {
    return wrapped.isHumanReadable();
  }
}

class CompatKeyedDecoder implements KeyedDecoder {
  CompatKeyedDecoder._(this.decoder) : keys = decoder.keys.iterator;

  static KeyedDecoder wrap<T>(MappedDecoder decoder) {
    return CompatKeyedDecoder._(decoder);
  }

  final MappedDecoder decoder;

  final Iterator<Object?> keys;
  bool _done = false;

  @override
  DecodingType whatsNext() {
    final key = keys.current;
    return decoder.whatsNext(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  bool decodeBool() {
    final key = keys.current;
    return decoder.decodeBool(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  bool? decodeBoolOrNull() {
    if (_done) return null;
    final key = keys.current;
    return decoder.decodeBoolOrNull(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  int decodeInt() {
    final key = keys.current;
    return decoder.decodeInt(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  int? decodeIntOrNull() {
    if (_done) return null;
    final key = keys.current;
    return decoder.decodeIntOrNull(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  double decodeDouble() {
    final key = keys.current;
    return decoder.decodeDouble(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  double? decodeDoubleOrNull() {
    if (_done) return null;
    final key = keys.current;
    return decoder.decodeDoubleOrNull(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  num decodeNum() {
    final key = keys.current;
    return decoder.decodeNum(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  num? decodeNumOrNull() {
    if (_done) return null;
    final key = keys.current;
    return decoder.decodeNumOrNull(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  String decodeString() {
    final key = keys.current;
    return decoder.decodeString(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  String? decodeStringOrNull() {
    if (_done) return null;
    final key = keys.current;
    return decoder.decodeStringOrNull(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  bool decodeIsNull() {
    if (_done) return false;
    final key = keys.current;
    return decoder.decodeIsNull(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  T decodeObject<T>({Decodable<T>? using}) {
    final key = keys.current;
    return decoder.decodeObject(key is String ? key : '', id: key is int ? key : null, using: using);
  }

  @override
  T? decodeObjectOrNull<T>({Decodable<T>? using}) {
    if (_done) return null;
    final key = keys.current;
    return decoder.decodeObjectOrNull(key is String ? key : '', id: key is int ? key : null, using: using);
  }

  @override
  List<E> decodeList<E>({Decodable<E>? using}) {
    final key = keys.current;
    return decoder.decodeList(key is String ? key : '', id: key is int ? key : null, using: using);
  }

  @override
  List<E>? decodeListOrNull<E>({Decodable<E>? using}) {
    if (_done) return null;
    final key = keys.current;
    return decoder.decodeListOrNull(key is String ? key : '', id: key is int ? key : null, using: using);
  }

  @override
  Map<K, V> decodeMap<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    final key = keys.current;
    return decoder.decodeMap(key is String ? key : '',
        id: key is int ? key : null, keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @override
  Map<K, V>? decodeMapOrNull<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    if (_done) return null;
    final key = keys.current;
    return decoder.decodeMapOrNull(key is String ? key : '',
        id: key is int ? key : null, keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @override
  IteratedDecoder decodeIterated() {
    final key = keys.current;
    return decoder.decodeIterated(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  KeyedDecoder decodeKeyed() {
    final key = keys.current;
    return decoder.decodeKeyed(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  MappedDecoder decodeMapped() {
    final key = keys.current;
    return decoder.decodeMapped(key is String ? key : '', id: key is int ? key : null);
  }

  @override
  Object? nextKey() {
    if (keys.moveNext()) {
      return keys.current;
    } else {
      _done = true;
      return null;
    }
  }

  @override
  void skipCurrentValue() {
    // do nothing
  }

  @override
  void skipRemainingKeys() {
    while (keys.moveNext()) {
      // do nothing
    }
  }

  @override
  bool isHumanReadable() {
    return decoder.isHumanReadable();
  }

  @override
  KeyedDecoder clone() {
    return CompatKeyedDecoder._(decoder);
  }

  @override
  Never expect(String expect) {
    final key = keys.current;
    return decoder.expect(key is String ? key : '', expect, id: key is int ? key : null);
  }
}
