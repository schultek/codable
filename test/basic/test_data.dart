import 'dart:convert';

final personTestData = {
  "name": "Alice Smith",
  "age": 30,
  "height": 5.6,
  "isDeveloper": true,
  "parent": {
    "name": "Carol Smith",
    "age": 55,
    "height": 5.4,
    "isDeveloper": false,
    "parent": null,
    "hobbies": ["gardening", "reading"],
    "friends": []
  },
  "hobbies": ["coding", "hiking", "painting"],
  "friends": [
    {
      "name": "Bob Johnson",
      "age": 32,
      "height": 5.9,
      "isDeveloper": true,
      "parent": {
        "name": "David Johnson",
        "age": 60,
        "height": 6.0,
        "isDeveloper": false,
        "parent": null,
        "hobbies": ["woodworking"],
        "friends": []
      },
      "hobbies": ["gaming", "cycling"],
      "friends": []
    },
    {
      "name": "Eve Davis",
      "age": 28,
      "height": 5.5,
      "isDeveloper": false,
      "parent": null,
      "hobbies": ["dancing", "photography"],
      "friends": []
    }
  ]
};

final personTestJson = jsonEncode(personTestData);
final personTestJsonBytes = utf8.encode(personTestJson);

final personListTestJson = jsonEncode(List.filled(10, personTestData));
final personListTestJsonBytes = utf8.encode(personListTestJson);

// https://msgpack.org/
final personTestMsgpackBytes = base64Decode(
    'h6RuYW1lq0FsaWNlIFNtaXRoo2FnZR6maGVpZ2h0y0AWZmZmZmZmq2lzRGV2ZWxvcGVyw6ZwYXJlbnSHpG5hbWWrQ2Fyb2wgU21pdGijYWdlN6ZoZWlnaHTLQBWZmZmZmZqraXNEZXZlbG9wZXLCpnBhcmVudMCnaG9iYmllc5KpZ2FyZGVuaW5np3JlYWRpbmenZnJpZW5kc5CnaG9iYmllc5OmY29kaW5npmhpa2luZ6hwYWludGluZ6dmcmllbmRzkoekbmFtZatCb2IgSm9obnNvbqNhZ2UgpmhlaWdodMtAF5mZmZmZmqtpc0RldmVsb3BlcsOmcGFyZW50h6RuYW1lrURhdmlkIEpvaG5zb26jYWdlPKZoZWlnaHQGq2lzRGV2ZWxvcGVywqZwYXJlbnTAp2hvYmJpZXORq3dvb2R3b3JraW5np2ZyaWVuZHOQp2hvYmJpZXOSpmdhbWluZ6djeWNsaW5np2ZyaWVuZHOQh6RuYW1lqUV2ZSBEYXZpc6NhZ2UcpmhlaWdodMtAFgAAAAAAAKtpc0RldmVsb3BlcsKmcGFyZW50wKdob2JiaWVzkqdkYW5jaW5nq3Bob3RvZ3JhcGh5p2ZyaWVuZHOQ');
