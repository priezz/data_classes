import 'common.dart';

extension ClassGeneratorNotification on ClassGenerator {
  Iterable<String> generateChangesNotificator() => [
        'static void _notifyOnCopy$genericTypesFull($modelClassNameTyped prev, $modelClassNameTyped next,) {',
        '  Future.wait([',
        for (final field in fields)
          "_notifyOnPropChange$genericTypes('${field.name}', prev.${field.name}, next.${field.name}),",
        '  ]);',
        '}',
        '',
        'static Future<void> _notifyOnPropChange$genericTypesFull(String name, dynamic prev, dynamic next) async {',
        '  if (!eqShallow(next, prev)) {',
        '    await $changesListenerName$genericTypes(',
        "      '$objectNamePrefix\$name',",
        '      next: next,',
        '      prev: prev',
        '    );',
        '  }',
        '}',
        '',
      ];
}
