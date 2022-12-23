import 'utils/types.dart';

typedef DataClassBuilder<T> = void Function(T);
typedef DataClassAsyncBuilder<T> = Future<void> Function(T);

class JsonDeserializationError implements Exception {
  JsonDeserializationError(this.cause);
  String cause;

  @override
  String toString() => cause;
}

abstract class IDataClass<T extends IDataClass<T, TModel>, TModel> {
  T copy([DataClassBuilder<TModel>? update]) {
    throw 'copy() method is not implemented.';
  }

  Future<T> copyAsync([DataClassAsyncBuilder<TModel>? update]) {
    throw 'copyAsync() method is not implemented.';
  }

  T copyWith() {
    throw 'copyWith() method is not implemented.';
  }

  TModel get $model;
  Map toJson() {
    throw 'toJson() method is not implemented.';
  }
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
