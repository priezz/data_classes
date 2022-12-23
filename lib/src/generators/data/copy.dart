import 'data.dart';

extension DataClassCopy on DataClassGenerator {
  Iterable<String> generateCopy() => [
        /// named constructor
        'factory $dataClassName.from($dataClassName$genericTypes source,) => ',
        '  $dataClassName$genericTypes._build(',
        '    (destModel) => _modelCopy(source._model, destModel),',
        '  );',

        /// copy
        '/// Creates a new instance of [$dataClassName],',
        '/// which is a copy of this with some changes',
        '@override $dataClassName$genericTypes copy([DataClassBuilder<$modelClassName>? update,]) => $dataClassName$genericTypes._build((dest) {',
        '  _modelCopy(_model, dest);',
        '  update?.call(dest);',
        if (childrenListener != null) '  _notifyOnPropChanges(_model, dest);',
        '});',

        /// copyAsync
        '/// Creates a new instance of [$dataClassName],',
        '/// which is a copy of this with some changes',
        '@override Future<$dataClassName$genericTypes> copyAsync([DataClassAsyncBuilder<$modelClassName>? update,]) async {',
        'final model = $modelClassName();',
        '_modelCopy(_model, model);',
        'await update?.call(model);\n',
        'return $dataClassName$genericTypes._build((dest) {',
        '  _modelCopy(model, dest);',
        '  update?.call(dest);',
        if (childrenListener != null) '  _notifyOnPropChanges(_model, dest);',
        '});',
        '}',

        /// copyWith
        if (generateCopyWith) ...[
          '/// Creates a new instance of [$dataClassName],',
          '/// which is a copy of this with some changes',
          '@override $dataClassName$genericTypes copyWith({',
          for (final field in fields)
            '${fieldDeclaration(field, required: false)},',
          '}) => copy((b) => b',
          for (final field in fields)
            '..${field.name} = ${field.name} ?? _model.${field.name}',
          if (fields.isNotEmpty) ',',
          ');',
          '',
        ],
      ];
}
