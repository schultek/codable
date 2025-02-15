import 'package:codable/common.dart';
import 'package:codable/core.dart';

part 'measures.codable.dart';

//~@Codable(equatable:true,toString:true)
//!          arguments could be used to trigger creation of equatable and toString() methods 
class Measures {
  final String id;
  final String? name;
  final int age;
  final bool isActive;
  final DateTime? signupDate;
  final Uri? website;
}

