part of 'data_classes_generator.dart';

List<String> _generateFieldDeserializer(
  FieldElement field, {
  bool convertToSnakeCase = false,
}) {
  final fieldName = field.displayName;
  final annotation = field.metadata
      .firstOrNullWhere(
        (annotation) =>
            annotation.element?.enclosingElement?.name == 'Serializable',
      )
      ?.computeConstantValue();
  final customDeserializer =
      annotation?.getField('fromJson')?.toFunctionValue()?.displayName;
  final customName = annotation?.getField('name')?.toStringValue();
  final accessor =
      "json['${customName ?? (convertToSnakeCase ? _camelToSnake(fieldName) : fieldName)}']";

  return [
    if (customDeserializer != null)
      'model.${field.displayName} = $customDeserializer(json);'
    else if (field.type.isLeaf) ...[
      'final ${field.displayName} = ',
      ..._generateLeafDeserializer(
        field.type,
        accessor,
        forceUnwrap: !field.hasInitializer,
      ),
      ';',
      if (field.type.isRequired &&
          field.hasInitializer &&
          !field.type.hasFromJson)
        'if ($fieldName != null)',
      'model.$fieldName = $fieldName;\n',
    ] else if (field.type.isIterable)
      ..._generateIterableDeserializer(
        field.type,
        accessor,
        fieldName: field.displayName,
        addNullCheck: field.hasInitializer && field.type.isRequired,
      )
    else if (field.type.isDartCoreMap)
      ..._generateMapDeserializer(
        field.type,
        accessor,
        fieldName: field.displayName,
        addNullCheck: field.hasInitializer && field.type.isRequired,
      )
  ];
}

List<String> _generateLeafDeserializer(
  DartType type,
  String accessor, {
  bool forceUnwrap = false,
  bool sourceIsAlwaysString = false,
}) {
  assert(
    type.isLeaf,
    '''Json leaf must be one of these types: [bool, double, int, String, DateTime]'''
    '''Given type: $type.''',
  );

  final typeStr = type
      .getDisplayString(withNullability: !type.hasFromJson && !type.isEnum)
      .removePrefix('[')
      .removeSuffix(']');
  final suffix = type.isRequired && forceUnwrap ? '!' : '';

  return [
    if (sourceIsAlwaysString &&
        (type.isDartCoreInt || type.isDartCoreDouble)) ...[
      if (type.isDartCoreInt)
        "int.tryParse(castOrNull<String>($accessor) ?? '')$suffix"
      else if (type.isDartCoreDouble)
        "double.tryParse(castOrNull<String>($accessor) ?? '')$suffix"
    ] else ...[
      if (type.hasFromJson) ...[
        if (!type.isRequired) '$accessor == null ? null : ',
        '$typeStr.fromJson($accessor ?? {})',
      ] else if (type.isEnum)
        "enumFromString(castOrNull<String>($accessor) ?? '', $typeStr.values)$suffix"
      else if (type.isDateTime)
        "DateTime.tryParse(castOrNull<String>($accessor) ?? '')$suffix"
      else if (type.isDynamic)
        accessor
      else
        'castOrNull<$typeStr>($accessor)$suffix',
    ],
  ];
}

List<String> _generateIterableDeserializer(
  DartType type,
  String accessor, {
  bool addNullCheck = false,
  String? fieldName,
  String? outputOperator,
}) {
  assert(type.isIterable, 'Field type must be Iterable! $type');

  final typeParameter = type.genericTypes.firstOrNull;

  assert(
    typeParameter != null,
    'All Iterables must have their type explicitly set! $type',
  );

  final isRoot = fieldName != null;
  final fieldGetter = fieldName ?? 'val';
  final fieldCall = !type.isRequired
      ? '$fieldGetter?'
      : addNullCheck
          ? fieldGetter
          : '($fieldGetter ?? [])';
  final mapFn = typeParameter!.isRequired ? 'mapNotNull' : 'map';

  return [
    if (!isRoot) '(e){',
    'final $fieldGetter = castOrNull<Iterable>($accessor);',
    if (!isRoot) '\n',
    if (addNullCheck) 'if ($fieldName != null)',
    outputOperator ?? (isRoot ? 'model.$fieldName =' : 'return'),
    ' $fieldCall.$mapFn(',
    if (typeParameter.isIterable)
      ..._generateIterableDeserializer(typeParameter, 'e')
    else if (typeParameter.isDartCoreMap) ...[
      ..._generateMapDeserializer(typeParameter, 'e',
          assignmentExpression: 'return'),
      ';}'
    ] else if (typeParameter.isLeaf) ...[
      '(e) => ',
      ..._generateLeafDeserializer(
        typeParameter,
        'e',
      ),
    ],
    ')',
    if (!type.isDartCoreIterable) '.to${type.nameWithoutTypeParams}()',
    ';\n',
    if (!isRoot) '}',
  ];
}

List<String> _generateMapDeserializer(
  DartType type,
  String accessor, {
  bool addNullCheck = false,
  String? fieldName,
  String? assignmentExpression,
}) {
  final typeParams = type.genericTypes;

  assert(
    type.isDartCoreMap && typeParams.length == 2,
    'Type must be a Map with both type parameters explicitly defined: $type!',
  );

  final keyType = typeParams.first;
  final valueType = typeParams.last;

  assert(
    keyType.isLeaf,
    '''Map key must be one of these types: [bool, double, int, String]'''
    '''Given type: $keyType.''',
  );
  assert(
    valueType.isLeaf || valueType.isIterable || valueType.isDartCoreMap,
    '''Map value must be one of these types: [bool, double, int, String, enum, Map, Iterable]'''
    '''Given type; $valueType''',
  );
  final isRoot = fieldName != null;
  final fieldGetter = fieldName ?? 'val';
  final fieldCall =
      addNullCheck || !type.isRequired ? fieldGetter : '($fieldGetter ?? {})';
  final shouldNullCheckValue = valueType.isRequired &&
      !valueType.isIterable &&
      !valueType.isDartCoreMap &&
      !valueType.isDynamic;

  return [
    if (!isRoot) '(e){',
    'final $fieldGetter = castOrNull<Map>($accessor);',
    if (addNullCheck) 'if ($fieldGetter != null)',
    assignmentExpression ?? (isRoot ? 'model.$fieldName =' : 'return'),
    if (!type.isRequired && !addNullCheck) ' $fieldGetter == null ? null : ',
    'Map.fromEntries($fieldCall.entries.mapNotNull((e){',
    'final key = ',
    ..._generateLeafDeserializer(
      keyType,
      'e.key',
      sourceIsAlwaysString: true,
    ),
    ';',
    if (valueType.isLeaf) ...[
      'final value = ',
      ..._generateLeafDeserializer(valueType, 'e.value'),
      ';'
    ] else if (valueType.isIterable) ...[
      ..._generateIterableDeserializer(
        valueType,
        'e.value',
        fieldName: 'valueTyped',
        outputOperator: 'final value =',
      )
    ] else if (valueType.isDartCoreMap)
      ..._generateMapDeserializer(
        valueType,
        'e.value',
        assignmentExpression: 'final value =',
        fieldName: 'valueTyped',
      ),
    '\n',
    if (!keyType.isRequired && !shouldNullCheckValue)
      'return MapEntry(key, value)'
    else ...[
      'return ',
      if (keyType.isRequired) 'key != null',
      if (keyType.isRequired && shouldNullCheckValue) ' && ',
      if (shouldNullCheckValue) 'value != null',
      '? MapEntry(key, value) : null',
    ],
    ';})',
    if (isRoot) ');\n' else ')',
  ];
}

extension on DartType {
  bool get hasFromJson => element is ClassElement
      ? (element as ClassElement)
          .constructors
          .any((method) => method.displayName == 'fromJson')
      : false;

  bool get isDateTime => getDisplayString(withNullability: false) == 'DateTime';
  bool get isEnum =>
      element is ClassElement ? (element as ClassElement).isEnum : false;
  bool get isIterable => isDartCoreIterable || isDartCoreList || isDartCoreSet;
  bool get isLeaf =>
      isDartCoreBool ||
      isDartCoreDouble ||
      isDartCoreInt ||
      isDartCoreString ||
      isDateTime ||
      isEnum ||
      isDynamic ||
      hasFromJson;

  bool get isRequired => nullabilitySuffix != NullabilitySuffix.question;

  Iterable<DartType> get genericTypes => this is ParameterizedType
      ? (this as ParameterizedType).typeArguments
      : const [];

  String get nameWithoutTypeParams {
    final name = getDisplayString(withNullability: false);
    final indexOfBracket = name.indexOf('<');
    return indexOfBracket > 0 ? name.substring(0, indexOfBracket) : name;
  }
}

Map<String, List<String>> thing = {};

void parse(dynamic json) {
  final data = castOrNull<Map>(json['thing']);

  thing = Map.fromEntries((data ?? {}).entries.mapNotNull((entry) {
    final keyTyped = castOrNull<String>(entry.key);
    final valueTyped = castOrNull<List>(entry.value);

    final value = (valueTyped ?? []).mapNotNull((e) {
      return castOrNull<String>(e);
    }).toList();

    return MapEntry(keyTyped!, value);
  }));
}
