import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import 'utils/annotations.dart';
import 'sugar_classes.dart' show Json;

const data = DataClass();
const sealed = Sealed();
const serializable = Serializable();
const sugar = SugarClass();

typedef ChangeListener = Future<void> Function(
  String path, {
  Object? next,
  Object? prev,
});

@immutable
class DataClass extends SugarClass {
  /// [builtValueSerializer] requires importing `package:built_value/serializer.dart`
  /// and using `json_serializer` for `__*ToJson` function generation.
  const DataClass({
    super.builtValueSerializer = false,
    super.changeListener,
    super.convertToSnakeCase = false,
    super.copy = true,
    super.equality = true,
    super.getName,
    super.immutable = false,
    super.name,
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
class SugarClass {
  const SugarClass({
    this.builtValueSerializer = false,
    ChangeListener? changeListener,
    this.convertToSnakeCase = false,
    this.copy = true,
    this.equality = true,
    Function? getName,
    this.immutable = false,
    this.name,
    this.sealed = false,
    this.serialize = false,
  })  : changeListenerName = null,
        objectNameGetterName = null;
  SugarClass.fromAnnotation(ConstantReader annotation)
      : builtValueSerializer = annotation.get('builtValueSerializer')!,
        changeListenerName =
            annotation.get<ExecutableElement>('changeListener')?.displayName,
        convertToSnakeCase = annotation.get('convertToSnakeCase')!,
        copy = annotation.get('copy')!,
        equality = annotation.get('equality')!,
        objectNameGetterName =
            annotation.get<ExecutableElement>('getName')?.displayName,
        immutable = annotation.get('immutable')!,
        name = annotation.get('name'),
        sealed = annotation.get('sealed')!,
        serialize = annotation.get('serialize')!;

  /// Requires importing `package:built_value/serializer.dart`
  /// and using `json_serializer` for `__*ToJson` function generation.
  final bool builtValueSerializer;
  final String? changeListenerName;
  final bool convertToSnakeCase;
  final bool copy;
  final bool equality;
  final String? objectNameGetterName;
  final bool immutable;
  final String? name;
  final bool sealed;
  final bool serialize;

  @override
  String toString() => 'SugarClass(\n'
      '  builtValueSerializer: $builtValueSerializer,\n'
      '  changeListener: $changeListenerName${changeListenerName != null ? '(..)' : ''},\n'
      '  convertToSnakeCase: $convertToSnakeCase,\n'
      '  copy: $copy,\n'
      '  equality: $equality,\n'
      '  getName: $objectNameGetterName${objectNameGetterName != null ? '(..)' : ''},\n'
      '  immutable: $immutable,\n'
      '  name: $name,\n'
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
