import 'package:codable_dart/core.dart';

abstract base class CustomTypeDelegate<T> implements Codable<T> {
  const CustomTypeDelegate();

  DecodingType<T>? _checkValue(dynamic value) => value is T ? DecodingType<T>.custom() : null;
}

extension CustomTypeExtension on Iterable<CustomTypeDelegate> {
  DecodingType? whatsNext(dynamic value) => map((e) => e._checkValue(value)).whereType<DecodingType>().firstOrNull;
}
