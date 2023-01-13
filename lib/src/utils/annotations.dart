import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
// import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import 'package:data_classes/src/utils/types.dart';
// import 'package:data_classes/src/annotations.dart' show FieldChangeListener;

extension ConstantReaderGetters on ConstantReader {
  T? get<T extends Object>(String fieldName) {
    final ConstantReader? field = peek(fieldName);
    dynamic value = _getDartObjectValue(field?.objectValue);

    return castOrNull<T>(value);
  }
}

dynamic _getDartObjectValue(DartObject? object) {
  if (object == null) return null;

  final value = object.toBoolValue() ??
      object.toDoubleValue() ??
      object.toIntValue() ??
      object.toMapValue() ??
      object.toSetValue() ??
      object.toListValue() ??
      object.toFunctionValue() ??
      object.toStringValue() ??
      object.toSymbolValue() ??
      object.toTypeValue() ??
      object;

  return value is Map
      ? {
          for (final entry in value.entries)
            entry.key: _getDartObjectValue(entry.value),
        }
      : value is Set
          ? {
              for (final item in value) _getDartObjectValue(item),
            }
          : value is Iterable
              ? [
                  for (final item in value) _getDartObjectValue(item),
                ]
              : value;
}

extension ElementAnnotation on Element {
  DartObject? getAnnotation(Type T) {
    DartObject? annotation = _getAnnotation(T);

    final Element element = this;
    annotation ??= element is VariableElement
        ? element.type.element?._getAnnotation(T)
        : null;

    return annotation;
  }

  DartObject? _getAnnotation(Type T) =>
      TypeChecker.fromRuntime(T).annotationsOf(this).firstOrNull;
}
