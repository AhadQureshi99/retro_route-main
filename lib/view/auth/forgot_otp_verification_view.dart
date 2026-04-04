import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/repository/auth_repo.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view_model/auth_view_model/forgotpassword_view_model.dart'; // if using go_router

final otpLoadingProvider = StateProvider<bool>((ref) => false);

class ForgotPasswordOtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const ForgotPasswordOtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<ForgotPasswordOtpVerificationScreen> createState() =>
      _ForgotOtpVerificationScreenState();
}

class _ForgotOtpVerificationScreenState extends ConsumerState<ForgotPasswordOtpVerificationScreen> {
  String _otpCode = "";


  @override
  Widget build(BuildContext context) {

    final forgotState = ref.watch(forgotPasswordProvider);
    final isLoading = forgotState.isLoading;

    ref.listen(forgotPasswordProvider, (prev, next) {
      next.whenOrNull(
        data: (res) {
          if (res != null && res.success) {
            CustomToast.success(msg: 'OTP Verified! Set new password');
            goRouter.push(
              '${AppRoutes.resetPassword}?email=${Uri.encodeComponent(widget.email)}',
            );
          }
        },
        error: (err, _) {
          CustomToast.error(msg: err.toString());
        },
      );
    });

    Future<void> verify() async {
      final code = _otpCode.trim();
      if (code.length != 6) return;
      ref.read(forgotPasswordProvider.notifier).verifyOtp(
            widget.email,
            code,
          );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              verticalSpacer(height: 40),

              customText(
                text: "Verification Code",
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),

              verticalSpacer(height: 12),

              customText(
                text: "Please type the verification code sent to",
                fontSize: 16,
                color: Colors.grey[700]!,
                fontWeight: FontWeight.w500,
              ),

              customText(
                text: widget.email,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary ?? Colors.deepPurple,
              ),

              verticalSpacer(height: 40),

              // ── OTP Field ───────────────────────────────────────────────
              OtpTextField(
                numberOfFields: 6,
                cursorColor: AppColors.primary,
                mainAxisAlignment: MainAxisAlignment.center,
                borderColor: AppColors.primary ?? const Color(0xFF6A53A1),
                focusedBorderColor:
                    AppColors.primary ?? const Color(0xFF512DA8),
                showFieldAsBox: true, 
                borderRadius: BorderRadius.circular(12),
                contentPadding: EdgeInsets.zero,
                fieldWidth: 55.w,
                fieldHeight: 70.h,
                textStyle: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                showCursor: true,
                onCodeChanged: (String code) {
                  setState(() => _otpCode = code);
                },

                onSubmit: (String verificationCode) {
                  setState(() => _otpCode = verificationCode);
                  verify();
                },
              ),

              verticalSpacer(height: 40),

              customButton(
                context: context,
                text: "Verify OTP",
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontColor: Colors.white,
                bgColor: AppColors.primary ?? Colors.deepPurple,
                borderRadius: 16,
                height: 56.h,
                width: double.infinity,
                isLoading: isLoading,
              onPressed: _otpCode.trim().length == 6 && !isLoading ? verify : null,
                borderColor: AppColors.black,
                isCircular: false,
              ),

            ],
          ),
        ),
      ),
    );
  }
}
