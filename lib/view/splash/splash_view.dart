import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:retro_route/model/login_model.dart';
import 'package:retro_route/model/setup_profile_model.dart';
import 'package:retro_route/repository/setup_profile_repo.dart';
import 'package:retro_route/utils/app_assets.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/services/notification_service.dart';
import 'package:retro_route/view/dashboard/dashboard_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    _initSplash();
  }

  Future<void> _initSplash() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasRegistered = prefs.getBool('has_registered') ?? false;

    if (!hasRegistered) {
      // First time user — skip splash animation, go straight to onboarding/register
      _decideNavigation();
    } else {
      // Returning user — show 3s splash animation
      Timer(const Duration(milliseconds: 3000), _decideNavigation);
    }
  }

  Future<void> _decideNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!hasSeenOnboarding) {
      if (mounted) {
        goRouter.go(AppRoutes.onboarding);
      }
      return;
    }

    // Wait until auth provider has resolved
    LoginResponse? authData;

    // Wait max ~5 seconds for auth to load (fallback to login if timeout)
    for (int i = 0; i < 25; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      final currentState = ref.read(authNotifierProvider);

      if (currentState.hasValue) {
        authData = currentState.value;
        break;
      }
      if (!mounted) return;
    }

    // Now decide based on auth and role
    if (mounted) {
      if (authData?.success == true) {
        // Navigate based on user role
        print("Session valid, user role: ${authData?.data?.user.role}");
        final role = authData?.data?.user.role ?? 'User';
        if (role.toLowerCase() == 'driver') {
          print("Navigating to DRIVER HOME because role is Driver");
          // If the app was opened from a notification tap, navigate
          // directly to the notification target screen.
          if (NotificationServices.instance.pendingNotificationData != null ||
              NotificationServices.instance.openedFromNotification ||
              await NotificationServices.hasPendingNavInPrefs()) {
            await _navigateToNotificationTarget(fallback: AppRoutes.driverHome);
            return;
          }
          goRouter.go(AppRoutes.driverHome);
        } else {
          // Check if user has completed setup
          final token = authData?.data?.token ?? '';
          final setupRepo = SetupProfileRepo();
          SetupProfileData? setupProfile;

          try {
            setupProfile = await setupRepo.getSetupProfile(token);
          } catch (_) {
            setupProfile = null;
          }

          final bool setupDone = setupProfile?.hasCompletedSetup == true;

          if (!setupDone) {
            print("Navigating to SETUP because setup not completed");
            
            goRouter.go(AppRoutes.setup);
          } else {
            print("Navigating to HOST because session is valid and setup completed");
            // If the app was opened from a notification tap, navigate
            // directly to the notification target screen.
            if (NotificationServices.instance.pendingNotificationData != null ||
                NotificationServices.instance.openedFromNotification ||
                await NotificationServices.hasPendingNavInPrefs()) {
              await _navigateToNotificationTarget(fallback: AppRoutes.host);
              return;
            }
            goRouter.go(AppRoutes.host);
          }
        }
      } else {
        print("Navigating to LOGIN because no valid session");
        goRouter.go(AppRoutes.login);
      }
    }
  }

  /// Consumes pending notification data and navigates directly to the
  /// target screen. This avoids going to /host first and relying on the
  /// dashboard to pick up the pending data (which can race with the
  /// milk-run redirect).
  Future<void> _navigateToNotificationTarget({required String fallback}) async {
    HomeDashboardScreen.suppressMilkRunForSession = true;

    var data = NotificationServices.instance.pendingNotificationData;
    NotificationServices.instance.pendingNotificationData = null;
    NotificationServices.instance.openedFromNotification = false;

    // Fallback: read from SharedPreferences if in-memory data is missing
    // (getInitialMessage() can return null on some Android devices).
    data ??= await NotificationServices.consumePendingNavFromPrefs();

    if (data != null) {
      final screen = data['screen'] as String?;
      final orderId = data['orderId'] as String?;

      switch (screen) {
        case 'OrderHistory':
          goRouter.go(AppRoutes.orderHistory);
          return;
        case 'CrateApproval':
          if (orderId != null) {
            goRouter.go('${AppRoutes.crateApproval}?orderId=$orderId');
            return;
          }
        case 'PoolReport':
          if (orderId != null) {
            goRouter.go('${AppRoutes.poolReport}?orderId=$orderId');
            return;
          }
        case 'DriverDeliveries':
        case 'DriverOrderDetail':
          goRouter.go(AppRoutes.driverHome);
          return;
      }
    }

    // Clear any prefs that might remain
    await NotificationServices.clearPendingNavFromPrefs();

    // Fallback: go to the default screen with suppression active
    goRouter.go(fallback);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Container(
        width: double.infinity,
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(
        //     begin: Alignment.topLeft,
        //     end: Alignment.bottomRight,
        //     colors: [
        //       AppColors.primary ?? Colors.deepPurple,
        //       (AppColors.primary ?? Colors.deepPurple).withOpacity(0.78),
        //     ],
        //   ),
        // ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: 320.w,
                  height: 320.w,
                  decoration: BoxDecoration(
                    // color: Colors.white,
                    borderRadius: BorderRadius.circular(32.r),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.black.withOpacity(0.28),
                    //     blurRadius: 24,
                    //     offset: const Offset(0, 12),
                    //   ),
                    // ],
                  ),
                  child: Image.asset(AppImages.logos),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
