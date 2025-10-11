import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:codable_builder/codable_builder.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

const builder = CodableBuilder();

final _emitter = DartEmitter(useNullSafetySyntax: true);
final _formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);

String emit(Spec code) {
  final output = code.accept(_emitter).toString();
  return _formatter.format(output);
}


Future<ClassElement2> getElementFrom(String path) async {
  final absolutePath = File('test/with_analyzer/sources/$path').absolute.path;

  final result = await resolveFile2(path: absolutePath);
  if (result is! ResolvedUnitResult) {
    throw Exception('Failed to resolve the file: $result');
  }

  return result.libraryElement2.classes.first;
}