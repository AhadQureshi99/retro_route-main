import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:retro_route/utils/driver_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to track whether SOD has been completed today.
final sodCompletedProvider = StateProvider<bool>((ref) => false);

class DriverSodScreen extends ConsumerStatefulWidget {
  const DriverSodScreen({super.key});

  @override
  ConsumerState<DriverSodScreen> createState() => _DriverSodScreenState();
}

class _DriverSodScreenState extends ConsumerState<DriverSodScreen> {
  final _readingCtrl = TextEditingController();
  File? _odometerImage;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _readingCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _odometerImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_readingCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter odometer reading')),
      );
      return;
    }
    if (_odometerImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo of the odometer')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString('sod_date', today);
      await prefs.setDouble(
        'sod_reading',
        double.tryParse(_readingCtrl.text.trim()) ?? 0,
      );
      await prefs.setString('sod_image', _odometerImage!.path);

      ref.read(sodCompletedProvider.notifier).state = true;

      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverColors.bg,
      body: Column(
        children: [
          // Header
          Container(
            color: DriverColors.navy,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                    child: Row(
                      children: [
                        Icon(Icons.wb_sunny_rounded,
                            color: DriverColors.orange, size: 28.sp),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start of Day',
                                style: GoogleFonts.inter(
                                  fontSize: 26.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Record your starting odometer reading',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: DriverColors.bg,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24.r)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  if (_submitted)
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: DriverColors.greenLight,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle,
                              color: DriverColors.green, size: 48.sp),
                          SizedBox(height: 12.h),
                          Text(
                            'Start of Day recorded!',
                            style: GoogleFonts.inter(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: DriverColors.green,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Odometer: ${_readingCtrl.text} km',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: DriverColors.green,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DriverColors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                'Continue to Dashboard',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Odometer reading input
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: DriverColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.speed_rounded,
                                  color: DriverColors.navy, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Odometer Reading',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: DriverColors.text,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          TextField(
                            controller: _readingCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.inter(fontSize: 18.sp),
                            decoration: InputDecoration(
                              hintText: 'Enter current km reading',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: DriverColors.textHint,
                              ),
                              suffixText: 'km',
                              suffixStyle: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: DriverColors.textMuted,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 14.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide:
                                    BorderSide(color: DriverColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide:
                                    BorderSide(color: DriverColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide(
                                    color: DriverColors.navy, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Odometer image
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: DriverColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.camera_alt_rounded,
                                  color: DriverColors.navy, size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'Odometer Photo',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: DriverColors.text,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 180.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: DriverColors.bg,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: DriverColors.border,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: _odometerImage != null
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12.r),
                                      child: Image.file(
                                        _odometerImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_rounded,
                                            size: 40.sp,
                                            color: DriverColors.textHint),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'Tap to take photo',
                                          style: GoogleFonts.inter(
                                            fontSize: 14.sp,
                                            color: DriverColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DriverColors.orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              DriverColors.orange.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          elevation: 0,
                        ),
                        child: _submitting
                            ? SizedBox(
                                height: 20.h,
                                width: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Start My Day',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
