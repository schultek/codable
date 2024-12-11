import 'package:codable/src/core/interface.dart';
import 'package:type_plus/type_plus.dart';

abstract class Mapper<T> {
  const Mapper();

  /// A unique id for this type, defaults to the name of the type.
  ///
  /// Override this if you have two types with the same name.
  String get id => T.name;

  /// A type factory is what makes generic types work.
  Function get typeFactory => (f) => f<T>();

  /// A getter for the type of this mapper.
  Type get type => T;

  bool isFor(dynamic v) => v is T;
  bool isForType(Type type) => type.base == T;
}

abstract interface class CodableMapper<T> implements Mapper<T> {
  Codable<T> get codable;
}

abstract interface class CodableMapper1<T> implements Mapper<T> {
  Codable<T> codable<A>([Codable<A>? codableA]);
}

abstract interface class CodableMapper2<T> implements Mapper<T> {
  Codable<T> codable<A, B>([Codable<A>? codableA, Codable<B>? codableB]);
}
