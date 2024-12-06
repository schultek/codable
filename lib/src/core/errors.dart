// A collection of errors that can be thrown by implementations using the codable package.
class CodableException implements Exception {
  CodableException._(this.message);

  final String message;

  @override
  String toString() => 'CodableException: $message';

  factory CodableException.wrap(Object error, {required String method, required String hint}) {
    if (error is WrappedCodableException) {
      return WrappedCodableException(method, '$hint->${error.hint}', error.error);
    } else {
      return WrappedCodableException(method, hint, error);
    }
  }

  /// Throws an [UnsupportedError] with the message "Unsupported method: 'Class.method()'".
  /// The message will include a reason if provided.
  ///
  /// It should primarily be used by a [Decoder] implementation when a decoding method is called that is not supported.
  /// For example, when calling [decodeList] on [CsvDecoder], the error would read
  /// "Unsupported operation: 'CsvDecoder.decodeList()'. The csv format does not support nested lists.".
  ///
  /// The [clazz] parameter is the class name.
  /// The [method] parameter is the method name.
  /// The [reason] parameter is an optional reason for why the method is not supported.
  factory CodableException.unsupportedMethod(String clazz, String method, {Object? reason}) {
    var message = "'$clazz.$method()'";
    if (reason != null) {
      message += '. $reason';
    }

    return CodableUnsupportedError(message);
  }

  /// Throws a [FormatException] with the message 'Unexpected type: Expected x but got y "..." at offset z.'.
  /// The message will include the expected type, the actual type if provided and the actual token at the provided offset if available.
  ///
  /// It should be used by a [Decoder] implementation when the [Decoder.expect] method is called, or when an unexpected
  /// token in the encoded data is encountered. For example, when a [Decodable] implementation calls [Decoder.decodeString]
  /// but the next token is not a string, the error would read 'Unexpected type: Expected string but got number "42" at offset 123.'.
  ///
  /// The [expected] parameter is the expected type.
  /// The [actual] parameter is the actual type if available.
  /// The [data] parameter is the encoded data. Supported types are String and List<int>.
  /// The [offset] parameter is the offset in the encoded data where the unexpected token was found.
  factory CodableException.unexpectedType({required String expected, String? actual, Object? data, int? offset}) {
    var message = 'Unexpected type: Expected $expected';
    var actualToken = _tokenAt(data, offset);
    if (actual != null) {
      message += ' but got $actual';
      if (actualToken != null) {
        message += ' $actualToken';
      }
    } else if (actualToken != null) {
      message += ' but got $actualToken';
    }
    if (offset != null) {
      message += 'at offset $offset';
    }
    message += '.';

    return CodableFormatException(message, data, offset);
  }

  /// Returns a substring of the source data starting at the given offset and of length 5.
  ///
  /// The [data] parameter must be a String or a List<int>.
  static String? _tokenAt(Object? data, int? offset) {
    String? token;
    if (offset != null) {
      if (data is String) {
        offset = offset.clamp(0, data.length);
        token = data.substring(offset, offset + 5);
      } else if (data is List<int>) {
        offset = offset.clamp(0, data.length);
        token = String.fromCharCodes(data, offset, offset + 5);
      }
    }
    if (token != null) {
      return '"${token.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
    }
    return null;
  }
}

class CodableFormatException extends FormatException implements CodableException {
  CodableFormatException(super.message, super.source, super.offset);

  @override
  String toString() => 'CodableException: ${super.toString().substring('FormatException: '.length)}';
}

class CodableUnsupportedError extends UnsupportedError implements CodableException {
  CodableUnsupportedError(super.message);

  @override
  String get message => 'Unsupported method ${super.message!}';

  @override
  String toString() => 'CodableException: $message';
}

class WrappedCodableException implements CodableException {
  WrappedCodableException(this.method, this.hint, this.error);

  final String method;
  final String hint;
  final Object error;

  @override
  String get message =>
      'Failed to $method $hint: ${error is CodableException ? (error as CodableException).message : error}';

  @override
  String toString() {
    return 'CodableException: $message';
  }
}
