import 'common.dart';

extension ClassGeneratorEquality on ClassGenerator {
  Iterable<String> generateEqualityOperator() => [
        '@override',
        'bool operator ==(Object other) =>',
        '  identical(this, other) || other is $classNameTyped',
        for (final field in fields)
          ' && $_equalityFn(_model.${field.name}, other._model.${field.name},)',
        ';',
      ];

  Iterable<String> generateHashCode() => [
        '/// This hash code compatible with [operator ==]. ',
        '/// [$className] classes with the same data',
        '/// have the same hash code.',
        '@override',
        'int get hashCode => ',
        if (fields.isNotEmpty) ...[
          'hashList([',
          for (final field in fields)
            field.isNullable(fieldTypes)
                ? 'if (${field.name} != null) ${field.name},'
                : '${field.name},',
          ']);',
        ] else
          '0;',
      ];

  // String get _equalityFn => immutable ? 'eqShallow' : 'eqDeep';
  String get _equalityFn => 'eqDeep';
}
