import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/utils/app_colors.dart';

// SCREEN 1 — "How Your Milk Run Works" intro
class OnboardingContent1 extends StatelessWidget {
  final VoidCallback onNext;
  const OnboardingContent1({required this.onNext, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Navy header banner ──────────────────────────────────────────
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Text(
            'How Your Milk Run Works',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ── Centered content — fits on screen without scrolling ────────
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Center(child: Image.asset('assets/images/7.png', width: 140.w)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  children: [
                    Text(
                      'Find Your "Milk" Run',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          color: Colors.black87,
                          // height: 1.55,
                        ),
                        children: const [
                          TextSpan(text: "Enter your address and we'll show you your "),
                          TextSpan(
                            text: 'FREE',
                            style: TextStyle(
                              color: Color(0xFFF97316),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(text: ' delivery days and the next run coming up.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: ClipOval(
                  child: Container(
                    width: 260.w,
                    height: 260.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        fit: BoxFit.contain,
                        image: AssetImage('assets/images/Pic.png'))
                    ),
                    // child: Image.asset(
                    //   'assets/images/Pic.png',
                    //   width: 260.w,
                    //   // height: 250.w,
                    //   fit: BoxFit.cover,
                    // ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Pinned bottom button ────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
                ),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Next',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2 — "Choose Your Type Of Stop"
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingContent2 extends StatelessWidget {
  final VoidCallback onNext;
  const OnboardingContent2({required this.onNext, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Navy header banner ──────────────────────────────────────────
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Text(
            'How Your Milk Run Works',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ── Centered content ─────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header icon + titles
                Column(
                  children: [
                    Center(child: Image.asset('assets/images/11.png', width: 72.w)),
                    SizedBox(height: 4.h),
                    Text(
                      'Choose Your Type Of Stop',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Tell us what you need',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        color: const Color(0xFFF97316),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // ── Type 1 ──────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/images/12.png', width: 56.w),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(fontSize: 16.sp),
                              children: const [
                                TextSpan(
                                  text: 'Type #1: ',
                                  style: TextStyle(
                                    color: AppColors.btnColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Bring Supplies',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '(I already know what I need)',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          _bullet('Select chemicals, filters, products.'),
                          _bullet('No Delivery Fees.'),
                          _bullet('Free water test request available.'),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Type 2 ──────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset('assets/images/8.png', width: 56.w),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(fontSize: 16.sp),
                              children: const [
                                TextSpan(
                                  text: 'Type #2: ',
                                  style: TextStyle(
                                    color: AppColors.btnColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Water Test First',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '(Get a Water Test before purchasing supplies)',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          _bullet('Choose water test first visit.'),
                          _bullet('Full chemical inventory on truck.'),
                          _bullet('Supplies left after test.'),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── NOTE card ────────────────────────────────────────────
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF97316), width: 2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/images/9.png', width: 48.w),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOTE',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              r'$39 charge for Water Test First visit. 100% is credited towards supplies purchased after the test.',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
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

        // ── Pinned bottom button ────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 20.h),
          decoration: BoxDecoration(
            color: AppColors.bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Book Your Stop',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.black)),
          Expanded(
            child: Text(
              text,
              style:
                  GoogleFonts.inter(fontSize: 14.sp, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
