// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// SugarClassesGenerator
// **************************************************************************

/// {@category sugar-class}
@immutable
abstract class Fruit
    implements ICopyable<Fruit, _FruitBaseModel>, IEquitable, ISerializable {
  /// Prevent inheritance
  Fruit._();

  static FruitApple apple({
    required double weight,
    required AppleColor color,
  }) =>
      FruitApple(
        weight: weight,
        color: color,
      );
  static FruitPlum plum({
    required double weight,
  }) =>
      FruitPlum(
        weight: weight,
      );
  static FruitOrange orange({
    required double weight,
  }) =>
      FruitOrange(
        weight: weight,
      );

  factory Fruit.fromJson(Json json) {
    switch (json['@class']) {
      case 'FruitApple':
        return FruitApple.fromJson(json);
      case 'FruitPlum':
        return FruitPlum.fromJson(json);
      case 'FruitOrange':
        return FruitOrange.fromJson(json);
      default:
        throw Exception('Could not deserialize Fruit from $json');
    }
  }

  final _FruitBaseModel _model = _FruitBaseModel();

  double get weight => _model.weight;

  @override
  Json toJson() => serializeToJson({
        'weightInGrams': _model.weight,
      }) as Json;

  R? maybe<R>({
    R Function(FruitApple)? apple,
    R Function(FruitPlum)? plum,
    R Function(FruitOrange)? orange,
    R Function()? $else,
  }) {
    final self = this;
    if (apple != null && self is FruitApple) {
      return apple(self);
    } else if (plum != null && self is FruitPlum) {
      return plum(self);
    } else if (orange != null && self is FruitOrange) {
      return orange(self);
    } else if ($else != null) {
      return $else();
    } else {
      return null;
    }
  }

  R? whenOrNull<R>({
    R Function(FruitApple)? apple,
    R Function(FruitPlum)? plum,
    R Function(FruitOrange)? orange,
  }) {
    final self = this;
    if (self is FruitApple) {
      return apple?.call(self);
    } else if (self is FruitPlum) {
      return plum?.call(self);
    } else if (self is FruitOrange) {
      return orange?.call(self);
    } else {
      throw Exception('Unexpected subclass of null.');
    }
  }

  R when<R>({
    required R Function(FruitApple) apple,
    required R Function(FruitPlum) plum,
    required R Function(FruitOrange) orange,
  }) =>
      whenOrNull(
        apple: apple,
        plum: plum,
        orange: orange,
      )!;

  R? whenApple<R>(R Function(FruitApple) f) =>
      this is FruitApple ? f(this as FruitApple) : null;
  R? whenPlum<R>(R Function(FruitPlum) f) =>
      this is FruitPlum ? f(this as FruitPlum) : null;
  R? whenOrange<R>(R Function(FruitOrange) f) =>
      this is FruitOrange ? f(this as FruitOrange) : null;

  FruitApple? get asAppleOrNull => castOrNull(this);
  FruitPlum? get asPlumOrNull => castOrNull(this);
  FruitOrange? get asOrangeOrNull => castOrNull(this);
}

/// {@category sugar-class}
@immutable
class FruitApple extends Fruit {
  factory FruitApple({
    required AppleColor color,
    required double weight,
  }) =>
      FruitApple._build(
        (b) => b
          ..color = color
          ..weight = weight,
      );

  FruitApple._build(
    ModelBuilder<_FruitAppleModel> builder,
  ) : super._() {
    builder.call(_model);
  }

  static void _modelCopy(
    _FruitAppleModel source,
    _FruitAppleModel dest,
  ) =>
      dest
        ..color = source.color
        ..weight = source.weight;

  factory FruitApple._fromModel(
    _FruitAppleModel source,
  ) =>
      FruitApple._build((dest) => _modelCopy(source, dest));

  factory FruitApple.fromJson(Json json) {
    if (json['@class'] != 'FruitApple') {
      throw Exception('Invalid json data for FruitApple. $json');
    }

    return FruitApple._fromModel(_modelFromJson(json));
  }

  static _FruitAppleModel _modelFromJson(
    Map<dynamic, dynamic> json,
  ) {
    final model = _FruitAppleModel();

    setModelField<AppleColor>(
      json,
      'color',
      (v) => model.color = v!,
      getter: (j) => enumValueFromJson(j, AppleColor.values),
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
  final _FruitAppleModel _model = _FruitAppleModel();

  AppleColor get color => _model.color;
  double get weight => _model.weight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FruitApple &&
          eqShallow(
            _model.color,
            other._model.color,
          ) &&
          eqShallow(
            _model.weight,
            other._model.weight,
          );

  /// This hash code compatible with [operator ==].
  /// [FruitApple] classes with the same data
  /// have the same hash code.
  @override
  int get hashCode => hashList([
        color,
        weight,
      ]);

  /// Converts this [FruitApple] into a [String].
  @override
  String toString() => 'FruitApple(\n'
      '  color: $color\n'
      '  weight: $weight\n'
      ')';

  factory FruitApple.from(
    FruitApple source,
  ) =>
      FruitApple._build(
        (destModel) => _modelCopy(source._model, destModel),
      );

  /// Creates a new instance of [FruitApple],
  /// which is a copy of this with some changes
  @override
  FruitApple copy([
    ModelBuilder<_FruitAppleModel>? update,
  ]) =>
      FruitApple._build((dest) {
        _modelCopy(_model, dest);
        update?.call(dest);
      });

  /// Creates a new instance of [FruitApple],
  /// which is a copy of this with some changes
  @override
  Future<FruitApple> copyAsync([
    ModelBuilderAsync<_FruitAppleModel>? update,
  ]) async {
    final model = _FruitAppleModel();
    _modelCopy(_model, model);
    await update?.call(model);

    return FruitApple._build((dest) {
      _modelCopy(model, dest);
      update?.call(dest);
    });
  }

  /// Creates a new instance of [FruitApple],
  /// which is a copy of this with some changes
  @override
  FruitApple copyWith({
    AppleColor? color,
    double? weight,
  }) =>
      copy(
        (b) => b
          ..color = color ?? _model.color
          ..weight = weight ?? _model.weight,
      );

  @override
  Json toJson() => serializeToJson({
        '@class': 'FruitApple',
        ...super.toJson(),
        'color': _model.color,
        'weightInGrams': _model.weight,
      }) as Json;
}

/// {@category sugar-class}
@immutable
class FruitPlum extends Fruit {
  factory FruitPlum({
    required double weight,
  }) =>
      FruitPlum._build(
        (b) => b..weight = weight,
      );

  FruitPlum._build(
    ModelBuilder<_FruitPlumModel> builder,
  ) : super._() {
    builder.call(_model);
  }

  static void _modelCopy(
    _FruitPlumModel source,
    _FruitPlumModel dest,
  ) =>
      dest..weight = source.weight;

  factory FruitPlum._fromModel(
    _FruitPlumModel source,
  ) =>
      FruitPlum._build((dest) => _modelCopy(source, dest));

  factory FruitPlum.fromJson(Json json) {
    if (json['@class'] != 'FruitPlum') {
      throw Exception('Invalid json data for FruitPlum. $json');
    }

    return FruitPlum._fromModel(_modelFromJson(json));
  }

  static _FruitPlumModel _modelFromJson(
    Map<dynamic, dynamic> json,
  ) {
    final model = _FruitPlumModel();

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
  final _FruitPlumModel _model = _FruitPlumModel();

  double get weight => _model.weight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FruitPlum &&
          eqShallow(
            _model.weight,
            other._model.weight,
          );

  /// This hash code compatible with [operator ==].
  /// [FruitPlum] classes with the same data
  /// have the same hash code.
  @override
  int get hashCode => hashList([
        weight,
      ]);

  /// Converts this [FruitPlum] into a [String].
  @override
  String toString() => 'FruitPlum(\n'
      '  weight: $weight\n'
      ')';

  factory FruitPlum.from(
    FruitPlum source,
  ) =>
      FruitPlum._build(
        (destModel) => _modelCopy(source._model, destModel),
      );

  /// Creates a new instance of [FruitPlum],
  /// which is a copy of this with some changes
  @override
  FruitPlum copy([
    ModelBuilder<_FruitPlumModel>? update,
  ]) =>
      FruitPlum._build((dest) {
        _modelCopy(_model, dest);
        update?.call(dest);
      });

  /// Creates a new instance of [FruitPlum],
  /// which is a copy of this with some changes
  @override
  Future<FruitPlum> copyAsync([
    ModelBuilderAsync<_FruitPlumModel>? update,
  ]) async {
    final model = _FruitPlumModel();
    _modelCopy(_model, model);
    await update?.call(model);

    return FruitPlum._build((dest) {
      _modelCopy(model, dest);
      update?.call(dest);
    });
  }

  /// Creates a new instance of [FruitPlum],
  /// which is a copy of this with some changes
  @override
  FruitPlum copyWith({
    double? weight,
  }) =>
      copy(
        (b) => b..weight = weight ?? _model.weight,
      );

  @override
  Json toJson() => serializeToJson({
        '@class': 'FruitPlum',
        ...super.toJson(),
        'weightInGrams': _model.weight,
      }) as Json;
}

/// {@category sugar-class}
@immutable
class FruitOrange extends Fruit {
  factory FruitOrange({
    required double weight,
  }) =>
      FruitOrange._build(
        (b) => b..weight = weight,
      );

  FruitOrange._build(
    ModelBuilder<_FruitOrangeModel> builder,
  ) : super._() {
    builder.call(_model);
  }

  static void _modelCopy(
    _FruitOrangeModel source,
    _FruitOrangeModel dest,
  ) =>
      dest..weight = source.weight;

  factory FruitOrange._fromModel(
    _FruitOrangeModel source,
  ) =>
      FruitOrange._build((dest) => _modelCopy(source, dest));

  factory FruitOrange.fromJson(Json json) {
    if (json['@class'] != 'FruitOrange') {
      throw Exception('Invalid json data for FruitOrange. $json');
    }

    return FruitOrange._fromModel(_modelFromJson(json));
  }

  static _FruitOrangeModel _modelFromJson(
    Map<dynamic, dynamic> json,
  ) {
    final model = _FruitOrangeModel();

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
  final _FruitOrangeModel _model = _FruitOrangeModel();

  double get weight => _model.weight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FruitOrange &&
          eqShallow(
            _model.weight,
            other._model.weight,
          );

  /// This hash code compatible with [operator ==].
  /// [FruitOrange] classes with the same data
  /// have the same hash code.
  @override
  int get hashCode => hashList([
        weight,
      ]);

  /// Converts this [FruitOrange] into a [String].
  @override
  String toString() => 'FruitOrange(\n'
      '  weight: $weight\n'
      ')';

  factory FruitOrange.from(
    FruitOrange source,
  ) =>
      FruitOrange._build(
        (destModel) => _modelCopy(source._model, destModel),
      );

  /// Creates a new instance of [FruitOrange],
  /// which is a copy of this with some changes
  @override
  FruitOrange copy([
    ModelBuilder<_FruitOrangeModel>? update,
  ]) =>
      FruitOrange._build((dest) {
        _modelCopy(_model, dest);
        update?.call(dest);
      });

  /// Creates a new instance of [FruitOrange],
  /// which is a copy of this with some changes
  @override
  Future<FruitOrange> copyAsync([
    ModelBuilderAsync<_FruitOrangeModel>? update,
  ]) async {
    final model = _FruitOrangeModel();
    _modelCopy(_model, model);
    await update?.call(model);

    return FruitOrange._build((dest) {
      _modelCopy(model, dest);
      update?.call(dest);
    });
  }

  /// Creates a new instance of [FruitOrange],
  /// which is a copy of this with some changes
  @override
  FruitOrange copyWith({
    double? weight,
  }) =>
      copy(
        (b) => b..weight = weight ?? _model.weight,
      );

  @override
  Json toJson() => serializeToJson({
        '@class': 'FruitOrange',
        ...super.toJson(),
        'weightInGrams': _model.weight,
      }) as Json;
}

class _FruitBaseModel {
  late double weight;
}

class _FruitAppleModel extends _FruitBaseModel {
  late AppleColor color;
}

class _FruitPlumModel extends _FruitBaseModel {}

class _FruitOrangeModel extends _FruitBaseModel {}

/// {@category sugar-class}
/// Box with some [T] fruits
class Box<T extends Fruit>
    implements ICopyable<Box<T>, BoxModel<T>>, IEquitable, ISerializable {
  factory Box({
    int? quantity,
    int? maxCapacity,
  }) =>
      Box._build(
        (b) => b
          ..quantity = quantity ?? b.quantity
          ..maxCapacity = maxCapacity,
      );

  Box._build(
    ModelBuilder<BoxModel<T>> builder,
  ) {
    builder.call(_model);
  }

  static void _modelCopy<T extends Fruit>(
    BoxModel<T> source,
    BoxModel<T> dest,
  ) =>
      dest
        ..quantity = source.quantity
        ..maxCapacity = source.maxCapacity;

  factory Box._fromModel(
    BoxModel<T> source,
  ) =>
      Box<T>._build((dest) => _modelCopy(source, dest));

  factory Box.fromJson(Json json) => Box._fromModel(_modelFromJson<T>(json));

  static BoxModel<T> _modelFromJson<T extends Fruit>(
    Map<dynamic, dynamic> json,
  ) {
    final model = BoxModel<T>();

    setModelField<int>(
      json,
      'quantity',
      (v) => model.quantity = v!,
      getter: (j) => intValueFromJson(j),
      nullable: false,
    );

    setModelField<int?>(
      json,
      'capacity',
      (v) => model.maxCapacity = v,
      getter: (j) => intValueFromJson(j),
    );

    return model;
  }

  final BoxModel<T> _model = BoxModel<T>();

  int get quantity => _model.quantity;
  set quantity(int value) {
    _notifyOnPropChange<T>('quantity', _model.quantity, value);
    _model.quantity = value;
  }

  int? get maxCapacity => _model.maxCapacity;
  set maxCapacity(int? value) {
    _notifyOnPropChange<T>('maxCapacity', _model.maxCapacity, value);
    _model.maxCapacity = value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Box<T> &&
          eqDeep(
            _model.quantity,
            other._model.quantity,
          ) &&
          eqDeep(
            _model.maxCapacity,
            other._model.maxCapacity,
          );

  /// This hash code compatible with [operator ==].
  /// [Box] classes with the same data
  /// have the same hash code.
  @override
  int get hashCode => hashList([
        quantity,
        if (maxCapacity != null) maxCapacity!,
      ]);

  /// Converts this [Box] into a [String].
  @override
  String toString() => 'Box(\n'
      '  quantity: $quantity\n'
      '''${maxCapacity != null ? '  maxCapacity: ${maxCapacity!}\n' : ''}'''
      ')';

  factory Box.from(
    Box<T> source,
  ) =>
      Box<T>._build(
        (destModel) => _modelCopy(source._model, destModel),
      );

  /// Creates a new instance of [Box],
  /// which is a copy of this with some changes
  @override
  Box<T> copy([
    ModelBuilder<BoxModel<T>>? update,
  ]) =>
      Box<T>._build((dest) {
        _modelCopy(_model, dest);
        update?.call(dest);
        _notifyOnCopy(_model, dest);
      });

  /// Creates a new instance of [Box],
  /// which is a copy of this with some changes
  @override
  Future<Box<T>> copyAsync([
    ModelBuilderAsync<BoxModel<T>>? update,
  ]) async {
    final model = BoxModel<T>();
    _modelCopy(_model, model);
    await update?.call(model);

    return Box<T>._build((dest) {
      _modelCopy(model, dest);
      update?.call(dest);
      _notifyOnCopy(_model, dest);
    });
  }

  /// Creates a new instance of [Box],
  /// which is a copy of this with some changes
  @override
  Box<T> copyWith({
    int? quantity,
    int? maxCapacity,
  }) =>
      copy(
        (b) => b
          ..quantity = quantity ?? _model.quantity
          ..maxCapacity = maxCapacity ?? _model.maxCapacity,
      );

  @override
  Json toJson() => serializeToJson({
        'quantity': _model.quantity,
        'capacity': _model.maxCapacity,
      }) as Json;

  static void _notifyOnCopy<T extends Fruit>(
    BoxModel<T> prev,
    BoxModel<T> next,
  ) {
    Future.wait([
      _notifyOnPropChange<T>('quantity', prev.quantity, next.quantity),
      _notifyOnPropChange<T>('maxCapacity', prev.maxCapacity, next.maxCapacity),
    ]);
  }

  static Future<void> _notifyOnPropChange<T extends Fruit>(
      String name, dynamic prev, dynamic next) async {
    if (!eqShallow(next, prev)) {
      await onBoxUpdate<T>(name: name, newValue: next, oldValue: prev);
    }
  }
}

/// {@category sugar-class}
/// Fruit shop
class Shop implements ICopyable<Shop, ShopModel>, IEquitable, ISerializable {
  factory Shop({
    required String name,
    List<Box>? boxes,
  }) =>
      Shop._build(
        (b) => b
          ..name = name
          ..boxes = boxes ?? b.boxes,
      );

  Shop._build(
    ModelBuilder<ShopModel> builder,
  ) {
    builder.call(_model);
  }

  static void _modelCopy(
    ShopModel source,
    ShopModel dest,
  ) =>
      dest
        ..boxes = source.boxes
        ..name = source.name;

  factory Shop._fromModel(
    ShopModel source,
  ) =>
      Shop._build((dest) => _modelCopy(source, dest));

  factory Shop.fromJson(Json json) => Shop._fromModel(_modelFromJson(json));

  static ShopModel _modelFromJson(
    Map<dynamic, dynamic> json,
  ) {
    final model = ShopModel();

    setModelField<List<Box>>(
      json,
      'boxes',
      (v) => model.boxes = v!,
      getter: (j) => listValueFromJson<Box>(
        j,
        value: (v) => valueFromJson(v, Box.fromJson),
      ),
      nullable: false,
    );

    setModelField<String>(
      json,
      'name',
      (v) => model.name = v!,
      required: true,
    );

    return model;
  }

  final ShopModel _model = ShopModel();

  List<Box> get boxes => _model.boxes;
  set boxes(List<Box> value) {
    _notifyOnPropChange('boxes', _model.boxes, value);
    _model.boxes = value;
  }

  String get name => _model.name;
  set name(String value) {
    _notifyOnPropChange('name', _model.name, value);
    _model.name = value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Shop &&
          eqDeep(
            _model.boxes,
            other._model.boxes,
          ) &&
          eqDeep(
            _model.name,
            other._model.name,
          );

  /// This hash code compatible with [operator ==].
  /// [Shop] classes with the same data
  /// have the same hash code.
  @override
  int get hashCode => hashList([
        boxes,
        name,
      ]);

  /// Converts this [Shop] into a [String].
  @override
  String toString() => 'Shop(\n'
      '  boxes: $boxes\n'
      '  name: $name\n'
      ')';

  factory Shop.from(
    Shop source,
  ) =>
      Shop._build(
        (destModel) => _modelCopy(source._model, destModel),
      );

  /// Creates a new instance of [Shop],
  /// which is a copy of this with some changes
  @override
  Shop copy([
    ModelBuilder<ShopModel>? update,
  ]) =>
      Shop._build((dest) {
        _modelCopy(_model, dest);
        update?.call(dest);
        _notifyOnCopy(_model, dest);
      });

  /// Creates a new instance of [Shop],
  /// which is a copy of this with some changes
  @override
  Future<Shop> copyAsync([
    ModelBuilderAsync<ShopModel>? update,
  ]) async {
    final model = ShopModel();
    _modelCopy(_model, model);
    await update?.call(model);

    return Shop._build((dest) {
      _modelCopy(model, dest);
      update?.call(dest);
      _notifyOnCopy(_model, dest);
    });
  }

  /// Creates a new instance of [Shop],
  /// which is a copy of this with some changes
  @override
  Shop copyWith({
    List<Box>? boxes,
    String? name,
  }) =>
      copy(
        (b) => b
          ..boxes = boxes ?? _model.boxes
          ..name = name ?? _model.name,
      );

  @override
  Json toJson() => serializeToJson({
        'boxes': _model.boxes,
        'name': _model.name,
      }) as Json;

  static void _notifyOnCopy(
    ShopModel prev,
    ShopModel next,
  ) {
    Future.wait([
      _notifyOnPropChange('boxes', prev.boxes, next.boxes),
      _notifyOnPropChange('name', prev.name, next.name),
    ]);
  }

  static Future<void> _notifyOnPropChange(
      String name, dynamic prev, dynamic next) async {
    if (!eqShallow(next, prev)) {
      await onShopUpdate(name: name, newValue: next, oldValue: prev);
    }
  }
}
