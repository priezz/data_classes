import 'package:data_classes/src/generators/common/common.dart';

// import 'copy.dart';
// import 'core.dart';
// import 'equality.dart';
// import 'notification.dart';
// import 'serialization.dart';

class DataClassGenerator extends ClassGenerator {
  DataClassGenerator({
    required super.withBuiltValueSerializer,
    required super.changesListenerName,
    required super.convertToSnakeCase,
    required super.withCopy,
    required super.withEquality,
    required super.immutable,
    required super.modelClass,
    required super.objectName,
    required super.objectNameGetterName,
    required super.resolver,
    required super.withSerialize,

    /// overrides
    super.classNameOverride,
    super.fieldTypesOverride,
    super.genericTypesOverride,
    super.modelClassNameOverride,
    super.parentClassName,
    super.qualifiedImportsOverride,
  });

  @override
  Future<Iterable<String>> generate() async {
    await super.generate();

    return [
      generateClassHeader(),
      ['{'],
      generateConstructors(),
      if (withSerialize) await generateDeserializer(),
      generateFields(),
      generateEqualityOperator(),
      generateHashCode(),
      generateToString(),
      generateCopy(),
      if (withSerialize) generateSerializer(),
      if (changesListenerName != null) generateChangesNotificator(),
      ['}'],
      if (withSerialize && withBuiltValueSerializer)
        generateBuiltValueSerializer(),
    ].expand((items) => items);
  }
}
