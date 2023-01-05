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
    required super.resolver,
    required super.withCopy,
    required super.withEquality,
    required super.withSerialize,
  }) : super(
          withBuiltValueSerializer: false,
          changesListenerName: null,
          objectName: null,
          objectNameGetterName: null,
        ) {
    modelClassNameTyped = '_${className}BaseModel$genericTypes';
  }

  Future<Iterable<String>> generate() async {
    await super.generate();

    return [
      generateClassHeader(abstract: true),
      ['{'],
      generateConstructors(),
      if (withSerialize) generateDeserializer(),
      generateFields(),
      if (withSerialize) generateSerializer(),
      generateSelectors(),
      ['}'],
      await generateSubclasses(),
      generateModels(),
    ].expand((items) => items);
  }

  Future<Iterable<String>> generateSubclasses() async => [
        for (final method in methods)
          (await DataClassGenerator(
            changesListenerName: null,
            convertToSnakeCase: convertToSnakeCase,
            immutable: immutable,
            modelClass: null,
            objectName: null,
            objectNameGetterName: null,
            resolver: resolver,
            withBuiltValueSerializer: false,
            withEquality: withEquality,
            withCopy: withCopy,
            withSerialize: withSerialize,

            /// overrides
            classNameOverride: getSubclassName(method),
            fieldTypesOverride: {
              ...paramsTypes[method]!,
              ...fieldTypes,
            },
            genericTypesOverride: genericTypes,
            modelClassNameOverride: getModelSubclassName(method),
            parentClassName: className,
            qualifiedImportsOverride: qualifiedImports,
          ).generate())
              .join('\n'),
      ];
}
