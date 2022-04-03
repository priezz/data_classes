import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

export 'package:meta/meta.dart';

part 'serializers.dart';

typedef ChangeListener = Future<void> Function(
  String path, {
  Object? next,
  Object? prev,
});
typedef DataClassBuilder<T> = void Function(T);
typedef DataClassAsyncBuilder<T> = Future<void> Function(T);
typedef EqualityFn = bool Function(Object?, Object?);

@immutable
class DataClass {
  const DataClass({
    this.builtValueSerializer = false,
    this.childrenListener,
    this.convertToSnakeCase = false,
    this.copyWith = true,
    this.deserializeDatesAsUtc = false,
    this.getName,
    this.immutable = false,
    this.listener,
    this.name,
    this.serialize = true,
  });
  final bool builtValueSerializer;
  final ChangeListener? childrenListener;
  final bool convertToSnakeCase;
  final bool copyWith;
  final bool deserializeDatesAsUtc;
  final Function? getName;
  final bool immutable;
  final String? name;
  final ChangeListener? listener;
  final bool serialize;
}

@immutable
class JsonKey {
  const JsonKey(this.name);
  final String name;
}

@immutable
class Serializable {
  const Serializable({
    this.fromJson,
    this.toJson,
  });
  final dynamic Function(Map<dynamic, dynamic> json)? fromJson;
  final dynamic Function(dynamic)? toJson;
}

class JsonDeserializationError implements Exception {
  JsonDeserializationError(this.cause);
  String cause;

  @override
  String toString() => cause;
}

abstract class IDataClass<T extends IDataClass<T, TModel>, TModel> {
  T copy([DataClassBuilder<TModel>? update]);
  // Future<T> copyAsync([DataClassAsyncBuilder<TModel>? update]);

  T copyWith() => copy();
  TModel get $model;
  Map toJson() => {};
}

// const String nullable = 'nullable';

/// Combines the [Object.hashCode] values of an arbitrary number of objects
/// from an [Iterable] into one value. This function will return the same
/// value if given [null] as if given an empty list.
// Borrowed from dart:ui.
int hashList(Iterable<Object> arguments) {
  int result = 0;
  for (Object argument in arguments) {
    int hash = result;
    hash = 0x1fffffff & (hash + argument.hashCode);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    result = hash ^ (hash >> 6);
  }
  result = 0x1fffffff & (result + ((0x03ffffff & result) << 3));
  result = result ^ (result >> 11);

  return 0x1fffffff & (result + ((0x00003fff & result) << 15));
}

T? castOrNull<T>(dynamic x) => x != null && x is T ? x : null;
bool eqDeep<T>(T e1, T e2) =>
    _compare(e1, e2, const DeepCollectionEquality().equals);
bool eqDeepUnordered<T>(T e1, T e2) =>
    _compare(e1, e2, const DeepCollectionEquality.unordered().equals);
bool eqShallow<T>(T e1, T e2) =>
    _compare(e1, e2, const DefaultEquality().equals);

bool _compare<T>(T? e1, T? e2, EqualityFn equalityFn) => e1 == null
    ? e2 == null
    : e2 == null
        ? false
        : e1 is Map
            ? _mapCompare(e1, e2 as Map, equalityFn)
            : e1 is Iterable
                ? equalityFn(e1, e2)
                : e1 is double && e2 is double && e1.isNaN && e2.isNaN
                    ? true
                    : equalityFn(e1, e2);

bool _mapCompare(Map? e1, Map? e2, EqualityFn equalityFn) {
  bool keysEqual =
      const DeepCollectionEquality.unordered().equals(e1?.keys, e2?.keys);
  if (!keysEqual) return false;
  if (e1 == null || e2 == null)
    return (e1?.isEmpty ?? true) && (e2?.isEmpty ?? true);

  final Set keys = {...e1.keys, ...e2.keys};
  for (final key in keys) {
    if (!_compare(e1[key], e2[key], equalityFn)) return false;
  }

  return true;
}

/// Get the enum value from a string [key].
///
/// Returns null if [key] is invalid.
T? enumFromString<T extends Enum>(String? key, Iterable<T> values) =>
    key == null ? null : values.firstWhereOrNull((v) => key == v.name);

int? intValueFromJson(dynamic json) =>
    castOrNull<int>(json) ?? int.tryParse(castOrNull<String>(json) ?? '');

void setModelField<T>(
  Map<dynamic, dynamic> json,
  String fieldName,
  void Function(T? v) setter, {
  T? Function(dynamic j)? getter,

  /// Nullable value is allowed
  bool nullable = true,

  /// Non-nullable value is required
  bool required = false,
}) {
  final bool hasKey = json.containsKey(fieldName);
  final T? value =
      hasKey ? (getter ?? castOrNull<T>).call(json[fieldName]) : null;
  if (value != null) {
    setter(value);
  } else {
    if (required) {
      throw JsonDeserializationError(
        hasKey
            ? '''Attempt to assign null value to non-nullable required `$fieldName` field. $json'''
            : '''Required field `$fieldName` is missing. $json''',
      );
    }
    if (nullable && hasKey) setter(null);
  }
}

extension StringX on String {
  String camelToSnake() => replaceAllMapped(
        RegExp('[A-Z]+'),
        (match) => '_${match.group(0)?.toLowerCase() ?? ''}',
      );

  String snakeToCamel() {
    final result = StringBuffer();
    toLowerCase().split(RegExp('[^A-Za-z0-9]+')).asMap().forEach(
          (i, part) => result.write(
            part.isEmpty
                ? ''
                : (i > 0 ? part[0].toUpperCase() : part[0]) + part.substring(1),
          ),
        );

    return result.toString();
  }
}

/// fromJson helpers
bool? boolValueFromJson(dynamic json) {
  final bool? result = castOrNull<bool>(json);
  if (result != null) return result;

  final String? str = castOrNull<String>(json)?.toLowerCase();
  return str == 'true' || str == 'false' ? false : null;
}

DateTime? dateTimeValueFromJson(dynamic json, {bool convertToUtc = false}) {
  final date = DateTime.tryParse(castOrNull<String>(json) ?? '');
  return convertToUtc ? date?.toUtc() : date;
}

double? doubleValueFromJson(dynamic json) => json == null
    ? null
    : json is num
        ? json.toDouble()
        : (double.tryParse(castOrNull<String>(json) ?? '') ?? double.nan);

T? enumValueFromJson<T extends Enum>(dynamic json, Iterable<T> values) =>
    enumFromString(castOrNull<String>(json), values);

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
