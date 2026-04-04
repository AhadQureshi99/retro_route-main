import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/utils/app_colors.dart';

Widget customPhoneField({
  required String selectedCode,
  required GlobalKey<PopupMenuButtonState<String>> popupMenuKey,
  required List<Map<String, String>> countries,
  required TextEditingController controller,
  required Function(String) onCountrySelect,
  final FocusNode? focusNode,
  final void Function(String)? onFieldSubmitted,
  final String? Function(String?)? validator,
}) {
  // State to hold current error message
  String? errorText;

  return StatefulBuilder(
    builder: (context, setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Phone Field Container
          Container(
            height: 56.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(11.r),
              border: Border.all(
                color:  AppColors.greyBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Country Code Dropdown
                PopupMenuButton<String>(
                  key: popupMenuKey,
                  offset: Offset(0, 56.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  color: AppColors.white,
                  onSelected: onCountrySelect,
                  constraints: BoxConstraints(
                    maxHeight: 300.h,
                    minWidth: 160.w,
                    maxWidth: 200.w,
                  ),
                  itemBuilder: (context) => countries.map((country) {
                    return PopupMenuItem(
                      value: country["code"],
                      child: Row(
                        children: [
                          customText(
                            text: country["flag"]!,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.black,
                          ),
                          SizedBox(width: 12.w),
                          customText(
                            text: country["code"]!,
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  child: Row(
                    children: [
                      customText(
                        text: selectedCode,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      SizedBox(width: 16.w),
                      Container(
                        width: 48.w,
                        height: double.infinity,
                        decoration: BoxDecoration(color: AppColors.green),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.white,
                          size: 28.w,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onFieldSubmitted: onFieldSubmitted,
                    keyboardType: TextInputType.phone,
                    validator: validator,
                    // Remove validator from here — we'll handle manually
                    onChanged: (value) {
                      // Trigger validation on change
                      final error = validator?.call(value);
                      setState(() {
                        errorText = error;
                      });
                    },
                    style: TextStyle(fontSize: 16.sp, color: AppColors.black),
                    decoration: InputDecoration(
                      hintText: "e.g. 3001234567",
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 16.sp,
                      ),
                      border: InputBorder.none,
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Error Text — Container ke bahar, bilkul neeche
          if (errorText != null)
            Padding(
              padding: EdgeInsets.only(top: 6.h, left: 12.w),
              child: Text(
                errorText!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      );
    },
  );
}