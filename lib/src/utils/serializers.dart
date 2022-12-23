import '../data_classes.dart' show IDataClass;

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

  if (obj is bool || obj is num || obj is String) return obj;

  if (obj is DateTime) return obj.toIso8601String();

  if (obj is Enum) return obj.name;

  if (obj is double) return obj.isFinite ? obj : 'NaN';

  try {
    if (obj is IDataClass || obj.toJson is Function) return obj.toJson();
  } catch (_) {}

  throw Exception('Invalid json field: $obj');
}

Iterable<T> serializeIterableToJson<T>(Iterable json) =>
    (serializeToJson(json) as Iterable).cast<T>();

// T? deserializePrimitive<T>(
//   dynamic value, [
//   T? defaultValue,
// ]) {
//   final valueStr = castOrNull<String>(value);
//   if(valueStr == null) return defaultValue;

//   dynamic deserialized;

//   if (T is DateTime) deserialized = DateTime.tryParse(valueStr);

//   if (T is String) deserialized = valueStr;

//   if (T is bool)
//     deserialized = valueStr.toLowerCase() == 'true';

//   if (T is double) deserialized = double.tryParse(valueStr) ?? double.nan;

//   if (T is int) deserialized = int.tryParse(valueStr);

//   return deserialized as T ?? defaultValue;
// }
