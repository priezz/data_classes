import 'package:analyzer/dart/ast/ast.dart';
// import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:dartx/dartx.dart';

final nullableQualifierRegex = RegExp(r'\?$');

extension DartTypeX on DartType {
  bool get isDateTime => getDisplayString(withNullability: false) == 'DateTime';

  bool get isEnum => element is EnumElement;

  bool get isIterable => isDartCoreIterable || isDartCoreList || isDartCoreSet;

  bool get isSimple =>
      isDartCoreBool ||
      isDartCoreDouble ||
      isDartCoreInt ||
      isDartCoreString ||
      isEnum ||
      isDateTime;
  // || isDynamic
  // || isDartCoreObject;

  // bool get isRequired => nullabilitySuffix != NullabilitySuffix.question;

  Iterable<DartType> get genericTypes => this is ParameterizedType
      ? (this as ParameterizedType).typeArguments
      : const [];
}

/// Finds non-resolved field type string
Future<String> getFieldTypeString(
  FieldElement field,
  Map<String, String> qualifiedImports, {
  required Resolver resolver,
}) async {
  final DartType type = field.type;

  final AstNode? node = await resolver.astNodeFor(field);
  late final String typeDeclaration;
  if (node != null) {
    final String? result = (node.parent != null ? node.parent! : node)
        .childEntities
        .map((e) => e.toString())
        .firstOrNullWhere(
          (e) =>
              e.isNotEmpty &&
              !e.startsWith('@') &&
              !['class', 'abstract'].contains(e),
        );
    typeDeclaration = result ?? type.getDisplayString(withNullability: false);
  } else {
    print(
      '------ Could not find node with `${field.name}` field declaration. ------',
    );
    typeDeclaration = type.getDisplayString(withNullability: false);
  }

  final LibraryElement? typeLibrary = type.element!.library;
  final String? prefixOrNull = qualifiedImports[typeLibrary?.identifier];
  final String prefix = (prefixOrNull != null) ? '$prefixOrNull.' : '';

  return '$prefix$typeDeclaration'.trim();
}

/// Finds non-resolved type string
Future<String> getTypeString(
  DartType type, {
  required Resolver resolver,
  required String typeString,
}) async {
  final String typeStringNonQualified =
      typeString.replaceAll(nullableQualifierRegex, '');
  if (type.isSimple) return typeStringNonQualified;

  late final String typeDeclaration;

  try {
    if (type.alias?.element != null) {
      final unit = await resolver.compilationUnitFor(
        await resolver.assetIdForElement(type.alias!.element),
      );
      final String? result = unit.declarations
          .map((d) => d.childEntities.take(4).toList())
          .firstOrNullWhere(
            (items) =>
                items.length >= 4 &&
                items[0].toString() == 'typedef' &&
                items[1].toString() == typeStringNonQualified,
          )?[3]
          .toString();

      if (result == null) {
        print(
          '------ Could not find node with `$typeStringNonQualified` type declaration. ------',
        );
      }
      typeDeclaration = result ?? typeStringNonQualified;
    } else {
      final AstNode? node = type.element != null
          ? await resolver.astNodeFor(type.element!)
          : null;
      if (node != null) {
        final String? result =
            node.childEntities.map((e) => e.toString()).firstOrNullWhere(
                  (e) =>
                      e.isNotEmpty &&
                      !e.startsWith('@') &&
                      !['class', 'abstract'].contains(e),
                );
        typeDeclaration = result ?? typeStringNonQualified;
      } else {
        final String displayString =
            type.getDisplayString(withNullability: false);
        typeDeclaration =
            displayString == 'dynamic' ? typeStringNonQualified : displayString;
      }
    }
  } catch (e) {
    typeDeclaration = typeStringNonQualified;
  }

  // print('------ $typeString -> $typeDeclaration ------');
  return typeDeclaration.trim();
}
