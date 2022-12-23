import 'package:analyzer/dart/element/element.dart';

import 'data.dart';

extension DataClassCore on DataClassGenerator {
  Iterable<String> generateConstructors() => [
        'factory $dataClassName({',
        for (final field in requiredFields)
          '  required ${fieldDeclaration(field, required: true)},',
        for (final field in nonRequiredFields)
          '${fieldDeclaration(field, required: false)},',
        '}) => $dataClassName._build((b) => b',
        for (final field in requiredFields) '..${field.name} = ${field.name}',
        for (final field in nonRequiredFields)
          '  ..${field.name} = ${field.name}${field.hasInitializer ? ' ?? b.${field.name}' : ''}',
        ',',
        ');',
        '',
        // TODO: use List.unmodifiable and Map.unmodifiable for immutable classes
        '$dataClassName._build(DataClassBuilder<$modelClassName>? builder,) {'
            '  builder?.call(_model);'
            // for (final field in fields)
            //   if (!_isNullable(field)) 'assert(_model.${field.name} != null);',
            '}',
        '',
        // TODO: Only when deserialization or copy methods are enabled
        'static void _modelCopy$genericTypes($modelClassName source, $modelClassName dest,) => dest',
        for (final field in fields) '..${field.name} = source.${field.name}',
        ';',
        '',
      ];

  Iterable<String> generateClassHeader() => [
        '/// {@category data-class}',
        if (modelClass.documentationComment != null)
          modelClass.documentationComment!
              .replaceAll('/// {@nodoc}\n', '')
              .replaceAll('{@nodoc}', ''),
        if (immutable) '@immutable',
        'class $dataClassName$genericTypes extends IDataClass<$dataClassName$genericTypes, $modelClassName> '
      ];

  Iterable<String> generateFields() => [
        'final $modelClassName _model = $modelClassName();',
        '@override $modelClassName get \$model => _model;',
        '',
        for (final field in fields) ...[
          if (field.documentationComment != null) field.documentationComment!,
          _fieldGetter(field),
          if (!immutable) _fieldSetter(field),
        ],
        '',
      ];

  String _fieldGetter(FieldElement field) =>
      '${fieldTypes[field]} get ${field.name} => '
      '_model.${field.name};';

  String _fieldSetter(FieldElement field) =>
      'set ${field.name}(${fieldTypes[field]} value) => '
      '_model.${field.name} = value;';
}
