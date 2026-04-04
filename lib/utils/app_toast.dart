// import 'package:OptiSlip/export.dart';


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';

class CustomToast {
  static final FToast _fToast = FToast();

  static void init() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rootNavigatorKey.currentContext != null) {
        _fToast.init(rootNavigatorKey.currentContext!);
      }
    });
  }

  static void _show({
    required String message,
    ToastType type = ToastType.info,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    Fluttertoast.cancel();
    _fToast.removeQueuedCustomToasts();

    Color bgColor = switch (type) {
      ToastType.success => Colors.green,
      ToastType.error => AppColors.red,
      ToastType.warning => Colors.orange,
      _ => Colors.blue,
    };

    _fToast.showToast(
      child: Container(
        width: 1.sw,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha:0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: Colors.white, fontSize: 16))),
          ],
        ),
      ),
      gravity: gravity,
      toastDuration: Duration(seconds: 4),
    );
  }

  static void success({String? msg}) => _show(message: msg ?? '', type: ToastType.success);
  static void error({ String? msg}) => _show(message: msg ?? '', type: ToastType.error);
  static void warning({String? msg}) => _show(message: msg ?? "", type: ToastType.warning);
  static void info({String? msg}) => _show(message: msg ?? "", type: ToastType.info);
}

enum ToastType { success, error, warning, info }