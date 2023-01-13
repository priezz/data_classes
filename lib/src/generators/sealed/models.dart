// import 'package:analyzer/dart/element/element.dart';

import 'package:data_classes/src/generators/common/common.dart'
    show VariableChecks;
import 'core.dart';
import 'sealed.dart';

extension SealedClassModels on SealedClassGenerator {
  Iterable<String> generateSubclassesModels() => [
        for (final method in methods) ...[
          'class ${getModelSubclassNameTyped(method)} extends $modelClassNameTyped {',
          for (final param in method.parameters)
            if (observableFields) ...[
              'final Observable<${fieldType(param, method: method, required: false)}> _${param.name} = Observable(${param.defaultValueCode ?? 'null'});',
              '${fieldType(param, method: method, required: true)} get ${param.name} => _${param.name}.value${fieldRequiresNullabilityModifier(param, method: method) ? '!' : ''};',
              'set ${param.name}(${fieldType(param, method: method, required: true)} value) => _${param.name}.value = value;',
              '',
            ] else
              '${param.hasDefaultValue || param.isNullable(paramsTypes[method]!) ? '' : 'late '}'
                  '${fieldDeclaration(param, method: method, required: true)}'
                  '${param.hasDefaultValue ? ' = ${param.defaultValueCode}' : ''}'
                  ';',
          '}',
          '',
        ],
      ];
}
