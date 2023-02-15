import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'package:data_classes/src/annotations/base.dart';
import 'package:data_classes/src/annotations/from_annotation.dart';
import 'package:data_classes/src/generators/common/common.dart';
import 'package:data_classes/src/utils/elements.dart';

import 'data/data.dart';
import 'sealed/sealed.dart';

const modelSuffix = 'Model';

final Set<Element> _elementsProcessed = {};

Builder generateSugarClasses(BuilderOptions options) => SharedPartBuilder(
      [SugarClassesGenerator()],
      'sugar',
      allowSyntaxErrors: true,
    );

class CodeGenError extends Error {
  CodeGenError(this.message);
  final String message;
  String toString() => message;
}

class SugarClassesGenerator extends GeneratorForAnnotation<SugarClass> {
  @override
  Future<String?> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (_elementsProcessed.contains(element)) return null;

    _elementsProcessed.add(element);
    typeCheck<SugarClass>(element);

    final SugarClass params = sugarClassFromAnnotation(annotation);
    // print(params);
    final ClassGenerator generator = params.sealed
        ? SealedClassGenerator(
            convertToSnakeCase: params.convertToSnakeCase,
            immutable: params.immutable,
            modelClass: element as ClassElement,
            mutateFromActionsOnly: params.mutateFromActionsOnly,
            observableFields: !params.immutable && params.observable,
            resolver: buildStep.resolver,
            withEquality: params.equality,
            withCopy: params.copy,
            withReflection: params.reflection,
            withSerialize: params.serialize,
          )
        : DataClassGenerator(
            convertToSnakeCase: params.convertToSnakeCase,
            immutable: params.immutable,
            modelClass: element as ClassElement,
            mutateFromActionsOnly: params.mutateFromActionsOnly,
            objectName: params.name,
            objectNameGetterName: params.objectNameGetterName,
            observableFields: !params.immutable && params.observable,
            observerNames: params.observerNames,
            resolver: buildStep.resolver,
            withBuiltValueSerializer: params.builtValueSerializer,
            withCopy: params.copy,
            withEquality: params.equality,
            withReflection: params.reflection,
            withSerialize: params.serialize || params.builtValueSerializer,
          );
    final String result = (await generator.generate()).join('\n');
    // print(result);

    return result;
  }
}
