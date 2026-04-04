import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/model/forgotresponse_model.dart';
import 'package:retro_route/repository/auth_repo.dart';

final forgotPasswordProvider =
    AsyncNotifierProvider<ForgotNotifier, ForgotResponse?>(() {
  return ForgotNotifier();
});

class ForgotNotifier extends AsyncNotifier<ForgotResponse?> {
  @override
  Future<ForgotResponse?> build() => Future.value(null);

  Future<void> sendOtp(String email) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepoProvider);
      final res = await repo.forgotPassword(email: email);
      if (res.success) {
        state = AsyncData(res);
      } else {
        state = AsyncError(Exception(res.message), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepoProvider);
      final res = await repo.forgotPasswordOtpVerify(email: email, otp: otp);
      if (res.success) {
        state = AsyncData(res);
      } else {
        state = AsyncError(Exception(res.message), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> resetPassword(
    String email,
    String newPassword,
    String confirmPassword,
  ) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepoProvider);
      final res = await repo.forgotResetPassword(
        email: email,
        newPassword: newPassword,
 );
      if (res.success) {
        state = AsyncData(res);
      } else {
        state = AsyncError(Exception(res.message), StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void resetState() {
    state = const AsyncData(null);
  }
}

// Repo provider (if not already)
final authRepoProvider = Provider<AuthRepo>((ref) => AuthRepo());