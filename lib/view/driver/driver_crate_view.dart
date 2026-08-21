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
  void initState() {
    super.initState();
    // If reopening the screen for a delivery already submitted (pending_approval),
    // resume polling automatically and restore crate items from backend data.
    if (widget.delivery.cratePending) {
      _submitted = true;
      _waitingApproval = true;
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkApproval());

      // Restore generatedCrate from the delivery's pendingCrate items
      final items = widget.delivery.crateApprovedItems;
      if (items.isNotEmpty) {
        final restored = items
            .map((m) => CrateItem.fromMap(m))
            .toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(driverDeliveriesProvider.notifier).restoreCrate(restored);
        });
      }
    }
  }

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
    } else if (updated != null && updated.crateDeclined) {
      _navigatedToDeliver = true;
      _pollTimer?.cancel();
      _pollTimer = null;
      setState(() => _waitingApproval = false);
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Crate Declined'),
            content: const Text('The customer has declined the recommended crate.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) {
          context.go(AppRoutes.driverHome);
        }
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

              // Add Products button
              if (!_submitted && !_waitingApproval)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddProductSheet(context),
                    icon: Icon(Icons.add, size: 16.sp),
                    label: Text('Add Products',
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                      side: BorderSide(color: DriverColors.border),
                      foregroundColor: DriverColors.text,
                    ),
                  ),
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

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddProductSheet(),
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

// ─────────────────────────────────────────────────────────────
// Add Products bottom sheet
// ─────────────────────────────────────────────────────────────
class _AddProductSheet extends ConsumerStatefulWidget {
  const _AddProductSheet();

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  // sku → selected qty
  final Map<String, int> _qty = {};

  List<Map<String, dynamic>> get _filtered {
    final all = AutoCrateLogic.catalogProducts;
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((p) {
      return (p['name'] as String).toLowerCase().contains(q) ||
          (p['sku'] as String).toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalSelected = _qty.values
        .where((qty) => qty > 0)
        .fold<int>(0, (sum, qty) => sum + qty);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: DriverColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: DriverColors.border,
              borderRadius: BorderRadius.circular(99.r),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
            child: Row(children: [
              Text('Add Products',
                  style: GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: DriverColors.text)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, size: 20.sp, color: DriverColors.textMuted),
              ),
            ]),
          ),
          SizedBox(height: 10.h),

          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: GoogleFonts.inter(fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: 'Search by name or SKU…',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13.sp, color: DriverColors.textHint),
                prefixIcon: Icon(Icons.search, size: 18.sp, color: DriverColors.textHint),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        child: Icon(Icons.clear, size: 16.sp, color: DriverColors.textHint),
                      )
                    : null,
                filled: true,
                fillColor: DriverColors.bg,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Divider(height: 1, color: DriverColors.bg),

          // Product list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No products found',
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, color: DriverColors.textMuted)))
                : ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      final sku = p['sku'] as String;
                      final qty = _qty[sku] ?? 0;
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: DriverColors.bg)),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name'] as String,
                                    style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: DriverColors.text)),
                                Text(
                                    '${p['size']}  ·  SKU ${p['sku']}  ·  \$${(p['price'] as double).toStringAsFixed(2)}',
                                    style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        color: DriverColors.textHint,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // Qty stepper
                          Row(children: [
                            GestureDetector(
                              onTap: () => setState(() {
                                if (qty > 0) _qty[sku] = qty - 1;
                              }),
                              child: Container(
                                width: 26.w,
                                height: 26.w,
                                decoration: BoxDecoration(
                                    color: DriverColors.bg,
                                    shape: BoxShape.circle),
                                child: Icon(Icons.remove, size: 13.sp),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text('$qty',
                                style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: qty > 0
                                        ? DriverColors.text
                                        : DriverColors.textHint)),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () => setState(() {
                                _qty[sku] = qty + 1;
                              }),
                              child: Container(
                                width: 26.w,
                                height: 26.w,
                                decoration: BoxDecoration(
                                    color: DriverColors.greenLight,
                                    shape: BoxShape.circle),
                                child: Icon(Icons.add,
                                    size: 13.sp, color: DriverColors.green),
                              ),
                            ),
                          ]),
                        ]),
                      );
                    },
                  ),
          ),

          // Add to Crate button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: totalSelected == 0
                      ? null
                      : () {
                          final items =
                              _qty.entries.where((e) => e.value > 0).toList();
                          if (items.isEmpty) return;

                          final notifier =
                              ref.read(driverDeliveriesProvider.notifier);
                          final catalog = AutoCrateLogic.catalogProducts;
                          if (catalog.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Product catalog unavailable. Please reopen and try again.'),
                              ),
                            );
                            return;
                          }

                          var addedCount = 0;
                          for (final entry in items) {
                            final matches =
                                catalog.where((p) => p['sku'] == entry.key);
                            if (matches.isEmpty) continue;
                            final prod = matches.first;
                            notifier.addCrateItem(CrateItem(
                              sku: prod['sku'] as String,
                              name: prod['name'] as String,
                              size: prod['size'] as String,
                              price: (prod['price'] as num).toDouble(),
                              qty: entry.value,
                              reason: 'Manually added',
                              urgent: false,
                            ));
                            addedCount += entry.value;
                          }

                          if (addedCount == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Selected products not found in catalog. Try clearing search and reselecting.'),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverColors.greenMid,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        DriverColors.greenMid.withOpacity(0.45),
                    disabledForegroundColor: Colors.white70,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                    elevation: 0,
                  ),
                  child: Text(
                      'Add $totalSelected item(s) to Crate',
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
