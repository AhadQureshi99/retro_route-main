// providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:retro_route/repository/auth_repo.dart';

final authRepositoryProvider = Provider<AuthRepo>((ref) {
  return AuthRepo();
});

final registerProvider = StateNotifierProvider<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier(ref.read(authRepositoryProvider));
});

class RegisterNotifier extends StateNotifier<RegisterState> {
  final AuthRepo _authRepo;
  
  RegisterNotifier(this._authRepo) : super(RegisterState.initial());
  
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authRepo.registerAccount(
        userName: name,
        email: email,
        phone: phone,
        password: password,
      );
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        email: email,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  void reset() {
    state = RegisterState.initial();
  }
}

class RegisterState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final String? email;
  
  RegisterState({
    required this.isLoading,
    required this.isSuccess,
    this.error,
    this.email,
  });
  
  RegisterState.initial()
      : isLoading = false,
        isSuccess = false,
        error = null,
        email = null;
  
  RegisterState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    String? email,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
      email: email ?? this.email,
    );
  }
}