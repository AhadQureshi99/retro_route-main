import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/model/order_model.dart';
import 'package:retro_route/model/orderhistory_model.dart';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final orderRepoProvider = Provider<OrderRepo>((ref) => OrderRepo());

class OrderRepo {
  final _apiServices = NetworkApiServices();

  /// Calls /payment/process — same endpoint the web uses.
  /// Returns [PaymentProcessResponse] on success.
  /// Throws [PaymentRequiresActionException] when 3D-Secure is needed.
  Future<PaymentProcessResponse> processPayment({
    required String token,
    required String paymentMethodId,
    required String addressId,
    required double deliveryCharges,
    required String scheduledDeliveryDate,
    String customerNote = '',
    String deliveryZone = '',
    String deliveryDay = '',
    bool isOutOfZone = false,
  }) async {
    final body = {
      "paymentMethodId": paymentMethodId,
      "addressId": addressId,
      "deliveryCharges": deliveryCharges,
      "scheduledDeliveryDate": scheduledDeliveryDate,
      "customerNote": customerNote,
      "deliveryZone": deliveryZone,
      "deliveryDay": deliveryDay,
      "isOutOfZone": isOutOfZone,
    };

    log("[OrderRepo] processPayment BODY: $body");

    // We make the HTTP call manually so we can inspect non-200 responses
    // (the backend returns 402 for requires_action / 3D-Secure).
    final uri = Uri.parse(AppUrls.processPayment);
    final response = await http.Client()
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer ${token.trim()}',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
    log("[OrderRepo] processPayment status=${response.statusCode} body=$responseJson");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PaymentProcessResponse.fromJson(responseJson);
    }

    // 3D-Secure / requires_action
    final clientSecret = responseJson['data']?['clientSecret'] as String?;
    if (clientSecret != null && clientSecret.isNotEmpty) {
      throw PaymentRequiresActionException(
        PaymentRequiresActionResponse.fromJson(responseJson),
      );
    }

    // Generic error
    final msg = responseJson['message'] ?? 'Payment failed';
    throw Exception(msg);
  }

  /// Syncs the local Flutter cart to the backend server-side cart.
  /// Clears the backend cart first, then adds each item with selectedSize.
  Future<void> syncCartToBackend({
    required String token,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    // 1. Clear backend cart
    try {
      final clearUri = Uri.parse(AppUrls.clearCart);
      await http.Client().delete(
        clearUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      log("[OrderRepo] Backend cart cleared");
    } catch (e) {
      log("[OrderRepo] Failed to clear backend cart: $e");
    }

    // 2. Add each item to backend cart
    for (final item in cartItems) {
      try {
        final addUri = Uri.parse(AppUrls.addToCart);
        final body = {
          "productId": item["productId"],
          "quantity": item["quantity"],
          if (item["selectedSize"] != null) "selectedSize": item["selectedSize"],
        };
        await http.Client().post(
          addUri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );
        log("[OrderRepo] Added to backend cart: $body");
      } catch (e) {
        log("[OrderRepo] Failed to add item to backend cart: $e");
      }
    }
  }

  Future<OrderResponse> createOrderAndGetPaymentIntent({
    required String token,
    required List<Map<String, dynamic>> products,
    required String customerNote,
    required String addressId,
    required double totalPrice,
    required double deliveryCharges,
    required DateTime scheduledDeliveryDate,
    String deliveryZone = '',
    String deliveryDay = '',
    bool isOutOfZone = false,
  }) async {
    // Format date as YYYY-MM-DD (same as web)
    final dateStr =
        '${scheduledDeliveryDate.year.toString().padLeft(4, '0')}-'
        '${scheduledDeliveryDate.month.toString().padLeft(2, '0')}-'
        '${scheduledDeliveryDate.day.toString().padLeft(2, '0')}';

    final body = {
      "products": products,
      "customerNote": customerNote,
      "addressId": addressId,
      "totalPrice": totalPrice,
      "deliveryCharges": deliveryCharges,
      "scheduledDeliveryDate": dateStr,
      "deliveryZone": deliveryZone,
      "deliveryDay": deliveryDay,
      "isOutOfZone": isOutOfZone,
    };

    log("[OrderRepo] REQUEST BODY: $body");

    try {
      final response = await _apiServices.postApi(
        body,
        AppUrls.createOrder,
        token,
      );

      log("Order created: $response");
      log("Full response JSON: $response");
      log("[OrderRepo] data keys: ${response['data']?.keys}");
      log("[OrderRepo] data.orderId: ${response['data']?['orderId']}");
      log("[OrderRepo] data.order: ${response['data']?['order']}");
      if (response['data']?['order'] != null) {
        log("[OrderRepo] data.order.orderId: ${response['data']['order']['orderId']}");
      }

      if (response['success'] != true) {
        final msg = response['message'] ?? response['error'] ?? 'Failed to create order';
        log("Order API error: $msg | full response: $response");
        throw Exception(msg);
      }

      return OrderResponse.fromJson(response);
    } catch (e) {
      log("Order creation failed: $e");
      rethrow;
    }
  }

  Future<OrdersHistoryResponse> getOrderHistory({required String token}) async {
    try {
      final response = await _apiServices.getApi(AppUrls.getOrderHistory, token);

      return OrdersHistoryResponse.fromJson(response);
    } catch (e, stack) {
      log("orderHistory failed", error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Confirm payment status with backend after Stripe sheet completes.
  Future<void> confirmPayment({
    required String token,
    required String orderId,
  }) async {
    try {
      final uri = Uri.parse(AppUrls.confirmPayment);
      final response = await http.Client()
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${token.trim()}',
            },
            body: jsonEncode({"orderId": orderId}),
          )
          .timeout(const Duration(seconds: 30));
      log("[OrderRepo] confirmPayment status=${response.statusCode} body=${response.body}");
    } catch (e) {
      log("[OrderRepo] confirmPayment failed: $e");
      // Non-fatal — Stripe webhook should also handle this
    }
  }
}

/// Thrown when the backend signals that 3D-Secure confirmation is required.
class PaymentRequiresActionException implements Exception {
  final PaymentRequiresActionResponse data;
  PaymentRequiresActionException(this.data);
  @override
  String toString() => 'PaymentRequiresActionException(clientSecret: ${data.clientSecret})';
}
