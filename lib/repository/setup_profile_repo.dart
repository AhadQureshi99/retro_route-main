import 'dart:developer';
import 'package:retro_route/model/setup_profile_model.dart';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';

class SetupProfileRepo {
  final _apiServices = NetworkApiServices();

  Future<SetupProfileData?> getSetupProfile(String token) async {
    try {
      final response = await _apiServices.getApi(
        AppUrls.getSetupProfile,
        token,
      );
      if (response is! Map<String, dynamic>) return null;
      final data = response['data'];
      if (data != null) {
        return SetupProfileData.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e, stack) {
      log("getSetupProfile failed", error: e, stackTrace: stack);
      return null;
    }
  }

  Future<bool> saveSetupProfile({
    required String token,
    required Map<String, dynamic> deliverySafety,
    required Map<String, dynamic> waterSetup,
  }) async {
    try {
      await _apiServices.postApi(
        {
          'deliverySafety': deliverySafety,
          'waterSetup': waterSetup,
        },
        AppUrls.saveSetupProfile,
        token,
      );
      return true;
    } catch (e, stack) {
      log("saveSetupProfile failed", error: e, stackTrace: stack);
      return false;
    }
  }

  Future<bool> updateUserDetails({
    required String token,
    required String name,
    required String email,
  }) async {
    try {
      await _apiServices.putApi(
        {'name': name, 'email': email},
        AppUrls.updateUserDetails,
        token,
      );
      return true;
    } catch (e, stack) {
      log("updateUserDetails failed", error: e, stackTrace: stack);
      return false;
    }
  }
}
