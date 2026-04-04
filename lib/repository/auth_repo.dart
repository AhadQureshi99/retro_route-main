import 'dart:developer';
import 'package:retro_route/model/forgotresponse_model.dart';
import 'package:retro_route/model/login_model.dart';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';

class AuthRepo {
  final _apiServices = NetworkApiServices();

  Future<void> registerAccount({
    required String userName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _apiServices.postApi(
        {"email": email, "name": userName, "phone": phone, "password": password},
        AppUrls.createAccount,
        null,
      );
      log("Response from login: $response");
    } catch (e) {
      log("Response from login: $e");
      rethrow;
    }
  }

  Future<void> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiServices.postApi(
        {"email": email, "otp": otp},
        AppUrls.verifyOtp,
        null,
      );
      log("Response from verity otp: $response");
    } catch (e) {
      log("Response from login: $e");
      rethrow;
    }
  }

  Future<void> resendRegistrationOtp({required String email}) async {
    try {
      await _apiServices.postApi(
        {"email": email},
        AppUrls.resendRegistrationOtp,
        null,
      );
    } catch (e) {
      log("Error resending OTP: $e");
      rethrow;
    }
  }

  Future<LoginResponse> loginAccount({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiServices.postApi(
        {"email": email, "password": password},
        AppUrls.loginAccount,
        null,
      );
      log("Response from login: $response");
      return LoginResponse.fromJson(response);
    } catch (e) {
      log("Response from login: $e");
      rethrow;
    }
  }

  Future<ForgotResponse> forgotPassword({required String email}) async {
    try {
      final response = await _apiServices.putApi(
        {"email": email},
        AppUrls.forgotpassword,
        null,
      );
      log("Response from forgot password: $response");
      return ForgotResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      log("Response from forgotpassword: $e");
      rethrow;
    }
  }

  Future<ForgotResponse> forgotPasswordOtpVerify({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _apiServices.putApi(
        {"email": email, "otp": otp},
        AppUrls.forgotPasswordOtpVerify,
        null,
      );
      log("Response from forgot password: $response");
      return ForgotResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      log("Response from forgotpassword: $e");
      rethrow;
    }
  }

  Future<ForgotResponse> forgotResetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await _apiServices.putApi(
        {
          "email": email,
          "newPassword": newPassword,
          "confirmPassword": newPassword,
        },
        AppUrls.resetPassword,
        null,
      );
      log("Response from reset password: $response");
      return ForgotResponse.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      log("Response from resetpassword: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUserDetails({
    required String name,
    required String email,
    required String token,
  }) async {
    try {
      final response = await _apiServices.putApi(
        {"name": name, "email": email},
        AppUrls.updateUserDetails,
        token,
      );
      log("Response from update user details: $response");
      return response as Map<String, dynamic>;
    } catch (e) {
      log("Error updating user details: $e");
      rethrow;
    }
  }

  Future<void> deleteAccount({required String token}) async {
    try {
      final response = await _apiServices.deleteApi(
        AppUrls.deleteAccount,
        token,
        null,
      );
      log("Response from delete account: $response");
    } catch (e) {
      log("Error deleting account: $e");
      rethrow;
    }
  }
}
