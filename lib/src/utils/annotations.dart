import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import 'package:data_classes/src/utils/types.dart';

extension ConstantReaderGetters on ConstantReader {
  T? get<T extends Object>(String fieldName) {
    final field = objectValue.getField(fieldName);

    late final dynamic value;
    if (field == null || field.isNull)
      value = null;
    else if (T == bool)
      value = field.toBoolValue();
    else if (T == double)
      value = field.toDoubleValue();
    else if (T == Function || T == ExecutableElement)
      value = field.toFunctionValue();
    else if (T == int)
      value = field.toIntValue();
    else if (T == List)
      value = field.toListValue();
    else if (T == Map)
      value = field.toMapValue();
    else if (T == Set)
      value = field.toSetValue();
    else if (T == String)
      value = field.toStringValue();
    else if (T == Symbol)
      value = field.toSymbolValue();
    else if (T == Type)
      value = field.toTypeValue();
    else
      value = null;

    return castOrNull<T>(value);
  }
}
