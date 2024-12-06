import 'package:codable/core.dart';
import 'package:codable/extended.dart';

bool isBounded<Type, Bound>() => _Type<Type>() is _Type<Bound>;

class _Type<T> {}

abstract mixin class SuperDecodable<T> implements Decodable<T> {
  String? get discriminatorKey;

  /// The set of discriminators for this class.
  List<Discriminator> get discriminators;

  /// The fallback decode for this class.
  T decodeFallback(Decoder decoder) {
    throw 'Fallback decode not implemented for $T.';
  }

  @override
  T decode(Decoder decoder) {
    final discriminator = findDiscriminator(decoder);
    if (discriminator != null) {
      final decodable = discriminator.resolve<T>();
      return decodable.decode(decoder);
    }
    return decodeFallback(decoder);
  }
}

abstract mixin class SuperDecodable1<T, A> implements SuperDecodable<T>, Decodable1<T, A> {
  @override
  T decodeFallback(Decoder decoder, [Decodable<A>? decodableA]) {
    throw 'Fallback decode not implemented for $T.';
  }

  @override
  T decode(Decoder decoder, [Decodable<A>? decodableA]) {
    final discriminator = findDiscriminator(decoder);
    if (discriminator != null) {
      final decodable = discriminator.resolve1<T, A>(decodableA);
      return decodable.decode(decoder);
    }
    return decodeFallback(decoder, decodableA);
  }
}

abstract mixin class SuperDecodable2<T, A, B> implements SuperDecodable<T>, Decodable2<T, A, B> {
  @override
  T decodeFallback(Decoder decoder, [Decodable<A>? decodableA, Decodable<B>? decodableB]) {
    throw 'Fallback decode not implemented for $T.';
  }

  @override
  T decode(Decoder decoder, [Decodable<A>? decodableA, Decodable<B>? decodableB]) {
    final discriminator = findDiscriminator(decoder);
    if (discriminator != null) {
      final decodable = discriminator.resolve2<T, A, B>(decodableA, decodableB);
      return decodable.decode(decoder);
    }
    return decodeFallback(decoder, decodableA, decodableB);
  }
}

extension SuperDecodableExtension<T> on SuperDecodable<T> {
  Discriminator? findDiscriminator(Decoder decoder, [String? currentValue, List<Discriminator>? customDiscriminators]) {
    final discriminators = [...this.discriminators, ...?customDiscriminators];

    String? discriminatorValue = currentValue;
    if (discriminatorValue == null && discriminatorKey != null) {
      discriminatorValue = decoder.clone().decodeMapped().decodeStringOrNull(discriminatorKey!);
    }

    for (var d in discriminators) {
      final discriminator = d.canDecodable(decoder, discriminatorKey, discriminatorValue);
      if (discriminator == null) continue;
      return discriminator;
    }

    return null;
  }
}

abstract base class Discriminator<T> {
  const Discriminator.base(this.value);

  factory Discriminator(Object? value, Decodable<T> Function() resolve) = _Discriminator0<T>;

  static Discriminator<T> arg1<T>(Object? value, Decodable<T> Function<A>(Decodable<A>? d1) resolve) =>
      _Discriminator1<T, dynamic>(value, resolve);
  static Discriminator<T> arg1Bounded<T, A>(Object? value, Function resolve) => _Discriminator1<T, A>(value, resolve);

  static Discriminator<T> arg2<T>(
          Object? value, Decodable<T> Function<A, B>(Decodable<A>? d1, Decodable<B>? d2) resolve) =>
      _Discriminator2<T, dynamic, dynamic>(value, resolve);
  static Discriminator<T> arg2Bounded<T, A, B>(Object? value, Function resolve) =>
      _Discriminator2<T, A, B>(value, resolve);

  static List<Discriminator<T>> chain<T>(
      List<Discriminator<T>> discriminators, Decodable<T> Function(Discriminator<T> d) resolve) {
    return [
      for (final d in discriminators) _Discriminator0<T>(d.value, () => resolve(d)),
    ];
  }

  static List<Discriminator<T>> chain1<T>(
      List<Discriminator<T>> discriminators, Decodable<T> Function<A>(Discriminator<T> d, Decodable<A>? d1) resolve) {
    return [
      for (final d in discriminators) _Discriminator1<T, dynamic>(d.value, <A>(Decodable<A>? d1) => resolve<A>(d, d1)),
    ];
  }

  static List<Discriminator<T>> chain2<T>(List<Discriminator<T>> discriminators,
      Decodable<T> Function<A, B>(Discriminator<T> d, Decodable<A>? d1, Decodable<B>? d2) resolve) {
    return [
      for (final d in discriminators)
        _Discriminator2<T, dynamic, dynamic>(
            d.value, <A, B>(Decodable<A>? d1, Decodable<B>? d2) => resolve<A, B>(d, d1, d2)),
    ];
  }

  final Object? value;
}

extension DiscriminatorApply on Discriminator {
  Decodable<T> resolve<T>() {
    return _resolve<T, dynamic, dynamic>(null, null);
  }

  Decodable<T> resolve1<T, A>(Decodable<A>? d1) {
    return _resolve<T, A, dynamic>(d1, null);
  }

  Decodable<T> resolve2<T, A, B>(Decodable<A>? d1, Decodable<B>? d2) {
    return _resolve<T, A, B>(d1, d2);
  }

  Decodable<T> _resolve<T, A, B>(Decodable<A>? d1, Decodable<B>? d2) {
    Decodable? result;
    if (this case _Discriminator0 d) {
      result = d._resolve();
    } else if (this case _Discriminator1 d) {
      result = d.resolve<A>(d1);
    } else if (this case _Discriminator2 d) {
      result = d.resolve<A, B>(d1, d2);
    }

    if (result is Decodable<T>) {
      return result;
    }
    throw 'Cannot resolve discriminator to decode type $T. Got ${result.runtimeType}.';
  }
}

final class _Discriminator0<T> extends Discriminator<T> {
  const _Discriminator0(super.value, this._resolve) : super.base();

  final Decodable<T> Function() _resolve;
}

final class _Discriminator1<T, $A> extends Discriminator<T> {
  const _Discriminator1(super.value, this._resolve) : super.base();

  final Function _resolve;

  Decodable<T> resolve<A>(Decodable<A>? d1) {
    final satisfiesA = isBounded<A, $A>();
    if (satisfiesA) {
      return _resolve<A>(d1);
    } else {
      return _resolve<$A>(d1);
    }
  }
}

final class _Discriminator2<T, $A, $B> extends Discriminator<T> {
  const _Discriminator2(super.value, this._resolve) : super.base();

  final Function _resolve;

  Decodable<T> resolve<A, B>(Decodable<A>? d1, Decodable<B>? d2) {
    final satisfiesA = isBounded<A, $A>();
    final satisfiesB = isBounded<B, $B>();
    if (satisfiesA && satisfiesB) {
      return _resolve<A, B>(d1, d2);
    } else if (satisfiesA) {
      return _resolve<A, $B>(d1, d2);
    } else if (satisfiesB) {
      return _resolve<$A, B>(d1, d2);
    } else {
      return _resolve<$A, $B>(d1, d2);
    }
  }
}

extension DiscriminatorExtension<T> on Discriminator<T> {
  Discriminator? canDecodable(Decoder decoder, String? currentKey, String? currentValue) {
    final discriminator = this;

    if (identical(discriminator.value, 'use_as_default')) {
      return discriminator;
    }

    if (discriminator.value is Function) {
      if (discriminator.value case bool Function(Decoder) fn) {
        if (fn(decoder.clone())) {
          return discriminator;
        } else {
          return null;
        }
      } else {
        throw AssertionError('Discriminator function must be of type "bool Function(Decoder)".');
      }
    }

    if (currentValue == discriminator.value) {
      return discriminator;
    }

    return null;
  }
}
