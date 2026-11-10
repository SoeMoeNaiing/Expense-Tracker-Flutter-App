class ImportSummary {
  final int imported;
  final List<String> errors;

  const ImportSummary({required this.imported, required this.errors});

  int get failed => errors.length;
  bool get isClean => errors.isEmpty;

  @override
  String toString() =>
      'ImportSummary(imported: $imported, errors: ${errors.length})';
}
