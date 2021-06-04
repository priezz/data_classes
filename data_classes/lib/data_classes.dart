import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

// export 'dart:async';
export 'package:collection/collection.dart'
    hide IterableExtension, IterableNullableExtension;
export 'package:dartx/dartx.dart' show IterableMapNotNull;
export 'package:meta/meta.dart';

part 'serializers.dart';

typedef ChangeListener = Future<void> Function(
  String path, {
  Object? next,
  Object? prev,
  dynamic Function()? toJson,
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

// @immutable
// class GenerateValueGetters {
//   const GenerateValueGetters({
//     this.usePrefix = false,
//     this.generateNegations = true,
//   });
//   final bool usePrefix;
//   final bool generateNegations;
// }

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

T? castOrNull<T>(dynamic x) => x is T ? x : null;
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
T? enumFromString<T>(String key, Iterable<T> values) =>
    values.firstWhereOrNull((v) => v != null && key == v.asString());

extension _EnumX on Object {
  /// Gets the string representation of an enum value.
  ///
  /// E.g CategoryLvl1.income becomes "income".
  String asString() {
    final String str = toString();
    final String enumStr = str.split('.').last;

    // ignore: no_runtimetype_tostring
    return '$runtimeType.$enumStr' == str ? enumStr : str;
  }

  bool get isEnum {
    final String str = toString();
    final String enumStr = str.split('.').last;

    // ignore: no_runtimetype_tostring
    return '$runtimeType.$enumStr' == str;
  }
}
