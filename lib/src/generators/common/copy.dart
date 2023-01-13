import 'common.dart';

extension ClassGeneratorCopy on ClassGenerator {
  Iterable<String> generateCopy() => [
        /// named constructor
        'factory $className.from($classNameTyped source,) => ',
        '  $classNameTyped._build(',
        '    (destModel) => _modelCopy(source._model, destModel),',
        '  );',

        /// copy
        '/// Creates a new instance of [$className],',
        '/// which is a copy of this with some changes',
        '@override $classNameTyped copy([ModelBuilder<$modelClassNameTyped>? update,]) => $classNameTyped._build((dest) {',
        '  _modelCopy(_model, dest);',
        '  update?.call(dest);',
        if (observerNames != null) '  _notifyOnCopy(_model, dest);',
        '});',

        /// copyAsync
        '/// Creates a new instance of [$className],',
        '/// which is a copy of this with some changes',
        '@override Future<$classNameTyped> copyAsync([ModelBuilderAsync<$modelClassNameTyped>? update,]) async {',
        'final model = $modelClassNameTyped();',
        '_modelCopy(_model, model);',
        'await update?.call(model);\n',
        'return $classNameTyped._build((dest) {',
        '  _modelCopy(model, dest);',
        '  update?.call(dest);',
        if (observerNames != null) '  _notifyOnCopy(_model, dest);',
        '});',
        '}',

        /// copyWith
        if (withCopy) ...[
          '/// Creates a new instance of [$className],',
          '/// which is a copy of this with some changes',
          '@override $classNameTyped copyWith(',
          if (fields.isNotEmpty) ...[
            '{',
            for (final field in fields)
              '${fieldDeclaration(field, required: false)},',
            '}',
          ],
          ') => copy((b) => b',
          if (fields.isNotEmpty) ...[
            for (final field in fields)
              '..${field.name} = ${field.name} ?? _model.${field.name}',
            ',',
          ],
          ');',
          '',
        ],
      ];
}
