import 'dart:collection';

import 'package:collection/collection.dart';

typedef EqualityFn = bool Function(Object?, Object?);

bool eqDeep<T>(T e1, T e2) => _compare(e1, e2, eqDeep);
bool eqDeepUnordered<T>(T e1, T e2) =>
    _compare(e1, e2, eqDeepUnordered, unordered: true);
bool eqShallow<T>(T e1, T e2) => _compare(e1, e2, _compareShallow);

/// Combines the [Object.hashCode] values of an arbitrary number of objects
/// from an [Iterable] into one value. This function will return the same
/// value if given [null] as if given an empty list.
// Borrowed from dart:ui.
int hashList(Iterable<Object?> arguments) {
  int result = 0;
  for (Object? argument in arguments) {
    int hash = result;
    hash = 0x1fffffff & (hash + argument.hashCode);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    result = hash ^ (hash >> 6);
  }
  result = 0x1fffffff & (result + ((0x03ffffff & result) << 3));
  result = result ^ (result >> 11);

  return 0x1fffffff & (result + ((0x00003fff & result) << 15));
}

bool _compare<T>(T? e1, T? e2, EqualityFn equalityFn,
        {bool unordered = false}) =>
    e1 == e2 ||
    (e1 == null
        ? e2 == null
        : e2 == null
            ? false
            : e1 is Set
                ? e2 is Set && _compareIterableUnordered(e1, e2, equalityFn)
                : e1 is Map
                    ? e2 is Map && _compareMap(e1, e2, equalityFn)
                    : e1 is List
                        ? e2 is List &&
                            (unordered
                                    ? _compareIterableUnordered
                                    : _compareList)
                                .call(e1, e2, equalityFn)
                        : e1 is Iterable
                            ? e2 is Iterable &&
                                (unordered
                                        ? _compareIterableUnordered
                                        : _compareIterable)
                                    .call(e1, e2, equalityFn)
                            : e1 is double &&
                                    e2 is double &&
                                    e1.isNaN &&
                                    e2.isNaN
                                ? true
                                : false);

bool _compareIterable<T>(
  Iterable<T> e1,
  Iterable<T> e2,
  EqualityFn equalityFn,
) {
  if (e1.length != e2.length) return false;

  Iterator<T> i1 = e1.iterator;
  Iterator<T> i2 = e2.iterator;
  while (true) {
    final bool hasNext = i1.moveNext();

    if (hasNext != i2.moveNext()) return false;
    if (!hasNext) return true;
    if (!equalityFn(i1.current, i2.current)) return false;
  }
}

bool _compareIterableUnordered<T>(
  Iterable<T> e1,
  Iterable<T> e2,
  EqualityFn equalityFn,
) {
  if (e1.length != e2.length) return false;

  final HashMap<T, int> counts = HashMap<T, int>(
    equals: equalityFn,
    // hashCode: (e) => e.hashCode,
    isValidKey: (e) => true, // e is T,
  );

  int length = 0;
  for (T e in e1) {
    int count = counts[e] ?? 0;
    counts[e] = count + 1;
    length++;
  }
  for (T e in e2) {
    int? count = counts[e];
    if (count == null || count == 0) return false;

    counts[e] = count - 1;
    length--;
  }

  return length == 0;
}

bool _compareMap(Map e1, Map e2, EqualityFn equalityFn) {
  final Iterable keys1 = e1.keys;
  final Iterable keys2 = e2.keys;
  final bool keysEqual = _compareIterableUnordered(
    keys1,
    keys2,
    const DefaultEquality().equals,
  );
  if (!keysEqual) return false;

  for (final key in keys1) {
    if (!_compare(e1[key], e2[key], equalityFn)) return false;
  }

  return true;
}

bool _compareList<T>(
  List<T> e1,
  List<T> e2,
  EqualityFn equalityFn,
) {
  int length = e1.length;
  if (length != e2.length) return false;

  for (int i = 0; i < length; i++) {
    if (!equalityFn(e1[i], e2[i])) return false;
  }

  return true;
}

bool _compareShallow<T>(T e1, T e2) => e1 == e2;
