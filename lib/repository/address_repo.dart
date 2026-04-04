import 'dart:developer';
import 'package:retro_route/model/address_model.dart';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';

class AddressRepo {
  final _apiServices = NetworkApiServices();

  Future<AddressResponse> getAddress({required String token}) async {
    try {
      final response = await _apiServices.getApi(AppUrls.getAddress, token);

      log("Raw response from address: $response");
      if (response is! Map<String, dynamic>) {
        throw Exception("Unexpected response type: ${response.runtimeType}");
      }

      final addressResponse = AddressResponse.fromJson(response);

      log("Parsed ${addressResponse.data?.length ?? 0} addresses");

      return addressResponse;
    } catch (e, stack) {
      log("Error fetching addresses: $e");
      log("Stack: $stack");
      rethrow;
    }
  }

  Future<void> addAddress({
    required String token,
    required String addressLine,
    required String city,
    required String state,
    required String country,
    required String postalCode,
    required String phone,
    required String? fullName,
    Map<String, double>? currentLoc,
    Map<String, double>? deliveryLoc,
  }) async {
    try {
      final body = <String, dynamic>{
        'fullName': fullName,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'country': country,
        'postalCode': postalCode,
        'phoneNumber': phone,
      };
      if (currentLoc != null) body['currentLoc'] = currentLoc;
      if (deliveryLoc != null) body['deliveryLoc'] = deliveryLoc;
      final response = await _apiServices.postApi(body, AppUrls.addAddress, token);
      log('Response from address: $response');
    } catch (e) {
      log('Response from address: $e');
      rethrow;
    }
  }

  Future<void> updateAddress({
    required String token,
    required String addressId,
    required String addressLine,
    required String city,
    required String state,
    required String country,
    required String postalCode,
    required String phone,
    required String fullname,
    Map<String, double>? currentLoc,
    Map<String, double>? deliveryLoc,
  }) async {
    try {
      final body = <String, dynamic>{
        'fullName': fullname,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'country': country,
        'postalCode': postalCode,
        'phoneNumber': phone,
      };
      if (currentLoc != null) body['currentLoc'] = currentLoc;
      if (deliveryLoc != null) body['deliveryLoc'] = deliveryLoc;
      final response = await _apiServices.patchApi(
        body, '${AppUrls.updateAddress}/$addressId', token);
      log('Response from address: $response');
    } catch (e) {
      log('Response from address: $e');
      rethrow;
    }
  }

  Future<void> deleteAddress({
    required String token,
    required String addressId,
  }) async {
    try {
      final response = await _apiServices.deleteApi(
        "${AppUrls.deleteAddress}/$addressId",
        token,
        null
        // {"addressId": addressId},
      );
      log("Response from address: $response");
    } catch (e) {
      log("Response from address: $e");
      rethrow;
    }
  }
}
