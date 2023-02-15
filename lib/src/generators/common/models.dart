import 'common.dart';

extension ClassModels on ClassGenerator {
  Iterable<String> generateBaseModels() => [
        'class $modelClassNameTyped${parentClassName != null ? ' extends ${parentClassName}BaseModel$genericTypes' : ''} {',
        for (final field in fields)
          if (observableFields) ...[
            "final Observable<${fieldType(field, required: false)}> _${field.name} = Observable(${fieldDefaultValues[field] ?? 'null'}, name: '${field.name}');",
            '${fieldType(field, required: true)} get ${field.name} => _${field.name}.value${fieldRequiresNullabilityModifier(field) ? '!' : ''};',
            'set ${field.name}(${fieldType(field, required: true)} value) => _${field.name}.value = value;',
            '',
          ] else
            '${fieldDefaultValues[field] != null || field.isNullable(fieldTypes) ? '' : 'late '}'
                '${fieldDeclaration(field, required: true)}'
                '${fieldDefaultValues[field] != null ? ' = ${fieldDefaultValues[field]}' : ''}'
                ';',
        '}',
        '',
      ];
}
