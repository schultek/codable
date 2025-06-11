// COPYRIGHT NOTICE: 
// This file contains code derived from the 'crimson' package, 
// licensed under Apache License 2.0 by Simon Choi.

/// JSON reference implementation.
///
/// A format that encodes models to a JSON string or bytes.
library json;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';
import 'package:codable_dart/standard.dart';
import 'package:meta/meta.dart';

import '../helpers/binary_tokens.dart';

extension JsonDecodable<T> on Decodable<T> {
  T fromJson(String json) {
    return fromJsonBytes(utf8.encode(json));
  }

  T fromJsonBytes(List<int> bytes) {
    return JsonDecoder.decode<T>(bytes, this);
  }
}

extension JsonEncodable<T> on Encodable<T> {
  String toJson(T value) {
    return utf8.decode(toJsonBytes(value));
  }

  List<int> toJsonBytes(T value) {
    return JsonEncoder.encode<T>(value, using: this);
  }
}

extension JsonSelfEncodableSelf<T extends SelfEncodable> on T {
  String toJson() {
    return utf8.decode(toJsonBytes());
  }

  List<int> toJsonBytes() {
    return JsonEncoder.encode<T>(this);
  }
}

class JsonDecoder implements Decoder, IteratedDecoder, KeyedDecoder {
  JsonDecoder(this.buffer, [int offset = 0]) : _offset = offset;

  final List<int> buffer;
  late Uint16List _stringBuffer = Uint16List(256);

  int _offset;
  @protected
  int get offset => _offset;

  static T decode<T>(List<int> value, Decodable<T> decodable) {
    return decodable.decode(JsonDecoder(value));
  }

  @override
  DecodingType whatsNext() {
    skipWhitespace();
    return switch (buffer[_offset]) {
      tokenDoubleQuote => DecodingType.string,
      tokenT || tokenF => DecodingType.bool,
      tokenN => DecodingType.nil,
      tokenLBrace => DecodingType.keyed,
      tokenLBracket => DecodingType.iterated,
      _ => DecodingType.num,
    };
  }

  @override
  bool decodeBool() {
    skipWhitespace();
    switch (buffer[_offset]) {
      case tokenT:
        _offset += 4;
        return true;
      case tokenF:
        _offset += 5;
        return false;
      default:
        expect('bool');
    }
  }

  @override
  bool? decodeBoolOrNull() {
    skipWhitespace();
    switch (buffer[_offset]) {
      case tokenT:
        _offset += 4;
        return true;
      case tokenF:
        _offset += 5;
        return false;
      case tokenN:
        _offset += 4;
        return null;
      default:
        expect('bool or null');
    }
  }

  @override
  double decodeDouble() {
    skipWhitespace();
    return _readNum().toDouble();
  }

  @override
  double? decodeDoubleOrNull() {
    skipWhitespace();
    if (buffer[_offset] == tokenN) {
      _offset += 4;
      return null;
    } else {
      return _readNum().toDouble();
    }
  }

  @override
  int decodeInt() {
    skipWhitespace();
    return _readInt();
  }

  @override
  int? decodeIntOrNull() {
    skipWhitespace();
    if (buffer[_offset] == tokenN) {
      _offset += 4;
      return null;
    } else {
      return _readInt();
    }
  }

  @override
  num decodeNum() {
    skipWhitespace();
    return _readNum();
  }

  @override
  num? decodeNumOrNull() {
    skipWhitespace();
    if (buffer[_offset] == tokenN) {
      _offset += 4;
      return null;
    } else {
      return _readNum();
    }
  }

  @override
  String decodeString() {
    skipWhitespace();
    return _readString();
  }

  @override
  String? decodeStringOrNull() {
    skipWhitespace();
    if (buffer[_offset] == tokenN) {
      _offset += 4;
      return null;
    }
    return _readString();
  }

  @override
  bool decodeIsNull() {
    skipWhitespace();
    if (buffer[_offset] == tokenN) {
      _offset += 4;
      return true;
    } else {
      return false;
    }
  }

  @override
  T decodeObject<T>({Decodable<T>? using}) {
    if (using != null) {
      return using.decode(this);
    } else {
      return _read() as T;
    }
  }

  @override
  T? decodeObjectOrNull<T>({Decodable<T>? using}) {
    if (decodeIsNull()) return null;
    return decodeObject(using: using);
  }

  @override
  List<I> decodeList<I>({Decodable<I>? using}) {
    return [
      for (; nextItem();) decodeObject(using: using),
    ];
  }

  @override
  List<I>? decodeListOrNull<I>({Decodable<I>? using}) {
    if (decodeIsNull()) return null;
    return decodeList(using: using);
  }

  @override
  Map<K, V> decodeMap<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    return {
      for (String? key; (key = nextKey()) != null;)
        if (key is K && keyUsing == null)
          key as K: decodeObject<V>(using: valueUsing)
        else
          StandardDecoder.decode<K>(key, using: keyUsing): decodeObject<V>(using: valueUsing),
    };
  }

  @override
  Map<K, V>? decodeMapOrNull<K, V>({Decodable<K>? keyUsing, Decodable<V>? valueUsing}) {
    if (decodeIsNull()) return null;
    return decodeMap(keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @override
  IteratedDecoder decodeIterated() {
    return this;
  }

  @override
  KeyedDecoder decodeKeyed() {
    return this;
  }

  @override
  MappedDecoder decodeMapped() {
    return CompatMappedDecoder.wrap(this);
  }

  @override
  bool nextItem() {
    skipWhitespace();
    switch (buffer[_offset++]) {
      case tokenLBracket:
      case tokenComma:
        skipWhitespace();
        if (buffer[_offset] == tokenRBracket) {
          _offset++;
          return false;
        }
        return true;
      case tokenRBracket:
        return false;
      default:
        _expect('[ or , or ]', _offset - 1);
    }
  }

  @override
  String? nextKey() {
    skipWhitespace();
    switch (buffer[_offset++]) {
      case tokenLBrace:
      case tokenComma:
        skipWhitespace();
        if (buffer[_offset] == tokenRBrace) {
          _offset++;
          return null;
        }

        final field = _readString();
        skipWhitespace();
        if (buffer[_offset++] != tokenColon) {
          _expect(':', _offset - 1);
        }
        return field;
      case tokenRBrace:
        return null;
      default:
        _expect('{ or , or }', _offset - 1);
    }
  }

  @override
  void skipCurrentItem() {
    return _skip();
  }

  @override
  void skipCurrentValue() {
    return _skip();
  }

  @override
  void skipRemainingKeys() {
    var level = 1;
    var i = _offset;
    while (true) {
      switch (buffer[i++]) {
        case tokenDoubleQuote: // If inside string, skip it
          _offset = i;
          _skipString();
          i = _offset;
          break;
        case tokenLBrace: // If open symbol, increase level
          level++;
          break;
        case tokenRBrace: // If close symbol, decrease level
          level--;

          // If we have returned to the original level, we're done
          if (level == 0) {
            _offset = i;
            return;
          }
          break;
      }
    }
  }

  @override
  void skipRemainingItems() {
    var level = 1;
    var i = _offset;
    while (true) {
      switch (buffer[i++]) {
        case tokenDoubleQuote: // If inside string, skip it
          _offset = i;
          _skipString();
          i = _offset;
          break;
        case tokenLBracket: // If open symbol, increase level
          level++;
          break;
        case tokenRBracket: // If close symbol, decrease level
          level--;
          // If we have returned to the original level, we're done
          if (level == 0) {
            _offset = i;
            return;
          }
          break;
      }
    }
  }

  @override
  bool isHumanReadable() {
    return true;
  }

  @override
  JsonDecoder clone() {
    return JsonDecoder(buffer, _offset);
  }

  @override
  Never expect(String expected) {
    _expect(expected, _offset);
  }

  Never _expect(String expected, int offset) {
    throw CodableException.unexpectedType(
      expected: expected,
      data: buffer,
      offset: offset,
    );
  }

  @pragma('vm:prefer-inline')
  dynamic _read() {
    skipWhitespace();
    switch (buffer[_offset]) {
      case tokenDoubleQuote:
        return _readString();
      case tokenT:
        _offset += 4;
        return true;
      case tokenF:
        _offset += 5;
        return false;
      case tokenN:
        _offset += 4;
        return null;
      case tokenLBracket:
        return decodeList<dynamic>();
      case tokenLBrace:
        return decodeMap<String, dynamic>();
      default:
        return _readNum();
    }
  }

  @protected
  void skipBytes(int count) {
    _offset += count;
    if (_offset > buffer.length) {
      throw RangeError.range(_offset, 0, buffer.length, 'offset');
    }
  }

  @pragma('vm:prefer-inline')
  @protected
  void skipWhitespace() {
    var i = _offset;
    if (buffer[i] > tokenSpace) {
      return;
    }

    while (buffer[++i] <= tokenSpace) {}
    _offset = i;
  }

  num _readNum() {
    final start = _offset;
    var i = start;
    var exponent = 0;
    // Added to exponent for each digit. Set to -1 when seeing '.'.
    var exponentDelta = 0;
    var sign = 1.0;

    if (buffer[i] == tokenMinus) {
      sign = -1.0;
      i++;
    }

    var doubleValue = (buffer[i++] ^ tokenZero).toDouble();
    if (doubleValue > 9) {
      _expect('number', i - 1);
    }

    while (true) {
      final c = buffer[i++];
      final digit = c ^ tokenZero;
      if (digit <= 9) {
        doubleValue = 10.0 * doubleValue + digit;
        exponent += exponentDelta;
      } else if (c == tokenPeriod && exponentDelta == 0) {
        exponentDelta = -1;
      } else if (c == tokenE || c == tokenUpperE) {
        var expValue = 0;
        var expSign = 1;
        if (buffer[i] == tokenMinus) {
          expSign = -1;
          i++;
        } else if (buffer[i] == tokenPlus) {
          i++;
        }
        while (true) {
          final c = buffer[i++];
          final digit = c ^ tokenZero;
          if (digit <= 9) {
            expValue = 10 * expValue + digit;
          } else {
            break;
          }
        }
        exponent += expSign * expValue;
        break;
      } else {
        break;
      }
    }

    _offset = i - 1;

    if (exponent == 0) {
      if (doubleValue <= maxInt) {
        return (sign * doubleValue).toInt();
      } else {
        return sign * doubleValue;
      }
    } else if (exponent < 0) {
      final negExponent = -exponent;
      if (negExponent < powersOfTen.length) {
        return sign * (doubleValue / powersOfTen[negExponent]);
      }
    } else if (exponent < powersOfTen.length) {
      return sign * (doubleValue * powersOfTen[exponent]);
    }

    final string = String.fromCharCodes(buffer, start, _offset);
    return num.parse(string);
  }

  int _readInt() {
    var i = _offset;
    var sign = 1;
    if (buffer[i] == tokenMinus) {
      sign = -1;
      i++;
    }

    var value = buffer[i++] ^ tokenZero;
    if (value > 9) {
      _expect('number', i - 1);
    }

    while (true) {
      final digit = buffer[i++] ^ tokenZero;
      if (digit <= 9) {
        value = 10 * value + digit;
      } else {
        break;
      }
    }

    _offset = i - 1;
    return sign * value;
  }

  String _readString() {
    if (buffer[_offset] != tokenDoubleQuote) {
      _expect('"', _offset);
    }
    final start = _offset + 1;
    var i = start;
    while (true) {
      final c = buffer[i++];
      if (c == tokenDoubleQuote) {
        _offset = i;
        return String.fromCharCodes(buffer, start, i - 1);
      } else if (c == tokenBackslash || c >= 128) {
        // If we encounter a backslash, which is a beginning of an escape
        // sequence or a high bit was set - indicating an UTF-8 encoded
        // multibyte character, there is no chance that we can decode the string
        // without instantiating a temporary buffer
        _offset = start;
        return _readStringSlowPath();
      }
    }
  }

  String _readStringSlowPath() {
    var i = _offset;
    var strBuf = _stringBuffer;
    var si = 0;
    while (true) {
      var bc = buffer[i++];
      if (bc == tokenDoubleQuote) {
        _offset = i;
        _stringBuffer = strBuf;
        return String.fromCharCodes(strBuf, 0, si);
      } else if (bc == tokenBackslash) {
        final nextChar = buffer[i++];
        if (nextChar == tokenU) {
          bc = (_parseHexDigit(i++) << 12) +
              (_parseHexDigit(i++) << 8) +
              (_parseHexDigit(i++) << 4) +
              _parseHexDigit(i++);
        } else {
          bc = _readEscapeSequence(nextChar);
        }
      } else if ((bc & 0x80) != 0) {
        final u2 = buffer[i++];
        if ((bc & 0xE0) == 0xC0) {
          bc = ((bc & 0x1F) << 6) + (u2 & 0x3F);
        } else {
          final u3 = buffer[i++];
          if ((bc & 0xF0) == 0xE0) {
            bc = ((bc & 0x0F) << 12) + ((u2 & 0x3F) << 6) + (u3 & 0x3F);
          } else {
            final u4 = buffer[i++];
            bc = ((bc & 0x07) << 18) + ((u2 & 0x3F) << 12) + ((u3 & 0x3F) << 6) + (u4 & 0x3F);

            if (bc >= 0x10000) {
              // split surrogates
              final sup = bc - 0x10000;
              if (si >= strBuf.length - 1) {
                strBuf = Uint16List((strBuf.length * 1.5).toInt())..setRange(0, si, strBuf);
              }
              strBuf[si++] = (sup >>> 10) + 0xd800;
              strBuf[si++] = (sup & 0x3ff) + 0xdc00;
              continue;
            }
          }
        }
      }
      if (si == strBuf.length) {
        strBuf = Uint16List((strBuf.length * 1.5).toInt())..setAll(0, strBuf);
      }
      strBuf[si++] = bc;
    }
  }

  @pragma('vm:prefer-inline')
  int _readEscapeSequence(int char) {
    switch (char) {
      case tokenB:
        return tokenBackspace;
      case tokenT:
        return tokenTab;
      case tokenN:
        return tokenLineFeed;
      case tokenF:
        return tokenFormFeed;
      case tokenR:
        return tokenCarriageReturn;
      case tokenDoubleQuote:
      case tokenSlash:
      case tokenBackslash:
        return char;
      default:
        _expect('valid escape sequence', _offset - 1);
    }
  }

  int _parseHexDigit(int offset) {
    final char = buffer[offset];
    final digit = char ^ 0x30;
    if (digit <= 9) return digit;
    final letter = (char | 0x20) ^ 0x60;
    // values 1 .. 6 are 'a' through 'f'
    if (letter <= 6 && letter > 0) return letter + 9;
    _expect('hex digit', offset);
  }

  void _skip() {
    skipWhitespace();
    switch (buffer[_offset++]) {
      case tokenDoubleQuote:
        _skipString();
        break;
      case tokenT:
        _offset += 3;
        break;
      case tokenF:
        _offset += 4;
        break;
      case tokenN:
        _offset += 3;
        break;
      case tokenLBracket:
        skipRemainingItems();
        break;
      case tokenLBrace:
        skipRemainingKeys();
        break;
      default:
        _skipNumber();
        break;
    }
  }

  void _skipString() {
    var escaped = false;
    for (var i = _offset;; i++) {
      final c = buffer[i];
      if (c == tokenDoubleQuote) {
        if (!escaped) {
          _offset = i + 1;
          return;
        } else {
          var j = i - 1;
          while (true) {
            if (j < _offset || buffer[j] != tokenBackslash) {
              // even number of backslashes either end of buffer, or " found
              _offset = i + 1;
              return;
            }
            j--;
            if (j < _offset || buffer[j] != tokenBackslash) {
              // odd number of backslashes it is \" or \\\"
              break;
            }
            j--;
          }
        }
      } else if (c == tokenBackslash) {
        escaped = true;
      }
    }
  }

  void _skipNumber() {
    var i = _offset;
    while (true) {
      final c = buffer[i++];
      if (c ^ tokenZero > 9 &&
          c != tokenMinus &&
          c != tokenPlus &&
          c != tokenPeriod &&
          c != tokenE &&
          c != tokenUpperE) {
        break;
      }
    }
    _offset = i - 1;
  }
}

class JsonEncoder implements Encoder, IteratedEncoder {
  JsonEncoder() {
    _keyed = JsonKeyedEncoder._(this);
  }

  final _buffers = <Uint8List>[];
  var _buffer = Uint8List(2048);
  var _offset = 0;

  late final JsonKeyedEncoder _keyed;

  @protected
  Uint8List get buffer => _buffer;
  @protected
  int get offset => _offset;

  static List<int> encode<T>(T value, {Encodable<T>? using}) {
    var encoder = JsonEncoder();
    encoder.encodeObject(value, using: using);
    return encoder.toBytes();
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeBool(bool value) {
    if (value) {
      _ensure(5);
      _buffer[_offset++] = tokenT;
      _buffer[_offset++] = tokenR;
      _buffer[_offset++] = tokenU;
      _buffer[_offset++] = tokenE;
    } else {
      _ensure(6);
      _buffer[_offset++] = tokenF;
      _buffer[_offset++] = tokenA;
      _buffer[_offset++] = tokenL;
      _buffer[_offset++] = tokenS;
      _buffer[_offset++] = tokenE;
    }
    _buffer[_offset++] = tokenComma;
  }

  @override
  void encodeBoolOrNull(bool? value) {
    if (value == null) {
      encodeNull();
    } else {
      encodeBool(value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeInt(int value) {
    encodeNum(value);
  }

  @override
  void encodeIntOrNull(int? value) {
    encodeNumOrNull(value);
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeDouble(double value) {
    encodeNum(value);
  }

  @override
  void encodeDoubleOrNull(double? value) {
    encodeNumOrNull(value);
  }

  @override
  void encodeNum(num value) {
    final str = value.toString();
    _ensure(str.length + 1);
    for (var i = 0; i < str.length; i++) {
      _buffer[_offset++] = str.codeUnitAt(i);
    }
    _buffer[_offset++] = tokenComma;
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeNumOrNull(num? value) {
    if (value == null) {
      encodeNull();
    } else {
      encodeNum(value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeString(String value) {
    _writeString(value);
    writeByte(tokenComma);
  }

  @override
  void encodeStringOrNull(String? value) {
    if (value == null) {
      encodeNull();
    } else {
      encodeString(value);
    }
  }

  @pragma('vm:prefer-inline')
  @override
  void encodeNull() {
    _ensure(5);
    _buffer[_offset++] = tokenN;
    _buffer[_offset++] = tokenU;
    _buffer[_offset++] = tokenL;
    _buffer[_offset++] = tokenL;
    _buffer[_offset++] = tokenComma;
  }

  @override
  bool canEncodeCustom<T>() {
    return false;
  }

  @override
  void encodeObject<T>(T value, {Encodable<T>? using}) {
    if (using != null) {
      using.encode(value, this);
    } else if (value is SelfEncodable) {
      value.encode(this);
    } else if (value == null) {
      encodeNull();
    } else if (value is bool) {
      encodeBool(value);
    } else if (value is num) {
      encodeNum(value);
    } else if (value is String) {
      encodeString(value);
    } else if (value is List) {
      encodeIterable<dynamic>(value);
    } else if (value is Map<String, dynamic>) {
      encodeMap<String, dynamic>(value);
    } else {
      throw ArgumentError('Unsupported type: ${value.runtimeType}');
    }
  }

  @override
  void encodeObjectOrNull<T>(T? value, {Encodable<T>? using}) {
    if (value == null) {
      encodeNull();
    } else {
      encodeObject<T>(value, using: using);
    }
  }

  @override
  void encodeIterable<E>(Iterable<E> value, {Encodable<E>? using}) {
    writeByte(tokenLBracket);
    for (final e in value) {
      encodeObject<E>(e, using: using);
    }
    _writeArrayEnd();
  }

  @override
  void encodeIterableOrNull<E>(Iterable<E>? value, {Encodable<E>? using}) {
    if (value == null) {
      encodeNull();
    } else {
      encodeIterable(value, using: using);
    }
  }

  @override
  void encodeMap<K, V>(Map<K, V> value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    writeByte(tokenLBrace);
    for (final key in value.keys) {
      if (key is String && keyUsing == null) {
        _writeObjectKey(key);
      } else {
        _writeObjectKey(StandardEncoder.encode<K>(key, using: keyUsing) as String);
      }

      final v = value[key] as V;
      encodeObject<V>(v, using: valueUsing);
    }
    _writeObjectEnd();
  }

  @override
  void encodeMapOrNull<K, V>(Map<K, V>? value, {Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    if (value == null) {
      encodeNull();
    } else {
      encodeMap<K, V>(value, keyUsing: keyUsing, valueUsing: valueUsing);
    }
  }

  @override
  IteratedEncoder encodeIterated() {
    writeByte(tokenLBracket);
    return this;
  }

  @override
  KeyedEncoder encodeKeyed() {
    writeByte(tokenLBrace);
    return _keyed;
  }

  @override
  void end() {
    _writeArrayEnd();
  }

  @override
  bool isHumanReadable() {
    return true;
  }

  @pragma('vm:prefer-inline')
  void _ensure(int size) {
    if (_buffer.length - _offset < size) {
      final bufferView = Uint8List.view(_buffer.buffer, 0, _offset);
      _buffers.add(bufferView);
      _buffer = Uint8List(max(size, _buffer.length) * 2);
      _offset = 0;
    }
  }

  @pragma('vm:prefer-inline')
  @protected
  void writeByte(int byte) {
    _ensure(1);
    _buffer[_offset++] = byte;
  }

  @pragma('vm:prefer-inline')
  void _writeString(String value) {
    _ensure(value.length + 2);
    var offset = _offset;

    _buffer[offset++] = tokenDoubleQuote;

    var i = 0;
    for (; i < value.length; i++) {
      final char = value.codeUnitAt(i);
      if (char < oneByteLimit && canDirectWrite[char]) {
        _buffer[offset++] = char;
      } else {
        break;
      }
    }

    if (i < value.length) {
      _offset = offset;
      _ensure((value.length - i) * 3 + 1);
      offset = _offset;

      for (; i < value.length; i++) {
        final char = value.codeUnitAt(i);
        if (char < oneByteLimit) {
          if (canDirectWrite[char]) {
            _buffer[offset++] = char;
          } else {
            switch (char) {
              case tokenDoubleQuote:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenDoubleQuote;
                break;
              case tokenBackslash:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenBackslash;
                break;
              case tokenBackspace:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenB;
                break;
              case tokenFormFeed:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenF;
                break;
              case tokenLineFeed:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenN;
                break;
              case tokenCarriageReturn:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenR;
                break;
              case tokenTab:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenT;
                break;
              default:
                _buffer[offset++] = tokenBackslash;
                _buffer[offset++] = tokenU;
                _buffer[offset++] = tokenZero;
                _buffer[offset++] = tokenZero;
                _buffer[offset++] = hexDigits[(char >> 4) & 0xF];
                _buffer[offset++] = hexDigits[char & 0xF];
            }
          }
        } else if ((char & surrogateTagMask) == leadSurrogateMin) {
          // combine surrogate pair
          final nextChar = value.codeUnitAt(++i);
          final rune = 0x10000 + ((char & surrogateValueMask) << 10) | (nextChar & surrogateValueMask);
          // If the rune is encoded with 2 code-units then it must be encoded
          // with 4 bytes in UTF-8.
          _buffer[offset++] = 0xF0 | (rune >> 18);
          _buffer[offset++] = 0x80 | ((rune >> 12) & 0x3f);
          _buffer[offset++] = 0x80 | ((rune >> 6) & 0x3f);
          _buffer[offset++] = 0x80 | (rune & 0x3f);
        } else if (char <= twoByteLimit) {
          _buffer[offset++] = 0xC0 | (char >> 6);
          _buffer[offset++] = 0x80 | (char & 0x3f);
        } else {
          _buffer[offset++] = 0xE0 | (char >> 12);
          _buffer[offset++] = 0x80 | ((char >> 6) & 0x3f);
          _buffer[offset++] = 0x80 | (char & 0x3f);
        }
      }
    }

    _buffer[offset++] = tokenDoubleQuote;
    _offset = offset;
  }

  @pragma('vm:prefer-inline')
  void _writeObjectKey(String field) {
    _writeString(field);
    writeByte(tokenColon);
  }

  @pragma('vm:prefer-inline')
  void _writeObjectEnd() {
    if (_buffer[_offset - 1] == tokenComma) {
      _buffer[_offset - 1] = tokenRBrace;
      writeByte(tokenComma);
    } else {
      _ensure(2);
      _buffer[_offset++] = tokenRBrace;
      _buffer[_offset++] = tokenComma;
    }
  }

  @pragma('vm:prefer-inline')
  void _writeArrayEnd() {
    if (_buffer[_offset - 1] == tokenComma) {
      _buffer[_offset - 1] = tokenRBracket;
      writeByte(tokenComma);
    } else {
      _ensure(2);
      _buffer[_offset++] = tokenRBracket;
      _buffer[_offset++] = tokenComma;
    }
  }

  /// Convert the internal buffer to a [Uint8List].
  Uint8List toBytes() {
    if (_buffer[_offset - 1] == tokenComma) {
      _offset--;
    }

    var size = 0;
    for (final buffer in _buffers) {
      size += buffer.length;
    }
    size += _offset;
    final result = Uint8List(size);
    var offset = 0;
    for (final buffer in _buffers) {
      result.setRange(offset, offset + buffer.length, buffer);
      offset += buffer.length;
    }
    result.setRange(offset, offset + _offset, _buffer);
    return result;
  }

}

class JsonKeyedEncoder implements KeyedEncoder {
  JsonKeyedEncoder._(this._parent);

  final JsonEncoder _parent;

  @override
  void encodeBool(String key, bool value, {int? id}) {
    _parent._writeObjectKey(key);
    _parent.encodeBool(value);
  }

  @override
  void encodeBoolOrNull(String key, bool? value, {int? id}) {
    _parent._writeObjectKey(key);
    _parent.encodeBoolOrNull(value);
  }

  @override
  void encodeInt(String key, int value, {int? id}) {
    _parent._writeObjectKey(key);
    _parent.encodeInt(value);
  }

  @override
  void encodeIntOrNull(String key, int? value, {int? id}) {
    _parent._writeObjectKey(key);
    _parent.encodeIntOrNull(value);
  }

  @override
  void encodeDouble(String key, double value, {int? id}) {
    _parent._writeObjectKey(key);
    _parent.encodeDouble(value);
  }

  @override
  void encodeDoubleOrNull(String key, double? value, {int? id}) {
    _parent._writeObjectKey(key);
    _parent.encodeDoubleOrNull(value);
  }

  @override
  void encodeNum(String key, num value, {int? id}) {
    _parent._writeObjectKey(key);
    _parent.encodeNum(value);
  }

  @override
  void encodeNumOrNull(String key, num? value, {int? id}) {
    _parent._writeObjectKey(key);
    _parent.encodeNumOrNull(value);
  }

  @override
  void encodeString(String key, String value, {int? id}) {
    _parent._writeObjectKey(key);
    _parent.encodeString(value);
  }

  @override
  void encodeStringOrNull(String key, String? value, {int? id}) {
    _parent._writeObjectKey(key);
    _parent.encodeStringOrNull(value);
  }

  @override
  void encodeNull(String key, {int? id}) {
    _parent._writeObjectKey(key);
    _parent.encodeNull();
  }

  @override
  bool canEncodeCustom<T>() {
    return _parent.canEncodeCustom<T>();
  }

  @override
  void encodeObject<T>(String key, T value, {int? id, Encodable<T>? using}) {
    _parent._writeObjectKey(key);
    _parent.encodeObject<T>(value, using: using);
  }

  @override
  void encodeObjectOrNull<T>(String key, T? value, {int? id, Encodable<T>? using}) {
    _parent._writeObjectKey(key);
    _parent.encodeObjectOrNull<T>(value, using: using);
  }

  @override
  void encodeIterable<E>(String key, Iterable<E> value, {int? id, Encodable<E>? using}) {
    _parent._writeObjectKey(key);
    _parent.encodeIterable<E>(value, using: using);
  }

  @override
  void encodeIterableOrNull<E>(String key, Iterable<E>? value, {int? id, Encodable<E>? using}) {
    _parent._writeObjectKey(key);
    _parent.encodeIterableOrNull<E>(value, using: using);
  }

  @override
  void encodeMap<K, V>(String key, Map<K, V> value, {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _parent._writeObjectKey(key);
    _parent.encodeMap<K, V>(value, keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @override
  void encodeMapOrNull<K, V>(String key, Map<K, V>? value,
      {int? id, Encodable<K>? keyUsing, Encodable<V>? valueUsing}) {
    _parent._writeObjectKey(key);
    _parent.encodeMapOrNull<K, V>(value, keyUsing: keyUsing, valueUsing: valueUsing);
  }

  @override
  IteratedEncoder encodeIterated(String key, {int? id}) {
    _parent._writeObjectKey(key);
    return _parent.encodeIterated();
  }

  @override
  KeyedEncoder encodeKeyed(String key, {int? id}) {
    _parent._writeObjectKey(key);
    return _parent.encodeKeyed();
  }

  @override
  void end() {
    _parent._writeObjectEnd();
  }

  @override
  bool isHumanReadable() {
    return _parent.isHumanReadable();
  }
}
