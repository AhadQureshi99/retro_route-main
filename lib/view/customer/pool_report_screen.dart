import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/crate_view_model/crate_view_model.dart';

class PoolReportScreen extends ConsumerWidget {
  final String orderId;
  const PoolReportScreen({super.key, required this.orderId});

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A':
        return const Color(0xFF2E7D32);
      case 'B':
        return const Color(0xFF558B2F);
      case 'C':
        return AppColors.btnColor;
      case 'D':
        return Colors.deepOrange;
      default:
        return Colors.red;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ok':
        return const Color(0xFF2E7D32);
      case 'low':
        return AppColors.btnColor;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authNotifierProvider).value?.data?.token ?? '';
    final reportAsync = ref.watch(poolReportProvider((token, orderId)));

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: GoogleFonts.inter(color: Colors.red))),
        data: (report) {
          if (report == null) {
            return Center(
              child: Text('Pool report not available yet.',
                  style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey[600])),
            );
          }

          final grade = report['grade'] as String? ?? 'N/A';
          final score = (report['overallScore'] as num?)?.toInt() ?? 0;
          final poolType = report['poolType'] as String? ?? 'hottub';
          final parameters = (report['parameters'] as List<dynamic>?) ?? [];
          final recommendations = (report['recommendations'] as List<dynamic>?) ?? [];
          final visualObs = (report['visualObservations'] as List<dynamic>?) ?? [];
          final driverName = report['driverName'] as String? ?? 'Driver';
          final certText = report['certifiedText'] as String? ?? '';

          return Column(
            children: [
              // Header
              Container(
                color: _gradeColor(grade),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 36.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_back, color: Colors.white, size: 18.sp),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pool Report Card',
                                      style: GoogleFonts.inter(
                                          fontSize: 22.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.3)),
                                  Text(
                                      '${poolType == 'pool' ? 'Pool' : 'Hot Tub'} · Tested by $driverName',
                                      style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Grade circle
                      Container(
                        width: 90.w,
                        height: 90.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12)
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(grade,
                                style: GoogleFonts.inter(
                                    fontSize: 36.sp,
                                    fontWeight: FontWeight.w900,
                                    color: _gradeColor(grade))),
                            Text('$score/100',
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: AppColors.bgColor,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Parameters
                      _sectionTitle('Water Chemistry'),
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBgColor,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: parameters.asMap().entries.map((entry) {
                            final p = entry.value as Map<String, dynamic>;
                            final name = p['name'] as String? ?? '';
                            final value = p['value'];
                            final unit = p['unit'] as String? ?? '';
                            final status = p['status'] as String? ?? 'na';
                            final idealMin = p['idealMin'];
                            final idealMax = p['idealMax'];

                            final valueStr = value is double
                                ? (value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1))
                                : value.toString();

                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: entry.key < parameters.length - 1
                                        ? Colors.grey.shade200
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8.w,
                                    height: 8.w,
                                    decoration: BoxDecoration(
                                      color: _statusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: GoogleFonts.inter(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.grey[900])),
                                        if (idealMin != null && idealMax != null)
                                          Text('Ideal: $idealMin–$idealMax $unit',
                                              style: GoogleFonts.inter(
                                                  fontSize: 10.sp,
                                                  color: Colors.grey[500])),
                                      ],
                                    ),
                                  ),
                                  Text('$valueStr $unit',
                                      style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w800,
                                          color: _statusColor(status))),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      if (visualObs.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        _sectionTitle('Visual Observations'),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Column(
                            children: visualObs
                                .map((obs) => Padding(
                                      padding: EdgeInsets.symmetric(vertical: 3.h),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning_amber, size: 14.sp, color: Colors.orange[800]),
                                          SizedBox(width: 8.w),
                                          Flexible(
                                            child: Text(obs.toString(),
                                                style: GoogleFonts.inter(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.orange[900])),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],

                      if (recommendations.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        _sectionTitle('Recommendations'),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Column(
                            children: recommendations
                                .map((rec) => Padding(
                                      padding: EdgeInsets.symmetric(vertical: 3.h),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.eco, size: 14.sp, color: AppColors.primary),
                                          SizedBox(width: 8.w),
                                          Flexible(
                                            child: Text(rec.toString(),
                                                style: GoogleFonts.inter(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF1B5E20))),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],

                      SizedBox(height: 16.h),

                      // Certification
                      if (certText.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.cardBgColor,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified, color: AppColors.primary, size: 20.sp),
                              SizedBox(width: 8.w),
                              Flexible(
                                child: Text(certText,
                                    style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700])),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: Colors.grey[800],
            letterSpacing: 0.3));
  }
}
