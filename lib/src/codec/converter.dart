import 'dart:convert';

// A simple converter that just calls a callback.
class CallbackConverter<S, T> extends Converter<S, T> {
  final T Function(S input) _convert;

  CallbackConverter(this._convert);

  @override
  T convert(S input) => _convert(input);
}
