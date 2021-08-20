part of 'data_classes.dart';

dynamic serializeToJson(dynamic obj) {
  if (obj == null) return null;

  if (obj is Map) {
    return {
      for (final entry in obj.entries)
        '${serializeToJson(entry.key)}': serializeToJson(entry.value),
    };
  }

  if (obj is Iterable) {
    return [
      for (final entry in obj) serializeToJson(entry),
    ];
  }

  if (obj is IDataClass) return obj.toJson();

  if (obj is bool || obj is num || obj is String) return obj;

  if (obj is DateTime) return obj.toIso8601String();

  if (obj is Object && obj.isEnum) return obj.asString();

  throw Exception('Invalid json field: $obj');
}

T? deserializePrimitive<T>(
  dynamic value, [
  T? defaultValue,
]) {
  final valueStr = castOrNull<String>(value);

  dynamic deserialized;

  if (T is DateTime) deserialized = DateTime.tryParse(valueStr ?? '');

  if (T is String) deserialized = valueStr;

  if (T is bool)
    deserialized = valueStr == null ? null : valueStr.toLowerCase() == 'true';

  if (T is double) deserialized = double.tryParse(valueStr ?? '');

  if (T is int) deserialized = int.tryParse(valueStr ?? '');

  return deserialized as T ?? defaultValue;
}
