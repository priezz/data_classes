import 'package:analyzer/dart/element/element.dart';

import 'package:data_classes/src/generators/generators.dart'
    show CodeGenError, modelSuffix;

void typeCheck<T>(Element element) async {
  if (element is! ClassElement) {
    throw CodeGenError(
      'You can only annotate classes with @$T(), but '
      '"${element.name}" isn\'t a class.',
    );
  }
  if (!element.name.endsWith(modelSuffix)) {
    throw CodeGenError(
      'The names of classes annotated with @$T() should have the '
      '"$modelSuffix" suffix, e.g. [${element.name}$modelSuffix]. '
      'The generated class, [${element.name.substring(1)}] in this case, will get '
      'generated automatically.',
    );
  }
}
