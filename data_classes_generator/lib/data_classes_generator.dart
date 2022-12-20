import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'package:data_classes/data_classes.dart';
import 'deserialization.dart';
import 'types.dart';

const modelSuffix = 'Model';

Builder generateDataClass(BuilderOptions options) =>
    SharedPartBuilder([DataClassGenerator()], 'data_class',
        allowSyntaxErrors: true);

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
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw CodeGenError(
        'You can only annotate classes with @DataClass(), but '
        '"${element.name}" isn\'t a class.',
      );
    }
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
    final String className = originalClass.name.substring(
      originalClass.name[0] == '_' ? 1 : 0,
      originalClass.name.length - modelSuffix.length,
    );
    final String modelName = originalClass.name;
    final String modelNameLower = modelName.replaceFirstMapped(
      RegExp('[A-Za-z]'),
      (m) => m.group(0)?.toLowerCase() ?? '',
    );
    // print(
    //     '$className<${originalClass.typeParameters.map((e) => e.name).join(', ')}>');

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
    final List<FieldElement> fields = originalClass.fields;
    final Map<FieldElement, String> fieldTypes = {
      for (final f in fields)
        f: await getFieldTypeString(f, qualifiedImports,
            resolver: buildStep.resolver),
    };
    final List<FieldElement> requiredFields = [];
    final List<FieldElement> nonRequiredFields = [];

    /// Consider all `late` fields as required
    for (final field in fields) {
      (field.isRequired ? requiredFields : nonRequiredFields).add(field);
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
        'required ${_field(field, fieldTypes)},',
      for (final field in nonRequiredFields)
        '${_field(field, fieldTypes, required: false)},',
      '}) => $className.build((b) => b',
      for (final field in requiredFields) '..${field.name} = ${field.name}',
      for (final field in nonRequiredFields)
        '..${field.name} = ${field.name}${field.hasInitializer ? ' ?? b.${field.name}' : ''}',
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
        _fieldGetter(field, fieldTypes),
        if (!immutable) _fieldSetter(field, fieldTypes),
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
        field.isNullable(fieldTypes)
            ? 'if (${field.name} != null) ${field.name}!,'
            : '${field.name},',
      ']);\n',

      /// toString converter.
      '/// Converts this [$className] into a [String].',
      '@override',
      "String toString() => \'$className(\\n'",
      for (final field in fields)
        field.isNullable(fieldTypes)
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
          '${_field(field, fieldTypes, required: false)},',
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
          ...await generateFieldDeserializer(
            field,
            convertToSnakeCase: convertToSnakeCase,
            resolver: buildStep.resolver,
            typeString: fieldTypes[field]!,
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
          "  notify('${field.name}', (m) => m.${field.name}, (m, v) => m..${field.name} = v as ${fieldTypes[field]},),",
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

    // print(buffer);
    return buffer.toString();
  }

  String _generateFieldSerializer(
    FieldElement field, {
    bool convertToSnakeCase = false,
  }) {
    final String? customName = field.jsonKey;
    final String? customSerializer =
        field.customSerializer ?? field.type.element?.customSerializer;
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

  // /// Capitalizes the first letter of a string.
  // String _capitalize(String string) {
  //   assert(string.isNotEmpty);
  //   return string[0].toUpperCase() + string.substring(1);
  // }

  /// Turns the [field] into type and the field name, separated by a space.
  String _field(
    FieldElement field,
    Map<FieldElement, String> fieldTypes, {
    bool required = true,
  }) =>
      '${fieldTypes[field]!}${required || field.isNullable(fieldTypes) ? '' : '?'} ${field.name}';

  String _fieldGetter(
    FieldElement field,
    Map<FieldElement, String> fieldTypes,
  ) =>
      '${fieldTypes[field]} get ${field.name} => '
      '_model.${field.name};';

  String _fieldSetter(
    FieldElement field,
    Map<FieldElement, String> fieldTypes,
  ) =>
      'set ${field.name}(${fieldTypes[field]} value) => '
      '_model.${field.name} = value;';
}

extension on FieldElement {
  bool isNullable(Map<FieldElement, String> fieldTypes) {
    final String typeString = fieldTypes[this]!;
    return typeString[typeString.length - 1] == '?';
  }

  bool get isRequired => isLate && !hasInitializer;
}
