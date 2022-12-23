import 'data.dart';

extension DataClassNotification on DataClassGenerator {
  Iterable<String> generateChangesNotificator() => [
        'static void _notifyOnPropChanges($modelClassName prev, $modelClassName next,) {',
        '  Future<void> notify(String name, dynamic Function($modelClassName) get, $modelClassName Function($modelClassName, dynamic) set,) async {',
        '    final prevValue = get(prev);',
        '    final nextValue = get(next);',
        '    if (!eqShallow(nextValue, prevValue)) {',
        '      await ${childrenListener!.name}(',
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
