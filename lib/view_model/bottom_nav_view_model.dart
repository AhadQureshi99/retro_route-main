import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _lastBottomNavIndexKey = 'last_bottom_nav_index';

/// Tracks the currently selected bottom nav index.
/// 0 = Home, 1 = Search, 2 = Favourites, 3 = Cart, 4 = Profile
final bottomNavProvider = StateProvider<int>((ref) => 0);

/// When true, the bottom nav bar is disabled (e.g. during payment processing).
final paymentProcessingProvider = StateProvider<bool>((ref) => false);
final settingsSheetOpenProvider = StateProvider<bool>((ref) => false);

Future<void> persistBottomNavIndex(int index) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_lastBottomNavIndexKey, index);
}

Future<int> loadPersistedBottomNavIndex() async {
  final prefs = await SharedPreferences.getInstance();
  final index = prefs.getInt(_lastBottomNavIndexKey);
  return index ?? BottomNavIndex.home;
}

/// Convenience indices so callers don't use magic numbers.
class BottomNavIndex {
  static const int home = 0;
  static const int search = 1;
  static const int favourites = 2;
  static const int cart = 3;
  static const int profile = 4;
}
