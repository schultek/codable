import 'dart:async';

import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';

extension AsAsyncCodable<T> on Codable<T> {
  /// Returns a [Codable] that can encode and decode a future of [T].
  Codable<Future<T>> future() => FutureCodable<T>(this);

  /// Returns a [Codable] that can encode and decode a stream of [T].
  LazyCodable<Stream<T>> stream() => StreamCodable<T>(this);
}

extension AsAsyncDecodable<T> on Decodable<T> {
  /// Returns a [Decodable] object that can decode a future of [T].
  Decodable<Future<T>> future() => FutureDecodable<T>(this);

  /// Returns a [Decodable] object that can decode a stream of [T].
  Decodable<Stream<T>> stream() => StreamDecodable<T>(this);
}

extension AsFutureEncodable<T> on Encodable<T> {
  /// Returns an [Encodable] that can encode a future of [T].
  Encodable<Future<T>> future() => FutureEncodable<T>(this);

  /// Returns an [Encodable] that can encode a stream of [T].
  Encodable<Stream<T>> stream() => StreamEncodable<T>(this);
}

/// A [Codable] that can encode and decode a future of [E].
///
/// Prefer using [AsAsyncCodable.future] instead of the constructor.
class FutureCodable<T> with _FutureDecodable<T> implements Codable<Future<T>>, ComposedDecodable1<Future<T>, T> {
  const FutureCodable(this.codable);

  @override
  final Codable<T> codable;

  @override
  void encode(Future<T> value, Encoder encoder) {
    encoder.encodeFuture(value, using: codable);
  }

  @override
  R extract<R>(R Function<A>(Codable<A>? codableA) fn) {
    return fn<T>(codable);
  }
}

/// A [Codable] implementation that can decode a stream of [T].
///
/// Prefer using [AsAsyncCodable.stream] instead of the constructor.
class StreamCodable<T> with _StreamDecodable<T> implements LazyCodable<Stream<T>>, ComposedDecodable1<Stream<T>, T> {
  const StreamCodable(this.codable);

  @override
  final Codable<T> codable;

  @override
  void encode(Stream<T> value, Encoder encoder) {
    encoder.encodeStream(value, using: codable);
  }

  @override
  R extract<R>(R Function<A>(Codable<A>? codableA) fn) {
    return fn<T>(codable);
  }
}

/// A [Decodable] implementation that can decode a future of [T].
///
/// Prefer using [AsAsyncDecodable.future] instead of the constructor.
class FutureDecodable<T> with _FutureDecodable<T> implements ComposedDecodable1<Future<T>, T> {
  const FutureDecodable(this.codable);

  @override
  final Decodable<T> codable;
}

/// A [Decodable] implementation that can decode a stream of [T].
///
/// Prefer using [AsAsyncDecodable.stream] instead of the constructor.
class StreamDecodable<T> with _StreamDecodable<T> implements ComposedDecodable1<Stream<T>, T> {
  const StreamDecodable(this.codable);

  @override
  final Decodable<T> codable;
}

/// An [Encodable] that can encode a future of [T].
///
/// Prefer using [AsFutureEncodable.future] instead of the constructor.
class FutureEncodable<T> implements Encodable<Future<T>> {
  const FutureEncodable(this.codable);

  final Encodable<T> codable;

  @override
  void encode(Future<T> value, Encoder encoder) {
    encoder.encodeFuture(value, using: codable);
  }
}

/// An [Encodable] that can encode a stream of [T].
///
/// Prefer using [AsFutureEncodable.stream] instead of the constructor.
class StreamEncodable<T> implements Encodable<Stream<T>> {
  const StreamEncodable(this.codable);

  final Encodable<T> codable;

  @override
  void encode(Stream<T> value, Encoder encoder) {
    encoder.encodeStream(value, using: codable);
  }
}

mixin _FutureDecodable<T> implements ComposedDecodable1<Future<T>, T> {
  Decodable<T> get codable;

  @override
  Future<T> decode(Decoder decoder) {
    return decoder.decodeFuture(using: codable);
  }

  @override
  R extract<R>(R Function<A>(Decodable<A>? codableA) fn) {
    return fn<T>(codable);
  }
}

mixin _StreamDecodable<T> implements ComposedDecodable1<Stream<T>, T>, LazyDecodable<Stream<T>> {
  Decodable<T> get codable;

  @override
  Stream<T> decode(Decoder decoder) {
    return decoder.decodeStream(using: codable);
  }

  @override
  void decodeLazy(LazyDecoder decoder, void Function(Stream<T> value) resolve) {
    resolve(decoder.decodeStream(using: codable));
  }

  @override
  R extract<R>(R Function<A>(Decodable<A>? codableA) fn) {
    return fn<T>(codable);
  }
}

extension AsyncDecoder on Decoder {
  /// Decodes a [Future] of [T] using the provided [Decodable].
  Future<T> decodeFuture<T>({Decodable<T>? using}) {
    final next = whatsNext();
    if (next is DecodingType<Future> || next is DecodingType<Stream>) {
      return decodeObject<Future<T>>(using: AsyncDecodable._future<T>(using));
    } else {
      return Future.value(decodeObject<T>(using: using));
    }
  }

  /// Decodes a [Future] of [T] or null using the provided [Decodable].
  Future<T>? decodeFutureOrNull<T>({Decodable<T>? using}) {
    if (decodeIsNull()) {
      return null;
    }
    return decodeFuture<T>(using: using);
  }

  /// Decodes a [Stream] of [T] using the provided [Decodable].
  Stream<T> decodeStream<T>({Decodable<T>? using}) {
    final next = whatsNext();
    if (next is DecodingType<Stream>) {
      return decodeObject<Stream<T>>(using: AsyncDecodable._stream<T>(using));
    } else if (next case DecodingType.iterated || DecodingType.list) {
      return Stream<T>.fromIterable(decodeList<T>(using: using));
    } else {
      return Stream<T>.value(decodeObject<T>(using: using));
    }
  }

  /// Decodes a [Stream] of [T] or null using the provided [Decodable].
  Stream<T>? decodeStreamOrNull<T>({Decodable<T>? using}) {
    if (decodeIsNull()) {
      return null;
    }
    return decodeStream<T>(using: using);
  }
}

extension AsyncMappedDecoder on MappedDecoder {
  /// Decodes a [Future] of [T] using the provided [Decodable].
  Future<T> decodeFuture<T>(String key, {int? id, Decodable<T>? using}) {
    final next = whatsNext(key, id: id);
    if (next is DecodingType<Future> || next is DecodingType<Stream>) {
      return decodeObject<Future<T>>(key, id: id, using: AsyncDecodable._future<T>(using));
    } else {
      return Future.value(decodeObject<T>(key, id: id, using: using));
    }
  }

  /// Decodes a [Future] of [T] or null using the provided [Decodable].
  Future<T>? decodeFutureOrNull<T>(String key, {int? id, Decodable<T>? using}) {
    if (decodeIsNull(key, id: id)) {
      return null;
    }
    return decodeFuture<T>(key, id: id, using: using);
  }

  /// Decodes a [Stream] of [T] using the provided [Decodable].
  Stream<T> decodeStream<T>(String key, {int? id, Decodable<T>? using}) {
    final next = whatsNext(key, id: id);
    if (next is DecodingType<Stream>) {
      return decodeObject<Stream<T>>(key, id: id, using: AsyncDecodable._stream<T>(using));
    } else if (next case DecodingType.iterated || DecodingType.list) {
      return Stream<T>.fromIterable(decodeList<T>(key, id: id, using: using));
    } else {
      return Stream.value(decodeObject<T>(key, id: id, using: using));
    }
  }

  /// Decodes a [Stream] of [T] or null using the provided [Decodable].
  Stream<T>? decodeStreamOrNull<T>(String key, {int? id, Decodable<T>? using}) {
    if (decodeIsNull(key, id: id)) {
      return null;
    }
    return decodeStream<T>(key, id: id, using: using);
  }
}

extension AsyncLazyDecoder on LazyDecoder {
  /// Decodes a [Future] of [T] using the provided [Decodable].
  Future<T> decodeFuture<T>({Decodable<T>? using}) {
    final completer = Completer<T>();
    decodeObject(completer.complete, using: using);
    return completer.future;
  }

  /// Decodes a [Stream] of [T] using the provided [Decodable].
  Stream<T> decodeStream<T>({Decodable<T>? using}) {
    final controller = StreamController<T>();
    whatsNext((type) {
      if (type case DecodingType.iterated || DecodingType.list) {
        decodeIterated((decoder) {
          decoder.decodeObject((v) {
            controller.add(v);
          }, using: using);
        }, done: () {
          controller.close();
        });
      } else {
        decodeEager((decoder) async {
          await controller.addStream(decoder.decodeStream<T>(using: using));
          controller.close();
        });
      }
    });
    return controller.stream;
  }
}

extension AsyncEncoder on Encoder {
  /// Encodes a [Future] of [T] using the provided [Encodable].
  void encodeFuture<T>(Future<T> value, {Encodable<T>? using}) {
    assert(canEncodeCustom<Future>(), '$runtimeType does not support encoding Futures.');
    encodeObject<Future>(value, using: AsyncEncodable._future<T>(using));
  }

  /// Encodes a [Future] of [T] or null using the provided [Encodable].
  void encodeFutureOrNull<T>(Future<T>? value, {Encodable<T>? using}) {
    if (value == null) {
      encodeNull();
    } else {
      encodeFuture(value, using: using);
    }
  }

  /// Encodes a [Stream] of [T] using the provided [Encodable].
  void encodeStream<T>(Stream<T> value, {Encodable<T>? using}) {
    assert(canEncodeCustom<Stream>(), '$runtimeType does not support encoding Streams.');
    encodeObject<Stream>(value, using: AsyncEncodable._stream<T>(using));
  }

  /// Encodes a [Stream] of [T] or null using the provided [Encodable].
  void encodeStreamOrNull<T>(Stream<T>? value, {Encodable<T>? using}) {
    if (value == null) {
      encodeNull();
    } else {
      encodeStream(value, using: using);
    }
  }
}

extension AsyncKeyedEncoder on KeyedEncoder {
  /// Encodes a [Future] of [T] using the provided [Encodable].
  void encodeFuture<T>(String key, Future<T> value, {Encodable<T>? using}) {
    assert(canEncodeCustom<Future>(), '$runtimeType does not support encoding Futures.');
    encodeObject<Future>(key, value, using: AsyncEncodable._future<T>(using));
  }

  /// Encodes a [Future] of [T] or null using the provided [Encodable].
  void encodeFutureOrNull<T>(String key, Future<T>? value, {Encodable<T>? using}) {
    if (value == null) {
      encodeNull(key);
    } else {
      encodeFuture(key, value, using: using);
    }
  }

  /// Encodes a [Stream] of [T] using the provided [Encodable].
  void encodeStream<T>(String key, Stream<T> value, {Encodable<T>? using}) {
    assert(canEncodeCustom<Stream>(), '$runtimeType does not support encoding Streams.');
    encodeObject<Stream>(key, value, using: AsyncEncodable._stream<T>(using));
  }

  /// Encodes a [Stream] of [T] or null using the provided [Encodable].
  void encodeStreamOrNull<T>(String key, Stream<T>? value, {Encodable<T>? using}) {
    if (value == null) {
      encodeNull(key);
    } else {
      encodeStream(key, value, using: using);
    }
  }
}

final class AsyncEncodable<R, T> implements Encodable<R> {
  AsyncEncodable._(this.target, {this.using});

  static AsyncEncodable<Stream, T> _stream<T>(Encodable<T>? using) {
    return AsyncEncodable._('Stream', using: using);
  }

  static AsyncEncodable<Future, T> _future<T>(Encodable<T>? using) {
    return AsyncEncodable._('Future', using: using);
  }

  final String target;
  final Encodable<T>? using;

  @override
  void encode(R value, Encoder encoder) {
    throw CodableException.unsupportedMethod('Encoder', 'encode$target()',
        reason: 'Called "encode$target()" on an encoder that does not support encoding ${target}s.');
  }

  $R extract<$R>($R Function<A>(Encodable<A>? encodableA) fn) {
    return fn<T>(using);
  }
}

final class AsyncDecodable<R, T> implements ComposedDecodable1<R, T> {
  AsyncDecodable._(this.target, {this.using});

  static AsyncDecodable<Stream<T>, T> _stream<T>(Decodable<T>? using) {
    return AsyncDecodable._('Stream', using: using);
  }

  static AsyncDecodable<Future<T>, T> _future<T>(Decodable<T>? using) {
    return AsyncDecodable._('Future', using: using);
  }

  final String target;
  final Decodable<T>? using;

  @override
  R decode(Decoder decoder) {
    throw CodableException.unsupportedMethod('Decoder', 'decode$target()',
        reason: 'Called "decode$target()" on a decoder that does not support decoding ${target}s.');
  }

  @override
  $R extract<$R>($R Function<A>(Decodable<A>? decodableA) fn) {
    return fn<T>(using);
  }
}
