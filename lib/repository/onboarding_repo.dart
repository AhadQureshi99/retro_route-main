import 'dart:developer';
import 'package:retro_route/services/data/network_api_services.dart';
import 'package:retro_route/utils/app_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepo {
  final _apiServices = NetworkApiServices();

  static const String _onboardingCompletedKey = 'retroroute_onboarding_completed';
  static const String _onboardingDataKey = 'retroroute_onboarding_data';

  /// Check onboarding status from backend API
  Future<bool> checkOnboardingStatus(String token) async {
    try {
      final response = await _apiServices.getApi(
        AppUrls.onboardingStatus,
        token,
      );
      log("Onboarding status response: $response");

      final data = response['data'] ?? {};
      final hasCompleted = data['hasCompletedOnboarding'] ?? false;
      return hasCompleted;
    } catch (e) {
      log("Error fetching onboarding status from API: $e");
      // Fallback to local storage
      return await checkLocalOnboardingStatus();
    }
  }

  /// Check onboarding status from local storage (fallback)
  Future<bool> checkLocalOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Mark onboarding as completed via backend API + local storage
  Future<void> completeOnboarding({
    required String token,
    Map<String, dynamic>? zone,
    String? dropOffSpot,
    String? accessNotes,
    String? preferredStopType,
    Map<String, dynamic>? notifications,
    String? selectedDeliveryDate,
  }) async {
    try {
      await _apiServices.postApi(
        {
          if (zone != null) 'zone': zone,
          if (dropOffSpot != null) 'dropOffSpot': dropOffSpot,
          if (accessNotes != null) 'accessNotes': accessNotes,
          if (preferredStopType != null) 'preferredStopType': preferredStopType,
          if (notifications != null) 'notifications': notifications,
          if (selectedDeliveryDate != null) 'selectedDeliveryDate': selectedDeliveryDate,
        },
        AppUrls.onboardingComplete,
        token,
      );
      log("Onboarding completed via API");
    } catch (e) {
      log("Error completing onboarding via API: $e");
    }

    // Always save locally as fallback
    await _markLocalOnboardingCompleted();
  }

  /// Mark onboarding completed locally only
  Future<void> _markLocalOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Mark local onboarding completed (public, for skip scenarios)
  Future<void> markLocalCompleted() async {
    await _markLocalOnboardingCompleted();
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding(String? token) async {
    try {
      if (token != null) {
        await _apiServices.postApi({}, AppUrls.onboardingReset, token);
      }
    } catch (e) {
      log("Error resetting onboarding via API: $e");
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompletedKey);
    await prefs.remove(_onboardingDataKey);
  }
}
