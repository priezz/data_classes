import 'package:analyzer/dart/element/element.dart';

import 'common.dart';

extension ClassGeneratorCore on ClassGenerator {
  Iterable<String> generateConstructors() => [
        /// default
        'factory $className(',
        if (fields.isNotEmpty) ...[
          '{',
          for (final field in requiredFields)
            'required ${fieldDeclaration(field, required: true)},',
          for (final field in nonRequiredFields)
            '${fieldDeclaration(field, required: false)},',
          '}',
        ],
        ') => $className._build((b) => b',
        if (fields.isNotEmpty) ...[
          for (final field in requiredFields) '..${field.name} = ${field.name}',
          for (final field in nonRequiredFields)
            '..${field.name} = ${field.name}${field.hasInitializer ? ' ?? b.${field.name}' : ''}',
          ',',
        ],
        ');',
        '',

        /// _build
        // TODO: use List.unmodifiable and Map.unmodifiable for immutable classes
        '$className._build(ModelBuilder<$modelClassNameTyped> builder,) ',
        if (parentClassName != null) ': super._() ',
        '{',
        '  builder.call(_model);',
        '}',
        '',

        /// _modelCopy
        // TODO: Only when deserialization or copy methods are enabled
        'static void _modelCopy$genericTypesFull($modelClassNameTyped source, $modelClassNameTyped dest,) => dest',
        for (final field in fields) '..${field.name} = source.${field.name}',
        ';',
        '',
        '/// Prevents `unused_element` warning for the sealed class definition',
        'static void _dummy(${modelClass != null ? modelClass!.name : '_${className}Model'} _) {}',
        '',
      ];

  Iterable<String> generateClassHeader({bool abstract = false}) => [
        '/// {@category sugar-class}',
        if (modelClass?.documentationComment != null)
          modelClass!.documentationComment!
              .replaceAll('/// {@nodoc}\n', '')
              .replaceAll('{@nodoc}', ''),
        if (immutable) '@immutable',
        '${abstract ? 'abstract ' : ''}'
            'class $className$genericTypesFull ',
        if (parentClassName != null)
          'extends $parentClassName$genericTypes'
        else ...[
          'implements ',
          [
            if (withCopy) 'ICopyable<$classNameTyped, $modelClassNameTyped>',
            if (withEquality) 'IEquitable',
            if (withSerialize) 'ISerializable',
          ].join(', '),
        ],
      ];

  Iterable<String> generateFields() => [
        if (parentClassName != null) '@override',
        'final $modelClassNameTyped _model = $modelClassNameTyped();',
        '',
        for (final field in fields) ...[
          if (field.documentationComment != null) field.documentationComment!,
          _fieldGetter(field),
          if (!immutable) ..._fieldSetter(field),
        ],
        '',
      ];

  String _fieldGetter(VariableElement field) =>
      '${fieldTypes[field]} get ${field.name} => '
      '_model.${field.name};';

  List<String> _fieldSetter(VariableElement field) => [
        'set ${field.name}(${fieldTypes[field]} value) ',
        if (observerNames?.isNotEmpty == true) ...[
          '{',
          "_notifyOnPropChange('${field.name}', _model.${field.name}, value, _model);",
        ] else
          ' => ',
        '_model.${field.name} = value;',
        if (observerNames?.isNotEmpty == true) '}'
      ];
}
