import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/crate_view_model/crate_view_model.dart';

class PoolReportsListScreen extends ConsumerWidget {
  const PoolReportsListScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authNotifierProvider).value?.data?.token ?? '';
    final reportsAsync = ref.watch(myPoolReportsProvider(token));

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Pool Report Cards',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red[300]),
                SizedBox(height: 12.h),
                Text(
                  'Failed to load reports',
                  style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: () => ref.invalidate(myPoolReportsProvider(token)),
                  child: Text('Retry', style: GoogleFonts.inter(color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64.sp, color: Colors.grey[300]),
                    SizedBox(height: 16.h),
                    Text(
                      'No Report Cards Yet',
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your pool report cards will appear here after a water test is completed.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myPoolReportsProvider(token)),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final r = reports[index];
                final grade = r['grade'] as String? ?? '?';
                final score = r['overallScore'] as num? ?? 0;
                final poolType = r['poolType'] as String? ?? 'pool';
                final driverName = r['driverName'] as String? ?? '';
                final orderId = (r['orderId'] ?? '').toString();

                String dateStr = '';
                final testedAt = r['testedAt'] ?? r['createdAt'];
                if (testedAt != null) {
                  try {
                    final dt = DateTime.parse(testedAt.toString());
                    dateStr = DateFormat('MMM d, yyyy').format(dt);
                  } catch (_) {}
                }

                final color = _gradeColor(grade);
                final poolLabel = poolType == 'hottub' ? 'Hot Tub' : 'Pool';

                return GestureDetector(
                  onTap: () {
                    if (orderId.isNotEmpty) {
                      context.push('${AppRoutes.poolReport}?orderId=$orderId');
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
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
                        // Grade circle
                        Container(
                          width: 56.w,
                          height: 56.w,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                grade,
                                style: GoogleFonts.inter(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '$score/100',
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 14.w),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$poolLabel Report Card',
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[900],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              if (driverName.isNotEmpty)
                                Text(
                                  'Tested by $driverName',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              if (dateStr.isNotEmpty)
                                Text(
                                  dateStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16.sp,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
