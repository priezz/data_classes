import 'package:analyzer/dart/element/element.dart';

import 'package:data_classes/src/generators/common/common.dart';
import 'package:data_classes/src/utils/strings.dart';
import 'sealed.dart';

extension SealedClassGeneratorCore on SealedClassGenerator {
  Iterable<String> generateConstructors() => [
        '/// Prevent inheritance',
        '$className._();',
        '',
        for (final method in methods) ...[
          'static ${getSubclassNameTyped(method)} ${method.name}$genericTypesFull({',
          for (final field in requiredFields)
            '  required ${fieldDeclaration(field, required: true)},',
          for (final field in nonRequiredFields)
            '${fieldDeclaration(field, required: false)},',
          for (final param in method.parameters)
            '${param.hasDefaultValue || param.isNullable(paramsTypes[method]!) ? '' : 'required '}'
                '${fieldDeclaration(param, method: method, required: true)}'
                '${param.hasDefaultValue ? ' = ${param.defaultValueCode}' : ''}'
                ',',
          '}) => ${getSubclassNameTyped(method)}(',
          for (final field in fields) '${field.name}: ${field.name}, ',
          for (final param in method.parameters)
            '${param.name}: ${param.name}, ',
          ');',
        ],
        '',
        '/// Prevents `unused_element` warning for the sealed class definition',
        'static void _dummy(${modelClass != null ? modelClass!.name : '_${className}Model'} _) {}',
        '',
      ];

  String getModelSubclassName(MethodElement method) =>
      '_${getSubclassName(method)}Model';

  String getModelSubclassNameTyped(MethodElement method) =>
      '${getModelSubclassName(method)}$genericTypes';

  String getSubclassName(MethodElement method) =>
      '$className${method.name.capitalized}';

  String getSubclassNameTyped(MethodElement method) =>
      '${getSubclassName(method)}$genericTypes';
}
