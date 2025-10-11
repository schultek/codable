import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';

import '../../proxy_hook.dart';

class Game implements SelfEncodable {
  String name;

  Game(this.name);

  @override
  void encode(Encoder encoder) {
    encoder.encodeKeyed()
      ..encodeString('name', name)
      ..end();
  }
}

class GameHook with ProxyHook {
  const GameHook();

  @override
  String visitString(String value) {
    return value.toUpperCase();
  }
}

class GameCodable extends CodableWithHooks<Game> {
  GameCodable() : super(const _GameCodable(), const GameHook());
}

class _GameCodable extends SelfCodable<Game> {
  const _GameCodable();

  @override
  Game decode(Decoder decoder) {
    final keyed = decoder.decodeMapped();
    return Game(
      keyed.decodeString('name'),
    );
  }
}
