import 'utils/types.dart';

typedef Class = void;
typedef Json = Map<dynamic, dynamic>;
typedef ModelBuilder<T> = void Function(T);
typedef ModelBuilderAsync<T> = Future<void> Function(T);

class JsonDeserializationError implements Exception {
  JsonDeserializationError(this.cause);
  String cause;

  @override
  String toString() => cause;
}

abstract class ICopyable<T extends ICopyable<T, TModel>, TModel> {
  T copy([ModelBuilder<TModel>? update]);

  Future<T> copyAsync([ModelBuilderAsync<TModel>? update]);

  T copyWith();
}

abstract class IEquitable {}

abstract class IReflective {
  operator [](String fieldName);
}

abstract class ISealed {
  R? maybe<R>();
  R when<R>();
  R? whenOrNull<R>();
}

abstract class ISerializable {
  ISerializable.fromJson(Json json);

  Map toJson();
}

// const String nullable = 'nullable';

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

void setModelField<T>(
  Json json,
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
