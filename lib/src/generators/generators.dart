import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'package:data_classes/src/annotations.dart';
import 'package:data_classes/src/utils/annotations.dart';

import 'data/data.dart';

const modelSuffix = 'Model';

Builder generateDataClasses(BuilderOptions options) => SharedPartBuilder(
      [DataClassesGenerator()],
      'data_class',
      allowSyntaxErrors: true,
    );

class CodeGenError extends Error {
  CodeGenError(this.message);
  final String message;
  String toString() => message;
}

class DataClassesGenerator extends GeneratorForAnnotation<DataClass> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw CodeGenError(
        'You can only annotate classes with @DataClass(), but '
        '"${element.name}" isn\'t a class.',
      );
    }
    if (!element.name.endsWith(modelSuffix)) {
      throw CodeGenError(
        'The names of classes annotated with @DataClass() should '
        'end with "$modelSuffix", for example ${element.name}$modelSuffix. '
        'The generated class (in that case, ${element.name}) will then get '
        'automatically generated for you by running `dart run build_runner '
        'build` (or `flutter run build_runner build` if you\'re using '
        'Flutter).',
      );
    }

    final Iterable<String> lines = await DataClassGenerator(
      builtValueSerializer: annotation.get('builtValueSerializer') ?? false,
      childrenListener: annotation.get('childrenListener'),
      convertToSnakeCase: annotation.get('convertToSnakeCase') ?? false,
      generateCopyWith: annotation.get('copyWith') ?? true,
      generateEquality: annotation.get('equality') ?? true,
      immutable: annotation.get('immutable') ?? false,
      //  listener : annotation.value('listener'),
      modelClass: element,
      objectName: annotation.get('name'),
      objectNameGetter: annotation.get('getName'),
      resolver: buildStep.resolver,
      serialize: annotation.get('serialize') ?? true,
    ).generate();

    return lines.join('\n');
  }
}
