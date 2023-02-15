import 'package:meta/meta.dart';

import 'package:data_classes/src/sugar_classes.dart';
import 'base.dart';

const data = DataClass();
const sealed = Sealed();
const serializable = Serializable();
const state = StateClass();
const sugar = SugarClass();

typedef Class = void;

@immutable
class DataClass extends SugarClass {
  /// [builtValueSerializer] requires importing `package:built_value/serializer.dart`
  /// and using `json_serializer` for `__*ToJson` function generation.
  const DataClass({
    super.builtValueSerializer = false,
    super.observers,
    super.convertToSnakeCase = false,
    super.copy = true,
    super.equality = true,
    super.getName,
    super.immutable = false,
    super.name,
    super.reflection = false,
    super.serialize = true,
  });
}

@immutable
class Sealed extends SugarClass {
  const Sealed({
    super.convertToSnakeCase = false,
    // super.copy = true,
    super.immutable = false,
    super.serialize = true,
  }) : super(copy: false, equality: true, sealed: true);
}

@immutable
class Serializable extends SugarClass {
  const Serializable({
    super.convertToSnakeCase = false,
    super.copy = false,
    super.equality = false,
    super.immutable = false,
  }) : super(serialize: true);
}

@immutable
class StateClass extends SugarClass {
  const StateClass({
    super.getName,
    super.observers,
    super.name,
  }) : super(
          copy: false,
          convertToSnakeCase: false,
          equality: true,
          immutable: false,
          mutateFromActionsOnly: false,
          observable: true,
          serialize: true,
        );
}

@immutable
class JsonKey {
  const JsonKey(this.name);
  final String name;
}

@immutable
class JsonMethods {
  const JsonMethods({
    this.fromJson,
    this.toJson,
  });
  final dynamic Function(Json json)? fromJson;
  final dynamic Function(dynamic)? toJson;
}
