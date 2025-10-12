Some common types that have codables included in the package.

# DateTime

The `DateTimeCodable` is a codable implementation for the core `DateTime` type. It shows how to de/encode a core type and combines several encoding strategies.

1. If the data format supports `DateTime` as a [custom type](#custom-types), it is encoded as a custom scalar value.
2. It uses a custom configuration option `preferredFormat` which the user can use to specify one of three formats.

   - `iso8601` will encode the value as an ISO8601 `String`.
   - `unixMilliseconds` will encode the value as a unix milliseconds `int`.
   - `auto` will let the data format determine how the value is encoded. For human-readable formats it is encoded as a `String` and for others as an `int`.

3. It uses a custom configuration option `convertUtc` which controls whether the date value will be converted to UTC before encoding and to local time when decoding.

The codable is implemented in [lib/src/common/datetime.dart](https://github.com/schultek/codable/blob/main/lib/src/common/datetime.dart)

# Uri

The `UriCodable` is a codable implementation for the core `Uri` type.

If the data format supports `Uri` as a [custom type](#custom-types), the value is encoded as a custom scalar value. Else, it is encoded as a `String`.

The codable is implemented in [lib/src/common/uri.dart](https://github.com/schultek/codable/blob/main/lib/src/common/uri.dart)
