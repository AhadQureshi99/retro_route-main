import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/components/custom_textfield.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view_model/auth_view_model/forgotpassword_view_model.dart';

class ForgotPasswordEmailScreen extends ConsumerStatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  ConsumerState<ForgotPasswordEmailScreen> createState() => _ForgotEmailPasswordScreenState();
}

class _ForgotEmailPasswordScreenState extends ConsumerState<ForgotPasswordEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false; 

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final forgotState = ref.watch(forgotPasswordProvider);
    final isLoading = forgotState.isLoading;

    ref.listen(forgotPasswordProvider, (prev, next) {
      next.whenOrNull(
        data: (res) {
          if (res != null && res.success) {
            CustomToast.success(msg: res.message);
            goRouter.push(
              '${AppRoutes.forgotOtp}?email=${Uri.encodeComponent(_emailController.text.trim())}',
            );
          }
        },
        error: (err, _) {
            CustomToast.error(msg: err.toString());
        },
      );
    });
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                verticalSpacer(height: 20),

                // Title
                customText(
                  text: "Forgot Password?",
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black ?? Colors.black87,
                ),
                verticalSpacer(height: 12),

                // Subtitle
                if (!_emailSent) ...[
                  customText(
                    text: "Don't worry! Enter your email address below and we'll send you a OTP code to reset your password.",
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600]!,
                    maxLine: 3,
                  ),
                ] else ...[
                  customText(
                    text: "Check your inbox!",
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary ?? Colors.deepPurple,
                  ),
                  verticalSpacer(height: 12),
                  customText(
                    text: "We’ve sent a password reset link to",
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700]!,
                  ),
                  verticalSpacer(height: 8),
                  customText(
                    text: _emailController.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black ?? Colors.black87,
                  ),
                  verticalSpacer(height: 16),
                  customText(
                    text: "Click the link in the email to create a new password. If you don't see it, check your spam folder.",
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600]!,
                    maxLine: 4,
                  ),
                ],

                verticalSpacer(height: _emailSent ? 40 : 50),

                // Email Field (only show before sending)
                if (!_emailSent)
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
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return "Please enter a valid email";
                      }
                      return null;
                    },
                  ),

                verticalSpacer(height: 40),

                // Action Button
                customButton(
                  context: context,
                  text: _emailSent ? "Resend Email" : "Send OTP",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontColor: Colors.white,
                  bgColor: AppColors.btnColor,
                  borderColor: Colors.transparent,
                  borderRadius: 16,
                  height: 56,
                  width: double.infinity,
                  isCircular: false,
                  isLoading: _isLoading,
                  onPressed:isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            ref.read(forgotPasswordProvider.notifier).sendOtp(
                                  _emailController.text.trim(),
                                );
                          }
                        }, 
                ),

                verticalSpacer(height: 32),

                // Back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    customText(
                      text: "Remember your password? ",
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600]!,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: customText(
                        text: "Log In",
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.btnColor,
                      ),
                    ),
                  ],
                ),

                verticalSpacer(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}