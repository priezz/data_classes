import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dartx/dartx.dart';

import 'package:data_classes/data_classes.dart';

List<String> generateFieldDeserializer(
  FieldElement field, {
  bool convertToSnakeCase = false,
}) {
  final DartType type = field.type;
  final String fieldName =
      field.displayName.isNotEmpty ? field.displayName : 'value';
  final String fieldJsonName = field.jsonKey ??
      (convertToSnakeCase ? fieldName.camelToSnake() : fieldName);
  final String? deserializer = _generateValueDeserializer(
    accessor: 'j',
    customDeserializer: field.customDeserializer,
    fieldType: type,
  );

  return [
    'setModelField<$type>(',
    '  json,',
    "  '$fieldJsonName',",
    '  (v) => model.$fieldName = v${type.isRequired ? '!' : ''},',
    if (deserializer != null) '  getter: (j) => $deserializer,',
    if (type.isRequired)
      field.hasInitializer ? '  nullable: false,' : '  required: true,',
    ');\n',
  ];
}

String? _generateValueDeserializer({
  required String accessor,
  required DartType fieldType,
  String? customDeserializer,
}) {
  late String typeStr;
  if (fieldType.hasFromJson || fieldType.isEnum) {
    typeStr = fieldType.getDisplayString(withNullability: false);
    // typeStr = fieldType
    // .getDisplayString(
    //   withNullability: !fieldType.hasFromJson && !fieldType.isEnum,
    // )
    // .removePrefix('[')
    // .removeSuffix(']');
  }
  return customDeserializer != null
      ? '$customDeserializer($accessor)'
      : fieldType.isDartCoreMap
          ? _generateMapDeserializer(
              accessor: accessor,
              fieldType: fieldType,
            )
          : fieldType.isIterable
              ? _generateIterableDeserializer(
                  accessor: accessor,
                  fieldType: fieldType,
                )
              : fieldType.isDartCoreBool
                  ? 'boolValueFromJson($accessor)'
                  : fieldType.isDartCoreInt
                      ? 'intValueFromJson($accessor)'
                      : fieldType.isDartCoreDouble
                          ? 'doubleValueFromJson($accessor)'
                          : fieldType.isDateTime
                              ? 'dateTimeValueFromJson($accessor)'
                              : fieldType.isEnum
                                  ? 'enumValueFromJson($accessor, $typeStr.values)'
                                  : fieldType.hasFromJson
                                      ? 'valueFromJson($accessor, $typeStr.fromJson)'
                                      : fieldType.isDynamic
                                          ? accessor
                                          : null;
}

String _generateIterableDeserializer({
  required String accessor,
  required DartType fieldType,
}) {
  final Iterable<DartType> typeParams = fieldType.genericTypes;
  assert(
    typeParams.length != 1,
    'Type must be an Iterable with type parameter explicitly defined: $fieldType!',
  );

  final DartType valueType = typeParams.first;
  final String? valueDeserializer =
      _generateValueDeserializer(accessor: 'v', fieldType: valueType);

  return [
    '${fieldType.isDartCoreList ? 'listValueFromJson' : fieldType.isDartCoreSet ? 'setValueFromJson' : 'iterableValueFromJson'}<$valueType>(',
    '  $accessor,',
    if (valueDeserializer != null) '  value: (v) => $valueDeserializer,',
    if (!valueType.isRequired) '  valueNullable: true,',
    ')',
  ].join();
}

String _generateMapDeserializer({
  required String accessor,
  required DartType fieldType,
}) {
  final Iterable<DartType> typeParams = fieldType.genericTypes;

  assert(
    fieldType.isDartCoreMap && typeParams.length == 2,
    'Type must be a Map with both type parameters explicitly defined: $fieldType!',
  );

  final DartType keyType = typeParams.first;
  final DartType valueType = typeParams.last;

  assert(
    keyType.isSimple,
    '''Map key type must be one of these types [bool, DateTime, double, enum, int, String] or should have `fromJson()` constructor.'''
    '''Given type: $keyType.''',
  );

  final String? keyDeserializer =
      _generateValueDeserializer(accessor: 'k', fieldType: keyType);
  final String? valueDeserializer =
      _generateValueDeserializer(accessor: 'v', fieldType: valueType);

  return [
    'mapValueFromJson<$keyType, $valueType>(',
    '  $accessor,',
    if (keyDeserializer != null) '  key: (k) => $keyDeserializer,',
    if (!keyType.isRequired) '  keyNullable: true,',
    if (valueDeserializer != null) '  value: (v) => $valueDeserializer,',
    if (!valueType.isRequired) '  valueNullable: true,',
    ')',
  ].join();
}

extension on DartType {
  // bool get hasFromJson {
  //   if (element is ClassElement && element!.name == 'Package')
  //     print(
  //         'Package: ${(element as ClassElement).constructors.map((c) => c.displayName)}, ${(element as ClassElement).methods.map((c) => c.displayName)}');

  //   return element is ClassElement
  //       ? (element as ClassElement)
  //           .constructors
  //           .any((method) => method.displayName == 'fromJson')
  //       : false;
  // }
  bool get hasFromJson => element is ClassElement
      ? (element as ClassElement).constructors.any(
          (method) => method.displayName == '${element!.displayName}.fromJson')
      : false;

  bool get isDateTime => getDisplayString(withNullability: false) == 'DateTime';

  bool get isEnum =>
      element is ClassElement ? (element as ClassElement).isEnum : false;

  bool get isIterable => isDartCoreIterable || isDartCoreList || isDartCoreSet;

  bool get isSimple =>
      isDartCoreBool ||
      isDartCoreDouble ||
      isDartCoreInt ||
      isDartCoreString ||
      isEnum ||
      isDateTime ||
      // isDynamic ||
      // isDartCoreObject ||
      hasFromJson;

  bool get isRequired => nullabilitySuffix != NullabilitySuffix.question;

  Iterable<DartType> get genericTypes => this is ParameterizedType
      ? (this as ParameterizedType).typeArguments
      : const [];

  // String get nameWithoutTypeParams {
  //   final name = getDisplayString(withNullability: false);
  //   final indexOfBracket = name.indexOf('<');
  //   return indexOfBracket > 0 ? name.substring(0, indexOfBracket) : name;
  // }
}

extension ElementX on Element {
  DartObject? get serializableAnnotation => metadata
      .firstOrNullWhere(
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
      .firstOrNullWhere((annotation) =>
          annotation.element?.enclosingElement?.name == 'JsonKey')
      ?.computeConstantValue()
      ?.getField('name')
      ?.toStringValue();
}
