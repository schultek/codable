import 'package:codable_dart/common.dart';
import 'package:codable_dart/core.dart';

class Measures implements SelfEncodable {
  Measures(this.id, this.name, this.age, this.isActive, this.signupDate, this.website);

  static const Codable<Measures> codable = MeasuresCodable();

  final String id;
  final String? name;
  final int age;
  final bool isActive;
  final DateTime? signupDate;
  final Uri? website;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Measures &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            age == other.age &&
            isActive == other.isActive &&
            signupDate == other.signupDate &&
            website == other.website;
  }

  @override
  int get hashCode => Object.hash(id, name, age, isActive, signupDate, website);

  @override
  String toString() {
    return 'Measures{id: $id, name: $name, age: $age, isActive: $isActive, signupDate: $signupDate, website: $website}';
  }

  @override
  void encode(Encoder encoder) {
    final keyed = encoder.encodeKeyed();
    keyed.encodeString('id', id);
    keyed.encodeStringOrNull('name', name);
    keyed.encodeInt('age', age);
    keyed.encodeBool('isActive', isActive);
    keyed.encodeObjectOrNull('signupDate', signupDate, using: const DateTimeCodable());
    keyed.encodeObjectOrNull('website', website, using: const UriCodable());
    keyed.end();
  }
}

class MeasuresCodable extends SelfCodable<Measures> {
  const MeasuresCodable();

  @override
  Measures decode(Decoder decoder) {
    return switch (decoder.whatsNext()) {
      DecodingType.mapped || DecodingType.map => decodeMapped(decoder.decodeMapped()),
      DecodingType.keyed || DecodingType.unknown => decodeKeyed(decoder.decodeKeyed()),
      _ => decoder.expect('keyed or mapped'),
    };
  }

  Measures decodeKeyed(KeyedDecoder decoder) {
    late String id;
    late String? name;
    late int age;
    late bool isActive;
    late DateTime? signupDate;
    late Uri? website;

    for (Object? key; (key = decoder.nextKey()) != null;) {
      switch (key) {
        case 'id':
          id = decoder.decodeString();
        case 'name':
          name = decoder.decodeStringOrNull();
        case 'age':
          age = decoder.decodeInt();
        case 'isActive':
          isActive = decoder.decodeBool();
        case 'signupDate':
          signupDate = decoder.decodeObjectOrNull(using: const DateTimeCodable());
        case 'website':
          website = decoder.decodeObjectOrNull(using: const UriCodable());
        default:
          decoder.skipCurrentValue();
      }
    }

    return Measures(id, name, age, isActive, signupDate, website);
  }

  Measures decodeMapped(MappedDecoder decoder) {
    return Measures(
      decoder.decodeString('id'),
      decoder.decodeStringOrNull('name'),
      decoder.decodeInt('age'),
      decoder.decodeBool('isActive'),
      decoder.decodeObjectOrNull('signupDate', using: const DateTimeCodable()),
      decoder.decodeObjectOrNull('website', using: const UriCodable()),
    );
  }
}
