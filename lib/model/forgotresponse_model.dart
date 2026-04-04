class ForgotResponse {
  final int statusCode;
  final String message;
  final bool success;

  ForgotResponse({
    required this.statusCode,
    required this.message,
    required this.success,
  });

  factory ForgotResponse.fromJson(Map<String, dynamic> json) {
    return ForgotResponse(
      statusCode: json['statusCode'] as int? ?? 0,
      message: json['message'] as String? ?? 'Operation failed',
      success: json['success'] as bool? ?? false,
    );
  }
}