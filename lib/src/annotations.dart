import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import 'utils/annotations.dart';
import 'utils/types.dart';
import 'sugar_classes.dart' show Json;

const data = DataClass();
const sealed = Sealed();
const serializable = Serializable();
const state = StateClass();
const sugar = SugarClass();

typedef FieldChangeListener = Future<void> Function<T>({
  required String name,
  required T? newValue,
  required T? oldValue,
});

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
    super.copy = true,
    super.immutable = false,
    super.serialize = true,
  }) : super(equality: true, sealed: true);
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
class SugarClass {
  const SugarClass({
    this.builtValueSerializer = false,
    this.convertToSnakeCase = false,
    this.copy = true,
    this.equality = true,
    this.getName,
    this.mutateFromActionsOnly = false,
    this.immutable = false,
    this.name,
    this.observable = false,
    this.observers,
    this.reflection = false,
    this.sealed = false,
    this.serialize = false,
  })  : observerNames = null,
        objectNameGetterName = null;
  SugarClass.fromAnnotation(ConstantReader annotation)
      : builtValueSerializer = annotation.get('builtValueSerializer')!,
        convertToSnakeCase = annotation.get('convertToSnakeCase')!,
        copy = annotation.get('copy')!,
        equality = annotation.get('equality')!,
        getName = null,
        immutable = annotation.get('immutable')!,
        mutateFromActionsOnly = annotation.get('mutateFromActionsOnly')!,
        objectNameGetterName =
            annotation.get<ExecutableElement>('getName')?.displayName,
        observable = annotation.get('observable')!,
        observers = null,
        observerNames = annotation
            // .get<Iterable<ExecutableElement>>('observers')
            .get<List>('observers')
            ?.map((o) => castOr<String>(o.displayName, ''))
            .toList(),
        reflection = annotation.get('reflection')!,
        name = annotation.get('name'),
        sealed = annotation.get('sealed')!,
        serialize = annotation.get('serialize')!;

  /// Requires importing `package:built_value/serializer.dart`
  /// and using `json_serializer` for `__*ToJson` function generation.
  final bool builtValueSerializer;
  final bool convertToSnakeCase;
  final bool copy;
  final bool equality;
  final Function? getName;
  final bool immutable;
  final bool mutateFromActionsOnly;
  final String? name;
  final String? objectNameGetterName;
  final bool observable;
  final List<FieldChangeListener>? observers;
  final List<String>? observerNames;
  final bool reflection;
  final bool sealed;
  final bool serialize;

  @override
  String toString() => 'SugarClass(\n'
      '  builtValueSerializer: $builtValueSerializer,\n'
      '  convertToSnakeCase: $convertToSnakeCase,\n'
      '  copy: $copy,\n'
      '  equality: $equality,\n'
      '  getName: $objectNameGetterName${objectNameGetterName != null ? '(..)' : ''},\n'
      '  immutable: $immutable,\n'
      '  mutateFromActionsOnly: $mutateFromActionsOnly,\n'
      '  name: $name,\n'
      '  observable: $observable,\n'
      '  observers: ${observerNames?.map((o) => '$o(..)').toList()},\n'
      '  reflection: $reflection,\n'
      '  sealed: $sealed,\n'
      '  serialize: $serialize,\n'
      ')';
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
