import 'package:data_classes/src/generators/common/common.dart';
import 'package:data_classes/src/generators/data/data.dart';

import 'core.dart';
import 'models.dart';
import 'selectors.dart';
import 'serialization.dart';

class SealedClassGenerator extends ClassGenerator {
  SealedClassGenerator({
    required super.convertToSnakeCase,
    required super.immutable,
    required super.modelClass,
    required super.mutateFromActionsOnly,
    required super.observableFields,
    required super.resolver,
    required super.withCopy,
    required super.withEquality,
    required super.withReflection,
    required super.withSerialize,
  }) : super(
          withBuiltValueSerializer: false,
          observerNames: null,
          objectName: null,
          objectNameGetterName: null,
        );

  @override
  Future<List<Iterable<String>>> build() async => [
        generateClassHeader(abstract: true),
        ['{'],
        generateConstructors(),
        if (withSerialize) generateDeserializer(),
        generateFields(),
        if (withSerialize) generateSerializer(),
        generateSelectors(),
        ['}'],
        await generateSubclasses(),
        generateBaseModels(),
        generateSubclassesModels(),
      ];

  Future<Iterable<String>> generateSubclasses() async => [
        for (final method in methods)
          (await DataClassGenerator(
            observerNames: null,
            convertToSnakeCase: convertToSnakeCase,
            immutable: immutable,
            modelClass: null,
            mutateFromActionsOnly: mutateFromActionsOnly,
            objectName: null,
            objectNameGetterName: null,
            observableFields: observableFields,
            resolver: resolver,
            withBuiltValueSerializer: false,
            withEquality: withEquality,
            withCopy: withCopy,
            withReflection: withReflection,
            withSerialize: withSerialize,

            /// overrides
            classNameOverride: getSubclassName(method),
            fieldTypesOverride: {
              ...paramsTypes[method]!,
              ...fieldTypes,
            },
            genericTypesOverride: genericTypes,
            genericTypesFullOverride: genericTypesFull,
            modelClassNameOverride: getModelSubclassName(method),
            parentClassName: className,
            qualifiedImportsOverride: qualifiedImports,
          ).generate())
              .join('\n'),
      ];
}
