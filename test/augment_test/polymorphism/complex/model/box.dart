import 'package:codable/core.dart';
import 'package:codable/extended.dart';

part 'box.codable.dart';

/*
//! CAUSING ANALYZER CRASHES

//@Codable()
abstract class Box<T> {
  final T content;
}


// For testing fixed type parameters.
//@Codable()    //?(Would this annotation be required or desired? could we infer from parent type ?)
class LabelBox extends Box<String> {
  const LabelBox(super.content);
}

// For testing reduced type parameters.
//@Codable()    //?(Would this annotation be required or desired? could we infer from parent type ?)
class AnyBox extends Box {
  const AnyBox(super.content);
}

// For testing bounded type parameters.
//@Codable()    //?(Would this annotation be required or desired? could we infer from parent type ?)
class NumberBox<T extends num> extends Box<T> {
  const NumberBox(super.content);
}

// For testing nested type parameters.
//@Codable()    //?(Would this annotation be required or desired? could we infer from parent type ?)
class Boxes<T> extends Box<List<T>> {
  const Boxes(super.content);
}

//!CAUSING ANALYZER CRASHES 
*/



//~ START ORIGINAL CODE (WITHOUT AUGMENTATION) FOR ABOVE CAUSING CRASHES

abstract class Box<T> implements SelfEncodable {
  const Box(this.content);

  final T content;

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT]) {
    encoder.encodeKeyed()
      ..encodeObject('content', content, using: encodableT)
      ..end();
  }
}

// For testing fixed type parameters.
class LabelBox extends Box<String> {
  const LabelBox(super.content);

  @override
  void encode(Encoder encoder, [_]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'label')
      ..encodeString('content', content)
      ..end();
  }
}

// For testing reduced type parameters.
class AnyBox extends Box {
  const AnyBox(super.content);

  @override
  void encode(Encoder encoder, [_]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'any')
      ..encodeObject('content', content)
      ..end();
  }
}

// For testing bounded type parameters.
class NumberBox<T extends num> extends Box<T> {
  const NumberBox(super.content);

  @override
  void encode(Encoder encoder, [_]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'number')
      ..encodeNum('content', content)
      ..end();
  }
}

// For testing nested type parameters.
class Boxes<T> extends Box<List<T>> {
  const Boxes(super.content);

  @override
  void encode(Encoder encoder, [Encodable<List<T>>? encodableT, Encodable<T>? encodableT2]) {
    final keyed = encoder.encodeKeyed();
    keyed.encodeString('type', 'boxes');
    if (encodableT2 == null && encodableT != null) {
      keyed.encodeObject('content', content, using: encodableT);
    } else {
      keyed.encodeIterable('content', content, using: encodableT2);
    }
    keyed.end();
  }
}

//~ END WORK AROUND FOR CRASH




/*
//! THESE VERSIONS WITH AUGMENTATION DONT CRASH 
but do cause the weird errors in the augmentation


// For testing additional type parameters.
//@Codable()    //?(Would this annotation be required or desired? could we infer from parent type ?)
class MetaBox<V, T> extends Box<T> {
  const MetaBox(this.metadata, super.content);

  final V metadata;
}

CAUSES ERROR - using non augmentation version below */


/* ERROR occurs on the augment version::
The augmentation type parameter must have the same bound as the corresponding type parameter of the declaration.
Try changing the augmentation to match the declaration type parameters.dart(augmentation_type_parameter_bound)
T
test/augment_test/polymorphism/complex/model/box.dart

// For testing self-dependent type parameters.
//@Codable()    //?(Would this annotation be required or desired? could we infer from parent type ?)
class HigherOrderBox<T, B extends Box<T>> extends MetaBox<T, B> {
  const HigherOrderBox(super.metadata, super.content);
}

//!!END VERSION that creates ERROR 
*/


//~ BEGIN original NON augmentation version 
class MetaBox<V, T> extends Box<T> {
  const MetaBox(this.metadata, super.content);

  final V metadata;

  @override
  void encode(Encoder encoder, [Encodable<T>? encodableT, Encodable<V>? encodableV]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'meta')
      ..encodeObject('metadata', metadata, using: encodableV)
      ..encodeObject('content', content, using: encodableT)
      ..end();
  }
}

// For testing self-dependent type parameters.
class HigherOrderBox<T, B extends Box<T>> extends MetaBox<T, B> {
  const HigherOrderBox(super.metadata, super.content);

  @override
  void encode(Encoder encoder, [Encodable<B>? encodableB, Encodable<T>? encodableT]) {
    encoder.encodeKeyed()
      ..encodeString('type', 'higher_order')
      ..encodeObject('metadata', metadata, using: encodableT)
      ..encodeObject('content', content, using: encodableB)
      ..end();
  }
}

//~ END original NON augmentation version to avoid weird analyzer errors



// For testing nested types.
//@Codable(equatable:true,toString:true)    //! arguments could be used to trigger creation of equatable and toString() methods 
class Data {
  final dynamic value;
}

