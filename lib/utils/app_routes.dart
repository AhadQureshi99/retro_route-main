import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:retro_route/model/driver_delivery_model.dart';
import 'package:retro_route/model/product_model.dart';
import 'package:retro_route/view/address/address_view.dart';
import 'package:retro_route/view/auth/forgot_otp_verification_view.dart';
import 'package:retro_route/view/auth/forgot_password_view.dart';
import 'package:retro_route/view/auth/login_view.dart';
import 'package:retro_route/view/auth/otp_verification_view.dart';
import 'package:retro_route/view/auth/register_view.dart';
import 'package:retro_route/view/auth/reset_password_view.dart';
import 'package:retro_route/view/auth/setup/post_signup_setup_screen.dart';
import 'package:retro_route/view/cart/cart_view.dart';
import 'package:retro_route/view/checkout/change_delivery_date_view.dart';
import 'package:retro_route/view/checkout/checkout_view.dart';
import 'package:retro_route/view/checkout/order_success_view.dart';
import 'package:retro_route/view/customer/crate_approval_screen.dart';
import 'package:retro_route/view/customer/pool_report_screen.dart';
import 'package:retro_route/view/dashboard/dashboard_view.dart';
import 'package:retro_route/view/driver/driver_crate_view.dart';
import 'package:retro_route/view/driver/driver_deliver_view.dart';
import 'package:retro_route/view/driver/driver_eod_view.dart';
import 'package:retro_route/view/driver/driver_home_view.dart';
import 'package:retro_route/view/driver/driver_order_detail_view.dart';
import 'package:retro_route/view/driver/driver_route_view.dart';
import 'package:retro_route/view/driver/driver_water_test_view.dart';
import 'package:retro_route/view/favourite/favourite_view.dart';
import 'package:retro_route/view/host/app_shell.dart';
import 'package:retro_route/view/host/host_view.dart';
import 'package:retro_route/view/order/orderhistory_view.dart';
import 'package:retro_route/view/product/product_details_view.dart';
import 'package:retro_route/view/profile/editprofile_view.dart';
import 'package:retro_route/view/profile/my_profile_view.dart';
import 'package:retro_route/view/profile/legal/privacy_policy_view.dart';
import 'package:retro_route/view/profile/legal/terms_conditions_view.dart';
import 'package:retro_route/view/splash/q_onboarding_view.dart';
import 'package:retro_route/view/splash/q_onboarding_view3.dart';
import 'package:retro_route/view/splash/splash_view.dart';
import 'package:retro_route/view/notification/notification_view.dart';

class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const login = '/login';
  static const otp = '/otp';
  static const register = '/register';
  static const forgotPassword = '/forgot';
  static const forgotOtp = '/forgototp';
  static const resetPassword = '/resetpassword';
  static const dashboard = '/dashboard';
  static const host = '/host';
  static const favourite = '/favourite';
  static const myAddress = '/address';
  static const productdetails = '/productdetails';
  static const orderHistory = '/orderHistory';
  static const editProfle = '/editProfle';
  static const myProfile = '/myProfile';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const success = '/success';
  static const driverHome = '/driver-home';
  static const driverOrderDetail = '/driver-order-detail';
  static const driverRoute = '/driver-route';
  static const driverWaterTest = '/driver-water-test';
  static const driverCrate = '/driver-crate';
  static const driverDeliver = '/driver-deliver';
  static const driverEod = '/driver-eod';
  static const onboarding4 = '/onboarding-4';
  static const onboarding3 = '/onboarding-3';
  static const setup = '/setup';
  static const termsConditions = '/terms-conditions';
  static const privacyPolicy = '/privacy-policy';
  static const deliverySafety = '/delivery-safety';
  static const crateApproval = '/crate-approval';
  static const poolReport = '/pool-report';
  static const notifications = '/notifications';
  static const changeDeliveryDate = '/change-delivery-date';
}

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    // ── Routes WITHOUT bottom nav ──────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) {
        final screen = int.tryParse(state.uri.queryParameters['screen'] ?? '') ?? 0;
        return QuestionOnboardingScreenOne(initialScreen: screen);
      },
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => SignUpScreen(),
    ),
    GoRoute(path: AppRoutes.login, builder: (context, state) => LoginScreen()),
    GoRoute(
      path: AppRoutes.onboarding3,
      builder: (context, state) => FindMilkRunScreen(),
    ),
    GoRoute(
      path: AppRoutes.setup,
      builder: (context, state) => const PostSignupSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Map<String, String>) {
          return OtpVerificationScreen(
            email: extra['email'] ?? '',
            password: extra['password'],
          );
        }
        return OtpVerificationScreen(email: extra as String);
      },
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordEmailScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotOtp,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return ForgotPasswordOtpVerificationScreen(email: email);
      },
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return ResetPasswordScreen(email: email);
      },
    ),
    GoRoute(
      path: AppRoutes.termsConditions,
      builder: (context, state) => const TermsConditionsScreen(),
    ),
    GoRoute(
      path: AppRoutes.privacyPolicy,
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),

    // ── Routes WITH bottom nav (ShellRoute) ────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        // Customer routes
        GoRoute(path: AppRoutes.host, builder: (context, state) => const HostView()),
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => HomeDashboardScreen(),
        ),
        GoRoute(path: AppRoutes.cart, builder: (context, state) => CartScreen()),
        GoRoute(
          path: AppRoutes.productdetails,
          builder: (context, state) {
            final product = state.extra as Product;
            return ProductDetailScreen(product: product);
          },
        ),
        GoRoute(
          path: AppRoutes.checkout,
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: AppRoutes.success,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            log("our order reponseis $extra");
            return OrderSuccessScreen(
              orderId: extra?['orderId'] as String?,
              orderNumber: extra?['orderNumber'] as String?,
              deliveryDate: extra?['deliveryDate'] as DateTime?,
              deliveryZone: extra?['deliveryZone'] as String?,
              deliveryAddress: extra?['deliveryAddress'] as String?,
              total: extra?['total'] as double?,
              customerName: extra?['customerName'] as String?,
              customerPhone: extra?['customerPhone'] as String?,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.favourite,
          builder: (context, state) => FavouriteScreen(),
        ),
        GoRoute(
          path: AppRoutes.myAddress,
          builder: (context, state) => AddressesScreen(),
        ),
        GoRoute(
          path: AppRoutes.orderHistory,
          builder: (context, state) => OrderHistoryScreen(),
        ),
        GoRoute(
          path: AppRoutes.editProfle,
          builder: (context, state) => EditProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.myProfile,
          builder: (context, state) => const MyProfileScreen(),
        ),

        GoRoute(
          path: AppRoutes.crateApproval,
          builder: (context, state) {
            final orderId = state.uri.queryParameters['orderId'] ?? '';
            return CrateApprovalScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: AppRoutes.poolReport,
          builder: (context, state) {
            final orderId = state.uri.queryParameters['orderId'] ?? '';
            return PoolReportScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => const NotificationView(),
        ),
        GoRoute(
          path: AppRoutes.changeDeliveryDate,
          builder: (context, state) => const ChangeDeliveryDateScreen(),
        ),

      ],
    ),

    // ── Driver routes WITHOUT bottom nav ───────────────────
    GoRoute(
      path: AppRoutes.driverHome,
      builder: (context, state) => const DriverHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverOrderDetail,
      builder: (context, state) {
        final delivery = state.extra as DriverDelivery;
        return DriverOrderDetailScreen(delivery: delivery);
      },
    ),
    GoRoute(
      path: AppRoutes.driverRoute,
      builder: (context, state) => const DriverRouteScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverWaterTest,
      builder: (context, state) {
        final delivery = state.extra as DriverDelivery;
        return DriverWaterTestScreen(delivery: delivery);
      },
    ),
    GoRoute(
      path: AppRoutes.driverCrate,
      builder: (context, state) {
        final delivery = state.extra as DriverDelivery;
        return DriverCrateScreen(delivery: delivery);
      },
    ),
    GoRoute(
      path: AppRoutes.driverDeliver,
      builder: (context, state) {
        final delivery = state.extra as DriverDelivery;
        return DriverDeliverScreen(delivery: delivery);
      },
    ),
    GoRoute(
      path: AppRoutes.driverEod,
      builder: (context, state) => const DriverEodScreen(),
    ),
  ],
);
