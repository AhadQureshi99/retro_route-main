import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:retro_route/model/driver_delivery_model.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/driver_constants.dart';
import 'package:retro_route/view/driver/widgets/driver_widgets.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/driver_view_model/driver_view_model.dart';

class DriverDeliverScreen extends ConsumerStatefulWidget {
  final DriverDelivery delivery;
  const DriverDeliverScreen({super.key, required this.delivery});

  @override
  ConsumerState<DriverDeliverScreen> createState() =>
      _DriverDeliverScreenState();
}

class _DriverDeliverScreenState extends ConsumerState<DriverDeliverScreen> {
  final _notes = TextEditingController();
  bool _photoDone = false,
      _paymentDone = false,
      _inventoryAuto = true,
      _notified = false;
  File? _proofImage;
  bool _uploading = false;

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final xFile =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (xFile != null) {
        setState(() {
          _proofImage = File(xFile.path);
          _photoDone = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Camera error: $e'),
          backgroundColor: DriverColors.red));
    }
  }

  Future<void> _confirm() async {
    if (!_photoDone) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Please take a delivery photo first'),
          backgroundColor: DriverColors.red));
      return;
    }
    if (!_paymentDone) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Please confirm payment collection'),
          backgroundColor: DriverColors.amber));
      return;
    }

    setState(() => _uploading = true);

    try {
      final token = ref.read(authNotifierProvider).value?.data?.token ?? '';
      bool ok;

      if (_proofImage != null) {
        ok = await ref
            .read(driverDeliveriesProvider.notifier)
            .updateDeliveryStatusWithProof(
              token: token,
              orderId: widget.delivery.id ?? '',
              status: 'Delivered',
              driverNotes: _notes.text,
              deliveryProofImage: _proofImage!,
            );
      } else {
        ok = await ref
            .read(driverDeliveriesProvider.notifier)
            .updateDeliveryStatus(
              token: token,
              orderId: widget.delivery.id ?? '',
              status: 'Delivered',
              driverNotes: _notes.text,
            );
      }

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Delivery confirmed! Moving to next stop.'),
            backgroundColor: Color(0xFF2E7D32)));
        context.go(AppRoutes.driverHome);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                ref.read(driverDeliveriesProvider).error ?? 'Delivery failed'),
            backgroundColor: DriverColors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Delivery failed: $e'),
          backgroundColor: DriverColors.red));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  // Use the delivery model's approved data (updated by backend after crate approval)
  late final List<Map<String, dynamic>> _approvedItems = widget.delivery.crateApprovedItems;
  late final double _total = widget.delivery.safeCrateTotal;

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final approvedItems = _approvedItems;

    return Scaffold(
      backgroundColor: DriverColors.bg,
      body: Column(children: [
        // Header
        Container(
          color: const Color(0xFF2E7D32),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Confirm Delivery',
                            style: GoogleFonts.inter(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5)),
                        Text(
                            '${widget.delivery.safeCustomerName} · \$${total.toStringAsFixed(2)} due',
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
                        BorderRadius.vertical(top: Radius.circular(24.r))),
              ),
            ]),
          ),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(children: [
              // Approved banner
              if (approvedItems.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12.w),
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                      color: DriverColors.greenLight,
                      borderRadius: BorderRadius.circular(12.r)),
                  child: Row(children: [
                    Icon(Icons.check_circle,
                        color: DriverColors.green, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Customer approved the crate',
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: DriverColors.green)),
                          Text(
                              '${approvedItems.length} items · \$${total.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: DriverColors.green,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ]),
                ),

              // Removed items section
              if (widget.delivery.crateRemovedItems.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12.w),
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: DriverColors.amber.withOpacity(0.3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.remove_circle_outline,
                            color: DriverColors.red, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                            'REMOVED BY CUSTOMER (${widget.delivery.crateRemovedItems.length})',
                            style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: DriverColors.red,
                                letterSpacing: 0.8)),
                      ]),
                      SizedBox(height: 8.h),
                      ...widget.delivery.crateRemovedItems.map((item) {
                        final name = item['name'] ?? '';
                        final sku = item['sku'] ?? '';
                        final qty = (item['qty'] as num?)?.toInt() ?? 1;
                        final price = (item['price'] as num?)?.toDouble() ?? 0;
                        final reason = item['reason'] ?? '';
                        final size = item['size'] ?? '';
                        final urgent = item['urgent'] == true;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 10.w,
                                height: 10.w,
                                margin: EdgeInsets.only(top: 3.h),
                                decoration: BoxDecoration(
                                  color: urgent
                                      ? DriverColors.red
                                      : DriverColors.textHint,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(children: [
                                        TextSpan(
                                          text: name,
                                          style: GoogleFonts.inter(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w800,
                                              color: DriverColors.text,
                                              decoration:
                                                  TextDecoration.lineThrough)),
                                        TextSpan(
                                          text: ' ×$qty',
                                          style: GoogleFonts.inter(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w500,
                                              color: DriverColors.textMuted)),
                                        if (size.isNotEmpty)
                                          TextSpan(
                                            text: ' · $size',
                                            style: GoogleFonts.inter(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w600,
                                                color: DriverColors.textMuted)),
                                      ]),
                                    ),
                                    Text(
                                        '${reason.isNotEmpty ? reason : 'N/A'} (SKU $sku) · \$${(price * qty).toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w500,
                                            color: DriverColors.textHint)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              // Qty changed items section
              Builder(builder: (_) {
                final qtyChanged = widget.delivery.crateApprovedItems.where((item) {
                  final origQty = (item['originalQty'] as num?)?.toInt();
                  final qty = (item['qty'] as num?)?.toInt() ?? 1;
                  return origQty != null && origQty != qty;
                }).toList();
                if (qtyChanged.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: EdgeInsets.all(12.w),
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.blue.withOpacity(0.3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.swap_horiz, color: Colors.blue[700], size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                            'QTY CHANGED BY CUSTOMER (${qtyChanged.length})',
                            style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue[700],
                                letterSpacing: 0.8)),
                      ]),
                      SizedBox(height: 8.h),
                      ...qtyChanged.map((item) {
                        final name = item['name'] ?? '';
                        final sku = item['sku'] ?? '';
                        final origQty = (item['originalQty'] as num?)?.toInt() ?? 1;
                        final qty = (item['qty'] as num?)?.toInt() ?? 1;
                        final price = (item['price'] as num?)?.toDouble() ?? 0;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                qty > origQty ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 14.sp,
                                color: qty > origQty ? Colors.blue[700] : DriverColors.amber,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(children: [
                                        TextSpan(
                                          text: name,
                                          style: GoogleFonts.inter(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w800,
                                              color: DriverColors.text)),
                                        TextSpan(
                                          text: '  ×$origQty → ×$qty',
                                          style: GoogleFonts.inter(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.blue[700])),
                                      ]),
                                    ),
                                    Text(
                                        '(SKU $sku) · \$${(price * qty).toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w500,
                                            color: DriverColors.textHint)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),

              // Current approved items (full list)
              if (approvedItems.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12.w),
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                      color: DriverColors.greenLight,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: DriverColors.green.withOpacity(0.3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.inventory_2_outlined,
                            color: DriverColors.green, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                            'CURRENT ORDER ITEMS (${approvedItems.length})',
                            style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: DriverColors.green,
                                letterSpacing: 0.8)),
                      ]),
                      SizedBox(height: 8.h),
                      ...approvedItems.map((item) {
                        final name = item['name'] ?? '';
                        final sku = item['sku'] ?? '';
                        final qty = (item['qty'] as num?)?.toInt() ?? 1;
                        final price = (item['price'] as num?)?.toDouble() ?? 0;
                        final size = item['size'] ?? '';
                        final reason = item['reason'] ?? '';
                        return Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 10.w,
                                height: 10.w,
                                margin: EdgeInsets.only(top: 3.h),
                                decoration: BoxDecoration(
                                  color: DriverColors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(children: [
                                        TextSpan(
                                          text: name,
                                          style: GoogleFonts.inter(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w800,
                                              color: DriverColors.text)),
                                        TextSpan(
                                          text: ' ×$qty',
                                          style: GoogleFonts.inter(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w500,
                                              color: DriverColors.textMuted)),
                                        if (size.isNotEmpty)
                                          TextSpan(
                                            text: ' · $size',
                                            style: GoogleFonts.inter(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w600,
                                                color: DriverColors.textMuted)),
                                      ]),
                                    ),
                                    Text(
                                        '${reason.isNotEmpty ? reason : ''} ${reason.isNotEmpty ? '· ' : ''}(SKU $sku) · \$${(price * qty).toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w500,
                                            color: DriverColors.textHint)),
                                  ],
                                ),
                              ),
                              Text(
                                  '\$${(price * qty).toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: DriverColors.green)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              // Price Breakdown
              if (widget.delivery.pendingCrate != null)
                DriverInfoCard(
                  title: 'Price Breakdown',
                  icon: Icons.receipt_long,
                  children: [
                    _buildPriceRow(
                      'Crate Subtotal',
                      '\$${((widget.delivery.pendingCrate!['subtotal'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                    ),
                    _buildPriceRow(
                      'HST (13%)',
                      '\$${((widget.delivery.pendingCrate!['hst'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                    ),
                    Divider(height: 16.h, color: DriverColors.bg),
                    _buildPriceRow(
                      'Total Amount',
                      '\$${(((widget.delivery.pendingCrate!['subtotal'] as num?)?.toDouble() ?? 0) + ((widget.delivery.pendingCrate!['hst'] as num?)?.toDouble() ?? 0)).toStringAsFixed(2)}',
                      isBold: true,
                      valueColor: DriverColors.green,
                    ),
                    if ((widget.delivery.pendingCrate!['credit'] as num?)?.toDouble() != null &&
                        (widget.delivery.pendingCrate!['credit'] as num).toDouble() > 0)
                      _buildPriceRow(
                        'Water Test Credit (incl. HST)',
                        '-\$${(widget.delivery.pendingCrate!['credit'] as num).toDouble().toStringAsFixed(2)}',
                        valueColor: const Color(0xFFE65100),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            children: List.generate(
                              (constraints.maxWidth / 8).floor(),
                              (i) => Expanded(
                                child: Container(
                                  height: 1,
                                  color: (i % 2 == 0) ? Colors.grey.shade300 : Colors.transparent,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildPriceRow(
                      'Crate Total',
                      '\$${((widget.delivery.pendingCrate!['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                      isBold: true,
                      valueColor: DriverColors.green,
                    ),
                  ],
                ),

              // Checklist
              DriverInfoCard(
                title: 'Checklist',
                icon: Icons.checklist,
                children: [
                  DriverChecklistItem(
                      label: 'Delivery photo taken',
                      checked: _photoDone,
                      onTap: () =>
                          setState(() => _photoDone = !_photoDone)),
                  Divider(height: 1, color: DriverColors.bg),
                  DriverChecklistItem(
                      label:
                          'Payment collected — \$${total.toStringAsFixed(2)}',
                      checked: _paymentDone,
                      onTap: () =>
                          setState(() => _paymentDone = !_paymentDone)),
                  Divider(height: 1, color: DriverColors.bg),
                  DriverChecklistItem(
                      label: 'Inventory auto-deducted ✓',
                      checked: _inventoryAuto,
                      onTap: () {}),
                  Divider(height: 1, color: DriverColors.bg),
                  DriverChecklistItem(
                      label: 'Customer notified via app',
                      checked: _notified,
                      onTap: () =>
                          setState(() => _notified = !_notified)),
                ],
              ),

              // Driver notes
              DriverInfoCard(
                title: 'Driver notes',
                icon: Icons.edit_note,
                children: [
                  TextField(
                    controller: _notes,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Optional — gate code, customer feedback...',
                      hintStyle: GoogleFonts.inter(
                          color: DriverColors.textHint, fontSize: 13.sp),
                      filled: true,
                      fillColor: DriverColors.bg,
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
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                  ),
                ],
              ),

              // Proof photo
              DriverInfoCard(
                title: 'Delivery proof photo',
                icon: Icons.camera_alt_outlined,
                children: [
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: _proofImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.file(_proofImage!,
                                height: 180.h,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                cacheHeight: 360,
                                filterQuality: FilterQuality.low))
                        : Container(
                            height: 120.h,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: DriverColors.border, width: 2),
                              borderRadius: BorderRadius.circular(12.r),
                              color: DriverColors.bg,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 32.sp,
                                    color: DriverColors.textHint),
                                SizedBox(height: 6.h),
                                Text('Tap to take photo',
                                    style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: DriverColors.text)),
                                Text(
                                    'Required for delivery confirmation',
                                    style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        color: DriverColors.textHint)),
                              ],
                            ),
                          ),
                  ),
                ],
              ),

              SizedBox(height: 10.h),
              DriverGreenButton(
                text: 'Confirm delivery →',
                onPressed: _confirm,
                loading: _uploading,
              ),
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 24.h),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                color: DriverColors.text,
              )),
          Text(value,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: valueColor ?? DriverColors.text,
              )),
        ],
      ),
    );
  }
}
