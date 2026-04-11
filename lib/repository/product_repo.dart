import 'dart:convert';
import 'dart:developer';
import 'package:retro_route/model/category_model.dart';
import 'package:retro_route/model/product_model.dart';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';

class ProductRepo {
  final _apiServices = NetworkApiServices();

Future<CategoryModel> getAllCategories() async {
  try {
    final response = await _apiServices.getApi(AppUrls.getAllCategories, null);

    // Optional safety check (very recommended)
    if (response is! Map<String, dynamic>) {
      throw Exception(
        "API returned unexpected type: ${response.runtimeType} "
        "(expected Map<String, dynamic>)"
      );
    }

    return CategoryModel.fromJson(response);

  } catch (e, stack) {
    log("getAllCategories failed", error: e, stackTrace: stack);
    rethrow;
  }
}




  Future<ProductResponse> getProductsByCategory({String? categoryId}) async {
  try {
    String endpoint;

    if (categoryId != null && categoryId.isNotEmpty) {
      endpoint = "${AppUrls.getProductByCategory}/$categoryId?limit=1000";
    } else {
     
      endpoint = "${AppUrls.getAllProducts ?? AppUrls.getProductByCategory}?limit=1000";
      log("Fetching ALL products (no category filter)");
    }

    final response = await _apiServices.getApi(endpoint, null);

    if (response is! Map<String, dynamic>) {
      throw Exception("Unexpected response type: ${response.runtimeType}");
    }

    return ProductResponse.fromJson(response);
  } catch (e, stack) {
    log("getProductsByCategory failed", error: e, stackTrace: stack);
    rethrow;
  }
}



}
