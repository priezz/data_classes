import 'package:data_classes/src/utils/strings.dart';

import 'core.dart';
import 'sealed.dart';

extension SealedClassSelectors on SealedClassGenerator {
  Iterable<String> generateSelectors() => [
        /// maybe
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

        /// whenOrNull
        'R? whenOrNull<R>({',
        for (final method in methods)
          'R Function(${getSubclassNameTyped(method)})? ${method.name},',
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

        /// when
        'R when<R>({',
        for (final method in methods)
          'required R Function(${getSubclassNameTyped(method)}) ${method.name},',
        '}) => whenOrNull(',
        for (final method in methods) '${method.name}: ${method.name},',
        ')!;',
        '',

        /// whenSubclass
        for (final method in methods)
          'R? when${method.name.capitalized}<R>(R Function(${getSubclassNameTyped(method)}) f) => this is ${getSubclassNameTyped(method)} ? f(this as ${getSubclassNameTyped(method)}) : null;',
        '',

        /// asSubclassOrNull
        for (final method in methods)
          '${getSubclassNameTyped(method)}? get as${method.name.capitalized}OrNull => castOrNull(this);',
      ];
}
