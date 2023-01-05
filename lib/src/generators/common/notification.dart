import 'common.dart';

extension ClassGeneratorNotification on ClassGenerator {
  Iterable<String> generateChangesNotificator() => [
        'static void _notifyOnPropChanges($modelClassNameTyped prev, $modelClassNameTyped next,) {',
        '  Future<void> notify(String name, dynamic Function($modelClassNameTyped) get, $modelClassNameTyped Function($modelClassNameTyped, dynamic) set,) async {',
        '    final prevValue = get(prev);',
        '    final nextValue = get(next);',
        '    if (!eqShallow(nextValue, prevValue)) {',
        '      await $changesListenerName(',
        "        '$objectNamePrefix\$name',",
        '        next: nextValue,',
        '        prev: prevValue,',
        '      );',
        '    }',
        '  }\n',
        '  Future.wait([',
        for (final field in fields)
          "  notify('${field.name}', (m) => m.${field.name}, (m, v) => m..${field.name} = v as ${fieldTypes[field]},),",
        '  ]);',
        '}',
      ];
}
