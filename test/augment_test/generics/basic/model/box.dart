import 'package:codable/core.dart';
import 'package:codable/extended.dart';

part 'box.codable.dart';

//@Codable()
class Box<T> implements SelfEncodable {
//~AUGMENT_CAUSES_ERROR//class Box<T> {
  Box(this.label, this.data);

  final String label;
  final T data;
//~AUGMENT_CAUSES_ERROR//}
//~AUGMENT_CAUSES_ERROR//augment class Box<T> implements SelfEncodable {

  static const Codable1<Box, dynamic> codable = BoxCodable();

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    encoder.encodeKeyed()
      ..encodeString('label', label)
      ..encodeObject('data', data, using: encodableT)
      ..end();
  }
}


/* 
//!USING `augment` causes analyzer to produce weird errors on 
```
The argument type 'Encodable<T>?' can't be assigned to the parameter type 'Encodable<T>?'. dartargument_type_not_assignable
interface.dart(89, 26): Encodable is defined in C:\src\codable_workspace\packages\codable\lib\src\core\interface.dart
interface.dart(89, 26): Encodable is defined in C:\src\codable_workspace\packages\codable\lib\src\core\interface.dart
[Encodable<T>? encodableT]
Type: Encodable<T>?
```

class Box<T> {
  Box(this.label, this.data);

  final String label;
  final T data;
}


augment class Box<T> implements SelfEncodable {

  static const Codable1<Box, dynamic> codable = BoxCodable();

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    encoder.encodeKeyed()
      ..encodeString('label', label)
      ..encodeObject('data', data, using: encodableT)
      ..end();
  }
}

*/