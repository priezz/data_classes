import 'core.dart';
import 'sealed.dart';

extension SealedClassSerialization on SealedClassGenerator {
  Iterable<String> generateDeserializer() => [
        'factory $className.fromJson(Json json) {',
        "  switch (json['@class']) {",
        for (final method in methods) ...[
          "  case '${getSubclassName(method)}':",
          '    return ${getSubclassNameTyped(method)}.fromJson(json);'
        ],
        '    default:',
        "      throw Exception('Could not deserialize $className from \$json');",
        '  }',
        '}',
        '',
      ];
}
