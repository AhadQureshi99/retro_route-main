import 'dart:developer';
import 'package:retro_route/model/favourite_model.dart';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';

class FavouritesRepo {
  final _apiServices = NetworkApiServices();

  Future<void> addFavourites({
    required String productId,
    required String token,
  }) async {
    try {
      final response = await _apiServices.postApi(
        {"productId": productId},
        AppUrls.addToFavourites,
        token,
      );
      log("Response from favrouites: $response");
    } catch (e) {
      log("Response from favrouites: $e");
      rethrow;
    }
  }

  Future<void> removeFavourites({
    required String productId,
    required String token,
  }) async {
    try {
      final response = await _apiServices.postApi(
        {"productId": productId},
        AppUrls.removeFavorites,
        token,
      );
      log("Response from favourites: $response");
    } catch (e) {
      log("Response from favourites: $e");
      rethrow;
    }
  }

  Future<FavoritesResponse> fetchFavourites({required String token}) async {
    try {
      final response = await _apiServices.getApi(AppUrls.getFavourites, token);

      log(
        "Raw API response type: ${response.runtimeType}",
      ); // should print: _InternalLinkedHashMap<String, dynamic>
      log("Raw response: $response");

      if (response is! Map<String, dynamic>) {
        throw Exception(
          "Unexpected response type: ${response.runtimeType}. Expected Map<String, dynamic>",
        );
      }

      return FavoritesResponse.fromJson(response as Map<String, dynamic>);
    } catch (e, stack) {
      log("Fetch favourites failed: $e");
      log("Stack: $stack");
      rethrow;
    }
  }
}
