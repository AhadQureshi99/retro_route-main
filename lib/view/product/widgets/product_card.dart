import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/utils/app_colors.dart';

Widget productCard({
  required String imageassets,
  String? title1,
  String? title2,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(imageassets, width: 44.w, height: 44.h),
      customText(
        text: title1 ?? "",
        fontWeight: FontWeight.w800,
        fontSize: 16,
        color: AppColors.primary,
      ),
      customText(
        text: title2 ?? "",
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: const Color.fromARGB(255, 71, 225, 230),
      ),
    ],
  );
}
