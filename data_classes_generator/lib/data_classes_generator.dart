import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:dartx/dartx.dart';
import 'package:source_gen/source_gen.dart';

import 'package:data_classes/data_classes.dart';
import 'deserialization.dart';

const modelSuffix = 'Model';

Builder generateDataClass(BuilderOptions options) =>
    SharedPartBuilder([DataClassGenerator()], 'data_classes');

class CodeGenError extends Error {
  CodeGenError(this.message);
  final String message;
  String toString() => message;
}

class DataClassGenerator extends GeneratorForAnnotation<DataClass> {
  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep _,
  ) {
    if (element is! ClassElement) {
      throw CodeGenError(
        'You can only annotate classes with @DataClass(), but '
        '"${element.name}" isn\'t a class.',
      );
    }
    // if (!element.name.startsWith('_') || !element.name.endsWith(modelSuffix)) {
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

    final ClassElement originalClass = element;
    // final name = originalClass.name;
    final String className = originalClass.name.substring(
      originalClass.name[0] == '_' ? 1 : 0,
      originalClass.name.length - modelSuffix.length,
    );
    final String modelName = originalClass.name;
    final String modelNameLower = modelName.replaceFirstMapped(
      RegExp('[A-Za-z]'),
      (m) => m.group(0)?.toLowerCase() ?? '',
    );

    /// When import prefixes (`import '...' as '...';`) are used in the mutable
    /// class's file, then in the generated file, we need to use the right
    /// prefix in front of the type in the immutable class too. So here, we map
    /// the module identifiers to their import prefixes.
    Map<String, String> qualifiedImports = {
      for (final import in originalClass.library.libraryImports)
        if (import.prefix != null)
          import.importedLibrary!.identifier: import.prefix!.element.name,
    };

    /// Collect all the fields and getters from the original class.
    final Set<FieldElement> fields = {};

    for (final field in originalClass.fields) {
      if (field.type.toString() == 'dynamic') {
        throw CodeGenError(
          'Dynamic types are not allowed.\n'
          'Fix:\n'
          '  class $modelName {\n'
          '    ...\n'
          '    Object? ${field.name};\n'
          '    ...\n'
          '  }',
        );
      }
      fields.add(field);
    }
    final List<FieldElement> requiredFields = [];
    final List<FieldElement> nonRequiredFields = [];
    for (final field in fields) {
      (_isRequired(field) ? requiredFields : nonRequiredFields).add(field);
    }

    final DartObject classAnnotation = originalClass.metadata
        .firstWhere(
          (annotation) =>
              annotation.element?.enclosingElement3?.name == 'DataClass',
        )
        .computeConstantValue()!;

    /// Check which methods should we generate
    final bool builtValueSerializer =
        classAnnotation.getField('builtValueSerializer')!.toBoolValue()!;
    final ExecutableElement? childrenListener =
        classAnnotation.getField('childrenListener')?.toFunctionValue();
    final bool generateCopyWith =
        classAnnotation.getField('copyWith')!.toBoolValue()!;
    final bool immutable =
        classAnnotation.getField('immutable')!.toBoolValue()!;
    final bool convertToSnakeCase =
        classAnnotation.getField('convertToSnakeCase')?.toBoolValue() ?? false;
    // final ExecutableElement listener = originalClass.metadata
    //     .firstWhere((annotation) =>
    //         annotation.element?.enclosingElement?.name == 'DataClass')
    //     .constantValue
    //     .getField('listener')
    //     .toFunctionValue();
    final String? objectName =
        classAnnotation.getField('name')?.toStringValue();
    final ExecutableElement? objectNameGetter =
        classAnnotation.getField('getName')?.toFunctionValue();
    final String objectNamePrefix = objectNameGetter != null
        ? '\$\{${objectNameGetter.displayName}(prev)\}.'
        : (objectName?.isNotEmpty ?? false)
            ? '$objectName.'
            : '';
    final bool serialize =
        classAnnotation.getField('serialize')!.toBoolValue()!;

    /// Equality stuff (== and hashCode).
    /// https://stackoverflow.com/questions/10404516/how-can-i-compare-lists-for-equality-in-dart
    final String equalityFn = immutable ? 'eqShallow' : 'eqDeep';

    /// Actually generate the class.
    final StringBuffer buffer = StringBuffer();
    buffer.writeAll([
      '// ignore_for_file: deprecated_member_use_from_same_package, duplicate_ignore, lines_longer_than_80_chars, prefer_constructors_over_static_methods, unnecessary_lambdas, unnecessary_null_comparison, unnecessary_nullable_for_final_variable_declarations, unused_element, require_trailing_commas',

      /// Start of the class.
      '/// {@category model}',
      originalClass.documentationComment
              ?.replaceAll('/// {@nodoc}\n', '')
              .replaceAll('{@nodoc}', '') ??
          '',
      if (immutable) '@immutable',
      'class $className extends IDataClass<$className, $modelName> {',

      /// The default constructor
      '/// Creates a new [$className] with the given attributes',
      'factory $className({',
      for (final field in requiredFields)
        'required ${_field(field, qualifiedImports)},',
      for (final field in nonRequiredFields)
        '${_field(field, qualifiedImports, required: false)},',
      '}) => $className.build((b) => b',
      for (final field in requiredFields) '..${field.name} = ${field.name}',
      for (final field in nonRequiredFields)
        '..${field.name} = ${field.name} ?? b.${field.name}',
      ',);\n',

      'factory $className.from($className source,) => $className.build((b) => _modelCopy(source._model, b));\n',

      'factory $className.fromModel($modelName source,) => $className.build((b) => _modelCopy(source, b));\n',

      // TODO: use List.unmodifiable and Map.unmodifiable for immutable classes
      '$className.build(DataClassBuilder<$modelName>? build,) {\n',
      'build?.call(_model);\n',
      // for (final field in fields)
      //   if (!_isNullable(field)) 'assert(_model.${field.name} != null);',
      '}\n',

      if (serialize) ...[
        /// fromJson
        'factory $className.fromJson(Map<dynamic, dynamic> json) =>',
        '$className.fromModel(_modelFromJson(json));\n',
      ],

      /// The field members.
      'final $modelName _model = $modelName();\n',
      for (final field in fields) ...[
        if (field.documentationComment != null) field.documentationComment,
        _fieldGetter(field, qualifiedImports),
        if (!immutable) _fieldSetter(field, qualifiedImports),
      ],

      '/// Checks if this [$className] is equal to the other one.',
      '@override',
      'bool operator ==(Object other) =>',
      '  identical(this, other) || other is $className &&',
      fields
          .map(
            (field) =>
                '$equalityFn(_model.${field.name}, other._model.${field.name},)',
          )
          .join(' &&\n'),
      ';\n',
      '@override',
      'int get hashCode => hashList([',
      for (final field in fields)
        _isNullable(field)
            ? 'if (${field.name} != null) ${field.name}!,'
            : '${field.name},',
      ']);\n',

      /// toString converter.
      '/// Converts this [$className] into a [String].',
      '@override',
      "String toString() => \'$className(\\n'",
      for (final field in fields)
        _isNullable(field)
            ? "'''\${${field.name} != null ? '  ${field.name}: \${${field.name}!}\\n' : ''}'''"
            : "'  ${field.name}: \$${field.name}\\n'",
      "')';\n",

      /// copy
      '/// Creates a new instance of [$className], which is a copy of this with some changes',
      '@override $className copy([DataClassBuilder<$modelName>? update,]) => $className.build((builder) {',
      '  _modelCopy(_model, builder);',
      '  update?.call(builder);',
      if (childrenListener != null) '  _notifyOnPropChanges(_model, builder);',
      '});',
      '\n',

      // '@override Future<$className> copyAsync([DataClassAsyncBuilder<$modelName>? update]) async {',
      // 'final newModel = $modelName();',
      // '_modelCopy(_model, newModel);',
      // 'await update?.call(newModel);',
      // 'return $className.fromModel(newModel);',
      // '}',
      // '\n',

      /// copyWith
      if (generateCopyWith) ...[
        '/// Creates a new instance of [$className], which is a copy of this with some changes',
        '@override $className copyWith({',
        for (final field in fields)
          '${_field(field, qualifiedImports, required: false)},',
        '}) => copy((b) => b',
        for (final field in fields)
          '..${field.name} = ${field.name} ?? _model.${field.name}',
        if (fields.isNotEmpty) ',',
        ');\n',
      ],

      if (serialize) ...[
        /// toJson
        '@override Map<dynamic, dynamic> toJson() => serializeToJson({',
        for (final field in fields)
          _generateFieldSerializer(
            field,
            convertToSnakeCase: convertToSnakeCase,
          ),
        '}) as Map<dynamic, dynamic>;\n',

        /// _modelFromJson
        'static $modelName _modelFromJson(Map<dynamic,dynamic> json,) {',
        '  final model = $modelName();\n',
        for (final field in fields)
          ...generateFieldDeserializer(
            field,
            convertToSnakeCase: convertToSnakeCase,
          ),
        '\n  return model;',
        '}',
      ],
      if (builtValueSerializer)
        'static Serializer<$className> get serializer => _${className}Serializer();',

      '@override $modelName get \$model => _model;\n',

      'static void _modelCopy($modelName source, $modelName dest,) => dest',
      for (final field in fields) '..${field.name} = source.${field.name}',
      ';\n',

      if (childrenListener != null) ...[
        'static void _notifyOnPropChanges($modelName prev, $modelName next,) {',
        '  Future<void> notify(String name, dynamic Function($modelName) get, $modelName Function($modelName, dynamic) set,) async {',
        '    final prevValue = get(prev);',
        '    final nextValue = get(next);',
        '    if (!eqShallow(nextValue, prevValue)) {',
        '      await ${childrenListener.name}(',
        "        '$objectNamePrefix\$name',",
        '        next: nextValue,',
        '        prev: prevValue,',
        '      );',
        '    }',
        '  }\n',
        '  Future.wait([',
        for (final field in fields)
          "  notify('${field.name}', (m) => m.${field.name}, (m, v) => m..${field.name} = v as ${_qualifiedType(field.type, qualifiedImports)},),",
        '  ]);',
        '}',
      ],

      /// End of the class.
      '}\n',

      if (builtValueSerializer) ...[
        'class _${className}Serializer implements StructuredSerializer<$className> {',
        '  @override',
        '  final Iterable<Type> types = const [$className];',
        '',
        '  @override',
        '  final String wireName = \'$className\';\n',
        '',
        '  @override',
        '  Iterable<Object> serialize(Serializers serializers, $className object,',
        '      {FullType specifiedType = FullType.unspecified}) {',
        '    final json = _${modelNameLower}ToJson(object._model);',
        '    final List<Object> result = [];',
        '    json.forEach((k, v) => result.addAll([k, v]));\n',
        '    return result;',
        '  }\n',
        '',
        '  @override',
        '  $className deserialize(Serializers serializers, Iterable<Object> serialized,',
        '      {FullType specifiedType = FullType.unspecified}) {',
        '    final Map<dynamic, dynamic> json = {};',
        '    final serializedAsList = serialized.toList();',
        '    serializedAsList.asMap().forEach((i, key) {',
        '      if (i.isEven) json[key] = serializedAsList[i + 1];',
        '    });\n',
        '    return $className.fromModel(_modelFromJson(json));',
        '  }\n',
        '}\n',
      ],
    ].expand((line) => [line, '\n']));

    return buffer.toString();
  }

  String _generateFieldSerializer(
    FieldElement field, {
    bool convertToSnakeCase = false,
  }) {
    final String? customName = field.jsonKey;
    final String? customSerializer =
        field.customSerializer ?? field.type.element2?.customSerializer;
    final String getter = '_model.${field.name}';
    final String invocation =
        customSerializer != null ? '$customSerializer($getter)' : getter;
    final String jsonKey = customName ??
        (convertToSnakeCase ? field.name.camelToSnake() : field.name);

    return "'$jsonKey': $invocation,";
  }

  /// Whether to ignore `childrenListener` or `listener` for the [field].
  // bool _ignoreListener(FieldElement field) {
  //   assert(field != null);

  //   return field.metadata
  //       .any((annotation) => annotation.element.name == 'ignoreChanges');
  // }

  /// Whether the [field] is nullable
  bool _isNullable(FieldElement field) =>
      field.type.nullabilitySuffix == NullabilitySuffix.question;

  /// Whether the [field] is required
  bool _isRequired(FieldElement field) =>
      !_isNullable(field) && !field.hasInitializer;

  // /// Capitalizes the first letter of a string.
  // String _capitalize(String string) {
  //   assert(string.isNotEmpty);
  //   return string[0].toUpperCase() + string.substring(1);
  // }

  /// Turns the [field] into type and the field name, separated by a space.
  String _field(
    FieldElement field,
    Map<String, String> qualifiedImports, {
    bool required = true,
  }) =>
      '${_qualifiedType(field.type, qualifiedImports)}${!required && field.type.nullabilitySuffix != NullabilitySuffix.question ? '?' : ''} ${field.name}';
  // }) {
  //   if (field.type.toString().contains('dynamic') &&
  //       field.enclosingElement.nameOffset > 0) {
  //     // if (field.type.toString() == 'List<dynamic>') {
  //     final source = field.declaration.source!.contents.data
  //         .substring(0, field.declaration.nameOffset);
  //     String? m;
  //     if (field.type.element != null &&
  //         field.type.isDynamic &&
  //         field.type.element!.isSynthetic) {
  //       final match = RegExp(r'(\w+\??)\s+$').firstMatch(source);
  //       m = match?.group(1);
  //     } else if (field.type.element != null) {
  //       final match = RegExp(r'(\w+<.+?>\??)\s+$').firstMatch(source);
  //       m = match?.group(1);
  //     }
  //     m ??= resolveFullTypeStringFrom(
  //       field.library,
  //       field.type,
  //       withNullability: true,
  //     );
  //     if (field.type.toString() != m) print(m);
  //   }

  //   return '${_qualifiedType(field.type, qualifiedImports)}${!required && field.type.nullabilitySuffix != NullabilitySuffix.question ? '?' : ''} ${field.name}';
  // }

  // String _fieldDeclaration(
  //   FieldElement field,
  //   Map<String, String> qualifiedImports,
  // ) =>
  //     '${_qualifiedType(field.type, qualifiedImports)} _${field.name};';

  String _fieldGetter(
    FieldElement field,
    Map<String, String> qualifiedImports,
  ) =>
      '${_qualifiedType(field.type, qualifiedImports)} get ${field.name} => '
      '_model.${field.name};';

  String _fieldSetter(
    FieldElement field,
    Map<String, String> qualifiedImports,
  ) =>
      'set ${field.name}(${_qualifiedType(field.type, qualifiedImports)} value) => '
      '_model.${field.name} = value;';

  /// Turns the [type] into a type with prefix.
  String _qualifiedType(DartType type, Map<String, String> qualifiedImports) {
    final LibraryElement? typeLibrary = type.element2!.library;
    final String? prefixOrNull = qualifiedImports[typeLibrary?.identifier];
    final String prefix = (prefixOrNull != null) ? '$prefixOrNull.' : '';

    // TODO: Add a parameter to keep null-safety
    return '$prefix${type.toString().replaceAll('*', '')}';
  }
}

String resolveFullTypeStringFrom(
  LibraryElement originLibrary,
  DartType type, {
  required bool withNullability,
}) {
  final PrefixElement? owner = originLibrary.prefixes.firstOrNullWhere(
    (prefix) {
      final List<LibraryImportElement> librariesForPrefix = prefix.imports2;

      return librariesForPrefix.any((l) {
        return l.importedLibrary!.anyTransitiveExport((library) {
          return library.id == _getElementForType(type).library?.id;
        });
      });
    },
  );

  String? displayType = type.getDisplayString(withNullability: withNullability);

  // The parameter is a typedef in the form of
  // SomeTypedef typedef
  //
  // In this case the analyzer would expand that typedef using getDisplayString
  // For example for:
  //
  // typedef SomeTypedef = Function(String);
  //
  // it would generate:
  // 'dynamic Function(String)'
  //
  // Instead of 'SomeTypedef'
  if (type is FunctionType && type.alias?.element != null) {
    displayType = type.alias!.element.name;
    if (type.alias!.typeArguments.isNotEmpty) {
      displayType += '<${type.alias!.typeArguments.join(', ')}>';
    }
    if (type.nullabilitySuffix == NullabilitySuffix.question) {
      displayType += '?';
    }
  }

  return owner != null ? '${owner.name}.$displayType' : displayType;
}

/// Returns the [Element] for a given [DartType]
///
/// this is usually type.element, except if it is a typedef then it is
/// type.alias.element
Element _getElementForType(DartType type) =>
    type.element2 != null ? type.element2! : type.alias!.element;

extension LibraryHasImport on LibraryElement {
  LibraryElement? findTransitiveExportWhere(
    bool Function(LibraryElement library) visitor,
  ) {
    if (visitor(this)) return this;

    final Set<LibraryElement> visitedLibraries = <LibraryElement>{};
    LibraryElement? visitLibrary(LibraryElement library) {
      if (!visitedLibraries.add(library)) return null;

      if (visitor(library)) return library;

      for (final export in library.exportedLibraries) {
        final result = visitLibrary(export);
        if (result != null) return result;
      }

      return null;
    }

    for (final import in exportedLibraries) {
      final result = visitLibrary(import);
      if (result != null) return result;
    }

    return null;
  }

  bool anyTransitiveExport(bool Function(LibraryElement library) visitor) =>
      findTransitiveExportWhere(visitor) != null;
}
