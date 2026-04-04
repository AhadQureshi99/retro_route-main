import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/model/address_model.dart';
import 'package:retro_route/repository/address_repo.dart';

// ── State 
class AddressState {
  final bool isLoading;
  final List<Address> addresses;
  final String? error;
  final bool hasFetched;

  AddressState({
    this.isLoading = false,
    this.addresses = const [],
    this.error,
    this.hasFetched = false,
  });

  AddressState copyWith({
    bool? isLoading,
    List<Address>? addresses,
    String? error,
    bool? hasFetched,
  }) {
    return AddressState(
      isLoading: isLoading ?? this.isLoading,
      addresses: addresses ?? this.addresses,
      error: error,
      hasFetched: hasFetched ?? this.hasFetched,
    );
  }
}


// ── Notifier ─────────────────────────────────────────────────────────────
class AddressNotifier extends Notifier<AddressState> {
  @override
  AddressState build() => AddressState();

  Future<void> fetchAddresses(String token) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(addressRepoProvider);
      final response = await repo.getAddress(token: token);

      print("Fetched ${response.data?.length ?? 0} addresses");

      state = state.copyWith(
        isLoading: false,
        addresses: response.data ?? [],
        hasFetched: true,
        error: null,
      );
    } catch (e) {
      print("Fetch error: $e");
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> addAddress({
    required String token,
    required String addressLine,
    required String city,
    required String statess,
    required String country,
    required String postalCode,
    required String phone,
    String? fullName,
    Map<String, double>? currentLoc,
    Map<String, double>? deliveryLoc,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final repo = ref.read(addressRepoProvider);
      await repo.addAddress(
        token: token,
        fullName: fullName,
        addressLine: addressLine,
        city: city,
        state: statess,
        country: country,
        postalCode: postalCode,
        phone: phone,
        currentLoc: currentLoc,
        deliveryLoc: deliveryLoc,
      );

      await fetchAddresses(token);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateAddress({
    required String token,
    required String addressId,
    required String addressLine,
    required String city,
    required String statess,
    required String country,
    required String postalCode,
    required String phone,
    String? fullName,
    Map<String, double>? currentLoc,
    Map<String, double>? deliveryLoc,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final repo = ref.read(addressRepoProvider);
      await repo.updateAddress(
        token: token,
        addressId: addressId,
        addressLine: addressLine,
        city: city,
        state: statess,
        country: country,
        postalCode: postalCode,
        phone: phone,
        fullname: fullName ?? '',
        currentLoc: currentLoc,
        deliveryLoc: deliveryLoc,
      );

      await fetchAddresses(token);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteAddress({
    required String token,
    required String addressId,
  }) async {
    try {
      final repo = ref.read(addressRepoProvider);
      await repo.deleteAddress(token: token, addressId: addressId);

      // Optimistic remove
      state = state.copyWith(
        addresses: state.addresses.where((a) => a.safeId != addressId).toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// ── Providers ────────────────────────────────────────────────────────────
final addressRepoProvider = Provider<AddressRepo>((ref) => AddressRepo());

final addressProvider = NotifierProvider<AddressNotifier, AddressState>(
  () => AddressNotifier(),
);