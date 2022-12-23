import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

import 'package:data_classes/src/generators/generators.dart' show modelSuffix;
import 'package:data_classes/src/generators/types.dart';

import 'copy.dart';
import 'core.dart';
import 'equality.dart';
import 'notification.dart';
import 'serialization.dart';

class DataClassGenerator {
  DataClassGenerator({
    required this.modelClass,
    required this.resolver,
    this.builtValueSerializer = false,
    this.childrenListener,
    this.convertToSnakeCase = false,
    this.generateCopyWith = true,
    this.generateEquality = true,
    this.immutable = false,
    this.objectName,
    this.objectNameGetter,
    this.serialize = true,
  }) {
    genericTypes = modelClass.typeParameters.isEmpty
        ? ''
        : '<${modelClass.typeParameters.map((e) => e.name).join(', ')}>';

    dataClassName = modelClass.name.substring(
      modelClass.name[0] == '_' ? 1 : 0,
      modelClass.name.length - modelSuffix.length,
    );
    modelClassName = '${modelClass.name}$genericTypes';

    objectNamePrefix = objectNameGetter != null
        ? '\$\{${objectNameGetter!.displayName}(prev)\}.'
        : (objectName?.isNotEmpty ?? false)
            ? '$objectName.'
            : '';

    /// Consider all `late` fields as required
    for (final field in fields) {
      (field.isRequired ? requiredFields : nonRequiredFields).add(field);
    }
  }

  final bool builtValueSerializer;
  final ExecutableElement? childrenListener;
  final bool convertToSnakeCase;
  final bool generateCopyWith;
  final bool generateEquality;
  final bool immutable;
  // final ExecutableElement listener;
  final ClassElement modelClass;
  final String? objectName;
  final ExecutableElement? objectNameGetter;
  final Resolver resolver;
  final bool serialize;

  late final String dataClassName;
  late final String genericTypes;
  late final String modelClassName;
  late final String objectNamePrefix;

  List<FieldElement> get fields => modelClass.fields;
  late final Map<FieldElement, String> fieldTypes;
  final List<FieldElement> nonRequiredFields = [];
  final List<FieldElement> requiredFields = [];

  Future<Iterable<String>> generate() async {
    /// When import prefixes (`import '...' as '...';`) are used in the mutable
    /// class's file, then in the generated file, we need to use the right
    /// prefix in front of the type in the immutable class too. So here, we map
    /// the module identifiers to their import prefixes.
    Map<String, String> qualifiedImports = {
      for (final import in modelClass.library.libraryImports)
        if (import.prefix != null)
          import.importedLibrary!.identifier: import.prefix!.element.name,
    };
    fieldTypes = {
      for (final f in fields)
        f: await getFieldTypeString(f, qualifiedImports, resolver: resolver),
    };

    return [
      // ...generateIgnores,
      ...generateClassHeader(),
      '{',
      ...generateConstructors(),
      if (serialize) ...generateFromJson(),
      ...generateFields(),
      ...generateEqualityOperator(),
      ...generateHashCode(),
      ...generateToString(),
      ...generateCopy(),
      if (serialize) ...await generateSerializers(),
      if (childrenListener != null) ...generateChangesNotificator(),
      '}',
      if (serialize && builtValueSerializer) ...generateBuiltValueSerializer(),
    ];
  }

  /// Turns the [field] into type and the field name, separated by a space.
  String fieldDeclaration(
    FieldElement field, {
    required bool required,
  }) =>
      '${fieldTypes[field]!}${required || field.isNullable(fieldTypes) ? '' : '?'} ${field.name}';

  static Iterable<String> generateIgnores = [
    '// ignore_for_file: deprecated_member_use_from_same_package, duplicate_ignore, lines_longer_than_80_chars, prefer_constructors_over_static_methods, sort_constructors_first, unnecessary_lambdas, unnecessary_null_comparison, unnecessary_nullable_for_final_variable_declarations, unused_element, require_trailing_commas',
  ];
}

extension FieldChecks on FieldElement {
  bool isNullable(Map<FieldElement, String> fieldTypes) {
    final String typeString = fieldTypes[this]!;
    return typeString[typeString.length - 1] == '?';
  }

  bool get isRequired => isLate && !hasInitializer;
}
