import 'package:collection/collection.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';

import 'package:data_classes/src/utils/strings.dart';

import '../types.dart';

const _typeRegex = r'\w+(\s*<.+>)?';
final RegExp _iterableRegex = RegExp(
  r'^(Iterable|\w*List(View)?|Set)\s*<\s*(' + _typeRegex + r')\s*>\??$',
);

final RegExp _mapRegex = RegExp(
  r'^\w*Map+\s*<(\s*' + _typeRegex + r')\s*,\s*(' + _typeRegex + r')\s*>\??$',
);

Future<List<String>> generateFieldDeserializer(
  FieldElement field, {
  required String typeString,
  required Resolver resolver,
  bool convertToSnakeCase = false,
}) async {
  final DartType type = field.type;
  final String fieldName =
      field.displayName.isNotEmpty ? field.displayName : 'value';
  final String fieldJsonName = field.jsonKey ??
      (convertToSnakeCase ? fieldName.camelToSnake() : fieldName);
  final String? deserializer = await _generateValueDeserializer(
    accessor: 'j',
    customDeserializer: field.customDeserializer,
    fieldType: type,
    resolver: resolver,
    typeString: typeString,
  );

  return [
    'setModelField<$typeString>(',
    '  json,',
    "  '$fieldJsonName',",
    '  (v) => model.$fieldName = v${typeIsNullable(typeString) ? '' : '!'},',
    if (deserializer != null) '  getter: (j) => $deserializer,',
    if (!typeIsNullable(typeString))
      field.hasInitializer ? '  nullable: false,' : '  required: true,',
    ');\n',
  ];
}

Future<String?> _generateValueDeserializer({
  required String accessor,
  required DartType fieldType,
  required Resolver resolver,
  required String typeString,
  String? customDeserializer,
}) async {
  String resolvedTypeString = await getTypeString(
    fieldType,
    typeString: typeString,
    resolver: resolver,
  );
  // print('$typeString -> $resolvedTypeString');

  RegExpMatch? match;
  bool isMap = false;
  bool isIterable = false;
  match = _mapRegex.firstMatch(typeString);
  if (match != null) {
    isMap = true;
  } else {
    match = _iterableRegex.firstMatch(typeString);
    if (match != null) isIterable = true;
  }

  if (customDeserializer != null) return '$customDeserializer($accessor)';
  if (fieldType.isDartCoreMap || isMap) {
    if (!isMap) {
      if (resolvedTypeString.indexOf('<') == -1) {
        resolvedTypeString = '$resolvedTypeString<dynamic, dynamic>';
      }
      match = _mapRegex.firstMatch(resolvedTypeString);
      if (match == null) {
        print('No Map types match for $resolvedTypeString! ($typeString)');
      }
    }

    return _generateMapDeserializer(
      accessor: accessor,
      fieldType: fieldType,
      resolver: resolver,
      typeStringMatch: match!,
    );
  }
  if (fieldType.isIterable || isIterable) {
    if (!isIterable) {
      if (resolvedTypeString.indexOf('<') == -1) {
        resolvedTypeString = '$resolvedTypeString<dynamic>';
      }
      match = _iterableRegex.firstMatch(resolvedTypeString);
      if (match == null) {
        print('No Iterable type match for $resolvedTypeString! ($typeString)');
      }
    }

    return _generateIterableDeserializer(
      accessor: accessor,
      fieldType: fieldType,
      resolver: resolver,
      typeStringMatch: match!,
    );
  }
  if (fieldType.isDartCoreBool) return 'boolValueFromJson($accessor)';
  if (fieldType.isDartCoreInt) return 'intValueFromJson($accessor)';
  if (fieldType.isDartCoreDouble) return 'doubleValueFromJson($accessor)';
  if (fieldType.isDateTime) return 'dateTimeValueFromJson($accessor)';
  if (fieldType.isEnum) {
    final int typeIndex = resolvedTypeString.indexOf('<');

    return typeIndex > -1
        ? 'castOrNull<${resolvedTypeString}>('
            'enumValueFromJson($accessor, ${resolvedTypeString.substring(0, typeIndex)}.values),'
            ')'
        : 'enumValueFromJson($accessor, $resolvedTypeString.values)';
  }
  if (fieldType.hasFromJson ||

      /// Here is an assumption that all unknown types are just not generated yet
      /// and will be serializable
      fieldType.isDynamic && resolvedTypeString != 'dynamic') {
    return 'valueFromJson($accessor, $resolvedTypeString.fromJson)';
  }
  // if( fieldType.isDynamic) return accessor;

  return null;
}

Future<String> _generateIterableDeserializer({
  required String accessor,
  required DartType fieldType,
  required Resolver resolver,
  required RegExpMatch typeStringMatch,
}) async {
  final Iterable<DartType> typeParams = fieldType.genericTypes;
  assert(
    typeParams.length != 1,
    'Type must be an Iterable with type parameter explicitly defined: $fieldType!',
  );

  final DartType valueType = typeParams.first;
  final String valueTypeString = typeStringMatch[3]!;
  final String? valueDeserializer = await _generateValueDeserializer(
    accessor: 'v',
    fieldType: valueType,
    resolver: resolver,
    typeString: valueTypeString,
  );
  // print('Iterable<$valueTypeString>');

  return [
    '${fieldType.isDartCoreList ? 'listValueFromJson' : fieldType.isDartCoreSet ? 'setValueFromJson' : 'iterableValueFromJson'}<$valueTypeString>(',
    '  $accessor,',
    if (valueDeserializer != null) '  value: (v) => $valueDeserializer,',
    if (typeIsNullable(valueTypeString)) '  valueNullable: true,',
    ')',
  ].join();
}

Future<String> _generateMapDeserializer({
  required String accessor,
  required DartType fieldType,
  required Resolver resolver,
  required RegExpMatch typeStringMatch,
}) async {
  final Iterable<DartType> typeParams = fieldType.genericTypes;
  assert(
    fieldType.isDartCoreMap && typeParams.length == 2,
    'Type must be a Map with both type parameters explicitly defined: $fieldType!',
  );

  final DartType keyType = typeParams.first;
  final DartType valueType = typeParams.last;
  final String keyTypeString = typeStringMatch[1]!;
  final String valueTypeString = typeStringMatch[3]!;
  // print('Map<$keyTypeString, $valueTypeString>');

  assert(
    keyType.isSimple || keyType.hasFromJson,
    '''Map key type must be one of these types [bool, DateTime, double, enum, int, String] or should have `fromJson()` constructor.'''
    '''Given type: $keyType.''',
  );

  final String? keyDeserializer = await _generateValueDeserializer(
    accessor: 'k',
    fieldType: keyType,
    resolver: resolver,
    typeString: keyTypeString,
  );
  final String? valueDeserializer = await _generateValueDeserializer(
    accessor: 'v',
    fieldType: valueType,
    resolver: resolver,
    typeString: valueTypeString,
  );

  return [
    'mapValueFromJson<$keyTypeString, $valueTypeString>(',
    '  $accessor,',
    if (keyDeserializer != null) '  key: (k) => $keyDeserializer,',
    if (typeIsNullable(keyTypeString)) '  keyNullable: true,',
    if (valueDeserializer != null) '  value: (v) => $valueDeserializer,',
    if (typeIsNullable(valueTypeString)) '  valueNullable: true,',
    ')',
  ].join();
}

extension on DartType {
  bool get hasFromJson => element is ClassElement
      ? (element as ClassElement).constructors.any(
          (method) => method.displayName == '${element!.displayName}.fromJson')
      : false;
}

extension ElementX on Element {
  DartObject? get serializableAnnotation => metadata
      .firstWhereOrNull(
        (annotation) =>
            annotation.element?.enclosingElement?.name == 'Serializable',
      )
      ?.computeConstantValue();

  String? get customSerializer => serializableAnnotation
      ?.getField('toJson')
      ?.toFunctionValue()
      ?.displayName;

  String? get customDeserializer => serializableAnnotation
      ?.getField('fromJson')
      ?.toFunctionValue()
      ?.displayName;

  String? get jsonKey => metadata
      .firstWhereOrNull((annotation) =>
          annotation.element?.enclosingElement?.name == 'JsonKey')
      ?.computeConstantValue()
      ?.getField('name')
      ?.toStringValue();
}

bool typeIsNullable(String typeString) =>
    typeString[typeString.length - 1] == '?';
