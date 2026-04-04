import 'dart:developer';
import 'package:retro_route/model/product_model.dart';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';

class WaterTestRepo {
  final _apiServices = NetworkApiServices();

  Future<Product?> getWaterTestService() async {
    try {
      final response = await _apiServices.getApi(
        AppUrls.getWaterTestService,
        null,
      );

      if (response is! Map<String, dynamic>) {
        throw Exception(
          "API returned unexpected type: ${response.runtimeType}",
        );
      }

      final data = response['data'];
      if (data != null && data['product'] != null) {
        return Product.fromJson(data['product'] as Map<String, dynamic>);
      }
    } catch (e, stack) {
      log("getWaterTestService failed", error: e, stackTrace: stack);
    }

    // Fallback for guest flow: some deployments protect the dedicated
    // water-test endpoint, so pick service product from public catalog.
    try {
      final fallbackResponse = await _apiServices.getApi(AppUrls.getAllProducts, null);
      if (fallbackResponse is! Map<String, dynamic>) return null;

      final dynamic products = fallbackResponse['data']?['products'];
      if (products is! List) return null;

      for (final item in products) {
        if (item is! Map<String, dynamic>) continue;

        final isService = item['isService'] == true;
        final name = (item['name'] as String? ?? '').toLowerCase();
        final looksLikeWaterTest = name.contains('water test');

        if (isService || looksLikeWaterTest) {
          return Product.fromJson(item);
        }
      }
      return null;
    } catch (e, stack) {
      log('getWaterTestService fallback failed', error: e, stackTrace: stack);
      return null;
    }
  }
}
