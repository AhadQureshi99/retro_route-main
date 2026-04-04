import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

Widget customText({
  required String text,
  required FontWeight fontWeight,
  required double fontSize,
  required Color color,
  TextOverflow? textFlow,
  int? maxLine,
  Color? decorationColor,
  TextDecoration? decoration,
  TextAlign? textAlign,
}) {
  return Text(
    text,
    overflow: textFlow,
    textAlign: textAlign,
    maxLines: maxLine,
    style: GoogleFonts.inter(
      fontWeight: fontWeight,
      fontSize: fontSize.sp,
      color: color,
      decoration: decoration,
      decorationColor: decorationColor,
    ),
  );
}

Widget customRichText({
  required List<TextSpan> textSpans,
  TextAlign? textAlign,
  TextOverflow? overflow,
  int? maxLines,
}) {
  return RichText(
    textAlign: textAlign ?? TextAlign.start,
    overflow: overflow ?? TextOverflow.clip,
    maxLines: maxLines,
    text: TextSpan(
      
      children: textSpans,
    ),
  );
}