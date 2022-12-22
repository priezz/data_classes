import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'package:data_classes/data_classes.dart';
import 'generator.dart';

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
    ConstantReader _,
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
        'end with "Model", for example ${element.name}Model. '
        'The generated class (in that case, ${element.name}) will then get '
        'automatically generated for you by running "pub run build_runner '
        'build" (or "flutter pub run build_runner build" if you\'re using '
        'Flutter).',
      );
    }

    return DataClassGenerator(element, buildStep.resolver).generate();
  }
}
