import 'dart:convert';

// A simple converter that just calls a callback.
class CallbackConverter<S, T, U> extends Converter<S, T> {
  final T Function(S input, {required U using}) _convert;
  final U using;

  const CallbackConverter(this._convert, this.using);

  @override
  T convert(S input) => _convert(input, using: using);
}
