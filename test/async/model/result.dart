import 'package:codable_dart/core.dart';
import 'package:codable_dart/extended.dart';

import '../../basic/model/person.dart';

sealed class UsersResult {}

class UsersData extends UsersResult {
  UsersData(this.users);

  final List<Person> users;
}

class UsersStream extends UsersResult {
  UsersStream(this.users);

  final Stream<Person> users;
}

class UsersError extends UsersResult {
  UsersError(this.error);

  final Object? error;
}

class UsersResultCodable extends LazyCodable<UsersResult> {
  const UsersResultCodable();

  @override
  UsersResult decode(Decoder decoder) {
    final keyed = decoder.decodeKeyed();

    List<Person>? users;
    Object? error;

    for (Object? key; (key = keyed.nextKey()) != null;) {
      switch (key) {
        case 'users':
          users = keyed.decodeList(using: Person.codable);
        case 'error':
          error = keyed.decodeObjectOrNull();

        default:
          keyed.skipCurrentValue();
      }
    }

    return users != null ? UsersData(users) : UsersError(error);
  }

  @override
  void decodeLazy(LazyDecoder decoder, void Function(UsersResult) resolve) {
    decoder.decodeKeyed((key, decoder) {
      switch (key) {
        case 'users':
          resolve(UsersStream(decoder.decodeStream(using: Person.codable)));
        case 'error':
          decoder.decodeObjectOrNull((e) => resolve(UsersError(e)));
        default:
          decoder.skipCurrentValue();
      }
    }, done: () {});
  }

  @override
  void encode(UsersResult value, Encoder encoder) {
    // TODO: implement encode
  }
}
