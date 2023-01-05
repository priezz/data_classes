// ignore_for_file: directives_ordering
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:build_runner_core/build_runner_core.dart' as _i1;
import 'package:data_classes/generators.dart' as _i2;
import 'package:build_config/build_config.dart' as _i3;
import 'package:source_gen/builder.dart' as _i4;
import 'dart:isolate' as _i5;
import 'package:build_runner/build_runner.dart' as _i6;
import 'dart:io' as _i7;

final _builders = <_i1.BuilderApplication>[
  _i1.apply(
    r'data_classes:generators',
    [_i2.generateSugarClasses],
    _i1.toDependentsOf(r'data_classes'),
    hideOutput: true,
    defaultGenerateFor: const _i3.InputSet(include: [
      r'lib/**.dart',
      r'test/**.dart',
    ]),
    appliesBuilders: const [r'source_gen:combining_builder'],
  ),
  _i1.apply(
    r'source_gen:combining_builder',
    [_i4.combiningBuilder],
    _i1.toNoneByDefault(),
    hideOutput: false,
    appliesBuilders: const [r'source_gen:part_cleanup'],
  ),
  _i1.applyPostProcess(
    r'source_gen:part_cleanup',
    _i4.partCleanup,
  ),
];
void main(
  List<String> args, [
  _i5.SendPort? sendPort,
]) async {
  var result = await _i6.run(
    args,
    _builders,
  );
  sendPort?.send(result);
  _i7.exitCode = result;
}
