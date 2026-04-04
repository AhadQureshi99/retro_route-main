import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/repository/auth_repo.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';

final otpLoadingProvider = StateProvider<bool>((ref) => false);

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String? password;

  const OtpVerificationScreen({super.key, required this.email, this.password});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  String _otpCode = "";
  final AuthRepo _authRepo = AuthRepo();
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 30;
  Timer? _resendTimer;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await _authRepo.resendRegistrationOtp(email: widget.email);
      if (!mounted) return;
      CustomToast.success(msg: 'OTP resent successfully!');
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(msg: 'Failed to resend OTP');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) return;

    setState(() => _isVerifying = true);

    try {
      await _authRepo.verifyRegisterOtp(otp: _otpCode, email: widget.email);

      if (!mounted) return;
      CustomToast.success(msg: 'OTP Verified!');

      // Auto-login after successful verification (same as web)
      if (widget.password != null && widget.password!.isNotEmpty) {
        try {
          await ref.read(authNotifierProvider.notifier).login(
            email: widget.email,
            password: widget.password!,
          );

          if (!mounted) return;

          // Read state immediately (no delay — prevents login listener race)
          final authState = ref.read(authNotifierProvider);
          final loginResponse = authState.value;

          if (loginResponse?.success == true &&
              loginResponse?.data?.token != null) {
            // Auto-login succeeded → navigate based on role
            final role = loginResponse?.data?.user.role ?? 'User';
            if (role.toLowerCase() == 'driver') {
              goRouter.go(AppRoutes.driverHome);
            } else {
              // New user → MUST go through delivery safety + water setup
              // Navigate immediately before any other listener can override
              goRouter.go(AppRoutes.setup);
            }
            return;
          }
        } catch (_) {
          // Auto-login failed, fall through to setup anyway for new users
          if (mounted) {
            goRouter.go(AppRoutes.setup);
          }
          return;
        }
      }

      // Fallback: if no password → go to setup (new user must complete profile)
      if (mounted) {
        goRouter.go(AppRoutes.setup);
      }
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(msg: 'Invalid OTP or error');
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canVerify = _otpCode.length == 6 && !_isVerifying;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Top curved header ─────────────────────────────────
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 220.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40.r),
                        bottomRight: Radius.circular(40.r),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 16.h),
                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        // Lock icon circle
                        Container(
                          width: 80.r,
                          height: 80.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.verified_user_rounded,
                            color: Colors.white,
                            size: 40.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Content card ──────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Transform.translate(
                    offset: Offset(0, -30.h),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 24.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Verification Code",
                              style: GoogleFonts.inter(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xff111827),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              "We've sent a 6-digit code to",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                widget.email,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            SizedBox(height: 32.h),

                            // ── OTP Field ─────────────────────────────
                            OtpTextField(
                              numberOfFields: 6,
                              cursorColor: AppColors.primary,
                              mainAxisAlignment: MainAxisAlignment.center,
                              borderColor: Colors.grey.shade300,
                              focusedBorderColor: AppColors.primary,
                              enabledBorderColor: Colors.grey.shade200,
                              showFieldAsBox: true,
                              borderRadius: BorderRadius.circular(14.r),
                              contentPadding: EdgeInsets.zero,
                              fieldWidth: 48.w,
                              fieldHeight: 58.h,
                              filled: true,
                              fillColor: Colors.grey[50]!,
                              textStyle: GoogleFonts.inter(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xff111827),
                              ),
                              showCursor: true,
                              onCodeChanged: (String code) {
                                setState(() => _otpCode = code);
                              },
                              onSubmit: (String verificationCode) {
                                setState(() => _otpCode = verificationCode);
                                _verifyOtp();
                              },
                            ),

                            SizedBox(height: 32.h),

                            // ── Verify Button ─────────────────────────
                            SizedBox(
                              width: double.infinity,
                              height: 56.h,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: canVerify
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.3),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: ElevatedButton(
                                  onPressed: canVerify ? _verifyOtp : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.btnColor,
                                    disabledBackgroundColor: Colors.grey[300],
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16.r),
                                    ),
                                  ),
                                  child: _isVerifying
                                      ? SizedBox(
                                          width: 24.r,
                                          height: 24.r,
                                          child:
                                              const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Verify & Continue",
                                              style: GoogleFonts.inter(
                                                fontSize: 17.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 20.sp,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),

                            SizedBox(height: 20.h),

                            // ── Resend OTP ────────────────────────────
                            GestureDetector(
                              onTap: _resendCountdown <= 0 ? _resendOtp : null,
                              child: _isResending
                                  ? SizedBox(
                                      width: 20.r,
                                      height: 20.r,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          color: Colors.grey[600],
                                        ),
                                        children: _resendCountdown > 0
                                            ? [
                                                const TextSpan(text: "Resend OTP in "),
                                                TextSpan(
                                                  text: "${_resendCountdown}s",
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ]
                                            : [
                                                TextSpan(
                                                  text: "Resend OTP",
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                      ),
                                    ),
                            ),

                            SizedBox(height: 16.h),

                            // ── Help text ─────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16.sp,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  "Check your spam folder if you didn't receive it",
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
