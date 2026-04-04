import 'dart:developer';
import 'package:retro_route/model/review_model.dart';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';

class ReviewRepo {
  final _apiServices = NetworkApiServices();
 

  Future<ReviewResponse> getProductReviews({required String token,required String productId,}) async {
    try {
      final response = await _apiServices.getApi("${AppUrls.getProductReview}/$productId", token);

      log("Raw response from review: $response");
      if (response is! Map<String, dynamic>) {
        throw Exception("Unexpected response type: ${response.runtimeType}");
      }

      final addressResponse = ReviewResponse.fromJson(response);

      log("Parsed ${addressResponse.data?.length ?? 0} addresses");

      return addressResponse;
    } catch (e, stack) {
      log("Error fetching addresses: $e");
      log("Stack: $stack");
      rethrow;
    }
  }



  Future<void> createReview({
    required String token,
    required String productId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    try {
      final response = await _apiServices.postApi(
        {
          "productId": productId,
          "rating": rating,
          "title": title,
          "comment": comment,
        },
        AppUrls.createReview,
        token,
      );

      log("Raw response from review: $response");
      if (response is! Map<String, dynamic>) {
        throw Exception("Unexpected response type: ${response.runtimeType}");
      }
    } catch (e, stack) {
      log("Error fetching review: $e");
      log("Stack: $stack");
      rethrow;
    }
  }



  Future<void> updateReview({
    required String token,
    required String reviewId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    try {
       await _apiServices.putApi(
        {
          "rating": rating,
          "title": title,
          "comment": comment,
        },
        "${AppUrls.updateProductReview}/$reviewId",
        token,
      );

    
    } catch (e, stack) {
      log("Error fetching review: $e");
      log("Stack: $stack");
      rethrow;
    }
  }

  Future<void> deleteReview({
    required String token,
    required String reviewId,
   
  }) async {
    try {
      final response = await _apiServices.deleteApi(
        "${AppUrls.deleteProductReview}/$reviewId",
        token,null
      );

      log("Raw response from review: $response");
      if (response is! Map<String, dynamic>) {
        throw Exception("Unexpected response type: ${response.runtimeType}");
      }
    } catch (e, stack) {
      log("Error fetching review: $e");
      log("Stack: $stack");
      rethrow;
    }
  }



}
