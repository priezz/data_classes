import 'data.dart';

extension DataClassEquality on DataClassGenerator {
  Iterable<String> generateEqualityOperator() => [
        '@override',
        'bool operator ==(Object other) =>',
        '  identical(this, other) || other is $dataClassName$genericTypes &&',
        fields
            .map(
              (field) =>
                  '$_equalityFn(_model.${field.name}, other._model.${field.name},)',
            )
            .join(' && '),
        ';',
      ];

  Iterable<String> generateHashCode() => [
        '/// This hash code compatible with [operator ==]. ',
        '/// [$dataClassName] classes with the same data',
        '/// have the same hash code.',
        '@override',
        'int get hashCode => hashList([',
        for (final field in fields)
          field.isNullable(fieldTypes)
              ? 'if (${field.name} != null) ${field.name}!,'
              : '${field.name},',
        ']);',
      ];

  String get _equalityFn => immutable ? 'eqShallow' : 'eqDeep';
}
