import 'package:meta/meta.dart';

export 'dart:async';
export 'package:collection/collection.dart';
export 'package:json_annotation/json_annotation.dart';
export 'package:meta/meta.dart' show immutable, required;

@immutable
class GenerateDataClass {
  const GenerateDataClass({
    this.builtValueSerializer = false,
    this.copyWith = true,
    this.immutable = false,
    this.serialize = true,
  })  : assert(copyWith != null),
        assert(serialize != null);

  final bool builtValueSerializer;
  final bool copyWith;
  final bool immutable;
  final bool serialize;
}

@immutable
class GenerateValueGetters {
  const GenerateValueGetters({
    this.usePrefix = false,
    this.generateNegations = true,
  })  : assert(usePrefix != null),
        assert(generateNegations != null);

  final bool usePrefix;
  final bool generateNegations;
}

const String nullable = 'nullable';

/// Combines the [Object.hashCode] values of an arbitrary number of objects
/// from an [Iterable] into one value. This function will return the same
/// value if given [null] as if given an empty list.
// Borrowed from dart:ui.
int hashList(Iterable<Object> arguments) {
  var result = 0;
  if (arguments != null) {
    for (Object argument in arguments) {
      var hash = result;
      hash = 0x1fffffff & (hash + argument.hashCode);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      result = hash ^ (hash >> 6);
    }
  }
  result = 0x1fffffff & (result + ((0x03ffffff & result) << 3));
  result = result ^ (result >> 11);
  return 0x1fffffff & (result + ((0x00003fff & result) << 15));
}
