/// Type [Void] is the same as [void] but can be used in type checking,
/// e.g. `if (T == Void) ...`.
// ignore: non_constant_identifier_names
final Void = getType<void>();

/// Returns [x as T] if [x] is of type [T] or null otherwise.
T? castOrNull<T>(dynamic x) => x != null && x is T ? x : null;

Type getType<T>() => T;

/// Checks if [S] is a subtype of [T].
bool isSubtypeOf<S, T>() => <S>[] is List<T>;
