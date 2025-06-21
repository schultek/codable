import 'dart:async';

import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';

class AsyncValue<T> implements SelfEncodable {
  AsyncValue.value(T value) : _value = value, _isRef = false;
  AsyncValue.reference(T value) : _value = value, _isRef = true;
  AsyncValue.future(Future<T> future) : _value = future, _isRef = true {
    future.then((value) {
      _value = value;
    });
  }

  FutureOr<T> _value;
  final bool _isRef;

  bool get isPending => _value is Future<T>;

  T get requireValue {
    if (_value is Future<T>) {
      throw StateError('Cannot access requireValue on an AsyncValue that is still pending.');
    }
    return _value as T;
  }

  FutureOr<T> get value => _value;
  T? get valueOrNull => _value is Future<T> ? null : _value as T?;

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    if (_value is Future<T>) {
      encoder.encodeFuture<T>(_value as Future<T>, using: encodableT);
    } else if (_isRef) {
      encoder.encodeReference<T>(_value as T, using: encodableT);
    } else {
      encoder.encodeObject<T>(_value as T, using: encodableT);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AsyncValue<T>) return false;
    return _value == other._value;
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => isPending ? '[pending $T]' : _value.toString();
}


extension AsyncEncodableExtension<T> on AsyncValue<T> {
  SelfEncodable use([Encodable<T>? encodableT]) {
    return SelfEncodable.fromHandler((e) => encode(e, encodableT));
  }
}

extension AsAsyncCodable<T> on Codable<T> {
  /// Returns a [Codable] that can encode and decode an [AsyncValue] of [T].
  Codable<AsyncValue<T>> async() => AsyncCodable<T>().use(this);
}

class AsyncCodable<T> extends Codable1<AsyncValue<T>, T> {
  const AsyncCodable();

  @override
  void encode(AsyncValue<T> value, Encoder encoder, [Encodable<T>? encodableA]) {
    value.encode(encoder, encodableA);
  }

  @override
  AsyncValue<T> decode(Decoder decoder, [Decodable<T>? decodableT]) {
    final next = decoder.whatsNext();
    if (next is DecodingType<Future> || next is DecodingType<Stream>) {
      return AsyncValue.future(decoder.decodeFuture<T>(using: decodableT));
    } else {
      return AsyncValue.value(decoder.decodeObject<T>(using: decodableT));
    }
  }
}

extension AsyncCodableExtension on Codable1<AsyncValue, dynamic> {
  // This is a convenience method for creating a AsyncCodable with an explicit child codable.
  Codable<AsyncValue<$A>> call<$A>([Codable<$A>? codableA]) => AsyncCodable<$A>().use(codableA);
}
