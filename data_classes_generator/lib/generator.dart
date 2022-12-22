import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

import 'package:data_classes/data_classes.dart';
import 'deserialization.dart';
import 'types.dart';

const modelSuffix = 'Model';

class DataClassGenerator {
  const DataClassGenerator(this.modelClass, this.resolver);
  final ClassElement modelClass;
  final Resolver resolver;

  Future<String> generate() async {
    final String genericTypes = modelClass.typeParameters.isEmpty
        ? ''
        : '<${modelClass.typeParameters.map((e) => e.name).join(', ')}>';

    final String dataClassName = modelClass.name.substring(
      modelClass.name[0] == '_' ? 1 : 0,
      modelClass.name.length - modelSuffix.length,
    );
    final String modelClassName = '${modelClass.name}$genericTypes';
    final String modelNameLower = modelClassName.replaceFirstMapped(
      RegExp('[A-Za-z]'),
      (m) => m.group(0)?.toLowerCase() ?? '',
    );

    /// When import prefixes (`import '...' as '...';`) are used in the mutable
    /// class's file, then in the generated file, we need to use the right
    /// prefix in front of the type in the immutable class too. So here, we map
    /// the module identifiers to their import prefixes.
    Map<String, String> qualifiedImports = {
      for (final import in modelClass.library.libraryImports)
        if (import.prefix != null)
          import.importedLibrary!.identifier: import.prefix!.element.name,
    };

    /// Collect all the fields and getters from the original class.
    final List<FieldElement> fields = modelClass.fields;
    final Map<FieldElement, String> fieldTypes = {
      for (final f in fields)
        f: await getFieldTypeString(f, qualifiedImports, resolver: resolver),
    };
    final List<FieldElement> requiredFields = [];
    final List<FieldElement> nonRequiredFields = [];

    /// Consider all `late` fields as required
    for (final field in fields) {
      (field.isRequired ? requiredFields : nonRequiredFields).add(field);
    }

    final DartObject classAnnotation = modelClass.metadata
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
      modelClass.documentationComment
              ?.replaceAll('/// {@nodoc}\n', '')
              .replaceAll('{@nodoc}', '') ??
          '',
      if (immutable) '@immutable',
      'class $dataClassName$genericTypes extends IDataClass<$dataClassName$genericTypes, $modelClassName> {',

      /// The default constructor
      '/// Creates a new [$dataClassName] with the given attributes',
      'factory $dataClassName({',
      for (final field in requiredFields)
        'required ${_fieldDeclaration(field, fieldTypes, required: true)},',
      for (final field in nonRequiredFields)
        '${_fieldDeclaration(field, fieldTypes, required: false)},',
      '}) => $dataClassName._build((b) => b',
      for (final field in requiredFields) '..${field.name} = ${field.name}',
      for (final field in nonRequiredFields)
        '..${field.name} = ${field.name}${field.hasInitializer ? ' ?? b.${field.name}' : ''}',
      ',);\n',

      'factory $dataClassName.from($dataClassName$genericTypes source,) => ',
      '  $dataClassName$genericTypes._build(',
      '    (destModel) => _modelCopy(source._model, destModel),',
      '  );\n',

      'factory $dataClassName.fromModel($modelClassName source,) => ',
      '  $dataClassName$genericTypes._build((dest) => _modelCopy(source, dest));\n',

      // TODO: use List.unmodifiable and Map.unmodifiable for immutable classes
      '$dataClassName._build(DataClassBuilder<$modelClassName>? builder,) {',
      '  builder?.call(_model);',
      // for (final field in fields)
      //   if (!_isNullable(field)) 'assert(_model.${field.name} != null);',
      '}\n',

      if (serialize) ...[
        /// fromJson
        'factory $dataClassName.fromJson(Map<dynamic, dynamic> json) =>',
        '$dataClassName.fromModel(_modelFromJson$genericTypes(json));\n',
      ],

      /// The field members.
      'final $modelClassName _model = $modelClassName();\n',
      for (final field in fields) ...[
        if (field.documentationComment != null) field.documentationComment,
        _fieldGetter(field, fieldTypes),
        if (!immutable) _fieldSetter(field, fieldTypes),
      ],

      '/// Checks if this [$dataClassName] is equal to the other one.',
      '@override',
      'bool operator ==(Object other) =>',
      '  identical(this, other) || other is $dataClassName$genericTypes &&',
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
      '/// Converts this [$dataClassName] into a [String].',
      '@override',
      "String toString() => \'$dataClassName(\\n'",
      for (final field in fields)
        field.isNullable(fieldTypes)
            ? "'''\${${field.name} != null ? '  ${field.name}: \${${field.name}!}\\n' : ''}'''"
            : "'  ${field.name}: \$${field.name}\\n'",
      "')';\n",

      /// copy
      '/// Creates a new instance of [$dataClassName], which is a copy of this with some changes',
      '@override $dataClassName$genericTypes copy([DataClassBuilder<$modelClassName>? update,]) => $dataClassName$genericTypes._build((dest) {',
      '  _modelCopy(_model, dest);',
      '  update?.call(dest);',
      if (childrenListener != null) '  _notifyOnPropChanges(_model, dest);',
      '});',
      '\n',

      /// copyAsync
      '/// Creates a new instance of [$dataClassName], which is a copy of this with some changes',
      '@override Future<$dataClassName$genericTypes> copyAsync([DataClassAsyncBuilder<$modelClassName>? update,]) async {',
      'final model = $modelClassName();',
      '_modelCopy(_model, model);',
      'await update?.call(model);\n',
      'return $dataClassName$genericTypes._build((dest) {',
      '  _modelCopy(model, dest);',
      '  update?.call(dest);',
      if (childrenListener != null) '  _notifyOnPropChanges(_model, dest);',
      '});',
      '}',
      '\n',

      /// copyWith
      if (generateCopyWith) ...[
        '/// Creates a new instance of [$dataClassName], which is a copy of this with some changes',
        '@override $dataClassName$genericTypes copyWith({',
        for (final field in fields)
          '${_fieldDeclaration(field, fieldTypes, required: false)},',
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
        'static $modelClassName _modelFromJson$genericTypes(Map<dynamic,dynamic> json,) {',
        '  final model = $modelClassName();\n',
        for (final field in fields)
          ...await generateFieldDeserializer(
            field,
            convertToSnakeCase: convertToSnakeCase,
            resolver: resolver,
            typeString: fieldTypes[field]!,
          ),
        '\n  return model;',
        '}',
      ],
      if (builtValueSerializer)
        'static Serializer<$dataClassName> get serializer => _${dataClassName}Serializer();',

      '@override $modelClassName get \$model => _model;\n',

      'static void _modelCopy$genericTypes($modelClassName source, $modelClassName dest,) => dest',
      for (final field in fields) '..${field.name} = source.${field.name}',
      ';\n',

      if (childrenListener != null) ...[
        'static void _notifyOnPropChanges($modelClassName prev, $modelClassName next,) {',
        '  Future<void> notify(String name, dynamic Function($modelClassName) get, $modelClassName Function($modelClassName, dynamic) set,) async {',
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
        'class _${dataClassName}Serializer implements StructuredSerializer<$dataClassName> {',
        '  @override',
        '  final Iterable<Type> types = const [$dataClassName];',
        '',
        '  @override',
        '  final String wireName = \'$dataClassName\';\n',
        '',
        '  @override',
        '  Iterable<Object> serialize(Serializers serializers, $dataClassName object,',
        '      {FullType specifiedType = FullType.unspecified}) {',
        '    final json = _${modelNameLower}ToJson(object._model);',
        '    final List<Object> result = [];',
        '    json.forEach((k, v) => result.addAll([k, v]));\n',
        '    return result;',
        '  }\n',
        '',
        '  @override',
        '  $dataClassName deserialize(Serializers serializers, Iterable<Object> serialized,',
        '      {FullType specifiedType = FullType.unspecified}) {',
        '    final Map<dynamic, dynamic> json = {};',
        '    final serializedAsList = serialized.toList();',
        '    serializedAsList.asMap().forEach((i, key) {',
        '      if (i.isEven) json[key] = serializedAsList[i + 1];',
        '    });\n',
        '    return $dataClassName.fromModel(_modelFromJson(json));',
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

  /// Turns the [field] into type and the field name, separated by a space.
  String _fieldDeclaration(
    FieldElement field,
    Map<FieldElement, String> fieldTypes, {
    required bool required,
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
