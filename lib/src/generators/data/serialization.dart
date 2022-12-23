import 'package:analyzer/dart/element/element.dart';

import 'package:data_classes/src/utils/strings.dart';

import 'data.dart';
import 'deserialization.dart';

extension DataClassSerialization on DataClassGenerator {
  Iterable<String> generateBuiltValueSerializer() => [
        'class _${dataClassName}Serializer implements StructuredSerializer<$dataClassName> {',
        '  @override',
        '  final Iterable<Type> types = const [$dataClassName];',
        '',
        '  @override',
        '  final String wireName = \'$dataClassName\';\n',
        '',
        '  @override',
        '  Iterable<Object?> serialize(Serializers serializers, $dataClassName object,',
        '      {FullType specifiedType = FullType.unspecified}) {',
        '    final Map<dynamic, dynamic> json = _${modelClassName.decapitalized}ToJson(object._model);\n',
        '    return [',
        '      for (final e in json.entries) ...[e.key, e.value],',
        '    ];',
        '  }',
        '',
        '  @override',
        '  $dataClassName deserialize(Serializers serializers, Iterable<Object?> serialized,',
        '      {FullType specifiedType = FullType.unspecified}) {',
        '    final Map<dynamic, dynamic> json = {};',
        '    final serializedAsList = serialized.toList();',
        '    serializedAsList.asMap().forEach((i, key) {',
        '      if (i.isEven) json[key] = serializedAsList[i + 1];',
        '    });',
        '',
        '    return $dataClassName._fromModel($dataClassName$genericTypes._modelFromJson(json),);',
        '  }',
        '}',
      ];

  Iterable<String> generateFromJson() => [
        'factory $dataClassName._fromModel($modelClassName source,) => ',
        '  $dataClassName$genericTypes._build((dest) => _modelCopy(source, dest));',
        '',
        'factory $dataClassName.fromJson(Map<dynamic, dynamic> json) =>'
            '$dataClassName._fromModel(_modelFromJson$genericTypes(json));\n',
        '',
      ];

  Future<Iterable<String>> generateSerializers() async => [
        /// toJson
        '@override Map<dynamic, dynamic> toJson() => serializeToJson({',
        for (final field in fields) _generateFieldSerializer(field),
        '}) as Map<dynamic, dynamic>;',
        '',

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
        '\nreturn model;',
        '}',
        '',
        if (builtValueSerializer)
          'static Serializer<$dataClassName> get serializer => _${dataClassName}Serializer();',
      ];

  Iterable<String> generateToString() => [
        '/// Converts this [$dataClassName] into a [String].',
        '@override',
        "String toString() => \'$dataClassName(\\n'",
        for (final field in fields)
          field.isNullable(fieldTypes)
              ? "'''\${${field.name} != null ? '  ${field.name}: \${${field.name}!}\\n' : ''}'''"
              : "'  ${field.name}: \$${field.name}\\n'",
        "')';",
        '',
      ];

  String _generateFieldSerializer(FieldElement field) {
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
}
