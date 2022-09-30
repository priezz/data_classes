// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// DataClassGenerator
// **************************************************************************

// ignore_for_file: deprecated_member_use_from_same_package, duplicate_ignore, lines_longer_than_80_chars, prefer_constructors_over_static_methods, unnecessary_lambdas, unnecessary_null_comparison, unnecessary_nullable_for_final_variable_declarations, unused_element
/// {@category model}
/// A fruit with a doc comment
@immutable
class Fruit extends IDataClass<Fruit, FruitModel> {
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

  factory Fruit.from(
    Fruit source,
  ) =>
      Fruit.build((b) => _modelCopy(source._model, b));

  factory Fruit.fromModel(
    FruitModel source,
  ) =>
      Fruit.build((b) => _modelCopy(source, b));

  Fruit.build(
    DataClassBuilder<FruitModel>? build,
  ) {
    build?.call(_model);
  }

  factory Fruit.fromJson(Map<dynamic, dynamic> json) =>
      Fruit.fromModel(_modelFromJson(json));

  final FruitModel _model = FruitModel();

  Color? get color => _model.color;
  Map<String, dynamic> get extraInfo => _model.extraInfo;
  String get name => _model.name;
  Tree get tree => _model.tree;
  double get weight => _model.weight;

  /// Checks if this [Fruit] is equal to the other one.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fruit &&
          eqShallow(
            _model.color,
            other._model.color,
          ) &&
          eqShallow(
            _model.extraInfo,
            other._model.extraInfo,
          ) &&
          eqShallow(
            _model.name,
            other._model.name,
          ) &&
          eqShallow(
            _model.tree,
            other._model.tree,
          ) &&
          eqShallow(
            _model.weight,
            other._model.weight,
          );

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
      '''${color != null ? '  color: ${color!}\n' : ''}'''
      '  extraInfo: $extraInfo\n'
      '  name: $name\n'
      '  tree: $tree\n'
      '  weight: $weight\n'
      ')';

  /// Creates a new instance of [Fruit], which is a copy of this with some changes
  @override
  Fruit copy([
    DataClassBuilder<FruitModel>? update,
  ]) =>
      Fruit.build((builder) {
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
      copy(
        (b) => b
          ..color = color ?? _model.color
          ..extraInfo = extraInfo ?? _model.extraInfo
          ..name = name ?? _model.name
          ..tree = tree ?? _model.tree
          ..weight = weight ?? _model.weight,
      );

  @override
  Map<dynamic, dynamic> toJson() => serializeToJson({
        'color': _model.color,
        'extraInfo': _model.extraInfo,
        'name': _model.name,
        'tree': _model.tree,
        'weightInGrams': _model.weight,
      }) as Map<dynamic, dynamic>;

  static FruitModel _modelFromJson(
    Map<dynamic, dynamic> json,
  ) {
    final model = FruitModel();

    setModelField<Color?>(
      json,
      'color',
      (v) => model.color = v,
      getter: (j) => enumValueFromJson(j, Color.values),
    );

    setModelField<Map<String, dynamic>>(
      json,
      'extraInfo',
      (v) => model.extraInfo = v!,
      getter: (j) => mapValueFromJson<String, dynamic>(
        j,
        value: (v) => v,
      ),
      nullable: false,
    );

    setModelField<String>(
      json,
      'name',
      (v) => model.name = v!,
      required: true,
    );

    setModelField<Tree>(
      json,
      'tree',
      (v) => model.tree = v!,
      getter: (j) => treeFromJson(j),
      required: true,
    );

    setModelField<double>(
      json,
      'weightInGrams',
      (v) => model.weight = v!,
      getter: (j) => doubleValueFromJson(j),
      required: true,
    );

    return model;
  }

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
        );
      }
    }

    Future.wait([
      notify(
        'color',
        (m) => m.color,
        (m, v) => m..color = v as Color?,
      ),
      notify(
        'extraInfo',
        (m) => m.extraInfo,
        (m, v) => m..extraInfo = v as Map<String, dynamic>,
      ),
      notify(
        'name',
        (m) => m.name,
        (m, v) => m..name = v as String,
      ),
      notify(
        'tree',
        (m) => m.tree,
        (m, v) => m..tree = v as Tree,
      ),
      notify(
        'weight',
        (m) => m.weight,
        (m, v) => m..weight = v as double,
      ),
    ]);
  }
}

// ignore_for_file: deprecated_member_use_from_same_package, duplicate_ignore, lines_longer_than_80_chars, prefer_constructors_over_static_methods, unnecessary_lambdas, unnecessary_null_comparison, unnecessary_nullable_for_final_variable_declarations, unused_element
/// {@category model}

@immutable
class Tree extends IDataClass<Tree, TreeModel> {
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

  factory Tree.from(
    Tree source,
  ) =>
      Tree.build((b) => _modelCopy(source._model, b));

  factory Tree.fromModel(
    TreeModel source,
  ) =>
      Tree.build((b) => _modelCopy(source, b));

  Tree.build(
    DataClassBuilder<TreeModel>? build,
  ) {
    build?.call(_model);
  }

  factory Tree.fromJson(Map<dynamic, dynamic> json) =>
      Tree.fromModel(_modelFromJson(json));

  final TreeModel _model = TreeModel();

  String get name => _model.name;
  double? get averageHeight => _model.averageHeight;

  /// Checks if this [Tree] is equal to the other one.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tree &&
          eqShallow(
            _model.name,
            other._model.name,
          ) &&
          eqShallow(
            _model.averageHeight,
            other._model.averageHeight,
          );

  @override
  int get hashCode => hashList([
        name,
        if (averageHeight != null) averageHeight!,
      ]);

  /// Converts this [Tree] into a [String].
  @override
  String toString() => 'Tree(\n'
      '  name: $name\n'
      '''${averageHeight != null ? '  averageHeight: ${averageHeight!}\n' : ''}'''
      ')';

  /// Creates a new instance of [Tree], which is a copy of this with some changes
  @override
  Tree copy([
    DataClassBuilder<TreeModel>? update,
  ]) =>
      Tree.build((builder) {
        _modelCopy(_model, builder);
        update?.call(builder);
      });

  /// Creates a new instance of [Tree], which is a copy of this with some changes
  @override
  Tree copyWith({
    String? name,
    double? averageHeight,
  }) =>
      copy(
        (b) => b
          ..name = name ?? _model.name
          ..averageHeight = averageHeight ?? _model.averageHeight,
      );

  @override
  Map<dynamic, dynamic> toJson() => serializeToJson({
        'name': _model.name,
        'averageHeight': _model.averageHeight,
      }) as Map<dynamic, dynamic>;

  static TreeModel _modelFromJson(
    Map<dynamic, dynamic> json,
  ) {
    final model = TreeModel();

    setModelField<String>(
      json,
      'name',
      (v) => model.name = v!,
      required: true,
    );

    setModelField<double?>(
      json,
      'averageHeight',
      (v) => model.averageHeight = v,
      getter: (j) => doubleValueFromJson(j),
    );

    return model;
  }

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
