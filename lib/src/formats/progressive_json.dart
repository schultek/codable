import 'dart:async';
import 'dart:convert' hide JsonDecoder;
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';

import '../helpers/binary_tokens.dart';
import 'json.dart';

extension ProgressiveJsonDecodable<T> on Decodable<T> {
  /// Decodes a progressive JSON byte stream into a [Stream] of [T].
  Stream<T> fromProgressiveJsonStream(Stream<List<int>> bytes) {
    return ProgressiveJsonDecoder.decode<T>(bytes, this);
  }

  /// Decodes progressive JSON bytes into [T].
  T fromProgressiveJson(List<int> bytes) {
    return ProgressiveJsonDecoder.decodeSync<T>(bytes, this);
  }
}

extension ProgressiveJsonEncodable<T> on Encodable<T> {
  /// Encodes the value to a [Stream] of progressive JSON bytes.
  Stream<List<int>> toProgressiveJsonStream(T value) {
    return ProgressiveJsonEncoder.encode<T>(value, using: this);
  }

  List<int> toProgressiveJson(T value) {
    return ProgressiveJsonEncoder.encodeSync<T>(value, using: this);
  }
}

extension ProgressiveJsonSelfEncodableSelf<T extends SelfEncodable> on T {
  Stream<List<int>> toProgressiveJsonStream() {
    return ProgressiveJsonEncoder.encode<T>(this);
  }

  List<int> toProgressiveJson() {
    return ProgressiveJsonEncoder.encodeSync<T>(this);
  }
}

extension ProgressiveJsonSelfEncodableStreamSelf<T extends SelfEncodable> on Stream<T> {
  Stream<List<int>> toProgressiveJson() {
    return ProgressiveJsonEncoder.encode<Stream<T>>(this);
  }
}

abstract class _ReferenceValue {
  Object decode<T>(Decodable<T>? decodable);
  void addValue(Decoder decoder);
  void done();
}

class _AsyncReferenceValue implements _ReferenceValue {
  _AsyncReferenceValue();

  final List<StreamController<Decoder>> _controllers = [];
  final List<Decoder> _decoders = [];
  final Map<Decoder, dynamic> _values = {};
  bool _closed = false;

  @override
  Stream<T> decode<T>(Decodable<T>? decodable) {
    final controller = StreamController<Decoder>();
    _controllers.add(controller);

    for (final decoder in _decoders) {
      controller.add(decoder);
    }

    if (_closed) {
      controller.close();
    }

    return controller.stream.map<T>((decoder) {
      if (_values.containsKey(decoder) && _values[decoder] is T) {
        return _values[decoder] as T;
      }
      return _values[decoder] = decoder.clone().decodeObject<T>(using: decodable);
    });
  }

  @override
  void addValue(Decoder decoder) {
    for (final controller in _controllers) {
      controller.add(decoder);
    }
    _decoders.add(decoder);
  }

  @override
  void done() {
    for (final controller in _controllers) {
      controller.close();
    }
    _controllers.clear();
    _closed = true;
  }
}

class _SyncReferenceValue implements _ReferenceValue {
  _SyncReferenceValue() : _ref = Reference<Decoder>.late();

  final Reference<Decoder> _ref;

  Reference? _value;
  @override
  Reference<T> decode<T>(Decodable<T>? decodable) {
    if (_value is Reference<T>) {
      return _value as Reference<T>;
    }
    final ref = _value = Reference<T>.late();
    _ref.get((decoder) {
      ref.set(decoder.decodeObject<T>(using: decodable));
    });
    return ref;
  }

  @override
  void addValue(Decoder decoder) {
    _ref.set(decoder);
  }

  @override
  void done() {}
}

class ProgressiveJsonDecoder extends JsonDecoder {
  ProgressiveJsonDecoder._(
    super.bytes, [
    super.offset = 0,
    this._isSync = false,
    Map<int, _ReferenceValue>? refs,
  ]) : _refs = refs ?? {};

  final bool _isSync;
  final Map<int, _ReferenceValue> _refs;

  static Stream<T> decode<T>(Stream<List<int>> value, Decodable<T> decodable) {
    final stream = value.transform(_LineSplitter());

    Map<int, _ReferenceValue>? refs = {};

    final marker = refs[0] = _AsyncReferenceValue(); // Initialize with a value for marker 0

    stream.listen((bytes) {
      if (bytes.isEmpty) {
        return; // Skip empty data
      }
      _parseBytes(bytes, refs, false);
    }, onDone: () {
      for (final value in refs.values) {
        value.done();
      }
    });

    return marker.decode<T>(decodable);
  }

  static T decodeSync<T>(List<int> value, Decodable<T> decodable) {
    final lines = _LineSplitter.convert(value);

    Map<int, _ReferenceValue>? refs = {};

    final marker = refs[0] = _SyncReferenceValue(); // Initialize with a value for marker 0

    for (final line in lines) {
      if (line.isEmpty) {
        continue; // Skip empty lines
      }
      _parseBytes(line, refs, true);
    }

    late T result;

    marker.decode<T>(decodable).get((v) => result = v);

    return result;
  }

  static void _parseBytes(List<int> bytes, Map<int, _ReferenceValue> refs, bool isSync) {
    final decoder = ProgressiveJsonDecoder._(bytes, 0, isSync, refs);
    final marker = decoder._parseLineMarker();
    final value = refs[marker] ??= (isSync ? _SyncReferenceValue() : _AsyncReferenceValue());
    value.addValue(decoder);
  }

  @override
  DecodingType whatsNext() {
    skipWhitespace(); // Ensure we are at the start of a new value
    if (buffer[offset] == tokenDollarSign) {
      return const DecodingType<Stream>.custom();
    }
    return super.whatsNext();
  }

  int _parseLineMarker() {
    if (buffer[offset] != tokenDollarSign) {
      return 0; // No marker found, return 0
    }

    skipBytes(1); // Skip the dollar sign
    final marker = decodeInt();

    assert(
      buffer[offset] == tokenColon,
      'Expected a colon after marker, but found ${String.fromCharCode(buffer[offset])}',
    );
    skipBytes(1); // Skip the colon

    return marker;
  }

  int? _readMarker() {
    skipWhitespace(); // Ensure we are at the start of a new value
    if (buffer[offset] != tokenDollarSign) {
      return null;
    }

    skipBytes(1); // Skip the dollar sign
    return decodeInt();
  }

  Stream _createStream(int marker, AsyncDecodable? using) {
    var value = (_refs[marker] ??= _AsyncReferenceValue()) as _AsyncReferenceValue;
    if (using == null) {
      return value.decode(null);
    }
    return using.extract(<T>(child) {
      return value.decode<T>(child);
    });
  }

  Reference _createReference(int marker, ReferenceDecodable? using) {
    var value = (_refs[marker] ??= _SyncReferenceValue()) as _SyncReferenceValue;
    if (using == null) {
      return value.decode(null);
    }
    return using.extract(<T>(child) {
      return value.decode<T>(child);
    });
  }

  @override
  T decodeObject<T>({Decodable<T>? using}) {
    if (<T>[] is List<Stream> && (using is AsyncDecodable || using == null)) {
      final marker = _readMarker();
      if (marker == null) {
        expect('Stream');
      }
      return _createStream(marker, using is AsyncDecodable ? using as AsyncDecodable : null) as T;
    }
    if (<T>[] is List<Future> && (using is AsyncDecodable || using == null)) {
      final marker = _readMarker();
      if (marker == null) {
        expect('Future');
      }
      return _createStream(marker, using is AsyncDecodable ? using as AsyncDecodable : null).first as T;
    }
    if (<T>[] is List<Reference> && (using is ReferenceDecodable || using == null)) {
      final marker = _readMarker();
      if (marker == null) {
        expect('Reference');
      }
      return _createReference(marker, using is ReferenceDecodable ? using as ReferenceDecodable : null) as T;
    }
    if (using == null) {
      final marker = _readMarker();
      if (marker != null) {
        return (_isSync ? _createReference(marker, null) : _createStream(marker, null)) as T;
      }
    }
    return super.decodeObject<T>(using: using);
  }

  @override
  ProgressiveJsonDecoder clone() {
    return ProgressiveJsonDecoder._(buffer, offset, _isSync, _refs);
  }
}

abstract class _EncodingValues<T> {
  _EncodingValues();

  void addValue(data, int marker);
  int? get(dynamic ref);

  int addStream(Stream stream, AsyncEncodable? using);
  int addFuture(Future future, AsyncEncodable? using);
  int addReference(Reference ref);

  List<int> _encodeItem(dynamic value, int marker, Encodable? using) {
    final encoder = ProgressiveJsonEncoder._(this);
    if (marker != 0) {
      encoder.encodeMarker(marker);
    }

    encoder.encodeObject(value);

    final bytes = encoder.toBytes() + [0x0A]; // Add newline at the end
    return bytes;
  }
}

class _AsyncEncodingValues extends _EncodingValues<Future<void>> {
  _AsyncEncodingValues(this._group);

  final StreamGroup<List<int>> _group;
  final Map<Object?, int> _objects = {};
  final Set<int> _markers = {};

  @override
  void addValue(data, int marker) {
    if (data is Object && data is! String && data is! bool && data is! num) {
      _objects[data] = marker;
    }
  }

  @override
  int? get(dynamic ref) => _objects[ref];

  @override
  int addStream(Stream stream, AsyncEncodable? using) {
    final marker = _objects[stream] ??= (_markers.length);
    _addStream(marker, stream, using);
    return marker;
  }

  @override
  int addFuture(Future future, AsyncEncodable? using) {
    final marker = _objects[future] ??= (_markers.length);
    _addStream(marker, future.asStream(), using);
    return marker;
  }

  void _addStream(int marker, Stream stream, AsyncEncodable? using) {
    if (!_markers.contains(marker)) {
      _markers.add(marker);
      _group.add(stream.map((value) {
        addValue(value, marker);
        return _encodeItem(value, marker, using?.using);
      }));
    }
  }

  @override
  int addReference(Reference ref) {
    final marker = _objects[ref.sentinel] ??= (_markers.length);

    if (!_markers.contains(marker)) {
      _markers.add(marker);
      var completer = Completer<List<int>>.sync();
      _group.add(completer.future.asStream());
      ref.get((value) {
        addValue(value, marker);
        completer.complete(_encodeItem(value, marker, ref.using));
      });
    }

    return marker;
  }
}

class _SyncEncodingValues extends _EncodingValues<void> {
  _SyncEncodingValues(this._sink);

  final Sink<List<int>> _sink;
  final Map<Object?, int> _objects = {};
  final List<void Function()> _callbacks = [];
  int _count = 0;

  @override
  void addValue(data, int marker) {
    if (data is Object && data is! String && data is! bool && data is! num) {
      _objects[data] = marker;
    }
  }

  @override
  int? get(dynamic ref) => _objects[ref];

  void done() async {
    while (_callbacks.isNotEmpty) {
      _callbacks.removeLast()();
    }
  }

  @override
  int addStream(Stream stream, AsyncEncodable? using) {
    throw UnsupportedError('Cannot add stream in sync encoder.');
  }

  @override
  int addFuture(Future future, AsyncEncodable? using) {
    throw UnsupportedError('Cannot add future in sync encoder.');
  }

  @override
  int addReference(Reference ref) {
    final marker = _objects[ref] ??= _count;

    if (_count <= marker) {
      _callbacks.insert(0, () {
        ref.get((value) {
          addValue(value, marker);
          _sink.add(_encodeItem(value, marker, ref.using));
        });
      });
      _count++;
    }

    return marker;
  }
}

class ProgressiveJsonEncoder extends JsonEncoder {
  ProgressiveJsonEncoder._(this._values);

  final _EncodingValues _values;

  static Stream<List<int>> encode<T>(T value, {Encodable<T>? using}) {
    final group = StreamGroup<List<int>>();
    final values = _AsyncEncodingValues(group);

    final encoder = ProgressiveJsonEncoder._(values);

    if (value is Future || value is Stream || value is Reference) {
      encoder.encodeObject<T>(value, using: using);
    } else {
      encoder.encodeObject<Reference<T>>(Reference(value, using: using));
    }

    var bytes = encoder.toBytes();

    if (bytes case [tokenDollarSign, 0x30 /* '0' */]) {
      // Skip if the data is just a marker with no value
    } else {
      group.add(Stream.value(bytes + [0x0A])); // Add newline at the end
    }

    if (group.isIdle) {
      group.close();
    } else {
      group.onIdle.listen((_) {
        group.close();
      });
    }

    return group.stream;
  }

  static List<int> encodeSync<T>(T value, {Encodable<T>? using}) {
    late List<int> out;

    final sink = ByteConversionSink.withCallback((result) {
      out = result;
    });
    final values = _SyncEncodingValues(sink);

    final encoder = ProgressiveJsonEncoder._(values);
    if (value is Reference) {
      encoder.encodeObject<T>(value, using: using);
    } else {
      encoder.encodeObject<Reference<T>>(Reference(value, using: using));
    }
    var bytes = encoder.toBytes();

    if (bytes case [tokenDollarSign, 0x30 /* '0' */]) {
      // Skip if the data is just a marker with no value
    } else {
      sink.add(bytes + [0x0A]); // Add newline at the end
    }

    values.done();
    sink.close();

    return out;
  }

  void encodeMarker(int marker) {
    writeByte(tokenDollarSign);
    encodeNum(marker);
    if (buffer[offset - 1] == tokenComma) {
      buffer[offset - 1] = tokenColon;
    } else {
      writeByte(tokenColon);
    }
    _marker = marker;
  }

  int _marker = 0;

  @override
  bool canEncodeCustom<T>() {
    if (T == Reference) {
      return true;
    }
    if (_values is _AsyncEncodingValues && (T == Stream || T == Future)) {
      return true;
    }
    return false;
  }

  void _encodeMarker(int marker) {
    writeByte(tokenDollarSign);
    encodeNum(marker);
  }

  @override
  void encodeObject<T>(T value, {Encodable<T>? using}) {
    if (value is Stream && (using is AsyncEncodable || using == null)) {
      final marker = _values.addStream(value, using is AsyncEncodable ? using as AsyncEncodable : null);
      _encodeMarker(marker);
    } else if (value is Future && (using is AsyncEncodable || using == null)) {
      final marker = _values.addFuture(value, using is AsyncEncodable ? using as AsyncEncodable : null);
      _encodeMarker(marker);
    } else if (value is Reference) {
      final marker = _values.addReference(value);
      _encodeMarker(marker);
    } else if (_values.get(value) case int marker when marker != _marker) {
      _encodeMarker(marker);
    } else {
      super.encodeObject(value, using: using);
    }
  }
}

final class _LineSplitter extends StreamTransformerBase<List<int>, List<int>> {
  const _LineSplitter();

  static List<List<int>> convert(List<int> data) {
    var lines = <List<int>>[];
    var end = data.length;
    var sliceStart = 0;
    var char = 0;
    for (var i = 0; i < end; i++) {
      var previousChar = char;
      char = data[i];
      if (char != _CR) {
        if (char != _LF) continue;
        if (previousChar == _CR) {
          sliceStart = i + 1;
          continue;
        }
      }
      lines.add(data.sublist(sliceStart, i));
      sliceStart = i + 1;
    }
    if (sliceStart < end) {
      lines.add(data.sublist(sliceStart, end));
    }
    return lines;
  }

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) {
    return Stream<List<int>>.eventTransformed(
      stream,
      (sink) => _LineSplitterEventSink(sink),
    );
  }
}

class _LineSplitterEventSink extends _LineSplitterSink implements EventSink<List<int>> {
  final EventSink<List<int>> _eventSink;

  _LineSplitterEventSink(EventSink<List<int>> eventSink)
      : _eventSink = eventSink,
        super(ByteConversionSink.from(eventSink));

  @override
  void addError(Object o, [StackTrace? stackTrace]) {
    _eventSink.addError(o, stackTrace);
  }
}

// ignore: constant_identifier_names
const int _LF = 10;
// ignore: constant_identifier_names
const int _CR = 13;

class _LineSplitterSink extends ByteConversionSink {
  final ByteConversionSink _sink;

  /// The carry-over from the previous chunk.
  ///
  /// If the previous slice ended in a line without a line terminator,
  /// then the next slice may continue the line.
  ///
  /// Set to `null` if there is no carry (the previous chunk ended on
  /// a line break).
  /// Set to an empty string if carry-over comes from multiple chunks,
  /// in which case the parts are stored in [_multiCarry].
  List<int>? _carry;

  /// Cache of multiple parts of carry-over.
  ///
  /// If a line is split over multiple chunks, avoid doing
  /// repeated string concatenation, and instead store the chunks
  /// into this stringbuffer.
  ///
  /// Is empty when `_carry` is `null` or a non-empty string.
  BytesBuilder? _multiCarry;

  /// Whether to skip a leading LF character from the next slice.
  ///
  /// If the previous slice ended on a CR character, a following LF
  /// would be part of the same line termination, and should be ignored.
  ///
  /// Only `true` when [_carry] is `null`.
  bool _skipLeadingLF = false;

  _LineSplitterSink(this._sink);

  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    end = RangeError.checkValidRange(start, end, chunk.length);
    // If the chunk is empty, it's probably because it's the last one.
    // Handle that here, so we know the range is non-empty below.
    if (start < end) {
      if (_skipLeadingLF) {
        if (chunk[start] == _LF) {
          start += 1;
        }
        _skipLeadingLF = false;
      }
      _addLines(chunk, start, end, isLast);
    }
    if (isLast) close();
  }

  @override
  void add(List<int> chunk) {
    addSlice(chunk, 0, chunk.length, false);
  }

  @override
  void close() {
    var carry = _carry;
    if (carry != null) {
      _sink.add(_useCarry(carry, []));
    }
    _sink.close();
  }

  void _addLines(List<int> lines, int start, int end, bool isLast) {
    var sliceStart = start;
    var char = 0;
    var carry = _carry;

    for (var i = start; i < end; i++) {
      var previousChar = char;
      char = lines[i];
      if (char != _CR) {
        if (char != _LF) continue;
        if (previousChar == _CR) {
          sliceStart = i + 1;
          continue;
        }
      }
      var slice = lines.sublist(sliceStart, i);
      if (carry != null) {
        slice = _useCarry(carry, slice); // Resets _carry to `null`.
        carry = null;
      }
      _sink.add(slice);

      sliceStart = i + 1;
    }

    if (sliceStart < end) {
      var endSlice = lines.sublist(sliceStart, end);
      if (isLast) {
        // Emit last line instead of carrying it over to the
        // immediately following `close` call.
        if (carry != null) {
          endSlice = _useCarry(carry, endSlice);
        }
        _sink.add(endSlice);
        return;
      }
      if (carry == null) {
        // Common case, this chunk contained at least one line-break.
        _carry = endSlice;
      } else {
        _addCarry(carry, endSlice);
      }
    } else {
      _skipLeadingLF = (char == _CR);
    }
  }

  /// Adds [newCarry] to existing carry-over.
  ///
  /// Always goes into [_multiCarry], we only call here if there
  /// was an existing carry that the new carry needs to be combined with.
  ///
  /// Only happens when a line is spread over more than two chunks.
  /// The [existingCarry] is always the current value of [_carry].
  /// (We pass the existing carry as an argument because we have already
  /// checked that it is non-`null`.)
  void _addCarry(List<int> existingCarry, List<int> newCarry) {
    assert(existingCarry == _carry);
    assert(newCarry.isNotEmpty);
    var multiCarry = _multiCarry ??= BytesBuilder();
    if (existingCarry.isNotEmpty) {
      assert(multiCarry.isEmpty);
      multiCarry.add(existingCarry);
      _carry = [];
    }
    multiCarry.add(newCarry);
  }

  /// Consumes and combines existing carry-over with continuation string.
  ///
  /// The [carry] value is always the current value of [_carry],
  /// which is non-`null` when this method is called.
  /// If that value is the empty string, the actual carry-over is stored
  /// in [_multiCarry].
  ///
  /// The [continuation] is only empty if called from [close].
  List<int> _useCarry(List<int> carry, List<int> continuation) {
    assert(carry == _carry);
    _carry = null;
    if (carry.isNotEmpty) {
      return carry + continuation;
    }
    var multiCarry = _multiCarry!;
    multiCarry.add(continuation);
    var result = multiCarry.toBytes();
    // If it happened once, it may happen again.
    // Keep the string buffer around.
    multiCarry.clear();
    return result;
  }
}
