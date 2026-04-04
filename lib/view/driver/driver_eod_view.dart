import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:retro_route/model/water_test_result_model.dart';
import 'package:retro_route/utils/driver_constants.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/view/driver/widgets/driver_widgets.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/driver_view_model/driver_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverEodScreen extends ConsumerStatefulWidget {
  const DriverEodScreen({super.key});

  @override
  ConsumerState<DriverEodScreen> createState() => _DriverEodScreenState();
}

class _DriverEodScreenState extends ConsumerState<DriverEodScreen> {
  final _km = TextEditingController(text: '0');
  final _eodReadingCtrl = TextEditingController();
  final _notes = TextEditingController();
  bool _submitted = false;
  bool _submitting = false;
  double _sodReading = 0;
  File? _eodOdometerImage;

  @override
  void initState() {
    super.initState();
    _loadSodReading();
  }

  Future<void> _loadSodReading() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final sodDate = prefs.getString('sod_date') ?? '';
    if (sodDate == today) {
      _sodReading = prefs.getDouble('sod_reading') ?? 0;
    }
    if (mounted) setState(() {});
  }

  void _calculateKm() {
    final eodReading = double.tryParse(_eodReadingCtrl.text.trim()) ?? 0;
    if (_sodReading > 0 && eodReading > _sodReading) {
      final driven = eodReading - _sodReading;
      _km.text = driven.toStringAsFixed(0);
      setState(() {});
    }
  }

  Future<void> _pickEodImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _eodOdometerImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    // Validate required fields
    final eodReading = double.tryParse(_eodReadingCtrl.text.trim()) ?? 0;
    if (eodReading <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your odometer reading'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_eodOdometerImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a photo of your odometer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final driverState = ref.read(driverDeliveriesProvider);
    final token = ref.read(authNotifierProvider).value?.data?.token ?? '';
    final driverId = ref.read(authNotifierProvider).value?.data?.user.id ?? '';

    final delivered = driverState.completedDeliveries.length;
    final pending = driverState.activeDeliveries.length;
    final totalStops = delivered + pending;
    final totalRevenue = driverState.completedDeliveries
        .fold<double>(0, (s, d) => s + d.safeTotal);

    final report = EodReport(
      driverId: driverId,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      totalStops: totalStops,
      delivered: delivered,
      pending: pending,
      totalRevenue: totalRevenue,
      waterTestsDone: 0, // TODO: Track water tests done today
      kmDriven: double.tryParse(_km.text) ?? 0,
      sodReading: _sodReading,
      eodReading: eodReading,
      avgMinPerStop: 0,
      notes: _notes.text.isEmpty ? null : _notes.text,
    );

    final ok = await ref
        .read(driverDeliveriesProvider.notifier)
        .submitEodReport(
          token: token,
          report: report,
          odometerImage: _eodOdometerImage,
        );

    setState(() {
      _submitting = false;
      if (ok) _submitted = true;
    });

    // After successful submission: clear SOD, logout, go to login
    if (ok && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sod_date');
      await prefs.remove('sod_reading');

      // Brief delay so driver sees the success message
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  void dispose() {
    _km.dispose();
    _eodReadingCtrl.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverDeliveriesProvider);
    final delivered = driverState.completedDeliveries.length;
    final totalStops =
        delivered + driverState.activeDeliveries.length;
    final revenue = driverState.completedDeliveries
        .fold<double>(0, (s, d) => s + d.safeTotal);

    return Scaffold(
      backgroundColor: DriverColors.bg,
      body: Column(children: [
        // Header
        Container(
          color: DriverColors.navy,
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle),
                      child: Icon(Icons.arrow_back,
                          color: Colors.white, size: 18.sp),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('End of Day',
                            style: GoogleFonts.inter(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5)),
                        Text('Submit your daily report',
                            style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.white60,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ]),
              ),
              SizedBox(height: 16.h),
              Container(
                height: 24.h,
                decoration: BoxDecoration(
                    color: DriverColors.bg,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24.r))),
              ),
            ]),
          ),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(children: [
              // Summary card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                    color: DriverColors.orange,
                    borderRadius: BorderRadius.circular(16.r)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's summary",
                        style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3)),
                    SizedBox(height: 14.h),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8.h,
                      crossAxisSpacing: 8.w,
                      childAspectRatio: 2.5,
                      children: [
                        _eodStat('$delivered', 'Delivered'),
                        _eodStat(
                            '\$${revenue.toStringAsFixed(0)}', 'Revenue'),
                        _eodStat('0', 'Water tests'),
                        _eodStat('$totalStops', 'Total stops'),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              if (_submitted)
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                      color: DriverColors.greenLight,
                      borderRadius: BorderRadius.circular(16.r)),
                  child: Row(children: [
                    Icon(Icons.check_circle,
                        color: DriverColors.green, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text('Report submitted to admin!',
                          style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: DriverColors.green)),
                    ),
                  ]),
                )
              else ...[
                // EOD Odometer Reading
                DriverInfoCard(
                  title: 'End of Day Odometer',
                  icon: Icons.speed_rounded,
                  children: [
                    if (_sodReading > 0) ...[
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: DriverColors.blueLight,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wb_sunny_rounded,
                                color: DriverColors.blue, size: 16.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'SOD Reading: ${_sodReading.toStringAsFixed(0)} km',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: DriverColors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],
                    Text('Current odometer reading (km)',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: DriverColors.textMuted)),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: _eodReadingCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateKm(),
                      decoration: InputDecoration(
                        hintText: 'Enter current km reading',
                        hintStyle: GoogleFonts.inter(
                            color: DriverColors.textHint),
                        suffixText: 'km',
                        filled: true,
                        fillColor: DriverColors.bg,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide:
                                BorderSide(color: DriverColors.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide:
                                BorderSide(color: DriverColors.border)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 10.h),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text('Odometer Photo',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: DriverColors.textMuted)),
                    SizedBox(height: 6.h),
                    GestureDetector(
                      onTap: _pickEodImage,
                      child: Container(
                        height: 140.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: DriverColors.bg,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: DriverColors.border),
                        ),
                        child: _eodOdometerImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10.r),
                                child: Image.file(
                                  _eodOdometerImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded,
                                      size: 32.sp,
                                      color: DriverColors.textHint),
                                  SizedBox(height: 6.h),
                                  Text('Tap to take photo',
                                      style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          color: DriverColors.textMuted)),
                                ],
                              ),
                      ),
                    ),
                    if (_sodReading > 0 &&
                        (double.tryParse(_km.text) ?? 0) > 0) ...[
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: DriverColors.greenLight,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.directions_car_rounded,
                                color: DriverColors.green, size: 16.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'Total km driven today: ${_km.text} km',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: DriverColors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 12.h),
                DriverInfoCard(
                  title: 'Additional details',
                  icon: Icons.info_outline,
                  children: [
                    Text('Distance driven (km)',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: DriverColors.textMuted)),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: _km,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: DriverColors.bg,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide:
                                BorderSide(color: DriverColors.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide:
                                BorderSide(color: DriverColors.border)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 10.h),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text('Notes for admin (optional)',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: DriverColors.textMuted)),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: _notes,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Any issues, feedback...',
                        hintStyle: GoogleFonts.inter(
                            color: DriverColors.textHint),
                        filled: true,
                        fillColor: DriverColors.bg,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide:
                                BorderSide(color: DriverColors.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide:
                                BorderSide(color: DriverColors.border)),
                        contentPadding: EdgeInsets.all(12.w),
                      ),
                    ),
                  ],
                ),
                DriverOrangeButton(
                  text: 'Submit end of day report',
                  onPressed: _submit,
                  loading: _submitting,
                ),
              ],
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 40.h),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _eodStat(String val, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10.r)),
      child: Row(children: [
        Text(val,
            style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70)),
        ),
      ]),
    );
  }
}
