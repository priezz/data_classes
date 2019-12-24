// ignore_for_file: undefined_class, uri_has_not_been_generated
import 'package:data_classes/data_classes.dart';

part 'main.g.dart';

void main() {
  final apple = Fruit(
    color: Color.green,
    name: 'apple',
    shape: Shape.round,
  );
  final orange1 = Fruit.fromJson(orangeJson);
  final orange2 = Fruit.fromJson(orangeJson);
  final yellowFruit = Fruit(color: Color.yellow);
  final lime = yellowFruit.copy((f) => f.name = 'lime');
  apple.big = true; // should be analyzer error

  print('Apple = $apple\nLime = $lime\nOrange = $orange1');
  print('Oranges are equal: ${orange1 == orange2}');
  print('Orange is equal to apple: ${orange1 == apple}');
  print('${orange1.coloredName}\n');
}

enum Color { red, yellow, green, brown, orange }
enum Shape { round, curved }

/// A fruit with a doc comment
@JsonSerializable()
@GenerateDataClass(immutable: true)
class FruitModel {
  String name = 'unknown';

  /// A field with a doc comment
  @GenerateValueGetters(usePrefix: true)
  @GenerateValueGetters()
  Color color;
  @GenerateValueGetters(generateNegations: true)
  Shape shape = Shape.curved;
  @JsonKey(name: 'liked_by')
  List<String> likedBy = [];
  @nullable
  bool big;

  String get coloredName => '$name is $color';
}

const orangeJson = {
  'big': true,
  'color': 'orange',
  'liked_by': ['Nancy'],
  'name': 'orange',
  'shape': 'round',
};
