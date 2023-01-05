T? castOrNull<T>(dynamic x) => x != null && x is T ? x : null;

bool isSubtypeOf<S, T>() => <S>[] is List<T>;
