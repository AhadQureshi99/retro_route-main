class OrderResponse {
  final String orderId;
  final String orderNumber;
  final String stripePaymentIntentId;
  final String clientSecret;
  final double amount;
  final String currency;

  OrderResponse.fromJson(Map<String, dynamic> json)
      : orderId = _parseString(json['data']?['orderId'] ?? json['data']?['order']?['_id'] ?? ''),
        orderNumber = _parseString(json['data']?['orderNumber'] ?? json['data']?['order']?['orderId'] ?? ''),
        stripePaymentIntentId = _parseString(json['data']?['stripePaymentIntentId'] ?? ''),
        clientSecret = _parseString(json['data']?['clientSecret'] ?? ''),
        amount = (json['data']?['amount'] ?? json['data']?['payment']?['amount'] ?? 0).toDouble(),
        currency = _parseString(json['data']?['currency'] ?? json['data']?['payment']?['currency'] ?? 'cad');

  static String _parseString(dynamic value) => value?.toString() ?? '';
}

/// Response from /payment/process (same endpoint the web uses).
class PaymentProcessResponse {
  final String orderId;
  final String? paymentId;
  final double? amount;

  PaymentProcessResponse({
    required this.orderId,
    this.paymentId,
    this.amount,
  });

  factory PaymentProcessResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final order = data?['order'] as Map<String, dynamic>?;
    final payment = data?['payment'] as Map<String, dynamic>?;
    return PaymentProcessResponse(
      orderId: order?['orderId'] ?? '',
      paymentId: payment?['id'] as String?,
      amount: (payment?['amount'] as num?)?.toDouble(),
    );
  }
}

/// When /payment/process returns requires_action (3D Secure).
class PaymentRequiresActionResponse {
  final String clientSecret;

  PaymentRequiresActionResponse({required this.clientSecret});

  factory PaymentRequiresActionResponse.fromJson(Map<String, dynamic> json) {
    return PaymentRequiresActionResponse(
      clientSecret: json['data']?['clientSecret'] ?? '',
    );
  }
}
