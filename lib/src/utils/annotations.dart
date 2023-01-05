import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';

import 'package:data_classes/src/utils/types.dart';

extension ConstantReaderGetters on ConstantReader {
  T? get<T extends Object>(String fieldName) {
    final ConstantReader? field = peek(fieldName);

    dynamic value;
    if (T == Function || T == ExecutableElement
        // || isSubtypeOf<T, Function>()
        // || isSubtypeOf<T, ExecutableElement>()
        )
      value = this.revive().namedArguments[fieldName]?.toFunctionValue();
    else if (field == null || field.isNull)
      value = null;
    else if (T == bool)
      value = field.boolValue;
    else if (T == double)
      value = field.doubleValue;
    else if (T == int)
      value = field.intValue;
    else if (T == List)
      value = field.listValue;
    else if (T == Map)
      value = field.mapValue;
    else if (T == Set)
      value = field.setValue;
    else if (T == String)
      value = field.stringValue;
    else if (T == Symbol)
      value = field.symbolValue;
    else if (T == Type)
      value = field.typeValue;
    else
      value = null;

    return castOrNull<T>(value);
  }
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
