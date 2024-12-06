import 'dart:async';

// ignore: implementation_imports
import 'package:codable/core.dart';
import 'package:codable/extended.dart';
import 'package:codable/standard.dart';
import 'package:type_plus/src/types_registry.dart' show TypeRegistry;
import 'package:type_plus/type_plus.dart';

import 'mapper.dart';

Decodable<T> findDecodableFor<T>() {
  if (T == List || isBounded<T, List>()) {
    final decodable = T.args.call1<ListCodable>(<E>() {
      return ListCodable<E>(findCodableFor<E>()!);
    });
    if (decodable is Decodable<T>) {
      return decodable as Decodable<T>;
    }
  }
  return findCodableFor<T>()!;
}

Codable<T>? findCodableFor<T>() {
  final mapper = MapperContainer.current.findByType<T>();
  return getCodableOf(mapper!);
}

Codable<T>? getCodableOf<T>(Mapper mapper) {
  return switch (mapper) {
    CodableMapper m => m.codable,
    CodableMapper1 m => T.args.call1<Codable>(<A>() => m.codable<A>(findCodableFor<A>())),
    CodableMapper2 m => T.args.call2<Codable>(<A, B>() => m.codable<A, B>(findCodableFor<A>(), findCodableFor<B>())),
    _ => null,
  } as Codable<T>?;
}

Encodable<T> findEncodeFor<T>(T value) {
  if (value is SelfEncodable) return Encodable.self();

  final mapper = MapperContainer.current.findByValue<T>(value);
  return getCodableOf<T>(mapper!)!;
}

extension on List<Type> {
  R call1<R>(R Function<A>() fn) {
    return first.provideTo(fn);
  }

  R call2<R>(R Function<A, B>() fn) {
    return first.provideTo(<A>() => this[1].provideTo(<B>() => fn<A, B>()));
  }
}

R useMappers<R>(R Function() callback, {List<Mapper>? mappers}) {
  return runZoned(callback, zoneValues: {
    MapperContainer._containerKey: MapperContainer._inherit(mappers: mappers),
  });
}

class MapperContainer implements TypeProvider {
  static final _containerKey = Object();
  static final _root = MapperContainer._({});

  static MapperContainer get current => Zone.current[_containerKey] as MapperContainer? ?? _root;

  static MapperContainer _inherit({List<Mapper>? mappers}) {
    var parent = current;
    if (mappers == null) {
      return parent;
    }

    return MapperContainer._({
      ...parent._mappers,
      for (final m in mappers) m.type: m,
    });
  }

  MapperContainer._(this._mappers) {
    TypeRegistry.instance.register(this);
  }

  final Map<Type, Mapper> _mappers;

  final Map<Type, Mapper?> _cachedMappers = {};
  final Map<Type, Mapper?> _cachedTypeMappers = {};

  final Map<Object, dynamic> _cachedObjects = {};

  Mapper? findByType<T>([Type? type]) {
    return _mapperForType(type ?? T);
  }

  Mapper? findByValue<T>(T value) {
    return _mapperForValue(value);
  }

  List<Mapper<T>> findAll<T>() {
    return _mappers.values.whereType<Mapper<T>>().toList();
  }

  Mapper? _mapperForValue(dynamic value) {
    var type = value.runtimeType;
    if (_cachedMappers[type] != null) {
      return _cachedMappers[type];
    }
    var baseType = type.base;
    if (baseType == UnresolvedType) {
      baseType = type;
    }
    if (_cachedMappers[baseType] != null) {
      return _cachedMappers[baseType];
    }

    var mapper = //
        // direct type
        _mappers[baseType] ??
            // indirect type ie. subtype
            _mappers.values.where((m) => m.isFor(value)).firstOrNull;

    if (mapper != null) {
      // if (mapper is ClassMapperBase) {
      //   mapper = mapper.subOrSelfFor(value) ?? mapper;
      // }
      if (baseType == mapper.type) {
        _cachedMappers[baseType] = mapper;
      } else {
        _cachedMappers[type] = mapper;
      }
    }

    return mapper;
  }

  Mapper? _mapperForType(Type type) {
    if (_cachedTypeMappers[type] case var m?) {
      return m;
    }
    var baseType = type.base;
    if (baseType == UnresolvedType) {
      baseType = type;
    }
    if (_cachedTypeMappers[baseType] case var m?) {
      return m;
    }
    var mapper = _mappers[baseType] ?? _mappers.values.where((m) => m.isForType(type)).firstOrNull;

    if (mapper != null) {
      if (baseType == mapper.type) {
        _cachedTypeMappers[baseType] = mapper;
      } else {
        _cachedTypeMappers[type] = mapper;
      }
    }
    return mapper;
  }

  @override
  Function? getFactoryById(String id) {
    return _mappers.values.where((m) => m.id == id).firstOrNull?.typeFactory;
  }

  @override
  List<Function> getFactoriesByName(String name) {
    return [
      ..._mappers.values.where((m) => m.type.name == name).map((m) => m.typeFactory),
    ];
  }

  @override
  String? idOf(Type type) {
    return _mappers[type]?.id;
  }

  T? getCached<T>(Object key) {
    return _cachedObjects[key] as T?;
  }

  void setCached<T>(Object key, T value) {
    _cachedObjects[key] = value;
  }
}
