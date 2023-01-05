extension StringX on String {
  String camelToSnake() => replaceAllMapped(
        RegExp('[A-Z]+'),
        (match) => '_${match.group(0)?.toLowerCase() ?? ''}',
      );

  String get capitalized => this.replaceFirstMapped(
        RegExp('[A-Za-z]'),
        (m) => m.group(0)?.toUpperCase() ?? '',
      );

  String get decapitalized => this.replaceFirstMapped(
        RegExp('[A-Za-z]'),
        (m) => m.group(0)?.toLowerCase() ?? '',
      );

  String snakeToCamel() {
    final result = StringBuffer();
    toLowerCase().split(RegExp('[^A-Za-z0-9]+')).asMap().forEach(
          (i, part) => result.write(
            part.isEmpty
                ? ''
                : (i > 0 ? part[0].toUpperCase() : part[0]) + part.substring(1),
          ),
        );

    return result.toString();
  }
}
