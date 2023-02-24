import 'utils/types.dart';

typedef FieldChangeListener = Future<void> Function<T>({
  required String name,
  required T? newValue,
  required T? oldValue,
});
typedef Json = Map<dynamic, dynamic>;
typedef ModelBuilder<T> = void Function(T);
typedef ModelBuilderAsync<T> = Future<void> Function(T);

/// Type [Void] is the same as [void] but can be used in type checking,
/// e.g. `if (T == Void) ...`.
// ignore: non_constant_identifier_names
final Void = getType<void>();

class JsonDeserializationError implements Exception {
  JsonDeserializationError(this.cause);
  String cause;

  @override
  String toString() => cause;
}

// abstract class ICopyable<T> {
//   T copy([DataClassBuilder? update]);

//   Future<T> copyAsync([DataClassAsyncBuilder? update]);

//   T copyWith();
// }

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
