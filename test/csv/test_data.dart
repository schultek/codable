import 'dart:convert';

import 'model/measures.dart';

final measuresCsv = '''
id,name,age,isActive,signupDate,website
1,John Doe,25,true,2023-06-15T00:00:00.000,https://johndoe.com
2,Jane Smith,30,false,,https://janesmith.org
3,,45,true,2021-09-12T00:00:00.000,https://example.com
4,Alex Brown,29,false,2020-11-23T00:00:00.000,
5,Chris Johnson,34,true,2019-03-10T00:00:00.000,https://chrisjohnson.net
''';

final measuresCsvBytes = utf8.encode(measuresCsv);

final measuresObjects = [
  Measures('1', 'John Doe', 25, true, DateTime(2023, 6, 15),
      Uri.parse('https://johndoe.com')),
  Measures(
      '2', 'Jane Smith', 30, false, null, Uri.parse('https://janesmith.org')),
  Measures('3', null, 45, true, DateTime(2021, 9, 12),
      Uri.parse('https://example.com')),
  Measures('4', 'Alex Brown', 29, false, DateTime(2020, 11, 23), null),
  Measures('5', 'Chris Johnson', 34, true, DateTime(2019, 3, 10),
      Uri.parse('https://chrisjohnson.net')),
];

final measuresData = [
  {
    "id": "1",
    "name": "John Doe",
    "age": 25,
    "isActive": true,
    "signupDate": "2023-06-15T00:00:00.000",
    "website": "https://johndoe.com"
  },
  {
    "id": "2",
    "name": "Jane Smith",
    "age": 30,
    "isActive": false,
    "signupDate": null,
    "website": "https://janesmith.org"
  },
  {
    "id": "3",
    "name": null,
    "age": 45,
    "isActive": true,
    "signupDate": "2021-09-12T00:00:00.000",
    "website": "https://example.com"
  },
  {
    "id": "4",
    "name": "Alex Brown",
    "age": 29,
    "isActive": false,
    "signupDate": "2020-11-23T00:00:00.000",
    "website": null,
  },
  {
    "id": "5",
    "name": "Chris Johnson",
    "age": 34,
    "isActive": true,
    "signupDate": "2019-03-10T00:00:00.000",
    "website": "https://chrisjohnson.net"
  }
];

final measuresJson = jsonEncode(measuresData);
