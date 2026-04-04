

// import 'package:OptiSlip/export.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/utils/app_colors.dart';

Widget customDropdownFieldWithPrefixIcon({
  required BuildContext context,
  required String hintText,
  String? iconPath, 
  String? prefixIconPath,
  Color? borderColor,
  required double width,
  double? height,
  Color? fillColor,
  double? hintFontSize,
  required double borderRadius,
  required List<String> items,
  required void Function(String?) onChanged,
  String? value,
  final Widget Function(BuildContext, String)? itemBuilder,
}) {
  return SizedBox(
    width: width.w,
    height: height?.h,
    child: DropdownButtonFormField<String>(
      dropdownColor: AppColors.white,
      borderRadius: BorderRadius.circular(16.r),
      isDense: true,
      initialValue: value ?? items.first,
      onChanged: onChanged,
      icon: iconPath != null && iconPath.isNotEmpty
          ? Padding(
              padding: EdgeInsets.only(right: 0.w),
              child: SvgPicture.asset(
                iconPath,
                height: 16.h,
                width: 16.h,
                fit: BoxFit.scaleDown,
              ),
            )
          : const Icon(Icons.arrow_drop_down, color: Colors.black, size: 28),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor ?? AppColors.white,
        prefixIcon: prefixIconPath != null && prefixIconPath.isNotEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: SvgPicture.asset(
                  prefixIconPath,
                  width: 20.w,
                  height: 20.h,
                  fit: BoxFit.scaleDown,
                ),
              )
            : null,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
          borderSide: BorderSide(
            color: borderColor ?? AppColors.green,
            width: 1.w,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
          borderSide: BorderSide(
            color: borderColor ?? AppColors.green,
            width: 1.w,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius.r),
          borderSide: BorderSide(
            color: borderColor ?? AppColors.green,
            width: 1.w,
          ),
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.grey,
          fontSize: hintFontSize?.sp ?? 20.sp,
          fontWeight: FontWeight.w400,
          fontFamily: GoogleFonts.nunito().fontFamily,
          fontStyle: FontStyle.normal,
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: 12.h,
          horizontal: fillColor != null ? 18.w : 4.w,
        ),
      ),
      style: TextStyle(
        color: AppColors.black,
        fontSize: 20.sp,
        fontFamily: GoogleFonts.nunito().fontFamily,
        fontWeight: FontWeight.bold,
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: itemBuilder != null
                  ? itemBuilder(context, e)
                  : Text(
                      e,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 18.sp,
                        fontFamily: GoogleFonts.nunito().fontFamily,
                      ),
                    ),
            ),
          )
          .toList(),
    ),
  );
}

//????????????????/

Widget customDropdownButton2FieldWithSuffixIcons({
  required BuildContext context,
  required String hintText,
  String? iconPath,
  String? prefixIconPath,
  Color? borderColor,
  required double width,
  double? height,
  Color? fillColor,
  double? hintFontSize,
  required double borderRadius,
  required List<String> items,
  required void Function(String?) onChanged,
  String? value,
  Widget Function(BuildContext, String)? itemBuilder,
  String? Function(String?)? validator,
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
}) {
  return SizedBox(
    width: width.w,
    height: height?.h ?? 56.h,
    child: DropdownButtonFormField2<String>(
      value: value,
      hint: Text(
        hintText,
        style: TextStyle(
          color: Colors.grey,
          fontSize: hintFontSize?.sp ?? 18.sp,
          fontWeight: FontWeight.w400,
          fontFamily: GoogleFonts.inter().fontFamily,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
         
          child: itemBuilder != null
              ? itemBuilder(context, item)
              : Text(
                  item,
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                    fontFamily: GoogleFonts.nunito().fontFamily,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: autovalidateMode,

      // Beautiful dropdown menu styling
      dropdownStyleData: DropdownStyleData(
        maxHeight: 300.h,
        width: width.w - 32.w, // matches field width minus padding
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius.r),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),

        offset: Offset(0, -4), // Perfect alignment below field
        scrollbarTheme: ScrollbarThemeData(
          
          radius: Radius.circular(10.r),
          thickness: WidgetStateProperty.all(6),
          thumbVisibility: WidgetStateProperty.all(true),
        ),
      ),

      // Menu item styling
      menuItemStyleData: MenuItemStyleData(
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
      ),

      // Custom dropdown button (the field itself)
      buttonStyleData: ButtonStyleData(
        height: height?.h ?? 56.h,
        padding: EdgeInsets.only(left: 16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius.r),
          border: Border.all(
            color: borderColor ?? AppColors.greyBorder,
            width: 1.w,
          ),
          color: fillColor ?? AppColors.white,
        ),
      ),

      // Custom icon (trailing)
      iconStyleData: IconStyleData(
        icon: iconPath != null && iconPath.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Container(
                  padding: EdgeInsets.zero,
                  width: 56.w,
                  height: 58.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(borderRadius.r),

                      bottomRight: Radius.circular(borderRadius.r),
                    ),
                    color: AppColors.green,
                  ),
                  child: SvgPicture.asset(
                    iconPath,
                    height: 20.h,
                    width: 20.w,
                    colorFilter: ColorFilter.mode(
                      AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              )
            : Container(
                padding: EdgeInsets.zero,
                width: 60.w,
                height: 58.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(borderRadius.r - 1.r),

                    bottomRight: Radius.circular(borderRadius.r - 1.r),
                  ),
                  color: AppColors.green,
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 34.sp,
                  color: AppColors.white,
                ),
              ),
        iconSize: 30,
      ),

      // Prefix icon (left side)
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none, // Removes ALL borders
        enabledBorder: InputBorder.none, // Removes when enabled
        focusedBorder: InputBorder.none, // Removes when focused
        disabledBorder: InputBorder.none,
        prefixIcon: prefixIconPath != null && prefixIconPath.isNotEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: SvgPicture.asset(
                  prefixIconPath,
                  width: 24.w,
                  height: 24.h,
                  colorFilter: ColorFilter.mode(
                    AppColors.green,
                    BlendMode.srcIn,
                  ),
                ),
              )
            : null,
        hintStyle: TextStyle(
          color: AppColors.grey,
          fontSize: hintFontSize?.sp ?? 18.sp,
        ),
      ),

      // Selected value style
      style: TextStyle(
        color: AppColors.black,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        fontFamily: GoogleFonts.nunito().fontFamily,
      ),
    ),
  );
}





Widget customDropdownButton2FieldWithSuffixIconsTitle({
  required BuildContext context,
  required String hintText,
  String? iconPath,
  String? prefixIconPath,
  Color? borderColor,
  required double width,
  double? height,
  Color? fillColor,
  String? suffixTitle,
  double? hintFontSize,
  required double borderRadius,
  required List<String> items,
  required void Function(String?) onChanged,
  String? value,
  Widget Function(BuildContext, String)? itemBuilder,
  String? Function(String?)? validator,
  AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
}) {
  return SizedBox(
    width: width.w,
    height: height?.h ?? 56.h,
    child: DropdownButtonFormField2<String>(
      value: value,
      hint: Text(
        hintText,
        style: TextStyle(
          color: Colors.grey,
          fontSize: hintFontSize?.sp ?? 18.sp,
          fontWeight: FontWeight.w400,
          fontFamily: GoogleFonts.inter().fontFamily,
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
         
          child: itemBuilder != null
              ? itemBuilder(context, item)
              : Text(
                  item,
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                    fontFamily: GoogleFonts.nunito().fontFamily,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: autovalidateMode,

      // Beautiful dropdown menu styling
      dropdownStyleData: DropdownStyleData(
        maxHeight: 300.h,
        width: width.w - 32.w, // matches field width minus padding
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius.r),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),

        offset: Offset(0, -4), // Perfect alignment below field
        scrollbarTheme: ScrollbarThemeData(
          
          radius: Radius.circular(10.r),
          thickness: WidgetStateProperty.all(6),
          thumbVisibility: WidgetStateProperty.all(true),
        ),
      ),

      // Menu item styling
      menuItemStyleData: MenuItemStyleData(
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
      ),

      // Custom dropdown button (the field itself)
      buttonStyleData: ButtonStyleData(
        height: height?.h ?? 56.h,
        padding: EdgeInsets.only(left: 16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius.r),
          border: Border.all(
            color: borderColor ?? AppColors.greyBorder,
            width: 1.w,
          ),
          color: fillColor ?? AppColors.white,
        ),
      ),

      // Custom icon (trailing)
      iconStyleData: IconStyleData(
        icon: iconPath != null && iconPath.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: Container(
                  padding: EdgeInsets.zero,
                  width: 56.w,
                  height: 58.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(borderRadius.r),

                      bottomRight: Radius.circular(borderRadius.r),
                    ),
                    color: AppColors.green,
                  ),
                  child: SvgPicture.asset(
                    iconPath,
                    height: 20.h,
                    width: 20.w,
                    colorFilter: ColorFilter.mode(
                      AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              )
            : Container(
                padding: EdgeInsets.zero,
                width: 80.w,
                height: 58.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(borderRadius.r - 1.r),

                    bottomRight: Radius.circular(borderRadius.r - 1.r),
                  ),
                  color: AppColors.green,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    suffixTitle !=null ? customText(text: suffixTitle, fontWeight: FontWeight.w500, fontSize: 16, color: AppColors.white): SizedBox.shrink(),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 34.sp,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
        iconSize: 30,
      ),

      // Prefix icon (left side)
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none, // Removes ALL borders
        enabledBorder: InputBorder.none, // Removes when enabled
        focusedBorder: InputBorder.none, // Removes when focused
        disabledBorder: InputBorder.none,
        prefixIcon: prefixIconPath != null && prefixIconPath.isNotEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: SvgPicture.asset(
                  prefixIconPath,
                  width: 24.w,
                  height: 24.h,
                  colorFilter: ColorFilter.mode(
                    AppColors.green,
                    BlendMode.srcIn,
                  ),
                ),
              )
            : null,
        hintStyle: TextStyle(
          color: AppColors.grey,
          fontSize: hintFontSize?.sp ?? 18.sp,
        ),
      ),

      // Selected value style
      style: TextStyle(
        color: AppColors.black,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        fontFamily: GoogleFonts.nunito().fontFamily,
      ),
    ),
  );
}
