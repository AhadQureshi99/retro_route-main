import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/config/delivery_zones.dart';
import 'package:retro_route/model/setup_profile_model.dart';
import 'package:retro_route/repository/setup_profile_repo.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view/auth/setup/delivery_safety_screen.dart';
import 'package:retro_route/view/auth/setup/water_setup_screen.dart';
import 'package:retro_route/view/dashboard/dashboard_view.dart';
import 'package:retro_route/view_model/address_view_model/address_view_model.dart';
import 'package:retro_route/view_model/address_view_model/selected_delivery_address_view_model.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/bottom_nav_view_model.dart';
import 'package:retro_route/view_model/selected_delivery_date_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostSignupSetupScreen extends ConsumerStatefulWidget {
  const PostSignupSetupScreen({super.key});

  @override
  ConsumerState<PostSignupSetupScreen> createState() => _PostSignupSetupScreenState();
}

class _PostSignupSetupScreenState extends ConsumerState<PostSignupSetupScreen> {
  int _currentStep = 1;
  bool _saving = false;

  DeliverySafety _deliveryData = DeliverySafety();
  WaterSetup _waterData = WaterSetup();

  final _scrollController = ScrollController();

  // Key to access DeliverySafetySection's state so we can flush text fields
  final _deliveryKey = GlobalKey<DeliverySafetySectionState>();
  final _waterKey = GlobalKey<WaterSetupSectionState>();

  void _handleNext() {
    if (_currentStep == 1) {
      final section = _deliveryKey.currentState;
      if (section != null && !section.validateSelection()) {
        return;
      }

      // Flush any pending text-field values before leaving step 1
      final flushed = _deliveryKey.currentState?.flushToData(_deliveryData);
      if (flushed != null) _deliveryData = flushed;

      setState(() => _currentStep = 2);
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _handleBack() {
    if (_currentStep == 2) {
      setState(() => _currentStep = 1);
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _goHostWithLastSelectedTab() async {
    final lastIndex = await loadPersistedBottomNavIndex();
    ref.read(bottomNavProvider.notifier).state = lastIndex;
    if (!mounted) return;

    // Restore guest session: create server address from onboarding data
    await _restoreGuestAddress();

    HomeDashboardScreen.suppressMilkRunForSession = true;
    goRouter.go(AppRoutes.host);
  }

  /// Creates a server-side address from locally saved guest onboarding data
  /// (street, city, postal) so checkout has an address ready.
  Future<void> _restoreGuestAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final street = prefs.getString('guest_street') ?? '';
      final city = prefs.getString('guest_city') ?? '';
      final postal = prefs.getString('guest_postal') ?? '';

      // Nothing to restore
      if (city.isEmpty && street.isEmpty) return;

      final token = ref.read(authNotifierProvider).value?.data?.token ?? '';
      if (token.isEmpty) return;

      final user = ref.read(authNotifierProvider).value?.data?.user;

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
        // Select the newly created address for checkout
        final addresses = ref.read(addressProvider).addresses;
        if (addresses.isNotEmpty) {
          ref.read(selectedDeliveryAddressProvider.notifier)
              .selectAddress(addresses.first);
        }

        // Restore delivery date if saved
        final savedDate = await loadSelectedDeliveryDate();
        if (savedDate != null) {
          ref.read(selectedDeliveryDateProvider.notifier).state = savedDate;
        } else {
          // Compute next delivery date from zone
          final zone = detectZoneByCity(city);
          if (zone != null) {
            final nextDate = getNextDeliveryDateFromDays(zone.deliveryDays);
            ref.read(selectedDeliveryDateProvider.notifier).state = nextDate;
            saveSelectedDeliveryDate(nextDate);
          }
        }
      }

      // Clean up guest keys regardless of success
      await prefs.remove('guest_street');
      await prefs.remove('guest_city');
      await prefs.remove('guest_postal');
    } catch (e) {
      debugPrint('[PostSignup] Failed to restore guest address: $e');
    }
  }

  Future<void> _handleSave() async {
    final waterSection = _waterKey.currentState;
    if (waterSection != null && !waterSection.validateSelection()) {
      return;
    }

    setState(() => _saving = true);
    try {
      final authState = ref.read(authNotifierProvider);
      final token = authState.value?.data?.token ?? '';

      final repo = SetupProfileRepo();
      final success = await repo.saveSetupProfile(
        token: token,
        deliverySafety: _deliveryData.toJson(),
        waterSetup: _waterData.toJson(),
      );

      if (success) {
        // Refresh auth session so profile shows correct user data
        await ref.read(authNotifierProvider.notifier).refreshSession();
        CustomToast.success(msg: "Setup complete! Welcome to RetroRoute 🎉");
        await _goHostWithLastSelectedTab();
      } else {
        CustomToast.error(msg: "Failed to save. Please try again.");
      }
    } catch (e) {
      CustomToast.error(msg: "Failed to save. Please try again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }





  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Step indicator ────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stepDot(active: _currentStep == 1),
                  Container(width: 28.w, height: 2, color: Colors.grey.shade200),
                  _stepDot(active: _currentStep == 2),
                ],
              ),
            ),

            // ── Content ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _currentStep == 1
                    ? DeliverySafetySection(
                        key: _deliveryKey,
                        data: _deliveryData,
                        onChange: (d) => setState(() => _deliveryData = d),
                      )
                    : WaterSetupSection(
                        key: _waterKey,
                        data: _waterData,
                        onChange: (d) => setState(() => _waterData = d),
                      ),
              ),
            ),

            // ── Bottom buttons ───────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2)),
                ],
              ),
              child: _currentStep == 1
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: _handleNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF26522),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                              elevation: 4,
                              shadowColor: const Color(0xFFFED7AA),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Continue to Water Setup", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                                SizedBox(width: 6.w),
                                Icon(Icons.arrow_forward_rounded, size: 18.sp, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF26522),
                              disabledBackgroundColor: const Color(0xFFF26522).withOpacity(0.6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                              elevation: 4,
                              shadowColor: const Color(0xFFFED7AA),
                            ),
                            child: _saving
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                      SizedBox(width: 8.w),
                                      Text("Saving...", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                                    ],
                                  )
                                : Text("Save & continue", style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        GestureDetector(
                          onTap: _handleBack,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back_rounded, size: 14.sp, color: Colors.grey.shade400),
                              SizedBox(width: 4.w),
                              Text("Back", style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey.shade400)),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _stepDot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 12.w : 10.w,
      height: active ? 12.w : 10.w,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF0d9488) : const Color(0xFFccfbf1),
        shape: BoxShape.circle,
      ),
    );
  }
}
