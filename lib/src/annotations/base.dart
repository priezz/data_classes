import 'package:meta/meta.dart';

import 'package:data_classes/src/sugar_classes.dart' show FieldChangeListener;

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
    this.objectNameGetterName,
    this.observers,
    this.observerNames,
    this.reflection = false,
    this.sealed = false,
    this.serialize = false,
  });

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
