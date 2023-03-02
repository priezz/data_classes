import 'package:data_classes/src/utils/strings.dart';

import 'core.dart';
import 'sealed.dart';

extension SealedClassSelectors on SealedClassGenerator {
  Iterable<String> generateSelectors() => [
        /// maybe
        '/// Returns the value when a method for a [$className] subclass corresponding',
        '/// to `this` is provided or from the \$else] method when it is not.',
        '/// Null is returned when a subclass method nor [\$else] are not provided.',
        'R? maybe<R>({',
        for (final method in methods)
          'R Function(${getSubclassNameTyped(method)})? ${method.name},',
        '  R Function()? \$else,',
        '}) {',
        '  final self = this;',
        [
          for (final method in methods)
            [
              'if (${method.name} != null && self is ${getSubclassNameTyped(method)}) {',
              '  return ${method.name}(self);',
              '}',
            ].join(),
        ].join(' else '),
        '  else if (\$else != null) {',
        '    return \$else();',
        '  } else {',
        '    return null;',
        '  }',
        '}',
        '',

        /// when
        '/// Returns a result<R> from the method for a [$className] subclass',
        '/// corresponding to `this`.',
        'R when<R>({',
        for (final method in methods)
          'required R Function(${getSubclassNameTyped(method)}) ${method.name},',
        '}) => whenOrNull(',
        for (final method in methods) '${method.name}: ${method.name},',
        ') as R;',
        '',

        /// whenOrNull
        '/// Returns the value when a method for a [$className] subclass corresponding',
        '/// to `this` is provided or null when it is not.',
        'R? whenOrNull<R>({',
        for (final method in methods)
          'R? Function(${getSubclassNameTyped(method)})? ${method.name},',
        '}) {',
        '  final self = this;',
        [
          for (final method in methods)
            [
              'if (self is ${getSubclassNameTyped(method)}) {',
              '  return ${method.name}?.call(self);',
              '}',
            ].join(),
        ].join(' else '),
        '  else {',
        "    throw Exception('Unexpected subclass of $parentClassName.');",
        '  }',
        '}',
        '',

        /// whenSubclass
        for (final method in methods) ...[
          '/// Returns the value when a `this` is [${getSubclassNameTyped(method)}]',
          '/// or null when it is not.',
          'R? when${method.name.capitalized}<R>(R Function(${getSubclassNameTyped(method)}) f) => this is ${getSubclassNameTyped(method)} ? f(this as ${getSubclassNameTyped(method)}) : null;',
        ],
        '',

        /// asSubclassOrNull
        for (final method in methods)
          '${getSubclassNameTyped(method)}? get as${method.name.capitalized}OrNull => castOrNull(this);',
      ];
}
