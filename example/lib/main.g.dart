// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// DataClassGenerator
// **************************************************************************

// ignore_for_file: argument_type_not_assignable, avoid_private_typedef_functions, avoid_single_cascade_in_expression_statements, dead_null_aware_expression, lines_longer_than_80_chars, implicit_dynamic_method, implicit_dynamic_parameter, implicit_dynamic_type, non_constant_identifier_names, prefer_asserts_with_message, prefer_constructors_over_static_methods, prefer_expression_function_bodies, sort_constructors_first
/// {@category model}
/// A fruit with a doc comment
@immutable
class Fruit extends IDataClass<Fruit, FruitModel> {
  final FruitModel _model = FruitModel();

  Color? get color => _model.color;
  Map<String, dynamic> get extraInfo => _model.extraInfo;
  String get name => _model.name;
  Tree get tree => _model.tree;
  double get weight => _model.weight;

  /// Creates a new [Fruit] with the given attributes
  factory Fruit({
    required String name,
    required Tree tree,
    required double weight,
    Color? color,
    Map<String, dynamic>? extraInfo,
  }) =>
      Fruit.build(
        (b) => b
          ..name = name
          ..tree = tree
          ..weight = weight
          ..color = color ?? b.color
          ..extraInfo = extraInfo ?? b.extraInfo,
      );

  factory Fruit.from(Fruit source) =>
      Fruit.build((b) => _modelCopy(source._model, b));

  factory Fruit.fromModel(FruitModel source) =>
      Fruit.build((b) => _modelCopy(source, b));

  Fruit.build(DataClassBuilder<FruitModel>? build) {
    build?.call(_model);
  }

  /// Checks if this [Fruit] is equal to the other one.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fruit &&
          eqShallow(_model.color, other._model.color) &&
          eqShallow(_model.extraInfo, other._model.extraInfo) &&
          eqShallow(_model.name, other._model.name) &&
          eqShallow(_model.tree, other._model.tree) &&
          eqShallow(_model.weight, other._model.weight);

  @override
  int get hashCode => hashList([
        if (color != null) color!,
        extraInfo,
        name,
        tree,
        weight,
      ]);

  /// Converts this [Fruit] into a [String].
  @override
  String toString() => 'Fruit(\n'
      '${color != null ? '  color: ${color!}\n' : ''}'
      '  extraInfo: $extraInfo\n'
      '  name: $name\n'
      '  tree: $tree\n'
      '  weight: $weight\n'
      ')';

  /// Creates a new instance of [Fruit], which is a copy of this with some changes
  @override
  Fruit copy([DataClassBuilder<FruitModel>? update]) => Fruit.build((builder) {
        _modelCopy(_model, builder);
        update?.call(builder);
        _notifyOnPropChanges(_model, builder);
      });

  /// Creates a new instance of [Fruit], which is a copy of this with some changes
  @override
  Fruit copyWith({
    Color? color,
    Map<String, dynamic>? extraInfo,
    String? name,
    Tree? tree,
    double? weight,
  }) =>
      copy((b) => b
        ..color = color ?? _model.color
        ..extraInfo = extraInfo ?? _model.extraInfo
        ..name = name ?? _model.name
        ..tree = tree ?? _model.tree
        ..weight = weight ?? _model.weight);

  factory Fruit.fromJson(Map<dynamic, dynamic> json) =>
      Fruit.fromModel(_$FruitModelFromJson(json));

  static Fruit deserialize(Map<dynamic, dynamic> json) => Fruit.fromJson(json);

  @override
  Map<dynamic, dynamic> toJson() => _$FruitModelToJson(_model);

  @override
  FruitModel get $model => _model;

  static void _modelCopy(
    FruitModel source,
    FruitModel dest,
  ) =>
      dest
        ..color = source.color
        ..extraInfo = source.extraInfo
        ..name = source.name
        ..tree = source.tree
        ..weight = source.weight;

  static void _notifyOnPropChanges(
    FruitModel prev,
    FruitModel next,
  ) {
    Future<void> notify(
      String name,
      dynamic Function(FruitModel) get,
      FruitModel Function(FruitModel, dynamic) set,
    ) async {
      final prevValue = get(prev);
      final nextValue = get(next);
      if (!eqShallow(nextValue, prevValue)) {
        await listener(
          '$name',
          next: nextValue,
          prev: prevValue,
          toJson: () => _$FruitModelToJson(set(FruitModel(), nextValue))[name],
        );
      }
    }

    Future.wait([
      notify('color', (m) => m.color, (m, v) => m..color = v as Color?),
      notify('extraInfo', (m) => m.extraInfo,
          (m, v) => m..extraInfo = v as Map<String, dynamic>),
      notify('name', (m) => m.name, (m, v) => m..name = v as String),
      notify('tree', (m) => m.tree, (m, v) => m..tree = v as Tree),
      notify('weight', (m) => m.weight, (m, v) => m..weight = v as double),
    ]);
  }
}

FruitModel _$FruitModelFromJson(Map<dynamic, dynamic> json) {
  final model = FruitModel();

  final color =
      enumFromString(castOrNull<String>(json['color']) ?? '', Color.values);
  model.color = color;

  final extraInfo = castOrNull<Map>(json['extraInfo']);
  if (extraInfo != null)
    model.extraInfo = Map.fromEntries(extraInfo.entries.mapNotNull((e) {
      final key = castOrNull<String>(e.key);
      final value = e.value;

      return key != null ? MapEntry(key, value) : null;
    }));

  final name = castOrNull<String>(json['name']);
  if (name == null) {
    throw JsonDeserializationError(
      'Attempted to assign null value to non-nullable required field: `name`.',
    );
  }
  model.name = name;

  model.tree = treeFromJson(json['tree']);

  final weight = castOrNull<num>(json['weightInGrams'])?.toDouble() ??
      double.tryParse(castOrNull<String>(json['weightInGrams']) ?? '');
  if (weight == null) {
    throw JsonDeserializationError(
      'Attempted to assign null value to non-nullable required field: `weight`.',
    );
  }
  model.weight = weight;

  return model;
}

Map<String, dynamic> _$FruitModelToJson(FruitModel instance) =>
    serializeToJson({
      'color': instance.color,
      'extraInfo': instance.extraInfo,
      'name': instance.name,
      'tree': instance.tree,
      'weightInGrams': instance.weight,
    });

// ignore_for_file: argument_type_not_assignable, avoid_private_typedef_functions, avoid_single_cascade_in_expression_statements, dead_null_aware_expression, lines_longer_than_80_chars, implicit_dynamic_method, implicit_dynamic_parameter, implicit_dynamic_type, non_constant_identifier_names, prefer_asserts_with_message, prefer_constructors_over_static_methods, prefer_expression_function_bodies, sort_constructors_first
/// {@category model}

@immutable
class Tree extends IDataClass<Tree, TreeModel> {
  final TreeModel _model = TreeModel();

  String get name => _model.name;
  double? get averageHeight => _model.averageHeight;

  /// Creates a new [Tree] with the given attributes
  factory Tree({
    required String name,
    double? averageHeight,
  }) =>
      Tree.build(
        (b) => b
          ..name = name
          ..averageHeight = averageHeight ?? b.averageHeight,
      );

  factory Tree.from(Tree source) =>
      Tree.build((b) => _modelCopy(source._model, b));

  factory Tree.fromModel(TreeModel source) =>
      Tree.build((b) => _modelCopy(source, b));

  Tree.build(DataClassBuilder<TreeModel>? build) {
    build?.call(_model);
  }

  /// Checks if this [Tree] is equal to the other one.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tree &&
          eqShallow(_model.name, other._model.name) &&
          eqShallow(_model.averageHeight, other._model.averageHeight);

  @override
  int get hashCode => hashList([
        name,
        if (averageHeight != null) averageHeight!,
      ]);

  /// Converts this [Tree] into a [String].
  @override
  String toString() => 'Tree(\n'
      '  name: $name\n'
      '${averageHeight != null ? '  averageHeight: ${averageHeight!}\n' : ''}'
      ')';

  /// Creates a new instance of [Tree], which is a copy of this with some changes
  @override
  Tree copy([DataClassBuilder<TreeModel>? update]) => Tree.build((builder) {
        _modelCopy(_model, builder);
        update?.call(builder);
      });

  /// Creates a new instance of [Tree], which is a copy of this with some changes
  @override
  Tree copyWith({
    String? name,
    double? averageHeight,
  }) =>
      copy((b) => b
        ..name = name ?? _model.name
        ..averageHeight = averageHeight ?? _model.averageHeight);

  factory Tree.fromJson(Map<dynamic, dynamic> json) =>
      Tree.fromModel(_$TreeModelFromJson(json));

  static Tree deserialize(Map<dynamic, dynamic> json) => Tree.fromJson(json);

  @override
  Map<dynamic, dynamic> toJson() => _$TreeModelToJson(_model);

  @override
  TreeModel get $model => _model;

  static void _modelCopy(
    TreeModel source,
    TreeModel dest,
  ) =>
      dest
        ..name = source.name
        ..averageHeight = source.averageHeight;
}

TreeModel _$TreeModelFromJson(Map<dynamic, dynamic> json) {
  final model = TreeModel();

  final name = castOrNull<String>(json['name']);
  if (name == null) {
    throw JsonDeserializationError(
      'Attempted to assign null value to non-nullable required field: `name`.',
    );
  }
  model.name = name;

  final averageHeight = castOrNull<num>(json['averageHeight'])?.toDouble() ??
      double.tryParse(castOrNull<String>(json['averageHeight']) ?? '');
  model.averageHeight = averageHeight;

  return model;
}

Map<String, dynamic> _$TreeModelToJson(TreeModel instance) => serializeToJson({
      'name': instance.name,
      'averageHeight': instance.averageHeight,
    });
