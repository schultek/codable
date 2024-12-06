/// Protocol for encoding and decoding objects to various data formats.
///
/// This library contains only the core protocol interfaces and classes.
/// - For reference implementations of common data formats see the `implementation` library.
/// - For extensions, helpers and utilities that make working with the protocol more convenient
///   see the `extended` library.
/// - For a high-level API that combines the protocol with end-user abstractions see the `mapper` library.
library core;

export 'src/core/interface.dart';
export 'src/core/decoder.dart';
export 'src/core/encoder.dart';
export 'src/core/errors.dart';
