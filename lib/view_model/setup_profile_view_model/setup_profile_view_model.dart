import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/model/setup_profile_model.dart';
import 'package:retro_route/repository/setup_profile_repo.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';

final setupProfileRepoProvider = Provider((ref) => SetupProfileRepo());

final setupProfileProvider =
    AsyncNotifierProvider<SetupProfileNotifier, SetupProfileData?>(
  SetupProfileNotifier.new,
);

class SetupProfileNotifier extends AsyncNotifier<SetupProfileData?> {
  @override
  Future<SetupProfileData?> build() async {
    final auth = ref.watch(authNotifierProvider).value;
    final token = auth?.data?.token;
    if (token == null || token.isEmpty) return null;
    final repo = ref.read(setupProfileRepoProvider);
    return repo.getSetupProfile(token);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<bool> saveDelivery(DeliverySafety delivery) async {
    final auth = ref.read(authNotifierProvider).value;
    final token = auth?.data?.token;
    if (token == null) return false;

    final repo = ref.read(setupProfileRepoProvider);
    final currentWater = state.value?.waterSetup ?? WaterSetup();

    final success = await repo.saveSetupProfile(
      token: token,
      deliverySafety: delivery.toJson(),
      waterSetup: currentWater.toJson(),
    );

    if (success) ref.invalidateSelf();
    return success;
  }

  Future<bool> saveWater(WaterSetup water) async {
    final auth = ref.read(authNotifierProvider).value;
    final token = auth?.data?.token;
    if (token == null) return false;

    final repo = ref.read(setupProfileRepoProvider);
    final currentDelivery = state.value?.deliverySafety ?? DeliverySafety();

    final success = await repo.saveSetupProfile(
      token: token,
      deliverySafety: currentDelivery.toJson(),
      waterSetup: water.toJson(),
    );

    if (success) ref.invalidateSelf();
    return success;
  }

  Future<bool> updateUserDetails({
    required String name,
    required String email,
  }) async {
    final auth = ref.read(authNotifierProvider).value;
    final token = auth?.data?.token;
    if (token == null) return false;

    final repo = ref.read(setupProfileRepoProvider);
    return repo.updateUserDetails(token: token, name: name, email: email);
  }
}
