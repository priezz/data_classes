// ignore_for_file: undefined_class, uri_has_not_been_generated
import 'package:data_classes/data_classes.dart';

// ignore: unused_import
import 'models_helpers.dart';
export 'models_helpers.dart';

part 'main.g.dart';

const pineappleJson = {
  'color': 'yellow',
  'extraInfo': {
    'cultivatedIn': 'Costa Rica',
    'priceInDollarsPerKg': 3.2,
  },
  'name': 'Pineapple',
  'weightInGrams': 500,
};

Future<void> main() async {
  final pineapple = Fruit.fromJson(pineappleJson);
  final pineappleCopy = pineapple.copy();
  print('Pineapple: $pineapple');
  print(
    'Pineapple is ${pineappleCopy != pineapple ? 'not ' : ''}equal to its copy',
  );

  final heavyPineapple = pineapple.copyWith(weight: 1500);
  print('Heavy pineapple: $heavyPineapple');

  final pineappleFromBrasil = await pineapple.copyAsync(
    (builder) async => builder.extraInfo = {
      ...builder.extraInfo,
      ...await fetchPineappleInfo(),
    },
  );
  print('Pineapple from Brasil: $pineappleFromBrasil');
}

Future<Map<String, String>> fetchPineappleInfo() async {
  await Future.delayed(Duration(seconds: 1));

  return {'cultivatedIn': 'Brasil'};
}

enum Color { red, yellow, green, brown, orange }

/// A fruit with a doc comment
@DataClass(
  immutable: true,
  childrenListener: listener,
)
class FruitModel {
  Color? color;
  Map<String, dynamic> extraInfo = {};
  late String name;
  @Serializable(fromJson: treeFromJson)
  late Tree tree;
  @JsonKey('weightInGrams')
  late double weight;
}

@DataClass(immutable: true)
class TreeModel {
  late String name;
  double? averageHeight;
}

Tree treeFromJson(dynamic json) =>
    json is Map ? Tree.fromJson(json) : Tree(name: 'Imaginary tree');

Future<void> listener(path, {next, prev, toJson}) async =>
    print('$path: $prev -> $next');
