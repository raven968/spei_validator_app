class ValidationResult {
  final bool isValidFormat;
  final List<String> issues;
  final Map<String, dynamic>? extractedData;
  final Map<String, dynamic>? banxicoStatus;

  ValidationResult({
    required this.isValidFormat,
    required this.issues,
    this.extractedData,
    this.banxicoStatus,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      isValidFormat: json['is_valid_format'] ?? false,
      issues: List<String>.from(json['issues'] ?? []),
      extractedData: json['extracted_data'] as Map<String, dynamic>?,
      banxicoStatus: json['banxico_status'] as Map<String, dynamic>?,
    );
  }
}
