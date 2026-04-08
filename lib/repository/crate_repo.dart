import 'dart:developer';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';

class CrateRepo {
  final _apiServices = NetworkApiServices();

  /// Fetch pending crate for an order
  Future<Map<String, dynamic>> getPendingCrate({
    required String token,
    required String orderId,
  }) async {
    try {
      final url = AppUrls.pendingCrate(orderId);
      log("Fetching pending crate: $url");
      final response = await _apiServices.getApi(url, token);
      return response as Map<String, dynamic>;
    } catch (e, stack) {
      log("Fetch pending crate failed: $e", stackTrace: stack);
      rethrow;
    }
  }

  /// Customer approves crate (optionally with modified items)
  Future<Map<String, dynamic>> approveCrate({
    required String token,
    required String orderId,
    List<Map<String, dynamic>>? modifiedItems,
  }) async {
    try {
      final url = AppUrls.approveCrate(orderId);
      final body = <String, dynamic>{};
      if (modifiedItems != null) {
        body['items'] = modifiedItems;
      }
      log("Approving crate: $url");
      final response = await _apiServices.putApi(body, url, token, isJson: true);
      return response as Map<String, dynamic>;
    } catch (e, stack) {
      log("Approve crate failed: $e", stackTrace: stack);
      rethrow;
    }
  }

  /// Customer declines crate
  Future<Map<String, dynamic>> declineCrate({
    required String token,
    required String orderId,
  }) async {
    try {
      final url = AppUrls.declineCrate(orderId);
      log("Declining crate: $url");
      final response = await _apiServices.putApi({}, url, token, isJson: true);
      return response as Map<String, dynamic>;
    } catch (e, stack) {
      log("Decline crate failed: $e", stackTrace: stack);
      rethrow;
    }
  }

  /// Fetch pool report for an order
  Future<Map<String, dynamic>> getPoolReport({
    required String token,
    required String orderId,
  }) async {
    try {
      final url = AppUrls.poolReport(orderId);
      log("Fetching pool report: $url");
      final response = await _apiServices.getApi(url, token);
      return response as Map<String, dynamic>;
    } catch (e, stack) {
      log("Fetch pool report failed: $e", stackTrace: stack);
      rethrow;
    }
  }

  /// Fetch customer water test history
  Future<Map<String, dynamic>> getWaterTestHistory({
    required String token,
  }) async {
    try {
      log("Fetching water test history");
      final response = await _apiServices.getApi(AppUrls.waterTestHistory, token);
      return response as Map<String, dynamic>;
    } catch (e, stack) {
      log("Fetch water test history failed: $e", stackTrace: stack);
      rethrow;
    }
  }

  /// Fetch all pool report cards for the customer
  Future<Map<String, dynamic>> getMyPoolReports({
    required String token,
  }) async {
    try {
      log("Fetching my pool reports");
      final response = await _apiServices.getApi(AppUrls.myPoolReports, token);
      return response as Map<String, dynamic>;
    } catch (e, stack) {
      log("Fetch my pool reports failed: $e", stackTrace: stack);
      rethrow;
    }
  }
}
