import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:source_gen/source_gen.dart';
import 'package:data_classes/data_classes.dart';

const modelSuffix = 'Model';

Builder generateDataClass(BuilderOptions options) =>
    SharedPartBuilder([DataClassGenerator()], 'data_classes');

class CodeGenError extends Error {
  CodeGenError(this.message);
  final String message;
  String toString() => message;
}

class DataClassGenerator extends GeneratorForAnnotation<GenerateDataClass> {
  @override
  generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep _,
  ) {
    if (element is! ClassElement) {
      throw CodeGenError(
          'You can only annotate classes with @GenerateDataClass(), but '
          '"${element.name}" isn\'t a class.');
    }
    // if (!element.name.startsWith('_') || !element.name.endsWith(modelSuffix)) {
    if (!element.name.endsWith(modelSuffix)) {
      throw CodeGenError(
          'The names of classes annotated with @GenerateDataClass() should '
          'start with "_" and end with "Model", for example ${element.name}Model. '
          'The generated class (in that case, ${element.name}) will then get '
          'automatically generated for you by running "pub run build_runner '
          'build" (or "flutter pub run build_runner build" if you\'re using '
          'Flutter).');
    }

    final ClassElement originalClass = element as ClassElement;
    // final name = originalClass.name;
    final name = originalClass.name
        .substring(1, originalClass.name.length - modelSuffix.length);
    final modelName = originalClass.name;

    /// When import prefixes (`import '...' as '...';`) are used in the mutable
    /// class's file, then in the generated file, we need to use the right
    /// prefix in front of the type in the immutable class too. So here, we map
    /// the module identifiers to their import prefixes.
    Map<String, String> qualifiedImports = {
      for (final import in originalClass.library.imports)
        if (import.prefix != null)
          import.importedLibrary.identifier: import.prefix.name,
    };

    /// Collect all the fields and getters from the original class.
    final fields = <FieldElement>{};

    for (final field in originalClass.fields) {
      // TODO: Create a flag to disallow dynamic types
      // if (field.type.toString().contains('dynamic')) {
      //   throw CodeGenError(
      //     'Dynamic types are not allowed.\n'
      //     'Fix:\n'
      //     '  class $name$modelClassSuffix {\n'
      //     '    ...\n'
      //     '    <SpecificType> ${field.name};'
      //     '    ...\n'
      //     '  }',
      //   );
      // }
      fields.add(field);
    }

    /// Check whether we should generate a `copyWith` method. Also ensure that
    /// there are no nullable fields.
    final builtValueSerializer = originalClass.metadata
        .firstWhere((annotation) =>
            annotation.element?.enclosingElement?.name == 'GenerateDataClass')
        .constantValue
        .getField('builtValueSerializer')
        .toBoolValue();
    final generateCopyWith = originalClass.metadata
        .firstWhere((annotation) =>
            annotation.element?.enclosingElement?.name == 'GenerateDataClass')
        .constantValue
        .getField('copyWith')
        .toBoolValue();
    final immutable = originalClass.metadata
        .firstWhere((annotation) =>
            annotation.element?.enclosingElement?.name == 'GenerateDataClass')
        .constantValue
        .getField('immutable')
        .toBoolValue();
    final serialize = originalClass.metadata
        .firstWhere((annotation) =>
            annotation.element?.enclosingElement?.name == 'GenerateDataClass')
        .constantValue
        .getField('serialize')
        .toBoolValue();

    // Users can annotate fields that hold an enum value with
    // `@GenerateValueGetters()` to generate value getters.
    // Here, we prepare a map from the getter name to its code content.
    final valueGetters = <String, String>{};
    for (final field in fields) {
      final annotation = field.metadata
          .firstWhere(
              (annotation) =>
                  annotation.element?.enclosingElement?.name ==
                  'GenerateValueGetters',
              orElse: () => null)
          ?.computeConstantValue();
      if (annotation == null) continue;

      final usePrefix = annotation.getField('usePrefix').toBoolValue();
      final generateNegations =
          annotation.getField('generateNegations').toBoolValue();

      final enumClass = field.type.element as ClassElement;
      if (enumClass?.isEnum == false) {
        throw CodeGenError('You annotated the $modelName\'s ${field.name} with '
            '@GenerateValueGetters(), but that\'s of '
            '${enumClass == null ? 'an unknown type' : 'the type ${enumClass.name}'}, '
            'which is not an enum. @GenerateValueGetters() should only be '
            'used on fields of an enum type.');
      }

      final prefix = 'is${usePrefix ? _capitalize(field.name) : ''}';
      final enumValues = enumClass.fields
          .where((field) => !['values', 'index'].contains(field.name));

      for (final value in enumValues) {
        for (final negate in generateNegations ? [false, true] : [false]) {
          final getter =
              '$prefix${negate ? 'Not' : ''}${_capitalize(value.name)}';
          final content = 'this.${field.name} ${negate ? '!=' : '=='} '
              '${_qualifiedType(value.type, qualifiedImports)}.${value.name}';

          if (valueGetters.containsKey(getter)) {
            throw CodeGenError(
                'A conflict occurred while generating value getters. The two '
                'conflicting value getters of the $modelName class are:\n'
                '- $getter, which tests if ${valueGetters[getter]}\n'
                '- $getter, which tests if $content');
          }

          valueGetters[getter] = content;
        }
      }
    }

    final String nameUncapitalized =
        name.substring(0, 1).toLowerCase() + name.substring(1);

    /// Actually generate the class.
    final buffer = StringBuffer();
    buffer.writeAll([
      '// ignore_for_file: lines_longer_than_80_chars, implicit_dynamic_parameter, non_constant_identifier_names, prefer_asserts_with_message, prefer_expression_function_bodies, unnecessary_getters_setters, sort_constructors_first',

      '/// {@nodoc}',
      'typedef ${name}Updater = void Function($modelName);',

      /// Start of the class.
      originalClass.documentationComment ?? '',
      if (immutable)
        '@immutable',
      'class $name extends $modelName {',

      // The field members.
      for (final field in fields) ...[
        if (field.documentationComment != null) field.documentationComment,
        _fieldDeclaration(field, qualifiedImports),
        _fieldGetter(field, qualifiedImports),
        if (!immutable) _fieldSetter(field, qualifiedImports),
      ],

      /// The default constructor
      '/// Creates a new [$name] with the given attributes',
      'factory $name([${name}Updater update]) => $name._($modelName(), update);',
      '$name._($modelName source, [${name}Updater update]):',
      fields.map((field) => '_${field.name} = source.${field.name}').join(','),
      ' {\n',
      'update?.call(this);',
      for (final field in fields)
        if (!_isNullable(field)) 'assert(_${field.name} != null);',
      '}\n',

      /// Deep equality stuff (== and hashCode).
      /// https://stackoverflow.com/questions/10404516/how-can-i-compare-lists-for-equality-in-dart
      '/// Checks if this [$name] is equal to the other one.',
      '@override',
      'bool operator ==(Object other) {',
      'final bool Function(dynamic e1, dynamic e2) eq = const DeepCollectionEquality().equals;\n',
      'return identical(this, other) || other is $modelName &&',

      fields
          .map(
            (field) =>
                // field.type.displayName.startsWith('List')
                // ? 'eq(${field.name}, other.${field.name})'
                // : '${field.name} == other.${field.name}')
                'eq(_${field.name}, other.${field.name})',
          )
          .join(' &&\n'),
      ';\n}\n',
      '@override',
      'int get hashCode => hashList([',
      fields.map((field) => field.name).join(', '),
      ']);\n',

      // toString converter.
      '/// Converts this [$name] into a [String].',
      '@override',
      "String toString() => \'$name(\\n'",
      for (final field in fields) "'  ${field.name}: \$${field.name}\\n'",
      "')';\n",

      /// copy
      '/// Creates a copy of this [$name] with some changes',
      '$name copy(void Function($modelName source) update) {',
      'assert(update != null,',
      '\'You called $name.copy, \'',
      '\'but did not provide a function for changing the attributes.\\n\'',
      '\'If you just want an unchanged copy: You do not need one, just use \'',
      '\'the original.\',',
      ');',
      '\nreturn $name._(this, update);',
      '}\n',

      /// copyWith
      if (generateCopyWith) ...[
        '/// Creates a copy of this [$name] with some changes',
        '$name copyWith({',
        for (final field in fields) '${_field(field, qualifiedImports)},',
        '}) => $name._(this, (b) => b',
        for (final field in fields)
          '..${field.name} = ${field.name} ?? this.${field.name}',
        ');',
      ],

      if (serialize) ...[
        /// fromJson
        'factory $name.fromJson(Map<dynamic, dynamic> json) =>',
        '$name._(_\$${modelName}FromJson(json));\n',

        /// toJson
        'Map<dynamic, dynamic> toJson() => _\$${modelName}ToJson(this);\n',

        if (builtValueSerializer)
          'static Serializer<$name> get serializer => _\$${nameUncapitalized}Serializer;'
      ],

      /// End of the class.
      '}\n',

      if (serialize && builtValueSerializer) ...[
        'Serializer<$name> _\$${nameUncapitalized}Serializer = _\$${name}Serializer();\n',
        'class _\$${name}Serializer implements StructuredSerializer<$name> {',
        '  @override',
        '  final Iterable<Type> types = const [$name];',
        '  @override',
        '  final String wireName = \'$name\';\n',
        '  @override',
        '  Iterable<Object> serialize(Serializers serializers, $name object,',
        '      {FullType specifiedType = FullType.unspecified}) {',
        '    final json = _\$${name}ToJson(object);',
        '    final List<Object> result = [];',
        '    json.forEach((k, v) => result.addAll([k, v]));\n',
        '    return result;',
        '  }\n',
        '  @override',
        '  $name deserialize(Serializers serializers, Iterable<Object> serialized,',
        '      {FullType specifiedType = FullType.unspecified}) {',
        '    final Map<dynamic, dynamic> json = {};',
        '    final serializedAsList = serialized.toList();',
        '    serializedAsList.asMap().forEach((i, key) {',
        '      if (i.isEven) json[key] = serializedAsList[i + 1];',
        '    });\n',
        '    return $modelName._($name._(), _\$${name}FromJson(json),);',
        '  }\n',
        '}',
      ]
    ].expand((line) => [line, '\n']));

    return buffer.toString();
  }

  /// Whether the [field] is nullable.
  bool _isNullable(FieldElement field) {
    assert(field != null);

    return field.metadata
        .any((annotation) => annotation.element.name == nullable);
  }

  /// Whether the [field] is nullable.
  bool _isRequired(FieldElement field) {
    assert(field != null);

    return !_isNullable(field) && field.initializer == null;
  }

  /// Capitalizes the first letter of a string.
  String _capitalize(String string) {
    assert(string.isNotEmpty);
    return string[0].toUpperCase() + string.substring(1);
  }

  /// Turns the [field] into type and the field name, separated by a space.
  String _field(
    FieldElement field,
    Map<String, String> qualifiedImports,
  ) {
    assert(field != null && qualifiedImports != null);
    return '${_qualifiedType(field.type, qualifiedImports)} ${field.name}';
  }

  String _fieldDeclaration(
    FieldElement field,
    Map<String, String> qualifiedImports,
  ) =>
      '${_qualifiedType(field.type, qualifiedImports)} _${field.name};';

  String _fieldGetter(
    FieldElement field,
    Map<String, String> qualifiedImports,
  ) =>
      '@override\n'
      '${_qualifiedType(field.type, qualifiedImports)} get ${field.name} => '
      '_${field.name};';

  String _fieldSetter(
    FieldElement field,
    Map<String, String> qualifiedImports,
  ) =>
      '@override\n'
      'set ${field.name}(${_qualifiedType(field.type, qualifiedImports)} value) => '
      '_${field.name} = value;';

  /// Turns the [type] into a type with prefix.
  String _qualifiedType(DartType type, Map<String, String> qualifiedImports) {
    final typeLibrary = type.element.library;
    final prefixOrNull = qualifiedImports[typeLibrary?.identifier];
    final prefix = (prefixOrNull != null) ? '$prefixOrNull.' : '';

    return '$prefix$type';
  }
}
