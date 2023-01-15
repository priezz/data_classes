/// Returns [x as T] if [x] is of type [T] or [fallback] otherwise.
T castOr<T>(dynamic x, T fallback) => x != null && x is T ? x : fallback;

/// Returns [x as T] if [x] is of type [T] or null otherwise.
T? castOrNull<T>(dynamic x) => x != null && x is T ? x : null;

Type getType<T>() => T;

/// Checks if [S] is a subtype of [T].
bool isSubtypeOf<S, T>() => <S>[] is List<T>;
