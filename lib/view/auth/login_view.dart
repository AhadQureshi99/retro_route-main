import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/components/custom_textfield.dart';
import 'package:retro_route/model/login_model.dart';
import 'package:retro_route/config/delivery_zones.dart';
import 'package:retro_route/repository/onboarding_repo.dart';
import 'package:retro_route/repository/setup_profile_repo.dart';
import 'package:retro_route/utils/app_assets.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view_model/address_view_model/address_view_model.dart';
import 'package:retro_route/view_model/address_view_model/selected_delivery_address_view_model.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/bottom_nav_view_model.dart';
import 'package:retro_route/view_model/selected_delivery_date_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;

  // Keys for SharedPreferences
  static const String _prefEmail = 'remember_email';
  static const String _prefPassword = 'remember_password';
  static const String _prefRememberMe = 'remember_me';
  
  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString(_prefEmail);
    final savedPassword = prefs.getString(_prefPassword);
    final savedRemember = prefs.getBool(_prefRememberMe) ?? false;

    if (savedRemember && savedEmail != null && savedPassword != null) {
      setState(() {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials(bool remember) async {
    final prefs = await SharedPreferences.getInstance();

    if (remember) {
      await prefs.setString(_prefEmail, _emailController.text.trim());
      await prefs.setString(_prefPassword, _passwordController.text);
      await prefs.setBool(_prefRememberMe, true);
    } else {
      await prefs.remove(_prefEmail);
      await prefs.remove(_prefPassword);
      await prefs.setBool(_prefRememberMe, false);
    }
  }

  /// Creates or updates a server-side address from guest onboarding data if present.
  Future<void> _restoreGuestAddressIfNeeded(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final street = prefs.getString('guest_street') ?? '';
      final city = prefs.getString('guest_city') ?? '';
      final postal = prefs.getString('guest_postal') ?? '';

      if (city.isEmpty && street.isEmpty) return;
      if (token.isEmpty) return;

      final user = ref.read(authNotifierProvider).value?.data?.user;

      // Check if addresses already exist
      await ref.read(addressProvider.notifier).fetchAddresses(token);
      final existingAddresses = ref.read(addressProvider).addresses;
      bool success;

      if (existingAddresses.isNotEmpty) {
        final existingId = existingAddresses.first.safeId;
        success = await ref.read(addressProvider.notifier).updateAddress(
          token: token,
          addressId: existingId,
          addressLine: street,
          city: city,
          statess: 'ON',
          country: 'CA',
          postalCode: postal,
          phone: user?.phone ?? '',
          fullName: user?.name ?? '',
        );
      } else {
        success = await ref.read(addressProvider.notifier).addAddress(
          token: token,
          addressLine: street,
          city: city,
          statess: 'ON',
          country: 'CA',
          postalCode: postal,
          phone: user?.phone ?? '',
          fullName: user?.name ?? '',
        );
      }

      if (success) {
        final addresses = ref.read(addressProvider).addresses;
        if (addresses.isNotEmpty) {
          ref.read(selectedDeliveryAddressProvider.notifier)
              .selectAddress(addresses.first);
        }

        final savedDate = await loadSelectedDeliveryDate();
        if (savedDate != null) {
          ref.read(selectedDeliveryDateProvider.notifier).state = savedDate;
        } else {
          final zone = detectZoneByCity(city);
          if (zone != null) {
            final nextDate = getNextDeliveryDateFromDays(zone.deliveryDays);
            ref.read(selectedDeliveryDateProvider.notifier).state = nextDate;
            saveSelectedDeliveryDate(nextDate);
          }
        }
      }

      await prefs.remove('guest_street');
      await prefs.remove('guest_city');
      await prefs.remove('guest_postal');
    } catch (e) {
      debugPrint('[Login] Failed to restore guest address: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<LoginResponse?>>(authNotifierProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (response) async {
          if (response != null && response.success) {
            final role = response.data?.user.role ?? 'User';

            if (role.toLowerCase() == 'driver') {
              _saveCredentials(_rememberMe);
              CustomToast.success(msg: 'Logged in successfully!');
              goRouter.go(AppRoutes.driverHome);
              return;
            }

            // Always check if profile setup is completed via API
            final token = response.data?.token ?? '';
            bool setupDone = true;
            try {
              final profile = await SetupProfileRepo().getSetupProfile(token);
              setupDone = profile?.hasCompletedSetup == true;
            } catch (_) {}

            if (!mounted) return;

            if (!setupDone) {
              // Setup not completed — redirect to setup screen
              goRouter.go(AppRoutes.setup);
            } else {
              _saveCredentials(_rememberMe);
              CustomToast.success(msg: 'Logged in successfully!');
              await _restoreGuestAddressIfNeeded(token);
              final lastTab = await loadPersistedBottomNavIndex();
              ref.read(bottomNavProvider.notifier).state = lastTab;
              goRouter.go(AppRoutes.host);
            }
          }
        },
        error: (err, _) {
          CustomToast.error(msg: 'Login failed');
        },
      );
    });
    
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                verticalSpacer(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        goRouter.go(AppRoutes.host);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
                verticalSpacer(height: 10),
                Image.asset(AppImages.logos, width: 200.w,height: 160.h,),

                Card(
                  color: AppColors.cardBgColor,
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      children: [
                        customText(
                          text: "Welcome Back!",
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black ?? Colors.black87,
                        ),
                        verticalSpacer(height: 8),
                        customText(
                          text: "Log in to continue your journey",
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600]!,
                        ),

                        verticalSpacer(height: 50),
                        CustomTextField(
                          controller: _emailController,
                          hintText: "Email Address",
                          width: double.infinity,
                          hintFontSize: 18,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          borderRadius: 16,
                          fillColor: Colors.grey[50],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter your email";
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return "Please enter a valid email";
                            }
                            return null;
                          },
                        ),
                        verticalSpacer(height: 20),

                        CustomTextField(
                          controller: _passwordController,
                          hintText: "Password",
                          width: double.infinity,
                          hintFontSize: 18,
                          obscureText: true,
                          isPasswordField: true,
                          prefixIcon: Icons.lock_outline,
                          borderRadius: 16,
                          fillColor: Colors.grey[50],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your password";
                            }
                            return null;
                          },
                        ),

                        verticalSpacer(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor:
                                      AppColors.btnColor,
                                  onChanged: (val) {
                                    setState(() => _rememberMe = val ?? false);
                                  },
                                ),
                                customText(
                                  text: "Remember me",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700]!,
                                ),
                              ],
                            ),

                            GestureDetector(
                              onTap: () {
                                goRouter.push(AppRoutes.forgotPassword);
                              },
                              child: customText(
                                text: "Forgot Password?",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.btnColor ,
                              ),
                            ),
                          ],
                        ),

                        verticalSpacer(height: 24),

                        customButton(
                          context: context,
                          text: "Log In",
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontColor: Colors.white,
                          bgColor: AppColors.btnColor ?? Colors.deepPurple,
                          borderColor: Colors.transparent,
                          borderRadius: 16,
                          height: 56,
                          width: double.infinity,
                          isCircular: false,
                          isLoading: isLoading,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .login(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                  );

                              if (!isLoading &&
                                  ref
                                          .read(authNotifierProvider)
                                          .value
                                          ?.success ==
                                      true) {
                                await _saveCredentials(_rememberMe);
                              }
                            }
                          },
                        ),

                        verticalSpacer(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            customText(
                              text: "Don't have an account? ",
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600]!,
                            ),
                            GestureDetector(
                              onTap: () {
                                goRouter.push(AppRoutes.register);
                              },
                              child: customText(
                                text: "Sign Up",
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.btnColor,
                              ),
                            ),
                          ],
                        ),
                        verticalSpacer(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
