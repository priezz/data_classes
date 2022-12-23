import 'package:collection/collection.dart';

import 'types.dart';

/// fromJson helpers
bool? boolValueFromJson(dynamic json) {
  final bool? result = castOrNull<bool>(json);
  if (result != null) return result;

  final String? str = castOrNull<String>(json)?.toLowerCase();
  return str == 'true' || str == 'false' ? false : null;
}

final _dateTimeRegExp = RegExp(
  r'^\d{4}-?\d{2}-?\d{2}(T\d{2}(:?\d{2}(:?\d{2}(\.\d{1,6})?)?)?([-\+]\d{2}(:?\d{2})?|Z)?)?(.+)?',
);

/// When [json] is a valid datetime string w/o a timezone specified
/// UTC zone is undertaken
DateTime? dateTimeValueFromJson(dynamic json) {
  String valueStr = (json as String? ?? '').replaceAll(' ', 'T');
  final Match? match = _dateTimeRegExp.firstMatch(valueStr);
  if (match != null && match[5] == null && match[7] == null) {
    valueStr = '$valueStr${valueStr.contains('T') ? '' : 'T00'}Z';
  }

  return DateTime.tryParse(valueStr);
}

double? doubleValueFromJson(dynamic json) => json == null
    ? null
    : json is num
        ? json.toDouble()
        : (double.tryParse(castOrNull<String>(json) ?? '') ?? double.nan);

T? enumValueFromJson<T extends Enum>(dynamic json, Iterable<T> values) =>
    enumFromString(castOrNull<String>(json), values);

/// Get the enum value from a string [key].
///
/// Returns null if [key] is invalid.
T? enumFromString<T extends Enum>(String? key, Iterable<T> values) =>
    key == null ? null : values.firstWhereOrNull((v) => key == v.name);

int? intValueFromJson(dynamic json) =>
    castOrNull<int>(json) ?? int.tryParse(castOrNull<String>(json) ?? '');

Iterable<V>? iterableValueFromJson<V>(
  dynamic json, {
  V? Function(dynamic v)? value,
  bool valueNullable = false,
}) {
  final V? Function(dynamic) valueGetter = value ?? castOrNull<V>;
  final Iterable<V?>? iterable = castOrNull<Iterable>(json)?.map(valueGetter);

  return (valueNullable ? iterable : iterable?.where((v) => v != null))
      ?.cast<V>();
}

List<V>? listValueFromJson<V>(
  dynamic json, {
  V? Function(dynamic v)? value,
  bool valueNullable = false,
}) =>
    iterableValueFromJson(json, value: value, valueNullable: valueNullable)
        ?.toList();

Map<K, V>? mapValueFromJson<K, V>(
  dynamic json, {
  K? Function(dynamic k)? key,
  bool keyNullable = false,
  V? Function(dynamic v)? value,
  bool valueNullable = false,
}) {
  final K? Function(dynamic) keyGetter = key ?? castOrNull<K>;
  final V? Function(dynamic) valueGetter = value ?? castOrNull<V>;
  final Map<K?, V?>? map = castOrNull<Map>(json)?.map(
    (k, v) {
      K? keyValue;
      try {
        keyValue = keyGetter(k);
      } catch (e) {
        print('[mapValueFromJson] Failed to get key from {$k: $v}. $e');
        return MapEntry(null, null);
      }
      V? valueValue;
      try {
        valueValue = valueGetter(v);
      } catch (e) {
        print('[mapValueFromJson] Failed to get value from {$k: $v}. $e');
        return MapEntry(null, null);
      }
      return MapEntry(keyValue, valueValue);
    },
  );
  if (!keyNullable || !valueNullable) {
    map
      ?..removeWhere(
        (k, v) => !keyNullable && k == null || !valueNullable && v == null,
      );
  }

  return map?.cast<K, V>();
}

Set<V>? setValueFromJson<V>(
  dynamic json, {
  V? Function(dynamic v)? value,
  bool valueNullable = false,
}) =>
    iterableValueFromJson(json, value: value, valueNullable: valueNullable)
        ?.toSet();

D? valueFromJson<D>(
  dynamic json,
  D Function(Map json) fromJson,
) {
  final Map? map = castOrNull<Map>(json);

  return map == null ? null : fromJson(map);
}
