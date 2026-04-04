import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/components/custom_textfield.dart';
import 'package:retro_route/utils/app_assets.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view_model/auth_view_model/register_view_model.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _agreeToTerms = false;

  /// Formats phone as "111 111 1111" (3-3-4 with spaces).
  String _formatPhoneNumber(String input) {
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
    final clipped = digits.length > 10 ? digits.substring(0, 10) : digits;
    if (clipped.length <= 3) return clipped;
    if (clipped.length <= 6) {
      return '${clipped.substring(0, 3)} ${clipped.substring(3)}';
    }
    return '${clipped.substring(0, 3)} ${clipped.substring(3, 6)} ${clipped.substring(6)}';
  }

  void _openTerms() {
    goRouter.push(AppRoutes.termsConditions);
  }

  void _openPrivacy() {
    goRouter.push(AppRoutes.privacyPolicy);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerProvider);

    // Listen for successful registration
    ref.listen<RegisterState>(registerProvider, (previous, current) {
      if (current.isSuccess && current.email != null) {
        // Navigate to OTP screen with email + password for auto-login
        if (mounted) {
          goRouter.push(
            AppRoutes.otp,
            extra: {
              'email': current.email!,
              'password': _passwordController.text,
            },
          );

          // Reset state after navigation
          Future.delayed(Duration.zero, () {
            ref.read(registerProvider.notifier).reset();
          });
        }
      }

      if (current.error != null) {
        CustomToast.error(msg: current.error!);
      }
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                verticalSpacer(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        goRouter.go(AppRoutes.login);
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
                        verticalSpacer(height: 8),
                        // Title
                        customText(
                          text: "Create Account",
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                        verticalSpacer(height: 8),
                        customText(
                          text: "Join us and start your journey today!",
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600]!,
                        ),

                        verticalSpacer(height: 16),

                        // Full Name Field
                        CustomTextField(
                          controller: _nameController,
                          hintText: "Full Name",
                          width: double.infinity,
                          hintFontSize: 18,
                          prefixIcon: Icons.person_outline,
                          borderRadius: 16,
                          fillColor: Colors.grey[50],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter your name";
                            }
                            return null;
                          },
                        ),

                        verticalSpacer(height: 16),

                        // Phone Number Field (right after name)
                        CustomTextField(
                          controller: _phoneController,
                          hintText: "Phone Number",
                          width: double.infinity,
                          hintFontSize: 18,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone,
                          borderRadius: 16,
                          fillColor: Colors.grey[50],
                          onChanged: (v) {
                            final formatted = _formatPhoneNumber(v);
                            if (_phoneController.text != formatted) {
                              _phoneController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );
                            }
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter your phone number";
                            }
                            return null;
                          },
                        ),

                        verticalSpacer(height: 16),

                        // Email Field
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
                        verticalSpacer(height: 16),

                        // Password Field
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
                              return "Please enter a password";
                            }
                            if (value.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),

                        verticalSpacer(height: 16),

                        // Confirm Password Field
                        CustomTextField(
                          controller: _confirmPasswordController,
                          hintText: "Confirm Password",
                          width: double.infinity,
                          hintFontSize: 18,
                          obscureText: true,
                          isPasswordField: true,
                          prefixIcon: Icons.lock_outline,
                          borderRadius: 16,
                          fillColor: Colors.grey[50],
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return "Passwords do not match";
                            }
                            return null;
                          },
                        ),

                        verticalSpacer(height: 16),

                        // Terms & Privacy Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              activeColor: AppColors.btnColor,
                              onChanged: (val) {
                                setState(() => _agreeToTerms = val ?? false);
                              },
                            ),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'I agree to the ',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _openTerms,
                                    child: Text(
                                      'Terms & Conditions',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        color: AppColors.btnColor,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.btnColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' and ',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _openPrivacy,
                                    child: Text(
                                      'Privacy Policy',
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        color: AppColors.btnColor,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: AppColors.btnColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        verticalSpacer(height: 16),

                        // Sign Up Button
                        customButton(
                          context: context,
                          text: "Sign Up",
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontColor: Colors.white,
                          bgColor: AppColors.btnColor,
                          borderColor: Colors.transparent,
                          borderRadius: 16,
                          height: 56,
                          width: double.infinity,
                          isCircular: false,
                          isLoading: registerState.isLoading,
                          onPressed: () async {
                                  if (!_agreeToTerms) {
                                    CustomToast.error(msg: 'Please agree to the Terms & Conditions and Privacy Policy to continue.');
                                    return;
                                  }
                                  if (_formKey.currentState!.validate()) {
                                    await ref
                                        .read(registerProvider.notifier)
                                        .register(
                                          name: _nameController.text.trim(),
                                          email: _emailController.text.trim(),
                                          phone: _phoneController.text.trim(),
                                          password: _passwordController.text,
                                        );
                                  }
                                },
                        ),

                        verticalSpacer(height: 16),

                        // Already have account?
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            customText(
                              text: "Already have an account? ",
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600]!,
                            ),
                            GestureDetector(
                              onTap: () {
                                goRouter.go(
                                  AppRoutes.login,
                                ); // or navigate to login
                              },
                              child: customText(
                                text: "Sign In",
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
