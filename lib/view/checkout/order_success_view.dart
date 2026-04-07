import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/view_model/bottom_nav_view_model.dart';

class OrderSuccessScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final String? orderNumber;
  final DateTime? deliveryDate;
  final String? deliveryZone;
  final String? deliveryAddress;
  final double? total;
  final String? customerName;
  final String? customerPhone;

  const OrderSuccessScreen({
    super.key,
    this.orderId,
    this.orderNumber,
    this.deliveryDate,
    this.deliveryZone,
    this.deliveryAddress,
    this.total,
    this.customerName,
    this.customerPhone,
  });

  /// Returns the human-readable order number, never the raw MongoDB ObjectId.
  String get displayOrderNumber {
    // Prefer orderNumber if available
    if (orderNumber != null && orderNumber!.isNotEmpty) return orderNumber!;
    // If orderId looks like a human-readable number (starts with # or is short), use it
    if (orderId != null && orderId!.isNotEmpty) {
      // MongoDB ObjectIds are 24 hex chars — never show those
      final isMongoId = RegExp(r'^[a-f0-9]{24}$').hasMatch(orderId!);
      if (!isMongoId) return orderId!;
    }
    return '';
  }

  @override
  ConsumerState<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends ConsumerState<OrderSuccessScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  /// Returns true if a string looks like a raw MongoDB ObjectId (24 hex chars).
  bool _isMongoId(String s) => RegExp(r'^[a-f0-9]{24}$').hasMatch(s);

  @override
  Widget build(BuildContext context) {
    final addressOk = widget.deliveryAddress != null &&
        widget.deliveryAddress!.trim().isNotEmpty &&
        !_isMongoId(widget.deliveryAddress!.trim());
    final hasDeliveryInfo =
        widget.deliveryDate != null || (widget.deliveryZone != null && widget.deliveryZone!.isNotEmpty) || addressOk;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Confetti at the top
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: [
                  AppColors.primary,
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
                createParticlePath: _drawStar,
                numberOfParticles: 25,
                minBlastForce: 20,
                maxBlastForce: 60,
                emissionFrequency: 0.08,
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 20.h, bottom: 16.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ── Check icon ─────────────────────────────────────
                  Container(
                    width: 64.w,
                    height: 64.w,
                    decoration:  BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.btnColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 40.sp,
                      color: AppColors.btnColor,
                    ),
                  ),

                  verticalSpacer(height: 12.h),

                  // ── Title ──────────────────────────────────────────
                  customText(
                    text: "Order Placed Successfully! 🎉",
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    textAlign: TextAlign.center,
                  ),

                  verticalSpacer(height: 6),

                  // ── Subtitle ───────────────────────────────────────
                  customText(
                    text:
                        "Thank you for your purchase. We've sent a confirmation email with your order details.",
                    fontSize: 13,
                    color: Colors.grey[800]!,
                    fontWeight: FontWeight.w400,
                    textAlign: TextAlign.center,
                    maxLine: 3,
                  ),

                  verticalSpacer(height: 14),

                  // ── Order Number card ──────────────────────────────────
                  if (widget.displayOrderNumber.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgColor,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        children: [
                          customText(
                            text: "Order ID",
                            fontSize: 18,
                            color: Colors.grey[900]!,
                            fontWeight: FontWeight.w500,
                          ),
                          verticalSpacer(height: 4),
                          customText(
                            text: widget.displayOrderNumber,
                            fontSize: 16,
                            color: Colors.grey[900]!,
                            fontWeight: FontWeight.w600,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  // ── Delivery Information card ──────────────────────
                  if (hasDeliveryInfo) ...[
                    verticalSpacer(height: 14.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  color: AppColors.primary, size: 18.sp),
                              horizontalSpacer(width: 8.w),
                              customText(
                                text: "Delivery Information",
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                          if (widget.deliveryDate != null) ...[
                            verticalSpacer(height: 12.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    color: Colors.black, size: 18.sp),
                                horizontalSpacer(width: 8.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    customText(
                                      text: "Scheduled Delivery",
                                      fontSize: 14,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    customText(
                                      text: _formatDate(widget.deliveryDate!),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                          if (widget.deliveryZone != null &&
                              widget.deliveryZone!.isNotEmpty) ...[
                            verticalSpacer(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    color: Colors.black, size: 18.sp),
                                horizontalSpacer(width: 8.w),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    customText(
                                      text: "Delivery Zone",
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    customText(
                                      text: widget.deliveryZone!,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                          // ── Customer Name ──
                          if (widget.customerName != null &&
                              widget.customerName!.trim().isNotEmpty) ...[
                            verticalSpacer(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.person_outline,
                                    color: Colors.black, size: 18.sp),
                                horizontalSpacer(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      customText(
                                        text: "Customer Name",
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      customText(
                                        text: widget.customerName!.trim(),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // ── Customer Phone ──
                          if (widget.customerPhone != null &&
                              widget.customerPhone!.trim().isNotEmpty) ...[
                            verticalSpacer(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.phone_outlined,
                                    color: Colors.black, size: 18.sp),
                                horizontalSpacer(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      customText(
                                        text: "Phone Number",
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      customText(
                                        text: widget.customerPhone!.trim(),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (addressOk) ...[
                            verticalSpacer(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.home_outlined,
                                    color: Colors.black, size: 18.sp),
                                horizontalSpacer(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      customText(
                                        text: "Delivery Address",
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      customText(
                                        text: widget.deliveryAddress!.trim(),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                        maxLine: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],

           
                        ],
                      ),
                    ),
                  ],

                  // ── Total Paid ─────────────────────────────────────
                  if (widget.total != null) ...[
                    verticalSpacer(height: 10.h),
                    customText(
                      text: "Total Paid",
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    verticalSpacer(height: 4),
                    customText(
                      text:
                          "\$${widget.total!.toStringAsFixed(2)} CAD",
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ],

                  verticalSpacer(height: 16.h),
                ],
              ),
            ),

            // ── "Continue Shopping" button pinned at bottom ──────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              child: customButton(
                context: context,
                text: "Continue Shopping",
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontColor: AppColors.white,
                bgColor: AppColors.btnColor,
                borderRadius: 30.r,
                height: 54,
                width: double.infinity,
                onPressed: () {
                  ref.read(bottomNavProvider.notifier).state = BottomNavIndex.home;
                  goRouter.go(AppRoutes.host);
                },
                borderColor: AppColors.btnColor,
                isCircular: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Path _drawStar(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width * 0.61, size.height * 0.37);
    path.lineTo(size.width, size.height * 0.38);
    path.lineTo(size.width * 0.68, size.height * 0.61);
    path.lineTo(size.width * 0.79, size.height);
    path.lineTo(size.width * 0.5, size.height * 0.75);
    path.lineTo(size.width * 0.21, size.height);
    path.lineTo(size.width * 0.32, size.height * 0.61);
    path.lineTo(0, size.height * 0.38);
    path.lineTo(size.width * 0.39, size.height * 0.37);
    path.close();
    return path;
  }
}
