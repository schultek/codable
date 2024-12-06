import 'package:codable/extended.dart';

import 'container.dart';

List<Discriminator<T>> findDiscriminatorFor<T>() {
  var mappers = MapperContainer.current.findAll<T>();
  return mappers.map((m) => getCodableOf<T>(m)).whereType<Discriminator<T>>().toList();
}

extension SuperDecodableExtension<T> on SuperDecodable<T> {
  List<Discriminator> _collectDiscriminatorsOrCached() {
    final cached = MapperContainer.current.getCached<List<Discriminator<T>>>(this);
    if (cached != null) {
      return cached;
    }

    final decodes = [...discriminators, ...findDiscriminatorFor<T>()];
    MapperContainer.current.setCached(this, decodes);
    return decodes;
  }
}
