import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/utils/app_assets.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/auth_helper.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/cart_view_model/cart_view_model.dart';
import 'package:retro_route/view_model/favourite_view_model/favourite_view_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthHelper.isLoggedIn(ref);
       final cart = ref.watch(cartProvider);
    final itemCount = cart.itemCount;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70.h,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
      
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              AppImages.logos,
              height: 70.h,
              fit: BoxFit.contain,
            ),
          ],
        ),
        actions: [
          // Cart
          GestureDetector(
            onTap: () => goRouter.push(AppRoutes.cart),
            child: Container(
              margin: EdgeInsets.only(right: 4.w),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    itemCount > 0
                        ? Icons.shopping_bag_rounded
                        : Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 26.sp,
                  ),
                  if (itemCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: const BoxDecoration(
                          color: Color(0xffef4444),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$itemCount',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Notifications
          GestureDetector(
            onTap: () => context.go(AppRoutes.notifications),
            child: Container(
              margin: EdgeInsets.only(right: 16.w),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 26.sp,
              ),
            ),
          ),
        ],
      ),
    
      body: isLoggedIn ? _buildLoggedInBody() : _buildGuestBody(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GUEST
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGuestBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                        radius: 60.r,
                        backgroundColor: AppColors.cardBgColor,
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 70.sp,
                          color: AppColors.btnColor,
                        ),
                      )
                      .animate()
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                        duration: 900.ms,
                      )
                      .fadeIn(delay: 300.ms),
                  verticalSpacer(height: 24.h),
                  customText(
                    text: "Welcome, Guest!",
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ).animate().fadeIn(delay: 400.ms),
                  verticalSpacer(height: 12.h),
                  customText(
                    text:
                        "Sign in to access your profile,\norders, and favorites",
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 500.ms),
                  verticalSpacer(height: 40.h),
                  customButton(
                    context: context,
                    text: "Log In",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontColor: Colors.white,
                    bgColor: AppColors.btnColor,
                    borderColor: Colors.transparent,
                    borderRadius: 16,
                    height: 56,
                    width: double.infinity,
                    isCircular: false,
                    onPressed: () => goRouter.push(AppRoutes.login),
                  ).animate().fadeIn(delay: 600.ms),
                  verticalSpacer(height: 16.h),
                  customButton(
                    context: context,
                    text: "Create Account",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontColor: AppColors.btnColor,
                    bgColor: Colors.transparent,
                    borderColor: AppColors.btnColor,
                    borderRadius: 16,
                    height: 56,
                    width: double.infinity,
                    isCircular: false,
                    onPressed: () => goRouter.push(AppRoutes.register),
                  ).animate().fadeIn(delay: 700.ms),
                  verticalSpacer(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => goRouter.push(AppRoutes.termsConditions),
                        child: customText(
                          text: 'Terms & Conditions',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.btnColor,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.btnColor,
                        ),
                      ),
                      horizontalSpacer(width: 10),
                      customText(
                        text: '|',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500]!,
                      ),
                      horizontalSpacer(width: 10),
                      GestureDetector(
                        onTap: () => goRouter.push(AppRoutes.privacyPolicy),
                        child: customText(
                          text: 'Privacy Policy',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.btnColor,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.btnColor,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 760.ms),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOGGED IN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLoggedInBody() {
    final user = ref.watch(authNotifierProvider).value;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Column(
        children: [
          // ── Purple header ──
          Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 32.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30.r),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                          radius: 45.r,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 50.sp,
                            color: AppColors.primary,
                          ),
                        )
                        .animate()
                        .scale(
                          begin: Offset(0.6, 0.6),
                          end: Offset(1.0, 1.0),
                          curve: Curves.easeOutBack,
                          duration: 900.ms,
                        )
                        .fadeIn(delay: 300.ms),
                    verticalSpacer(height: 12),
                    customText(
                          text: user?.data?.user.name ?? '',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .slideY(begin: 0.3, end: 0),
                    verticalSpacer(height: 4),
                    customText(
                      text: user?.data?.user.email ?? '',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 100.ms, duration: 800.ms)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

          verticalSpacer(height: 20),

          // ── Menu tiles ──
          _profileTile(
            icon: Icons.person_outline,
            title: "My Profile",
            onTap: () => goRouter.push(AppRoutes.myProfile),
          ).animate().slideX(
            begin: -0.4,
            end: 0,
            delay: 300.ms,
            duration: 600.ms,
            curve: Curves.easeOutCubic,
          ),
          _profileTile(
            icon: Icons.location_on_outlined,
            title: "Delivery Address",
            onTap: () => goRouter.push(AppRoutes.myAddress),
          ).animate().slideX(
            begin: -0.4,
            end: 0,
            delay: 400.ms,
            duration: 600.ms,
            curve: Curves.easeOutCubic,
          ),
          _profileTile(
            icon: Icons.favorite_border,
            title: "My Wishlist",
            onTap: () => goRouter.push(AppRoutes.favourite),
          ).animate().slideX(
            begin: -0.4,
            end: 0,
            delay: 500.ms,
            duration: 600.ms,
            curve: Curves.easeOutCubic,
          ),
          _profileTile(
            icon: Icons.shopping_bag_outlined,
            title: "My Orders",
            onTap: () => goRouter.push(AppRoutes.orderHistory),
          ).animate().slideX(
            begin: -0.4,
            end: 0,
            delay: 600.ms,
            duration: 600.ms,
            curve: Curves.easeOutCubic,
          ),
          _profileTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () => goRouter.push(AppRoutes.termsConditions),
          ).animate().slideX(
            begin: -0.4,
            end: 0,
            delay: 650.ms,
            duration: 600.ms,
            curve: Curves.easeOutCubic,
          ),
          _profileTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => goRouter.push(AppRoutes.privacyPolicy),
          ).animate().slideX(
            begin: -0.4,
            end: 0,
            delay: 680.ms,
            duration: 600.ms,
            curve: Curves.easeOutCubic,
          ),
          _profileTile(
            icon: Icons.settings_outlined,
            title: "Settings",
            onTap: () => _showSettingsSheet(context, ref),
          ).animate().slideX(
            begin: -0.4,
            end: 0,
            delay: 710.ms,
            duration: 600.ms,
            curve: Curves.easeOutCubic,
          ),
          _profileTile(
            icon: Icons.logout,
            title: "Logout",
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () => _showLogoutDialog(context, ref),
          ).animate().slideX(
            begin: -0.4,
            end: 0,
            delay: 740.ms,
            duration: 600.ms,
            curve: Curves.easeOutCubic,
          ),

          verticalSpacer(height: 130),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _profileTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 24.sp, color: iconColor ?? AppColors.primary),
              SizedBox(width: 16.w),
              Expanded(
                child: customText(
                  text: title,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? Colors.black87,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              verticalSpacer(height: 16.h),
              customText(
                text: "Settings",
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              verticalSpacer(height: 8.h),
              Divider(color: Colors.grey[200]),
              verticalSpacer(height: 8.h),
              customText(
                text: "Account",
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              verticalSpacer(height: 8.h),
              InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showDeleteAccountDialog(context, ref);
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever_rounded,
                          size: 24.sp, color: Colors.red),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: customText(
                          text: "Delete Account",
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 16.sp, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              verticalSpacer(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
                elevation: 16,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 60.sp,
                        color: Colors.red[600],
                      ).animate().scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.easeOutBack,
                        duration: 700.ms,
                      ),
                      verticalSpacer(height: 16.h),
                      customText(
                        text: "Delete Account",
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ).animate().fadeIn(delay: 200.ms),
                      verticalSpacer(height: 12.h),
                      customText(
                        text:
                            "Do you want to permanently delete your account?",
                        fontSize: 16.sp,
                        color: Colors.grey,
                        textAlign: TextAlign.center,
                        fontWeight: FontWeight.w500,
                      ).animate().fadeIn(delay: 300.ms),
                      verticalSpacer(height: 32.h),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: customButton(
                              context: context,
                              text: isDeleting
                                  ? "Deleting..."
                                  : "Yes, Delete My Account",
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              fontColor: Colors.white,
                              bgColor: Colors.red,
                              borderRadius: 16.r,
                              height: 50.h,
                              onPressed: isDeleting
                                  ? () {}
                                  : () async {
                                      setDialogState(
                                          () => isDeleting = true);
                                      try {
                                        await ref
                                            .read(authNotifierProvider
                                                .notifier)
                                            .deleteAccount();
                                        ref.invalidate(
                                            favoritesProvider);
                                        if (dialogContext.mounted) {
                                          Navigator.pop(
                                              dialogContext);
                                        }
                                        goRouter.go(AppRoutes.login);
                                      } catch (e) {
                                        setDialogState(
                                            () => isDeleting = false);
                                        if (dialogContext.mounted) {
                                          Navigator.pop(
                                              dialogContext);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Failed to delete account. Please try again.'),
                                              backgroundColor:
                                                  Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              borderColor: Colors.red,
                              isCircular: false,
                            ).animate().scale(delay: 400.ms),
                          ),
                          verticalSpacer(height: 12.h),
                          SizedBox(
                            width: double.infinity,
                            child: customButton(
                              context: context,
                              text: "No, Keep My Account",
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              fontColor: Colors.grey[700]!,
                              bgColor: Colors.grey[200]!,
                              borderRadius: 16.r,
                              height: 50.h,
                              onPressed: () =>
                                  Navigator.pop(dialogContext),
                              borderColor: Colors.grey,
                              isCircular: false,
                            ).animate().scale(delay: 500.ms),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOutBack,
                duration: 500.ms,
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child:
              Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.r),
                ),
                elevation: 16,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 60.sp,
                        color: Colors.red[600],
                      ).animate().scale(
                        begin: Offset(0.5, 0.5),
                        end: Offset(1.0, 1.0),
                        curve: Curves.easeOutBack,
                        duration: 700.ms,
                      ),
                      verticalSpacer(height: 16.h),
                      customText(
                        text: "Logout",
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ).animate().fadeIn(delay: 200.ms),
                      verticalSpacer(height: 12.h),
                      customText(
                        text: "Are you sure you want to logout?",
                        fontSize: 16.sp,
                        color: Colors.grey,
                        textAlign: TextAlign.center,
                        fontWeight: FontWeight.w500,
                      ).animate().fadeIn(delay: 300.ms),
                      verticalSpacer(height: 32.h),
                      Row(
                        children: [
                          Expanded(
                            child: customButton(
                              context: context,
                              text: "Cancel",
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              fontColor: Colors.grey,
                              bgColor: Colors.grey[200]!,
                              borderRadius: 16.r,
                              height: 50.h,
                              onPressed: () => Navigator.pop(dialogContext),
                              borderColor: Colors.grey,
                              isCircular: false,
                            ).animate().scale(delay: 400.ms),
                          ),
                          horizontalSpacer(width: 16.w),
                          Expanded(
                            child: customButton(
                              context: context,
                              text: "Logout",
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              fontColor: Colors.white,
                              bgColor: Colors.red,
                              borderRadius: 16.r,
                              height: 50.h,
                              onPressed: () {
                                ref
                                    .read(authNotifierProvider.notifier)
                                    .logout();
                                ref.invalidate(favoritesProvider);
                                Navigator.pop(dialogContext);
                                goRouter.go(AppRoutes.login);
                              },
                              borderColor: Colors.red,
                              isCircular: false,
                            ).animate().scale(delay: 500.ms),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().scale(
                begin: Offset(0.7, 0.7),
                end: Offset(1.0, 1.0),
                curve: Curves.easeOutBack,
                duration: 500.ms,
              ),
        );
      },
    );
  }
}
