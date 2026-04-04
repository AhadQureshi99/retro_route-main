// components/custom_bottom_navigation.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/view/cart/cart_view.dart';
import 'package:retro_route/view/dashboard/dashboard_view.dart';
import 'package:retro_route/view/favourite/favourite_view.dart';
import 'package:retro_route/view/profile/profile_view.dart';
import 'package:retro_route/view/search/search_view.dart';
import 'package:retro_route/view_model/bottom_nav_view_model.dart';

class HostView extends ConsumerWidget {
  const HostView({super.key});

  static const List<Widget> _screens = [
    HomeDashboardScreen(),
    SearchScreen(),
    FavouriteScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavProvider);
    return _screens[selectedIndex];
  }
}
