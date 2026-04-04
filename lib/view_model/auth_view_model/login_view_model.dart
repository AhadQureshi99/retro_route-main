import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/model/login_model.dart';
import 'package:retro_route/repository/auth_repo.dart';
import 'package:retro_route/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, LoginResponse?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<LoginResponse?> {
  static const String _prefKey = 'auth_session_json';

  @override
  Future<LoginResponse?> build() async {
    return _restoreSession();
  }

  /// Try to load saved session on app start
  Future<LoginResponse?> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);

      if (jsonStr == null || jsonStr.trim().isEmpty) {
        return null;
      }

      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = LoginResponse.fromJson(jsonMap);

      // Basic validation (optional but recommended)
      if (restored.success != true || restored.data?.token?.isEmpty == true) {
        await prefs.remove(_prefKey);
        return null;
      }

      print("Session restored → user: ${restored.data?.user?.name ?? 'unknown'}");
      return restored;
    } catch (e) {
      print("Session restore failed: $e");
      return null;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(authRepoProvider);
      final response = await repo.loginAccount(email: email, password: password);

      if (response.success == true && response.data != null) {
        // Persist full response
        await _saveSession(response);
        state = AsyncData(response);
        // Update FCM token on login
        await NotificationServices.instance.saveTokenOnLogin();
      } else {
        state = AsyncError(
          Exception(response.message ?? "Login failed"),
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> _saveSession(LoginResponse response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      log("Saving session for user: ${response.data?.user?.role ?? 'unknown'}");
      final jsonStr = jsonEncode(response.toJson());
      await prefs.setString(_prefKey, jsonStr);
      // Also save user profile for compatibility
      if (response.data?.user != null) {
        final userJson = jsonEncode(response.data!.user!.toJson());
        await prefs.setString('auth_profile', userJson);
      }
    } catch (e) {
      print("Failed to save session: $e");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    state = const AsyncData(null);
  }

  Future<void> deleteAccount() async {
    final currentSession = state.value;
    if (currentSession?.data?.token == null) return;
    final token = currentSession!.data!.token;
    final repo = AuthRepo();
    await repo.deleteAccount(token: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    state = const AsyncData(null);
  }

  /// Update user profile (name & email) via API and refresh local session
  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final currentSession = state.value;
    if (currentSession == null || currentSession.data == null) {
      throw Exception("No active session");
    }

    final token = currentSession.data!.token;
    final repo = ref.read(authRepoProvider);

    await repo.updateUserDetails(name: name, email: email, token: token);

    // Build updated session with new user data
    final oldUser = currentSession.data!.user;
    final updatedUser = User(
      id: oldUser.id,
      name: name,
      email: email,
      avatar: oldUser.avatar,
      verifyEmail: oldUser.verifyEmail,
      lastLoginDate: oldUser.lastLoginDate,
      status: oldUser.status,
      role: oldUser.role,
      isAvailable: oldUser.isAvailable,
      assignedDeliveries: oldUser.assignedDeliveries,
      forgotPasswordOTP: oldUser.forgotPasswordOTP,
      forgotPasswordOTPExpires: oldUser.forgotPasswordOTPExpires,
      isOTPVerified: oldUser.isOTPVerified,
      permissions: oldUser.permissions,
      addressDetails: oldUser.addressDetails,
      shoppingCart: oldUser.shoppingCart,
      orderHistory: oldUser.orderHistory,
      createdAt: oldUser.createdAt,
      updatedAt: DateTime.now(),
      version: oldUser.version,
    );

    final updatedSession = LoginResponse(
      statusCode: currentSession.statusCode,
      message: currentSession.message,
      success: currentSession.success,
      data: LoginData(user: updatedUser, token: token),
    );

    await _saveSession(updatedSession);
    state = AsyncData(updatedSession);
  }
}

final authRepoProvider = Provider<AuthRepo>((ref) => AuthRepo());