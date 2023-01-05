// import 'package:analyzer/dart/element/element.dart';

import 'package:data_classes/src/generators/common/common.dart';
import 'core.dart';
import 'sealed.dart';

extension SealedClassModels on SealedClassGenerator {
  Iterable<String> generateModels() => [
        'class $modelClassNameTyped {',
        for (final field in fields)
          // '${field.hasInitializer || field.isNullable(fieldTypes) ? '' : 'late '}'
          '${field.isNullable(fieldTypes) ? '' : 'late '}'
              '${fieldDeclaration(field, required: true)}'
              // '${field.hasInitializer ? ' = ${field.}' : ''}'
              ';',
        '}',
        '',
        for (final method in methods) ...[
          'class ${getModelSubclassNameTyped(method)} extends $modelClassNameTyped {',
          for (final param in method.parameters)
            '${param.hasDefaultValue || param.isNullable(paramsTypes[method]!) ? '' : 'late '}'
                '${fieldDeclaration(param, method: method, required: true)}'
                '${param.hasDefaultValue ? ' = ${param.defaultValueCode}' : ''}'
                ';',
          '}',
          '',
        ],
      ];
}
