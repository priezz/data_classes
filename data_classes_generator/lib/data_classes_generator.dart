import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:dartx/dartx.dart';
// import 'package:collection/collection.dart' show IterableExtension;
// ignore: import_of_legacy_library_into_null_safe
import 'package:source_gen/source_gen.dart';

import 'package:data_classes/data_classes.dart';

part 'serialization.dart';

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
    final modelName = originalClass.name;

    /// When import prefixes (`import '...' as '...';`) are used in the mutable
    /// class's file, then in the generated file, we need to use the right
    /// prefix in front of the type in the immutable class too. So here, we map
    /// the module identifiers to their import prefixes.
    Map<String, String> qualifiedImports = {
      for (final import in originalClass.library.imports)
        if (import.prefix != null)
          import.importedLibrary!.identifier: import.prefix!.name,
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
              annotation.element?.enclosingElement?.name == 'DataClass',
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

    // /// Users can annotate fields that hold an enum value with
    // /// `@GenerateValueGetters()` to generate value getters.
    // /// Here, we prepare a map from the getter name to its code content.
    // final valueGetters = <String, String>{};
    // for (final field in fields) {
    //   final annotation = field.metadata
    //       .firstWhereOrNull((annotation) =>
    //           annotation.element?.enclosingElement?.name ==
    //           'GenerateValueGetters')
    //       ?.computeConstantValue();
    //   if (annotation == null) continue;

    //   final usePrefix = annotation.getField('usePrefix')!.toBoolValue()!;
    //   final generateNegations =
    //       annotation.getField('generateNegations')!.toBoolValue();

    //   final enumClass = field.type.element as ClassElement;
    //   if (!enumClass.isEnum) {
    //     throw CodeGenError('You annotated the $modelName\'s ${field.name} with '
    //         '@GenerateValueGetters(), but that\'s of '
    //         'the type ${enumClass.name}, '
    //         'which is not an enum. @GenerateValueGetters() should only be '
    //         'used on fields of an enum type.');
    //   }

    //   final prefix = 'is${usePrefix ? _capitalize(field.name) : ''}';
    //   final enumValues = enumClass.fields
    //       .where((field) => !['values', 'index'].contains(field.name));

    //   for (final value in enumValues) {
    //     for (final negate in generateNegations! ? [false, true] : [false]) {
    //       final getter =
    //           '$prefix${negate ? 'Not' : ''}${_capitalize(value.name)}';
    //       final content = 'this.${field.name} ${negate ? '!=' : '=='} '
    //           '${_qualifiedType(value.type, qualifiedImports)}.${value.name}';

    //       if (valueGetters.containsKey(getter)) {
    //         throw CodeGenError(
    //             'A conflict occurred while generating value getters. The two '
    //             'conflicting value getters of the $modelName class are:\n'
    //             '- $getter, which tests if ${valueGetters[getter]}\n'
    //             '- $getter, which tests if $content');
    //       }

    //       valueGetters[getter] = content;
    //     }
    //   }
    // }

    // final String nameUncapitalized =
    //     name.substring(0, 1).toLowerCase() + name.substring(1);

    /// Equality stuff (== and hashCode).
    /// https://stackoverflow.com/questions/10404516/how-can-i-compare-lists-for-equality-in-dart
    final String equalityFn = immutable ? 'eqShallow' : 'eqDeep';

    /// Actually generate the class.
    final buffer = StringBuffer();
    buffer.writeAll([
      '// ignore_for_file: argument_type_not_assignable, avoid_private_typedef_functions, avoid_single_cascade_in_expression_statements, dead_null_aware_expression, lines_longer_than_80_chars, implicit_dynamic_method, implicit_dynamic_parameter, implicit_dynamic_type, non_constant_identifier_names, prefer_asserts_with_message, prefer_constructors_over_static_methods, prefer_expression_function_bodies, sort_constructors_first',

      /// Start of the class.
      '/// {@category model}',
      originalClass.documentationComment
              ?.replaceAll('/// {@nodoc}\n', '')
              .replaceAll('{@nodoc}', '') ??
          '',
      if (immutable) '@immutable',
      'class $className extends IDataClass<$className, $modelName> {',
      '@override final $modelName _model = $modelName();\n',

      /// The field members.
      for (final field in fields) ...[
        if (field.documentationComment != null) field.documentationComment,
        _fieldGetter(field, qualifiedImports),
        if (!immutable) _fieldSetter(field, qualifiedImports),
      ],

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

      'factory $className.from($className source) => $className.build((b) => _modelCopy(source._model, b));\n',

      'factory $className.fromModel($modelName source) => $className.build((b) => _modelCopy(source, b));\n',

      // TODO: use List.unmodifiable and Map.unmodifiable for immutable classes
      '$className.build(DataClassBuilder<$modelName>? build) {\n',
      'build?.call(_model);\n',
      // for (final field in fields)
      //   if (!_isNullable(field)) 'assert(_model.${field.name} != null);',
      '}\n',

      '/// Checks if this [$className] is equal to the other one.',
      '@override',
      'bool operator ==(Object other) =>',
      '  identical(this, other) || other is $className &&',
      fields
          .map(
            (field) =>
                '$equalityFn(_model.${field.name}, other._model.${field.name})',
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
            ? "'\${${field.name} != null ? '  ${field.name}: \${${field.name}!}\\n' : ''}'"
            : "'  ${field.name}: \$${field.name}\\n'",
      "')';\n",

      /// copy
      '/// Creates a new instance of [$className], which is a copy of this with some changes',
      '@override $className copy([DataClassBuilder<$modelName>? update]) => $className.build((builder) {',
      '  _modelCopy(_model, builder);',
      '  update?.call(builder);',
      if (childrenListener != null) '  _notifyOnPropChanges(_model, builder);',
      '});',

      /// copyWith
      if (generateCopyWith) ...[
        '/// Creates a new instance of [$className], which is a copy of this with some changes',
        '@override $className copyWith({',
        for (final field in fields)
          '${_field(field, qualifiedImports, required: false)},',
        '}) => copy((b) => b',
        for (final field in fields)
          '..${field.name} = ${field.name} ?? _model.${field.name}',
        ');\n',
      ],

      if (serialize) ...[
        /// fromJson
        'factory $className.fromJson(Map<dynamic, dynamic> json) =>',
        '$className.fromModel(_\$${modelName}FromJson(json));\n',
        'static $className deserialize(Map<dynamic, dynamic> json) =>',
        '$className.fromJson(json);\n',

        /// toJson
        '@override Map<dynamic, dynamic> toJson() => _\$${modelName}ToJson(_model);\n',
      ],
      if (builtValueSerializer)
        'static Serializer<$className> get serializer => _\$${className}Serializer();',

      '@override $modelName get thisModel => _model;\n',

      'static void _modelCopy($modelName source, $modelName dest,) => dest',
      for (final field in fields)
        '..${field.name} = source.${field.name} ${_isNullable(field) ? '?? dest.${field.name}' : ''}',
      ';\n',

      if (childrenListener != null) ...[
        'static void _notifyOnPropChanges($modelName prev, $modelName next,) {',
        '  Future<void> notify(String name, dynamic Function($modelName) get, $modelName Function($modelName, dynamic) set,) async {',
        '    final prevValue = get(prev);',
        '    final nextValue = get(next);',
        '    if (!eqShallow(nextValue, prevValue)) {',
        '      await $childrenListener(',
        "        '$objectNamePrefix\$name',",
        '        next: nextValue,',
        '        prev: prevValue,',
        "        toJson: () => _\$${modelName}ToJson(set($modelName(), nextValue))[name],",
        '      );',
        '    }',
        '  }\n',
        '  Future.wait([',
        for (final field in fields)
          "  notify('${field.name}', (m) => m.${field.name}, (m, v) => m..${field.name} = v as ${_qualifiedType(field.type, qualifiedImports)}),",
        '  ]);',
        '}',
      ],

      /// End of the class.
      '}\n',

      if (builtValueSerializer) ...[
        'class _\$${className}Serializer implements StructuredSerializer<$className> {',
        '  @override',
        '  final Iterable<Type> types = const [$className];',
        '  @override',
        '  final String wireName = \'$className\';\n',
        '  @override',
        '  Iterable<Object> serialize(Serializers serializers, $className object,',
        '      {FullType specifiedType = FullType.unspecified}) {',
        '    final json = _\$${modelName}ToJson(object._model);',
        '    final List<Object> result = [];',
        '    json.forEach((k, v) => result.addAll([k, v]));\n',
        '    return result;',
        '  }\n',
        '  @override',
        '  $className deserialize(Serializers serializers, Iterable<Object> serialized,',
        '      {FullType specifiedType = FullType.unspecified}) {',
        '    final Map<dynamic, dynamic> json = {};',
        '    final serializedAsList = serialized.toList();',
        '    serializedAsList.asMap().forEach((i, key) {',
        '      if (i.isEven) json[key] = serializedAsList[i + 1];',
        '    });\n',
        '    return $className.fromModel(_\$${modelName}FromJson(json));',
        '  }\n',
        '}\n',
      ],

      if (serialize) ...[
        '$modelName _\$${modelName}FromJson(Map<dynamic,dynamic> json){',
        'final model = $modelName();\n',
        for (final field in fields) ..._generateFieldDeserializer(field),
        'return model;',
        '}',
        '\n\n',
        'Map<String, dynamic> _\$${modelName}ToJson($modelName instance) =>',
        'serializeToJson({',
        for (final field in fields) _generateFieldSerializer(field),
        '});',
      ]
    ].expand((line) => [line, '\n']));

    return buffer.toString();
  }

  String _generateFieldSerializer(FieldElement field) {
    final annotation = field.metadata
        .firstOrNullWhere(
          (annotation) =>
              annotation.element?.enclosingElement?.name == 'Serializable',
        )
        ?.computeConstantValue();
    final customSerializer =
        annotation?.getField('toJson')?.toFunctionValue()?.displayName;
    final customName = annotation?.getField('name')?.toStringValue();
    final getter = 'instance.${field.name}';
    final invocation =
        customSerializer != null ? '$customSerializer($getter)' : getter;

    return "'${customName ?? field.name}': $invocation,";
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
    final typeLibrary = type.element!.library;
    final prefixOrNull = qualifiedImports[typeLibrary?.identifier];
    final prefix = (prefixOrNull != null) ? '$prefixOrNull.' : '';

    // TODO: Add a parameter to keep null-safety
    return '$prefix${type.toString().replaceAll('*', '')}';
  }
}
