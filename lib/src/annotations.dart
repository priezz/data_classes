import 'package:meta/meta.dart';

typedef ChangeListener = Future<void> Function(
  String path, {
  Object? next,
  Object? prev,
});

@immutable
class DataClass {
  const DataClass({
    this.builtValueSerializer = false,
    this.childrenListener,
    this.convertToSnakeCase = false,
    this.copyWith = true,
    this.equality = true,
    this.getName,
    this.immutable = false,
    this.listener,
    this.name,
    this.serialize = true,
  });

  /// Requires importing `package:built_value/serializer.dart`
  /// and using `json_serializer` for `__*ToJson` function generation.
  final bool builtValueSerializer;
  final ChangeListener? childrenListener;
  final bool convertToSnakeCase;
  final bool copyWith;
  final bool equality;
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
