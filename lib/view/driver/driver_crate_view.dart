import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/model/driver_delivery_model.dart';
import 'package:retro_route/model/water_test_result_model.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/driver_constants.dart';
import 'package:retro_route/view/driver/widgets/driver_widgets.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/driver_view_model/driver_view_model.dart';

class DriverCrateScreen extends ConsumerStatefulWidget {
  final DriverDelivery delivery;
  const DriverCrateScreen({super.key, required this.delivery});

  @override
  ConsumerState<DriverCrateScreen> createState() => _DriverCrateScreenState();
}

class _DriverCrateScreenState extends ConsumerState<DriverCrateScreen> {
  bool _submitted = false;
  bool _submitting = false;
  bool _waitingApproval = false;
  Timer? _pollTimer;
  bool _navigatedToDeliver = false; // guard against double-push

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  Future<void> _submitAndWait() async {
    if (_submitting || _submitted) return;
    setState(() => _submitting = true);
    final token = ref.read(authNotifierProvider).value?.data?.token ?? '';
    final ok = await ref
        .read(driverDeliveriesProvider.notifier)
        .submitWaterTest(token: token);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _submitted = true;
        _submitting = false;
        _waitingApproval = true;
      });
      // Start polling every 5 seconds for customer approval
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkApproval());
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ref.read(driverDeliveriesProvider).error ?? 'Failed to submit water test'),
        backgroundColor: DriverColors.red,
      ));
    }
  }

  Future<void> _checkApproval() async {
    // Guard: if already navigated, do nothing
    if (_navigatedToDeliver) return;

    final token = ref.read(authNotifierProvider).value?.data?.token ?? '';
    // Refresh deliveries to get updated pendingCrate status
    await ref.read(driverDeliveriesProvider.notifier).fetchActiveDeliveries(token);
    if (!mounted || _navigatedToDeliver) return;

    // Find this delivery in the refreshed list
    final deliveries = ref.read(driverDeliveriesProvider).activeDeliveries;
    final updated = deliveries.where((d) => d.id == widget.delivery.id).firstOrNull;
    if (updated != null && updated.crateApproved) {
      _navigatedToDeliver = true; // prevent any concurrent callback from pushing again
      _pollTimer?.cancel();
      _pollTimer = null;
      setState(() => _waitingApproval = false);
      if (mounted) {
        // Use pushReplacement so the crate screen is disposed (kills any residual state)
        context.pushReplacement(AppRoutes.driverDeliver, extra: updated);
      }
    }
  }

  DriverDelivery get delivery => widget.delivery;

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverDeliveriesProvider);
    final crate = driverState.generatedCrate;
    final waterTest = driverState.pendingWaterTest;
    final urgentItems = crate.where((c) => c.urgent).toList();

    final subtotal =
        crate.fold<double>(0, (s, c) => s + c.lineTotal);
    // Only apply credit if customer paid full price for water test
    // Credit includes the $39 fee + HST charged on it
    final waterTestFee = 39.0;
    final waterTestCredit = (delivery.waterTestDiscount ?? 0) > 0 ? 0.0 : double.parse((waterTestFee + waterTestFee * 0.13).toStringAsFixed(2));
    final afterCredit = (subtotal - waterTestCredit).clamp(0.0, double.infinity);
    final hst = afterCredit * 0.13;
    final total = afterCredit + hst;

    return PopScope(
      canPop: !_waitingApproval,
      child: Scaffold(
      backgroundColor: DriverColors.bg,
      body: Column(children: [
        // Header
        Container(
          color: DriverColors.navy,
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                child: Row(children: [
                  if (!_waitingApproval)
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle),
                      child: Icon(Icons.arrow_back,
                          color: Colors.white, size: 18.sp),
                    ),
                  ),
                  if (!_waitingApproval)
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recommended Crate',
                            style: GoogleFonts.inter(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5)),
                        Text(
                            '${delivery.safeCustomerName} · based on water test',
                            style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.white60,
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
              if (urgentItems.isNotEmpty)
                UrgentBanner(
                    '${urgentItems.length} urgent item(s) — ${urgentItems.map((i) => i.name).take(2).join(', ')}'),

              if (waterTest != null) ...[
                Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  decoration: BoxDecoration(
                      color: DriverColors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05), blurRadius: 8)
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
                        child: Row(
                          children: [
                            Icon(Icons.science_outlined,
                                size: 14.sp, color: DriverColors.textHint),
                            SizedBox(width: 6.w),
                            Text('WATER TEST VALUES',
                                style: GoogleFonts.inter(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: DriverColors.textHint,
                                    letterSpacing: 0.8)),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: DriverColors.bg),
                      Padding(
                        padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
                        child: Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: _waterTestValueChips(waterTest),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Products list
              Container(
                decoration: BoxDecoration(
                    color: DriverColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 8)
                    ]),
                child: Column(children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
                    child: Row(children: [
                      Text('PRODUCTS',
                          style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: DriverColors.textHint,
                              letterSpacing: 0.8)),
                      const Spacer(),
                      Text('${crate.length} items',
                          style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: DriverColors.textMuted)),
                    ]),
                  ),
                  Divider(height: 1, color: DriverColors.bg),
                  ...crate.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    return Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 11.h),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: i < crate.length - 1
                                    ? DriverColors.bg
                                    : Colors.transparent)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 10.w,
                            height: 10.w,
                            margin: EdgeInsets.only(top: 3.h),
                            decoration: BoxDecoration(
                              color: item.urgent
                                  ? DriverColors.red
                                  : DriverColors.greenMid,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: item.name,
                                        style: GoogleFonts.inter(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w800,
                                            color: DriverColors.text)),
                                      TextSpan(
                                        text: ' ×${item.qty}',
                                        style: GoogleFonts.inter(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w500,
                                            color: DriverColors.textMuted)),
                                      if (item.size.isNotEmpty)
                                        TextSpan(
                                          text: ' · ${item.size}',
                                          style: GoogleFonts.inter(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w600,
                                              color: DriverColors.textMuted)),
                                    ],
                                  ),
                                ),
                                Text('${item.reason} (SKU ${item.sku})',
                                    style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w500,
                                        color: DriverColors.textHint)),
                              ],
                            ),
                          ),
                          Row(children: [
                            GestureDetector(
                              onTap: () => ref
                                  .read(driverDeliveriesProvider.notifier)
                                  .updateCrateQty(i, item.qty - 1),
                              child: Container(
                                width: 22.w,
                                height: 22.w,
                                decoration: BoxDecoration(
                                    color: DriverColors.bg,
                                    shape: BoxShape.circle),
                                child: Icon(Icons.remove, size: 12.sp),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              child: Text('×${item.qty}',
                                  style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      color: DriverColors.textMuted)),
                            ),
                            GestureDetector(
                              onTap: () => ref
                                  .read(driverDeliveriesProvider.notifier)
                                  .updateCrateQty(i, item.qty + 1),
                              child: Container(
                                width: 22.w,
                                height: 22.w,
                                decoration: BoxDecoration(
                                    color: DriverColors.bg,
                                    shape: BoxShape.circle),
                                child: Icon(Icons.add, size: 12.sp),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text('\$${item.lineTotal.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w800,
                                    color: DriverColors.text)),
                          ]),
                        ],
                      ),
                    );
                  }),
                ]),
              ),

              SizedBox(height: 10.h),

              // Price summary
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                    color: DriverColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 8)
                    ]),
                child: Column(children: [
                  _priceRow(
                      'Subtotal', '\$${subtotal.toStringAsFixed(2)}', false),
                  if (waterTestCredit > 0)
                    _priceRow('Water test credit (incl. HST)', '− \$${waterTestCredit.toStringAsFixed(2)}', false,
                        valueColor: DriverColors.green),
                  _priceRow('HST (13%)', '\$${hst.toStringAsFixed(2)}', false),
                  Divider(height: 20.h, color: DriverColors.bg),
                  _priceRow('Total due today',
                      '\$${total.toStringAsFixed(2)}', true),
                ]),
              ),

              SizedBox(height: 10.h),

              // Customer approval notice
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                    color: DriverColors.navy,
                    borderRadius: BorderRadius.circular(12.r)),
                child: Row(children: [
                  Icon(Icons.phone_iphone,
                      color: DriverColors.orange, size: 18.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                        'Show this screen to the customer — get approval before delivering',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),

              SizedBox(height: 16.h),

              // Action buttons
              if (_waitingApproval) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: DriverColors.amberLight,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: DriverColors.amber.withOpacity(0.3)),
                  ),
                  child: Column(children: [
                    SizedBox(
                      width: 28.w,
                      height: 28.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: DriverColors.amber,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text('Waiting for customer approval…',
                        style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: DriverColors.amber)),
                    SizedBox(height: 4.h),
                    Text('The customer will approve the crate on their app.\nThis screen will auto-advance once approved.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: DriverColors.amber,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              ] else
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                        side: BorderSide(color: DriverColors.border)),
                    child: Text('← Edit test',
                        style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: DriverColors.text)),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_submitted || _submitting) ? null : _submitAndWait,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: DriverColors.greenMid,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: DriverColors.greenMid.withOpacity(0.5),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                        elevation: 0),
                    child: _submitting
                        ? SizedBox(
                            height: 20.h,
                            width: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text('Submit & wait for approval',
                            style: GoogleFonts.inter(
                                fontSize: 14.sp, fontWeight: FontWeight.w800)),
                  ),
                ),
              ]),
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 40.h),
            ]),
          ),
        ),
      ]),
    ),
    );
  }

  List<Widget> _waterTestValueChips(WaterTestResult wt) {
    final entries = <MapEntry<String, double?>>[
      MapEntry('Free chlorine', wt.freeChlorine),
      MapEntry('Total chlorine', wt.totalChlorine),
      MapEntry('Bromine', wt.bromine),
      MapEntry('pH', wt.pH),
      MapEntry('Alkalinity', wt.alkalinity),
      MapEntry('Hardness', wt.hardness),
      MapEntry('Cyanuric acid', wt.cyanuricAcid),
      MapEntry('Copper', wt.copper),
      MapEntry('Iron', wt.iron),
      MapEntry('Phosphate', wt.phosphate),
      MapEntry('Salt', wt.salt),
      MapEntry('Borate', wt.borate),
      MapEntry('Biguanide', wt.biguanide),
      MapEntry('Biguanide shock', wt.biguanideShock),
    ].where((e) => e.value != null).toList();

    if (entries.isEmpty) {
      return [
        Text(
          'No values entered',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: DriverColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ];
    }

    return entries.map((e) {
      final value = e.key == 'pH'
          ? e.value!.toStringAsFixed(1)
          : (e.value! % 1 == 0)
              ? e.value!.toStringAsFixed(0)
              : e.value!.toStringAsFixed(1);

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: DriverColors.bg,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(color: DriverColors.border),
        ),
        child: Text(
          '${e.key}: $value',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: DriverColors.text,
          ),
        ),
      );
    }).toList();
  }

  Widget _priceRow(String label, String value, bool total,
      {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: total ? 15.sp : 13.sp,
                fontWeight: total ? FontWeight.w800 : FontWeight.w500,
                color: total ? DriverColors.text : DriverColors.textMuted)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: total ? 20.sp : 13.sp,
                fontWeight: total ? FontWeight.w900 : FontWeight.w700,
                color: valueColor ??
                    (total ? DriverColors.orange : DriverColors.text))),
      ]),
    );
  }
}
