import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/utils/driver_constants.dart';

// ─── STATUS BADGE ──────────────────────────────────────────────────────────
class DriverStatusBadge extends StatelessWidget {
  final String status;
  const DriverStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    switch (status) {
      case 'Pending':
        bg = DriverColors.amberLight;
        text = DriverColors.amber;
        label = 'Pending';
        break;
      case 'On My Way':
        bg = DriverColors.blueLight;
        text = DriverColors.blue;
        label = 'On My Way';
        break;
      case 'Delivered':
        bg = DriverColors.greenLight;
        text = DriverColors.green;
        label = 'Delivered';
        break;
      case 'water_test':
        bg = DriverColors.purpleLight;
        text = DriverColors.purple;
        label = 'Water Test';
        break;
      default:
        bg = DriverColors.border;
        text = DriverColors.textHint;
        label = status;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20.r)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10.sp, fontWeight: FontWeight.w700, color: text)),
    );
  }
}

// ─── WATER TEST STATUS PILL ────────────────────────────────────────────────
class WtPill extends StatelessWidget {
  final WtStatus status;
  const WtPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;
    switch (status) {
      case WtStatus.ok:
        bg = DriverColors.greenLight;
        text = DriverColors.green;
        label = 'OK';
        break;
      case WtStatus.low:
        bg = DriverColors.redLight;
        text = DriverColors.red;
        label = 'Low';
        break;
      case WtStatus.high:
        bg = DriverColors.amberLight;
        text = DriverColors.amber;
        label = 'High';
        break;
      case WtStatus.na:
        bg = DriverColors.border;
        text = DriverColors.textHint;
        label = 'N/A';
        break;
      case WtStatus.pending:
        bg = DriverColors.border;
        text = DriverColors.textHint;
        label = '--';
        break;
    }
    return Container(
      width: 50.w,
      padding: EdgeInsets.symmetric(vertical: 4.h),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20.r)),
      child: Text(label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              fontSize: 10.sp, fontWeight: FontWeight.w800, color: text)),
    );
  }
}

// ─── ORANGE BUTTON ─────────────────────────────────────────────────────────
class DriverOrangeButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final double? height;

  const DriverOrangeButton(
      {super.key,
      required this.text,
      this.onPressed,
      this.loading = false,
      this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height ?? 52.h,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DriverColors.orange,
          disabledBackgroundColor: DriverColors.orange.withOpacity(0.6),
          foregroundColor: DriverColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          elevation: 0,
        ),
        child: loading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(text,
                style: GoogleFonts.inter(
                    fontSize: 15.sp, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

// ─── GREEN BUTTON ──────────────────────────────────────────────────────────
class DriverGreenButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const DriverGreenButton(
      {super.key, required this.text, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DriverColors.greenMid,
          foregroundColor: DriverColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          elevation: 0,
        ),
        child: loading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(text,
                style: GoogleFonts.inter(
                    fontSize: 15.sp, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

// ─── INFO SECTION CARD ─────────────────────────────────────────────────────
class DriverInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const DriverInfoCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: DriverColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
            child: Row(children: [
              Icon(icon, size: 14.sp, color: DriverColors.textMuted),
              SizedBox(width: 6.w),
              Text(title.toUpperCase(),
                  style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: DriverColors.textHint,
                      letterSpacing: 0.8)),
            ]),
          ),
          Divider(height: 1, color: DriverColors.bg),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── INFO ROW ──────────────────────────────────────────────────────────────
class DriverInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const DriverInfoRow(
      {super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: DriverColors.textHint,
                  letterSpacing: 0.3)),
          SizedBox(height: 2.h),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? DriverColors.text)),
        ],
      ),
    );
  }
}

// ─── POOL TAG CHIP ─────────────────────────────────────────────────────────
class PoolTag extends StatelessWidget {
  final String label;
  const PoolTag(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 5.w, bottom: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: DriverColors.blueLight,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: DriverColors.blue)),
    );
  }
}

// ─── CHECKLIST ITEM ────────────────────────────────────────────────────────
class DriverChecklistItem extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;

  const DriverChecklistItem(
      {super.key,
      required this.label,
      required this.checked,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              color: checked ? DriverColors.orange : Colors.transparent,
              border: Border.all(
                  color: checked ? DriverColors.orange : DriverColors.border,
                  width: 2),
              borderRadius: BorderRadius.circular(7.r),
            ),
            child: checked
                ? Icon(Icons.check, color: Colors.white, size: 14.sp)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: DriverColors.text))),
        ]),
      ),
    );
  }
}

// ─── URGENT BANNER ─────────────────────────────────────────────────────────
class UrgentBanner extends StatelessWidget {
  final String text;
  const UrgentBanner(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: DriverColors.amberLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: DriverColors.amber.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded,
            color: DriverColors.amber, size: 18.sp),
        SizedBox(width: 8.w),
        Expanded(
            child: Text(text,
                style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: DriverColors.amber))),
      ]),
    );
  }
}

// ─── DRIVER HEADER ─────────────────────────────────────────────────────────
class DriverHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color bgColor;
  final VoidCallback? onBack;

  const DriverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.bgColor = const Color(0xFFF4511E),
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
            child: Row(children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                        color: Colors.white24, shape: BoxShape.circle),
                    child:
                        Icon(Icons.arrow_back, color: Colors.white, size: 18.sp),
                  ),
                ),
              if (onBack != null) SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.inter(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.white70,
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
                  BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
          ),
        ]),
      ),
    );
  }
}
