import 'package:data_classes/src/generators/common/common.dart';

class DataClassGenerator extends ClassGenerator {
  DataClassGenerator({
    required super.convertToSnakeCase,
    required super.immutable,
    required super.modelClass,
    required super.mutateFromActionsOnly,
    required super.objectName,
    required super.objectNameGetterName,
    required super.observableFields,
    required super.observerNames,
    required super.resolver,
    required super.withBuiltValueSerializer,
    required super.withCopy,
    required super.withEquality,
    required super.withReflection,
    required super.withSerialize,

    /// overrides
    super.classNameOverride,
    super.fieldTypesOverride,
    super.genericTypesOverride,
    super.genericTypesFullOverride,
    super.modelClassNameOverride,
    super.parentClassName,
    super.qualifiedImportsOverride,
  });

  @override
  Future<List<Iterable<String>>> build() async => [
        generateClassHeader(),
        ['{'],
        generateConstructors(),
        if (withSerialize) await generateDeserializer(),
        generateFields(),
        if (withEquality) ...[
          generateEqualityOperator(),
          generateHashCode(),
        ],
        if (withSerialize) generateToString(),
        if (withCopy) generateCopy(),
        if (withSerialize) generateSerializer(),
        if ((!immutable || withCopy) && observerNames?.isNotEmpty == true)
          generateChangesNotificator(),
        ['}'],
        generateBaseModels(),
        if (withSerialize && withBuiltValueSerializer)
          generateBuiltValueSerializer(),
      ];
}
