import 'package:analyzer/dart/element/element.dart';

import 'package:data_classes/src/utils/strings.dart';

import 'common.dart';
import 'deserialization.dart';

extension ClassGeneratorSerialization on ClassGenerator {
  Iterable<String> generateBuiltValueSerializer() => [
        'class _${className}Serializer implements StructuredSerializer<$className> {',
        '  @override',
        '  final Iterable<Type> types = const [$className];',
        '',
        '  @override',
        '  final String wireName = \'$className\';\n',
        '',
        '  @override',
        '  Iterable<Object?> serialize(Serializers serializers, $className object,',
        '      {FullType specifiedType = FullType.unspecified}) {',
        '    final Json json = object.toJson();\n',
        '    return [',
        '      for (final e in json.entries) ...[e.key, e.value],',
        '    ];',
        '  }',
        '',
        '  @override',
        '  $className deserialize(Serializers serializers, Iterable<Object?> serialized,',
        '      {FullType specifiedType = FullType.unspecified}) {',
        '    final Json json = {};',
        '    final serializedAsList = serialized.toList();',
        '    serializedAsList.asMap().forEach((i, key) {',
        '      if (i.isEven) json[key] = serializedAsList[i + 1];',
        '    });',
        '',
        '    return $className._fromModel($classNameTyped._modelFromJson(json),);',
        '  }',
        '}',
      ];

  Future<Iterable<String>> generateDeserializer() async => [
        'factory $className._fromModel($modelClassNameTyped source,) => ',
        '  $classNameTyped._build((dest) => _modelCopy(source, dest));',
        '',
        'factory $className.fromJson(Json json)',
        if (parentClassName != null) ...[
          '{',
          "  if (json['@class'] != '$className') {",
          "    throw Exception('Invalid json data for $className. \$json');",
          '  }',
          '',
          'return ',
        ] else
          ' =>',
        '$className._fromModel(_modelFromJson$genericTypes(json));\n',
        if (parentClassName != null) '}',
        '',

        /// _modelFromJson
        'static $modelClassNameTyped _modelFromJson$genericTypesFull(Map<dynamic,dynamic> json,) {',
        '  final model = $modelClassNameTyped();\n',
        for (final field in fields)
          ...await generateFieldDeserializer(
            field,
            convertToSnakeCase: convertToSnakeCase,
            resolver: resolver,
            typeString: fieldTypes[field]!,
          ),
        '\nreturn model;',
        '}',
      ];

  Iterable<String> generateSerializer() => [
        /// toJson
        '@override Json toJson() => serializeToJson({',
        if (parentClassName != null) ...[
          "'@class': '$className',",
          '...super.toJson(),',
        ],
        for (final field in fields) _generateFieldSerializer(field),
        '}) as Json;',

        if (withBuiltValueSerializer)
          'static Serializer<$className> get serializer => _${className}Serializer();',
        '',
      ];

  Iterable<String> generateToString() => [
        '/// Converts this [$className] into a [String].',
        '@override',
        "String toString() => \'$className(\\n'",
        for (final field in fields)
          field.isNullable(fieldTypes)
              ? "'''\${${field.name} != null ? '  ${field.name}: \${${field.name}!}\\n' : ''}'''"
              : "'  ${field.name}: \$${field.name}\\n'",
        "')';",
        '',
      ];

  String _generateFieldSerializer(VariableElement field) {
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
