import 'dart:developer';
import 'dart:io';
import 'package:retro_route/model/driver_delivery_model.dart';
import 'package:retro_route/model/water_test_result_model.dart';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';

class DriverRepo {
  final _apiServices = NetworkApiServices();

  /// Fetch deliveries by status (Pending, Delivered, OnMyWay)
  Future<DriverDeliveriesResponse> fetchMyDeliveries({
    required String token,
    String? status,
    DateTime? dateFilter,
  }) async {
    try {
      String url = AppUrls.getMyDeliveries;
      
      // Build query parameters
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (dateFilter != null) {
        queryParams['date'] = dateFilter.toIso8601String().split('T').first;
      }
      
      if (queryParams.isNotEmpty) {
        url = '$url?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      log("Fetching deliveries from: $url");
      final response = await _apiServices.getApi(url, token);

      log("Raw API response: $response");

      if (response is! Map<String, dynamic>) {
        throw Exception("Unexpected response type: ${response.runtimeType}");
      }

      return DriverDeliveriesResponse.fromJson(response);
    } catch (e, stack) {
      log("Fetch deliveries failed: $e");
      log("Stack: $stack");
      rethrow;
    }
  }

  /// Fetch driver stats
  Future<DriverStatsResponse> fetchDriverStats({required String token}) async {
    try {
      log("Fetching driver stats from: ${AppUrls.getDriverStats}");
      final response = await _apiServices.getApi(AppUrls.getDriverStats, token);

      log("Raw stats response: $response");

      if (response is! Map<String, dynamic>) {
        throw Exception("Unexpected response type: ${response.runtimeType}");
      }

      return DriverStatsResponse.fromJson(response);
    } catch (e, stack) {
      log("Fetch driver stats failed: $e");
      log("Stack: $stack");
      rethrow;
    }
  }

  /// Update delivery status (On My Way - JSON PUT)
  Future<Map<String, dynamic>> updateDeliveryStatus({
    required String token,
    required String orderId,
    required String status,
    String? driverNotes,
    double? driverLat,
    double? driverLon,
  }) async {
    try {
      final body = {
        'orderId': orderId,
        'status': status,
        if (driverNotes != null && driverNotes.isNotEmpty) 'notes': driverNotes,
        if (driverLat != null) 'driverLat': driverLat,
        if (driverLon != null) 'driverLon': driverLon,
      };

      log("Updating delivery status: $body");
      final response = await _apiServices.putApi(
        body,
        AppUrls.updateDeliveryStatus,
        token,
        isJson: true,
      );

      log("Update status response: $response");
      return response as Map<String, dynamic>;
    } catch (e, stack) {
      log("Update delivery status failed: $e");
      log("Stack: $stack");
      rethrow;
    }
  }

  /// Update delivery status with proof image (Delivered - Multipart PUT)
  Future<Map<String, dynamic>> updateDeliveryStatusWithProof({
    required String token,
    required String orderId,
    required String status,
    String? driverNotes,
    required File deliveryProofImage,
  }) async {
    try {
      final data = {
        'orderId': orderId,
        'status': status,
        if (driverNotes != null && driverNotes.isNotEmpty) 'notes': driverNotes,
      };

      log("Updating delivery status with proof: $data");
      final response = await _apiServices.putApi(
        data,
        AppUrls.updateDeliveryStatus,
        token,
        isJson: false,
        files: [deliveryProofImage],
        fileFields: ['deliveryProofImage'],
      );

      log("Update status with proof response: $response");
      return response as Map<String, dynamic>;
    } catch (e, stack) {
      log("Update delivery status with proof failed: $e");
      log("Stack: $stack");
      rethrow;
    }
  }

  /// Save water test result + recommended crate via POST
  Future<Map<String, dynamic>> saveWaterTest({
    required String token,
    required WaterTestResult waterTest,
    required List<CrateItem> crateItems,
  }) async {
    try {
      final body = {
        ...waterTest.toJson(),
        'recommendedProducts': crateItems.map((c) => c.toJson()).toList(),
      };
      log("Saving water test: $body");
      final response = await _apiServices.postApi(
        body,
        AppUrls.submitWaterTest,
        token,
        isJson: true,
      );
      log("Save water test response: $response");
      return response as Map<String, dynamic>;
    } catch (e, stack) {
      log("Save water test failed: $e");
      log("Stack: $stack");
      rethrow;
    }
  }

  /// Submit end of day report (with optional odometer image)
  Future<Map<String, dynamic>> submitEodReport({
    required String token,
    required EodReport report,
    File? odometerImage,
    File? sodOdometerImage,
  }) async {
    try {
      log("Submitting EOD report: ${report.toJson()}");
      final files = <File>[];
      final fileFields = <String>[];
      if (odometerImage != null) {
        files.add(odometerImage);
        fileFields.add('odometerImage');
      }
      if (sodOdometerImage != null) {
        files.add(sodOdometerImage);
        fileFields.add('sodOdometerImage');
      }
      final response = await _apiServices.postApi(
        report.toJson(),
        AppUrls.submitEodReport,
        token,
        isJson: files.isEmpty,
        files: files.isNotEmpty ? files : null,
        fileFields: fileFields.isNotEmpty ? fileFields : null,
      );
      log("Submit EOD report response: $response");
      return response as Map<String, dynamic>;
    } catch (e, stack) {
      log("Submit EOD report failed: $e");
      log("Stack: $stack");
      rethrow;
    }
  }
}
