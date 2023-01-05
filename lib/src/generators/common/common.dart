import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';

import 'package:data_classes/src/generators/generators.dart' show modelSuffix;
import 'package:data_classes/src/generators/types.dart';

export 'copy.dart';
export 'core.dart';
export 'equality.dart';
export 'notification.dart';
export 'serialization.dart';

abstract class ClassGenerator {
  ClassGenerator({
    required this.withBuiltValueSerializer,
    required this.changesListenerName,
    required this.convertToSnakeCase,
    required this.withCopy,
    required this.withEquality,
    required this.immutable,
    required this.modelClass,
    required this.objectName,
    required this.objectNameGetterName,
    required this.resolver,
    required this.withSerialize,
    String? classNameOverride,
    Map<VariableElement, String>? fieldTypesOverride,
    String? genericTypesOverride,
    String? modelClassNameOverride,
    this.parentClassName,
    Map<String, String>? qualifiedImportsOverride,
  }) {
    assert(
      modelClass != null ||
          classNameOverride != null &&
              fieldTypesOverride != null &&
              genericTypesOverride != null &&
              modelClassNameOverride != null &&
              qualifiedImportsOverride != null,
    );

    if (modelClass != null) {
      genericTypes = modelClass!.typeParameters.isEmpty
          ? ''
          : '<${modelClass!.typeParameters.map((e) => e.name).join(', ')}>';

      className = modelClass!.name.substring(
        modelClass!.name[0] == '_' ? 1 : 0,
        modelClass!.name.length - modelSuffix.length,
      );
      modelClassNameTyped = '${modelClass!.name}$genericTypes';
    } else {
      className = classNameOverride!;
      _fields = fieldTypesOverride!.keys.toList();
      fieldTypes = fieldTypesOverride;
      genericTypes = genericTypesOverride!;
      modelClassNameTyped = '$modelClassNameOverride$genericTypes';
      qualifiedImports = qualifiedImportsOverride!;
    }

    classNameTyped = '$className$genericTypes';
    objectNamePrefix = objectNameGetterName != null
        ? '\$\{$objectNameGetterName(prev)\}.'
        : (objectName?.isNotEmpty ?? false)
            ? '$objectName.'
            : '';

    /// Consider all `late` fields as required
    for (final field in fields) {
      (field.isRequired ? requiredFields : nonRequiredFields).add(field);
    }
  }

  final String? changesListenerName;
  final bool convertToSnakeCase;
  final bool immutable;
  // final ExecutableElement listener;
  final ClassElement? modelClass;
  final String? objectName;
  final String? objectNameGetterName;
  final String? parentClassName;
  final Resolver resolver;
  final bool withBuiltValueSerializer;
  final bool withCopy;
  final bool withEquality;
  final bool withSerialize;

  late final String className;
  late final String classNameTyped;
  String genericTypes = '';
  String genericTypesFull = '';
  late String modelClassNameTyped;
  late final String objectNamePrefix;

  List<VariableElement> get fields => modelClass?.fields ?? _fields;
  List<MethodElement> get methods => modelClass?.methods ?? [];
  Map<VariableElement, String> fieldTypes = {};
  Map<MethodElement, Map<VariableElement, String>> paramsTypes = {};
  final List<VariableElement> nonRequiredFields = [];
  Map<String, String> qualifiedImports = {};
  final List<VariableElement> requiredFields = [];

  List<VariableElement> _fields = [];

  @mustCallSuper
  Future<Iterable<String>> generate() async {
    /// When import prefixes (`import '...' as '...';`) are used in the mutable
    /// class's file, then in the generated file, we need to use the right
    /// prefix in front of the type in the immutable class too. So here, we map
    /// the module identifiers to their import prefixes.
    if (qualifiedImports.isEmpty && modelClass != null) {
      qualifiedImports = {
        for (final import in modelClass!.library.libraryImports)
          if (import.prefix != null)
            import.importedLibrary!.identifier: import.prefix!.element.name,
      };

      fieldTypes = {
        for (final field in fields)
          field: await getElementTypeString(
            field,
            qualifiedImports,
            lookupParent: true,
            resolver: resolver,
          ),
      };
      paramsTypes = {
        for (final method in methods)
          method: {
            for (final param in method.parameters)
              param: await getElementTypeString(
                param,
                qualifiedImports,
                resolver: resolver,
              ),
          },
      };
      if (modelClass!.typeParameters.isNotEmpty) {
        genericTypesFull = await getElementTypeString(
          modelClass!,
          qualifiedImports,
          predicate: (s) => RegExp(r'^<.*>$').hasMatch(s),
          resolver: resolver,
        );
      }
    }

    return [];
  }

  /// Turns the [element] into type and the field name, separated by a space.
  String fieldDeclaration(
    VariableElement element, {
    required bool required,
    MethodElement? method,
  }) {
    final types = method != null ? paramsTypes[method]! : fieldTypes;

    return '${types[element]!}${required || element.isNullable(types) ? '' : '?'} ${element.name}';
  }
}

extension FieldChecks on FieldElement {
  bool get isRequired => isLate && !hasInitializer;
}

extension VariableChecks on VariableElement {
  bool get hasInitializer {
    final self = this;
    if (self is FieldElement) return self.hasInitializer;
    if (self is ParameterElement) return self.hasDefaultValue;
    return false;
  }

  bool isNullable(Map<VariableElement, String> types) {
    final String typeString = types[this]!;
    return typeString[typeString.length - 1] == '?';
  }

  bool get isRequired {
    final self = this;
    if (self is FieldElement) return self.isLate && !self.hasInitializer;
    if (self is ParameterElement) return self.isRequired;
    return false;
  }
}

// extension ParamChecks on ParameterElement {
//   bool get isRequired2 => !hasDefaultValue;
// }
