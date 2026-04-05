// ── Selected Address Provider ───────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:retro_route/model/address_model.dart';
import 'package:retro_route/view_model/address_view_model/address_view_model.dart';

final selectedDeliveryAddressProvider = StateNotifierProvider<
    SelectedAddressNotifier, Address?>(
  (ref) => SelectedAddressNotifier(ref),
);

class SelectedAddressNotifier extends StateNotifier<Address?> {
  final Ref ref;

  SelectedAddressNotifier(this.ref) : super(null) {
    // Keep selected address in sync with current address list.
    ref.listen(addressProvider, (previous, next) {
      final addresses = next.addresses;

      // If there are no addresses, clear selection immediately.
      if (addresses.isEmpty) {
        if (state != null) state = null;
        return;
      }

      // Auto-select first available address when nothing is selected.
      if (state == null) {
        state = addresses.first;
        return;
      }

      // If selected address was deleted, fall back to first valid address.
      // If it still exists, refresh with the latest copy (handles edits).
      final freshCopy = addresses.cast<Address?>().firstWhere(
        (a) => a!.safeId == state!.safeId,
        orElse: () => null,
      );
      if (freshCopy == null) {
        state = addresses.first;
      } else {
        state = freshCopy;
      }
    });
  }

  void selectAddress(Address? address) {
    state = address;
  }

  void clearSelection() {
    state = null;
  }
}