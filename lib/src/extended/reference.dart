import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';

extension ReferenceDecoder on Decoder {
  /// Decodes a [Reference] of [T] using the provided [Decodable].
  Reference<T> decodeReference<T>({Decodable<T>? using}) {
    final next = whatsNext();
    if (next is DecodingType<Reference> || next is DecodingType<Future> || next is DecodingType<Stream>) {
      return decodeObject<Reference<T>>(using: ReferenceDecodable<T>._(using: using));
    } else {
      return Reference(decodeObject<T>(using: using));
    }
  }

  /// Decodes a [Reference] of [T] or null using the provided [Decodable].
  Reference<T>? decodeReferenceOrNull<T>({Decodable<T>? using}) {
    if (decodeIsNull()) {
      return null;
    }
    return decodeReference<T>(using: using);
  }
}

extension ReferenceMappedDecoder on MappedDecoder {
  /// Decodes a [Reference] of [T] using the provided [Decodable].
  Reference<T> decodeReference<T>(String key, {int? id, Decodable<T>? using}) {
    final next = whatsNext(key, id: id);
    if (next is DecodingType<Reference> || next is DecodingType<Future> || next is DecodingType<Stream>) {
      return decodeObject<Reference<T>>(key, id: id, using: ReferenceDecodable<T>._(using: using));
    } else {
      return Reference(decodeObject<T>(key, id: id, using: using));
    }
  }

  /// Decodes a [Reference] of [T] or null using the provided [Decodable].
  Reference<T>? decodeReferenceOrNull<T>(String key, {int? id, Decodable<T>? using}) {
    if (decodeIsNull(key, id: id)) {
      return null;
    }
    return decodeReference<T>(key, id: id, using: using);
  }
}

extension ReferenceEncoder on Encoder {
  /// Encodes a [Reference] of [T] using the provided [Encodable].
  void encodeReference<T>(T value, {Encodable<T>? using}) {
    assert(canEncodeCustom<Reference>(), '$runtimeType does not support encoding References.');
    encodeObject<Reference>(Reference<T>(value, using: using));
  }

  /// Encodes a [Reference] of [T] or null using the provided [Encodable].
  void encodeReferenceOrNull<T>(T? value, {Encodable<T>? using}) {
    if (value == null) {
      encodeNull();
    } else {
      encodeReference(value, using: using);
    }
  }
}

extension ReferenceKeyedEncoder on KeyedEncoder {
  /// Encodes a [Reference] of [T] using the provided [Encodable].
  void encodeReference<T>(String key, T value, {Encodable<T>? using}) {
    assert(canEncodeCustom<Reference>(), '$runtimeType does not support encoding References.');
    encodeObject<Reference>(key, Reference<T>(value, using: using));
  }

  /// Encodes a [Reference] of [T] or null using the provided [Encodable].
  void encodeReferenceOrNull<T>(String key, T? value, {Encodable<T>? using}) {
    if (value == null) {
      encodeNull(key);
    } else {
      encodeReference(key, value, using: using);
    }
  }
}

sealed class Reference<T> {
  factory Reference(T value, {Encodable<T>? using}) = _ValueReference<T>;
  factory Reference.late({Encodable<T>? using}) = _LateReference<T>;

  Encodable<T>? get using;

  Reference<R> get<R>(R Function(T value) callback);
  void set(T value);

  Object? get sentinel;
}

class _ValueReference<T> implements Reference<T> {
  _ValueReference(this._value, {this.using});

  T _value;

  @override
  final Encodable<T>? using;

  @override
  Reference<R> get<R>(R Function(T value) callback) {
    return Reference<R>(callback(_value));
  }

  @override
  void set(T value) {
    _value = value;
  }

  @override
  Object? get sentinel => _value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return (other is _ValueReference<T> &&  _value == other._value) ||
           (other is _LateReference<T> && other._isSet && _value == other._value);
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() {
    return 'Reference<$T>($_value)';
  }
}

class _LateReference<T> implements Reference<T> {
  _LateReference({this.using});

  T? _value;
  bool _isSet = false;
  final Set<void Function(T value)> _callbacks = {};

  @override
  final Encodable<T>? using;

  @override
  Reference<R> get<R>(R Function(T value) callback) {
    if (_isSet) {
      return Reference<R>(callback(_value as T));
    } else {
      final late = Reference<R>.late();
      _callbacks.add((value) {
        late.set(callback(value));
      });
      return late;
    }
  }

  @override
  void set(T value) {
    _value = value;
    _isSet = true;
    for (var callback in _callbacks) {
      callback(value);
    }
    _callbacks.clear();
  }

  @override
  Object? get sentinel => _isSet ? _value : this;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (!_isSet) return false;
    return (other is _LateReference<T> && other._isSet && _value == other._value) ||
           (other is _ValueReference<T> && _value == other._value);
  }

  @override
  int get hashCode => _isSet ? _value.hashCode : identityHashCode(this);


  @override
  String toString() {
    if (_isSet) {
      return 'Reference<$T>($_value)';
    } else {
      return 'Reference<$T>.late(not yet set)';
    }
  }
}

final class ReferenceDecodable<T> implements ComposedDecodable1<Reference<T>, T> {
  ReferenceDecodable._({this.using});

  final Decodable<T>? using;

  @override
  Reference<T> decode(Decoder decoder) {
    throw UnsupportedError('Called "decodeReference()" on a decoder that does not support decoding References.');
  }

  @override
  $R extract<$R>($R Function<A>(Decodable<A>? decodableA) fn) {
    return fn<T>(using);
  }
}
