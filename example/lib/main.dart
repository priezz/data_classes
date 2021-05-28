// ignore_for_file: undefined_class, uri_has_not_been_generated
import 'package:data_classes/data_classes.dart';
import 'package:data_classes/serializers.dart';

import 'models_helpers.dart';
export 'models_helpers.dart';

part 'main.g.dart';

void main() {
}

enum Color { red, yellow, green, brown, orange }
enum Shape { round, curved }

/// A fruit with a doc comment
@DataClass(immutable: true)
class FruitModel {
  String name = 'unknown';
  late Color color;
  Shape shape = Shape.curved;
  List<Map<String, String>?> iterableNullable = [];
  late List<Set<List<String>>> iterableNotNullable;
  List<Set<List<String>>> iterableDefault = [
    {
      ['Hello']
    }
  ];
  List<String> likedBy = [];
  Map<String, List<String>> mapDefault = {
    'hello': ['world']
  };
  late Map<int, List<String>> mapNotNullable;
  Map<String, Map<int, List<String?>>?>? mapNullable;
  late bool big;
  Seed seed = Seed(number: 2);
  Seed? optionalSeed;
  Map<Color, Iterable<String>> colorsMap = {};
  late DateTime timeStamp;
}

@JsonSerializable()
@DataClass(immutable: true)
class SeedModel {
  bool big = false;
  bool edible = true;
  late int number;
}

const orangeJson = {
  'big': true,
  'color': 'orange',
  'liked_by': ['Nancy'],
  'name': 'orange',
  'shape': 'round',
};
