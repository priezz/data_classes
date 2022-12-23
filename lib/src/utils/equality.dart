import 'package:collection/collection.dart';

typedef EqualityFn = bool Function(Object?, Object?);

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
