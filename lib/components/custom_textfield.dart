import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/utils/app_colors.dart';


class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final double width;
  final double? hintFontSize;
  final double borderRadius;
  final bool obscureText;
  final bool isPasswordField;
  final bool readOnly;
  final bool showSuffixIcon;
  final Color? suffixIconColor;
  final Color? suffixBgColor;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Color? borderColor;
  final Color? fillColor;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final int? minLines;
  final int? maxLines;
  final bool? enAbleTextField;
  final TextInputAction? textInputAction;
  final void Function()? onTap;
  final void Function()? onSuffixTap;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    this.controller,
     this.hintText,
    required this.width,
    this.hintFontSize,
    this.borderRadius = 8.0,
    this.obscureText = false,
    this.isPasswordField = false,
    this.readOnly = false,
    this.showSuffixIcon = false,
    this.suffixIconColor,
    this.suffixBgColor,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.borderColor,
    this.fillColor,
    this.keyboardType,
    this.enAbleTextField,
    this.focusNode,
    this.minLines,
    this.maxLines =1,
    this.onTap,
    this.onSuffixTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: widget.enAbleTextField,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        readOnly: widget.readOnly,
        obscureText: widget.isPasswordField ? _obscureText : widget.obscureText,
        minLines: widget.minLines ?? 1,
        maxLines: widget.isPasswordField ? 1 : widget.maxLines,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        onFieldSubmitted:widget.onFieldSubmitted,
        validator:widget.validator,
        
        style: TextStyle(
          fontSize: widget.hintFontSize ?? 20.sp,
          fontWeight: FontWeight.bold,
          fontFamily: GoogleFonts.nunito().fontFamily,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: widget.fillColor ?? Colors.white,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontSize: widget.hintFontSize ?? 20.sp,
            fontWeight: FontWeight.w400,
            fontFamily: GoogleFonts.nunito().fontFamily,
            color: Colors.grey,
          ),
          errorStyle: TextStyle(color: Colors.red),
          contentPadding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius.r),
            borderSide: BorderSide(color: widget.borderColor ?? AppColors.greyBorder, width: 1.w),
          ),
          disabledBorder:  OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius.r),
            borderSide: BorderSide(color: widget.borderColor ?? AppColors.greyBorder, width: 1.w),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius.r),
            borderSide: BorderSide(color: widget.borderColor ?? AppColors.greyBorder, width: 1.w),
          ),
          border:OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius.r),
            borderSide: BorderSide(color: widget.borderColor ?? AppColors.greyBorder, width: 1.w),
          ) ,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius.r),
            borderSide: BorderSide(color: widget.borderColor ?? AppColors.greyBorder, width: 1.w),
          ),
          isDense: true,
          errorMaxLines: 3,
          prefixIcon: widget.prefixIcon != null
              ? Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: GestureDetector(
                    onTap: widget.onTap,
                    child: Icon(widget.prefixIcon!),
                  ),
                )
              : null,
          suffixIcon: widget.isPasswordField || widget.showSuffixIcon
              ? GestureDetector(
                  onTap: () {
                    if (widget.isPasswordField) {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    }
                    widget.onSuffixTap?.call();
                  },
                  child: widget.isPasswordField
                      ? Icon(
                          _obscureText ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.black,
                        )
                      : widget.suffixIcon != null
                          ? Container(
                            height: 48,width: 30.w,
                            
                            decoration: BoxDecoration(
                              color: widget.suffixBgColor,
                              borderRadius: BorderRadius.only(topRight:Radius.circular(widget.borderRadius.r),bottomRight:Radius.circular(widget.borderRadius.r) )),
                           child: Padding(
                             padding: const EdgeInsets.only(right: 4.0),
                             child: Icon(widget.suffixIcon!,color: widget.suffixIconColor,),
                           ))
                          : null,
                )
              : null,
        ),
      ),
    );
  }
}
