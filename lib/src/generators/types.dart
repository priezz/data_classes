import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';

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

/// Finds an element declaration and returns its parts.
Future<Iterable<String>> getElementDeclaration(
  Element element, {
  required Resolver resolver,
  bool debug = false,
  bool lookupParent = false,
}) async {
  AstNode? node;
  try {
    node = await resolver.astNodeFor(element);
  } catch (_) {}
  if (node != null) {
    final Iterable<String> children =
        (lookupParent && node.parent != null ? node.parent! : node)
            .childEntities
            .map((e) => e.toString())
            .where(
              (e) => e.isNotEmpty && !e.startsWith('@') && e != 'abstract',
            );
    if (debug) {
      StringBuffer s = StringBuffer('${element.source?.uri}:${node.offset}\n');
      children.forEach(s.writeln);
      print(s);
    }

    return children;
  } else {
    return [];
  }
}

/// Finds non-resolved field type string
Future<String> getElementTypeString(
  Element element,
  // Map<String, String> qualifiedImports,
  {
  required Resolver resolver,
  bool debug = false,
  Iterable<String>? declaration,
  bool lookupParent = false,
  bool Function(String)? predicate,
}) async {
  // final DartType? type = element is VariableElement ? element.type : null;

  final Iterable<String> declarationEffective = declaration ??
      await getElementDeclaration(
        element,
        debug: debug,
        lookupParent: lookupParent,
        resolver: resolver,
      );
  String? typeDeclaration;
  if (declarationEffective.isEmpty) {
    throw ('------ Could not find node with `${element.name}` element declaration. ------');
  }

  final String? result = declarationEffective
      .firstWhereOrNull((e) => predicate?.call(e) ?? e != 'class');
  if (element.name != null) {
    typeDeclaration =
        result?.replaceAll(RegExp(r'\s+' + element.name! + r'$'), '');
  }
  // typeDeclaration ??= type?.getDisplayString(withNullability: false);
  if (typeDeclaration == null) {
    throw ('------ Could not find type for the `${element.name}` element. ------');
  }

  return typeDeclaration.trim();
  // } else {
  //   // typeDeclaration = type?.getDisplayString(withNullability: false);
  // }

  // final LibraryElement? typeLibrary = type?.element!.library;
  // final String? prefixOrNull = qualifiedImports[typeLibrary?.identifier];
  // final String prefix = (prefixOrNull != null) ? '$prefixOrNull.' : '';

  // return '$prefix$typeDeclaration'.trim();
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
          .firstWhereOrNull(
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
            node.childEntities.map((e) => e.toString()).firstWhereOrNull(
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
