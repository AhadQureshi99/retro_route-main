import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/repository/crate_repo.dart';

final crateRepoProvider = Provider<CrateRepo>((ref) => CrateRepo());

// ── Pending Crate state ──
class PendingCrateState {
  final bool isLoading;
  final Map<String, dynamic>? data; // { orderId, pendingCrate, waterTest }
  final String? error;

  const PendingCrateState({this.isLoading = false, this.data, this.error});
  PendingCrateState copyWith({bool? isLoading, Map<String, dynamic>? data, String? error}) =>
      PendingCrateState(
        isLoading: isLoading ?? this.isLoading,
        data: data ?? this.data,
        error: error,
      );
}

class PendingCrateNotifier extends Notifier<PendingCrateState> {
  @override
  PendingCrateState build() => const PendingCrateState();

  Future<void> fetch({required String token, required String orderId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(crateRepoProvider);
      final res = await repo.getPendingCrate(token: token, orderId: orderId);
      final payload = res['data'] as Map<String, dynamic>?;
      state = state.copyWith(isLoading: false, data: payload);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> approve({
    required String token,
    required String orderId,
    List<Map<String, dynamic>>? modifiedItems,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(crateRepoProvider);
      final res = await repo.approveCrate(token: token, orderId: orderId, modifiedItems: modifiedItems);
      state = state.copyWith(isLoading: false);
      final data = res['data'] as Map<String, dynamic>?;
      return data;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<bool> decline({required String token, required String orderId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(crateRepoProvider);
      await repo.declineCrate(token: token, orderId: orderId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final pendingCrateProvider =
    NotifierProvider<PendingCrateNotifier, PendingCrateState>(PendingCrateNotifier.new);

// ── Pool Report (simple future-based) ──
final poolReportProvider =
    FutureProvider.family<Map<String, dynamic>?, (String token, String orderId)>(
        (ref, args) async {
  final repo = ref.read(crateRepoProvider);
  final res = await repo.getPoolReport(token: args.$1, orderId: args.$2);
  return res['data'] as Map<String, dynamic>?;
});
