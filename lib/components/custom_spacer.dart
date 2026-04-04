
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget verticalSpacer({required double height}) {
  return SizedBox(height:height.h ,);
}
Widget horizontalSpacer({required double width}) {
  return SizedBox(
    width: width.w,
  );
}