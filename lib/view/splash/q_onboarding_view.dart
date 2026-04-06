import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/repository/water_test_repo.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view/splash/q_onboarding_view2.dart';
import 'package:retro_route/view/splash/q_onboarding_view3.dart';
import 'package:retro_route/view/splash/q_onboarding_view4.dart';
import 'package:retro_route/view_model/address_view_model/address_view_model.dart';
import 'package:retro_route/view_model/address_view_model/selected_delivery_address_view_model.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/bottom_nav_view_model.dart';
import 'package:retro_route/view_model/cart_view_model/cart_view_model.dart';
import 'package:retro_route/config/delivery_zones.dart';
import 'package:retro_route/view_model/selected_delivery_date_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main 5-screen orchestrator — mirrors the web OnboardingPopup design.
// Shared progress-dot header; each screen is a plain widget (no Scaffold).
// ─────────────────────────────────────────────────────────────────────────────
class QuestionOnboardingScreenOne extends ConsumerStatefulWidget {
  final int initialScreen;

  const QuestionOnboardingScreenOne({
    this.initialScreen = 0,
    super.key,
  });

  @override
  ConsumerState<QuestionOnboardingScreenOne> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<QuestionOnboardingScreenOne> {
  int _screen = 0;
  Map<String, dynamic>? _routeInfo;

  Future<void> _finishOnboardingAndGoHost() async {
    if (!mounted) return;
    final rootNav = Navigator.of(context, rootNavigator: true);
    if (rootNav.canPop()) {
      rootNav.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        goRouter.go(AppRoutes.host);
      });
      return;
    }
    goRouter.go(AppRoutes.host);
  }

  @override
  void initState() {
    super.initState();
    final start = widget.initialScreen;
    _screen = start < 0 ? 0 : (start > 4 ? 4 : start);
    if (_screen >= 4) _loadSavedRouteInfo();
  }

  Future<void> _loadSavedRouteInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('milkrun_city') ?? '';
    final savedAddress = prefs.getString('milkrun_full_address') ?? '';
    if (savedCity.isEmpty) return;
    final zone = detectZoneByCity(savedCity);
    if (zone != null && mounted) {
      // Use the date the user picked from the schedule grid (if any),
      // otherwise fall back to the next computed delivery date.
      final pickedDate = ref.read(selectedDeliveryDateProvider);
      setState(() {
        _routeInfo = {
          'zone': zone,
          'address': savedAddress.isNotEmpty ? savedAddress : savedCity,
          'nextDate': pickedDate ?? getNextDeliveryDateFromDays(zone.deliveryDays),
        };
      });
    }
  }

  void _next() {
    if (_screen < 4) setState(() => _screen++);
  }

  void _back() {
    if (_screen > 0) setState(() => _screen--);
  }

  Future<void> _close() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    await _finishOnboardingAndGoHost();
  }

  void _onRouteSelected(Map<String, dynamic> data) {
    setState(() => _routeInfo = data);
    _saveRouteInfo(data);
  }

  Future<void> _saveRouteInfo(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final zone = data['zone'];
    final address = data['address'] as String? ?? '';
    if (zone is DeliveryZone) {
      await prefs.setString('milkrun_city', zone.cities.isNotEmpty ? zone.cities.first : '');
      await prefs.setString('milkrun_full_address', address);
      await prefs.setString('milkrun_address', address);
    }
  }

  /// Creates a server-side address from onboarding data and selects it + the
  /// delivery date so checkout can pick them up.
  Future<void> _createAndSelectAddress() async {
    if (_routeInfo == null) return;
    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token == null || token.isEmpty) return;

    final street = _routeInfo!['street'] as String? ?? '';
    final city = _routeInfo!['city'] as String? ?? '';
    final postal = _routeInfo!['postal'] as String? ?? '';
    final nextDate = _routeInfo!['nextDate'] as DateTime?;
    final user = ref.read(authNotifierProvider).value?.data?.user;

    // Only create if we have at least a city
    if (city.isEmpty) return;

    try {
      final success = await ref.read(addressProvider.notifier).addAddress(
            token: token,
            addressLine: street,
            city: city,
            statess: 'ON',
            country: 'CA',
            postalCode: postal,
            phone: user?.phone ?? '',
            fullName: user?.name ?? '',
          );

      if (success) {
        final addresses = ref.read(addressProvider).addresses;
        if (addresses.isNotEmpty) {
          ref
              .read(selectedDeliveryAddressProvider.notifier)
              .selectAddress(addresses.first);
        }
      }
    } catch (e) {
      debugPrint('[Onboarding] Failed to create address: $e');
    }

    // Set the delivery date provider
    if (nextDate != null) {
      ref.read(selectedDeliveryDateProvider.notifier).state = nextDate;
      saveSelectedDeliveryDate(nextDate);
    }
  }

  Future<void> _handleBringSupplies(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    await _createAndSelectAddress();
    ref.read(bottomNavProvider.notifier).state = BottomNavIndex.home;
    await _finishOnboardingAndGoHost();
  }

  Future<void> _handleWaterTestFirst(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);

      await _createAndSelectAddress();

      // Fetch the water test product and add it to the cart
      debugPrint('[WaterTest] Fetching water test product...');
      final product = await WaterTestRepo().getWaterTestService();
      debugPrint('[WaterTest] Product fetched: ${product?.name ?? 'null'}');
      if (!mounted) {
        debugPrint('[WaterTest] Widget unmounted after fetch, aborting');
        return;
      }

      if (product != null) {
        final comingFromSupplies = data['stopType'] == 'supplies';
        await prefs.setBool(waterTestFromSuppliesKey, comingFromSupplies);

        // Remove existing water-test entries for this product id so we don't
        // end up with duplicates.
        final existingItems = ref
            .read(cartProvider)
            .items
            .where((i) => i.product.id == product.id)
            .toList();
        for (final item in existingItems) {
          ref
              .read(cartProvider.notifier)
              .remove(item.product, selectedSize: item.selectedSize);
        }

        // Always add as a paid item. The cart/checkout will automatically
        // make it free when other products are present.
        ref.read(cartProvider.notifier).add(product);

        // Option 1 (supplies + water test): go Home tab so user can add products.
        // Option 2 (book water test first): go Cart tab.
        ref.read(bottomNavProvider.notifier).state = comingFromSupplies
            ? BottomNavIndex.home
            : BottomNavIndex.cart;

        debugPrint('[WaterTest] Added to cart, items: ${ref.read(cartProvider).itemCount}');
        CustomToast.success(
          msg: 'Water test added to cart!',
        );
      } else {
        debugPrint('[WaterTest] Product was null, could not add to cart');
        CustomToast.error(msg: 'Could not load water test. Please try again.');
      }
    } catch (e, stack) {
      debugPrint('[WaterTest] Error: $e\n$stack');
      CustomToast.error(msg: 'Something went wrong. Please try again.');
    }
    // Always navigate home so user isn't stranded on onboarding
    if (mounted) await _finishOnboardingAndGoHost();
  }

  @override
  Widget build(BuildContext context) {
    final bool isHero = _screen == 0;
    return Scaffold(
      backgroundColor: isHero ? AppColors.bgColor : AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isHero),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: KeyedSubtree(
                  key: ValueKey(_screen),
                  child: _buildScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared header: back · progress dots · close ──────────────────────────
  Widget _buildHeader(bool isHero) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: Colors.transparent,
      child: Row(
        children: [
          _screen > 0
              ? GestureDetector(
                  onTap: _back,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isHero
                          ? AppColors.btnColor
                          : AppColors.btnColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 24.sp,
                      color: Colors.white ,
                    ),
                  ),
                )
              : SizedBox(width: 32.w),
          const Spacer(),
          // Progress dots (5 total, active dot widens)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final active = i == _screen;
              final done = i < _screen;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                width: active ? 24.w : 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: (active || done)
                      ? (isHero ? AppColors.primary : AppColors.primary)
                      : (isHero
                          ? AppColors.primary.withOpacity(0.35)
                          : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              );
            }),
          ),
          const Spacer(),
          // Close / skip button
          GestureDetector(
            onTap: _close,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isHero
                    ? AppColors.btnColor
                    : AppColors.btnColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 20.sp,
                color:  Colors.white ,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    switch (_screen) {
      case 0:
        return _Screen0(onNext: _next);
      case 1:
        return OnboardingContent1(onNext: _next);
      case 2:
        return OnboardingContent2(onNext: _next);
      case 3:
        return FindMilkRunContent(
          onNext: _next,
          onSelectRoute: _onRouteSelected,
          onSkip: _next,
        );
      case 4:
        return BookMyStopContent(
          routeInfo: _routeInfo,
          onBringSupplies: _handleBringSupplies,
          onWaterTestFirst: _handleWaterTestFirst,
          onBack: _back,
          onRouteChanged: _onRouteSelected,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 0  —  Hero / Splash   (mirrors web OnboardingScreen0Content)
// Full-gradient background, brand title, truck image, "WE TEST YOUR WATER",
// orange GET STARTED pill button.
// ─────────────────────────────────────────────────────────────────────────────
class _Screen0 extends StatelessWidget {
  final VoidCallback onNext;
  const _Screen0({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image fills all available space above the button — fully visible
        Expanded(
          child: Image.asset(
            'assets/images/1.png',
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),

        // Button sits below the image, never overlapping it
        Container(
          color: AppColors.bgColor,
          padding: EdgeInsets.fromLTRB(32.w, 16.h, 32.w, 32.h),
          child: GestureDetector(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
                ),
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'GET STARTED',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
