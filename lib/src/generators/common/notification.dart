import 'common.dart';

extension ClassGeneratorNotification on ClassGenerator {
  Iterable<String> generateChangesNotificator() => [
        'static final List<FieldChangeListener> _listeners = ${observerNames!};',
        '',
        'static void _notifyOnCopy$genericTypesFull($modelClassNameTyped prev, $modelClassNameTyped next,) {',
        '  Future.wait([',
        for (final field in fields)
          "  _notifyOnPropChange('${field.name}', prev.${field.name}, next.${field.name}, next),",
        '  ]);',
        '}',
        '',
        'static Future<void> _notifyOnPropChange<T>(String name, T? prev, T? next, $modelClassNameTyped nextModel,) async {',
        '  if (!eqDeep(next, prev)) {',
        '    await Future.wait([',
        '      for (final listener in _listeners)',
        '        listener(',
        '          name: ${objectNamePrefix.isNotEmpty ? "'$objectNamePrefix\$name'" : 'name'},',
        '          newValue: next,',
        '          oldValue: prev,',
        '        ),',
        '    ]);',
        '  }',
        '}',
        '',
      ];
}
