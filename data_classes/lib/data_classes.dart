import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

// export 'dart:async';
export 'package:collection/collection.dart' hide IterableExtension;
export 'package:json_annotation/json_annotation.dart';
export 'package:meta/meta.dart';

typedef ChangeListener = Future<void> Function(
  String path, {
  Object next,
  Object prev,
  Object Function() toJson,
});
typedef DataClassBuilder<T> = void Function(T);
typedef DataClassAsyncBuilder<T> = Future<void> Function(T);
typedef EqualityFn = bool Function(Object, Object);

@immutable
class GenerateDataClass {
  const GenerateDataClass({
    this.builtValueSerializer = false,
    this.childrenListener,
    this.copyWith = true,
    this.getName,
    this.immutable = false,
    this.listener,
    this.name,
    this.serialize = true,
  })  : assert(copyWith != null),
        assert(serialize != null);

  final bool builtValueSerializer;
  final ChangeListener childrenListener;
  final bool copyWith;
  final Function getName;
  final bool immutable;
  final String name;
  final ChangeListener listener;
  final bool serialize;
}

@immutable
class GenerateValueGetters {
  const GenerateValueGetters({
    this.usePrefix = false,
    this.generateNegations = true,
  })  : assert(usePrefix != null),
        assert(generateNegations != null);

  final bool usePrefix;
  final bool generateNegations;
}

abstract class DataClass<T extends DataClass<T, TModel>, TModel> {
  TModel get _model;

  T copy([DataClassBuilder<TModel> update]);

  Future<T> copyAsync([DataClassAsyncBuilder<TModel> update]) async {
    final T result = copy();
    await update?.call(result._model);

    return result;
  }

  T copyWith() => null;

  TModel get thisModel => null;

  Map toJson() => null;
}

const String nullable = 'nullable';

/// Combines the [Object.hashCode] values of an arbitrary number of objects
/// from an [Iterable] into one value. This function will return the same
/// value if given [null] as if given an empty list.
// Borrowed from dart:ui.
int hashList(Iterable<Object> arguments) {
  var result = 0;
  if (arguments != null) {
    for (Object argument in arguments) {
      var hash = result;
      hash = 0x1fffffff & (hash + argument.hashCode);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      result = hash ^ (hash >> 6);
    }
  }
  result = 0x1fffffff & (result + ((0x03ffffff & result) << 3));
  result = result ^ (result >> 11);
  return 0x1fffffff & (result + ((0x00003fff & result) << 15));
}

bool eqDeep<T>(T e1, T e2) =>
    _compare(e1, e2, const DeepCollectionEquality().equals);
bool eqDeepUnordered<T>(T e1, T e2) =>
    _compare(e1, e2, const DeepCollectionEquality.unordered().equals);
bool eqShallow<T>(T e1, T e2) =>
    _compare(e1, e2, const DefaultEquality().equals);

_compare<T>(T e1, T e2, EqualityFn equalityFn) => e1 is Map
    ? _mapCompare(e1, e2 as Map, equalityFn)
    : e1 is Iterable
        ? equalityFn(e1, e2)
        : e1 is double &&
                e2 is double &&
                (e1?.isNaN ?? false) &&
                (e2?.isNaN ?? false)
            ? true
            : equalityFn(e1, e2);

bool _mapCompare(Map e1, Map e2, EqualityFn equalityFn) {
  bool keysEqual =
      const DeepCollectionEquality.unordered().equals(e1?.keys, e2?.keys);
  if (!keysEqual) return false;

  final Set keys = {...e1?.keys, ...e2?.keys};
  for (final key in keys) {
    if (!_compare(
        e1 != null ? e1[key] : null, e2 != null ? e2[key] : null, equalityFn))
      return false;
  }

  return true;
}
