import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSelectedDeliveryDate = 'selected_delivery_date';
const _kAddressDeliveryDatePrefix = 'address_delivery_date_';

/// Holds the delivery date the user explicitly chose in the Milk Run dialog.
/// When non-null, checkout uses this instead of auto-computing from the zone.
final selectedDeliveryDateProvider = StateProvider<DateTime?>((ref) => null);

/// Persist the selected delivery date to SharedPreferences.
Future<void> saveSelectedDeliveryDate(DateTime date) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kSelectedDeliveryDate, date.toIso8601String());
}

/// Load the persisted delivery date. Returns null if none saved or if it's in the past.
Future<DateTime?> loadSelectedDeliveryDate() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kSelectedDeliveryDate);
  if (raw == null) return null;
  final date = DateTime.tryParse(raw);
  if (date == null) return null;
  // Only return if the date is today or in the future
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (date.isBefore(today)) {
    await prefs.remove(_kSelectedDeliveryDate);
    return null;
  }
  return date;
}

/// Clear the persisted delivery date.
Future<void> clearSelectedDeliveryDate() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kSelectedDeliveryDate);
}

// ── Per-address delivery date persistence ─────────────────────────────────

/// Save a delivery date for a specific address.
Future<void> saveAddressDeliveryDate(String addressId, DateTime date) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('$_kAddressDeliveryDatePrefix$addressId', date.toIso8601String());
}

/// Load the delivery date for a specific address.
/// Returns null if none saved or if it's in the past.
Future<DateTime?> loadAddressDeliveryDate(String addressId) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('$_kAddressDeliveryDatePrefix$addressId');
  if (raw == null) return null;
  final date = DateTime.tryParse(raw);
  if (date == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (date.isBefore(today)) {
    await prefs.remove('$_kAddressDeliveryDatePrefix$addressId');
    return null;
  }
  return date;
}

/// Remove the delivery date for a specific address.
Future<void> clearAddressDeliveryDate(String addressId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('$_kAddressDeliveryDatePrefix$addressId');
}
