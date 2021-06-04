part of 'data_classes.dart';

Map<String, dynamic> serializeToJson(dynamic value) =>
    _serializeEntryToJson('', value)[''];

Map<String, dynamic> _serializeEntryToJson(dynamic key, dynamic value) {
  final keyStr = _serializePrimitive(key, castToString: true);

  if (value == null) return {};

  if (_isPrimitive(value)) return {keyStr: _serializePrimitive(value)};

  if (value is Iterable)
    return {
      keyStr: value
          .map((v) => _serializeEntryToJson('', v)[''])
          .whereNotNull()
          .toList()
    };

  if (value is Map)
    return {
      keyStr: {
        for (final entry in value.entries)
          ..._serializeEntryToJson(entry.key, entry.value)
      }
    };

  if (value is IDataClass)
    return {
      keyStr: _serializeEntryToJson('', value.toJson())[''],
    };

  throw Exception('Invalid json field: $value');
}

bool _isPrimitive(dynamic value) =>
    value is bool ||
    value is DateTime ||
    value is String ||
    value is num ||
    (value is Object && value.isEnum);

dynamic _serializePrimitive(
  dynamic value, {
  bool castToString = false,
}) {
  assert(
    _isPrimitive(value),
    'Value must be a String, DateTime, num or Enum! $value',
  );

  dynamic serialized;

  if (value is String) serialized = value;

  if (value is DateTime) serialized = value.toIso8601String();

  if (value is bool || value is num) serialized = value;

  if (value is Object && value.isEnum) serialized = value.asString();

  return !castToString && (value is num || value is bool)
      ? serialized
      : '$serialized';
}

T? deserializePrimitive<T>(
  dynamic value, [
  T? defaultValue,
]) {
  final valueStr = castOrNull<String>(value);

  dynamic deserialized;

  if (T is DateTime) deserialized = DateTime.tryParse(valueStr ?? '');

  if (T is String) deserialized = valueStr;

  if (T is bool) deserialized = _boolFromString(valueStr);

  if (T is double) deserialized = double.tryParse(valueStr ?? '');

  if (T is int) deserialized = int.tryParse(valueStr ?? '');

  return deserialized as T ?? defaultValue;
}

bool? _boolFromString(String? str) {
  if (str == null) return null;

  final strLower = str.toLowerCase();

  return strLower == 'true'
      ? true
      : strLower == 'false'
          ? false
          : null;
}
