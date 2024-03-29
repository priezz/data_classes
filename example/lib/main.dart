import 'package:data_classes/data_classes.dart';

part 'main.g.dart';

enum AppleColor { red, yellow, green }

@Sealed(immutable: true)
abstract class FruitModel {
  apple(AppleColor color);
  plum();
  orange();

  // @JsonMethods(fromJson: treeFromJson)
  @JsonKey('weightInGrams')
  late double weight;
}

/// Box with some [T] fruits
@DataClass(observers: [onBoxUpdate])
class BoxModel<T extends Fruit> {
  int quantity = 0;
  @JsonKey('capacity')
  int? maxCapacity;
}

extension BoxAdd<T extends Fruit> on Box<T> {
  void add(T fruit) => quantity++;
}

/// Fruit shop
@DataClass(observers: [onShopUpdate])
class ShopModel {
  List<Box> boxes = [];
  late String name;
}

Future<void> onBoxUpdate<T>({
  required String name,
  required T? newValue,
  required T? oldValue,
}) async =>
    print('[BOX<$T>] $name: $oldValue -> $newValue');

Future<void> onShopUpdate<T>({
  required String name,
  required T? newValue,
  required T? oldValue,
}) async =>
    print('[SHOP] $name: $oldValue -> $newValue');

void main() {
  Shop shop = Shop(name: 'My Fruit Shop');
  final Box<FruitApple> apples = Box(maxCapacity: 50);
  final Box mixed = Box(maxCapacity: 10);
  final Box<FruitOrange> oranges = Box(maxCapacity: 20);
  final Box<FruitPlum> plums = Box(quantity: 100);
  apples.add(
    Fruit.apple(color: AppleColor.red, weight: 120),
  ); // -> OK, notification
  // apples.add(Fruit.orange(weight: 160)); // -> compiler error
  mixed.add(
    Fruit.orange(weight: 160),
  ); // -> OK, notification
  shop.boxes.addAll([mixed, oranges]); // -> no notification
  shop.boxes = [apples, mixed, oranges, plums]; // -> notification
}
