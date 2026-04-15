import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/view_model/bottom_nav_view_model.dart';
import 'package:retro_route/view_model/cart_view_model/cart_view_model.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavProvider);
    final cartItemCount = ref.watch(cartProvider).itemCount;
    final isProcessingPayment = ref.watch(paymentProcessingProvider);
    final isSettingsSheetOpen = ref.watch(settingsSheetOpenProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: child,
      bottomNavigationBar: IgnorePointer(
        ignoring: isProcessingPayment || isSettingsSheetOpen,
        child: SafeArea(
        child: CurvedNavigationBar(
          index: selectedIndex,
          backgroundColor: AppColors.bgColor,
          color: AppColors.primary,
          buttonBackgroundColor: AppColors.primary,
          animationDuration: const Duration(milliseconds: 300),
          animationCurve: Curves.easeInOut,
          height: 50,
          onTap: (index) {
            // Close any open dialogs/popups before navigating
            Navigator.of(context, rootNavigator: true).popUntil((route) => route is! DialogRoute && route is! PopupRoute);
            ref.read(bottomNavProvider.notifier).state = index;
            persistBottomNavIndex(index);
            context.go(AppRoutes.host);
          },
          items: [
            const Icon(Icons.home, size: 30, color: Colors.white),
            const Icon(Icons.storefront, size: 30, color: Colors.white),
            const Icon(Icons.favorite_outline, size: 30, color: Colors.white),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(cartItemCount > 0 ? Icons.shopping_bag_rounded : Icons.shopping_bag_outlined, size: 30, color: Colors.white),
                if (cartItemCount > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
                      decoration: const BoxDecoration(
                        color: AppColors.btnColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$cartItemCount',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Icon(Icons.person, size: 30, color: Colors.white),
          ],
        ),
      ),
      ),
    );
  }
}
