import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:retro_route/repository/order_repo.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/utils/app_urls.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/crate_view_model/crate_view_model.dart';

class CrateApprovalScreen extends ConsumerStatefulWidget {
  final String orderId;
  const CrateApprovalScreen({super.key, required this.orderId});

  @override
  ConsumerState<CrateApprovalScreen> createState() => _CrateApprovalScreenState();
}

class _CrateApprovalScreenState extends ConsumerState<CrateApprovalScreen> {
  List<Map<String, dynamic>> _items = [];
  Set<int> _enabled = {}; // indices of toggled-on items
  bool _loaded = false;
  bool _approving = false;
  double _crateCredit = 0.0; // $39 credit from backend (0 if water test was already free)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = ref.read(authNotifierProvider).value?.data?.token ?? '';
    await ref.read(pendingCrateProvider.notifier).fetch(
          token: token,
          orderId: widget.orderId,
        );
    final data = ref.read(pendingCrateProvider).data;
    if (data != null) {
      final crate = data['pendingCrate'] as Map<String, dynamic>?;
      final rawItems = crate?['items'] as List<dynamic>? ?? [];
      final credit = (crate?['credit'] as num?)?.toDouble() ?? 0.0;
      setState(() {
        _items = rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _enabled = Set<int>.from(List.generate(_items.length, (i) => i));
        _crateCredit = credit;
        _loaded = true;
      });
    }
  }

  void _updateQty(int index, int delta) {
    setState(() {
      final newQty = ((_items[index]['qty'] as num?)?.toInt() ?? 1) + delta;
      if (newQty <= 0) {
        _items.removeAt(index);
        _enabled = _enabled
            .where((i) => i != index)
            .map((i) => i > index ? i - 1 : i)
            .toSet();
      } else {
        _items[index] = {..._items[index], 'qty': newQty};
      }
    });
  }

  double get _subtotal => _items.asMap().entries
      .where((e) => _enabled.contains(e.key))
      .fold<double>(0, (s, e) =>
          s + ((e.value['price'] as num?)?.toDouble() ?? 0) *
              ((e.value['qty'] as num?)?.toInt() ?? 1));

  int get _enabledCount => _items.asMap().entries
      .where((e) => _enabled.contains(e.key))
      .fold<int>(0, (s, e) => s + ((e.value['qty'] as num?)?.toInt() ?? 1));

  double get _waterTestFee => 0.0; // Water test fee is never added on crate screen
  double get _afterCredit => (_crateCredit > 0) ? (_subtotal - _crateCredit).clamp(0, double.infinity) : _subtotal;
  double get _hst => _afterCredit * 0.13;
  double get _total => _afterCredit + _hst;

  Future<void> _approve() async {
    if (_approving) return;
    setState(() => _approving = true);
    try {
    final token = ref.read(authNotifierProvider).value?.data?.token ?? '';
    final enabledItems = _items.asMap().entries
        .where((e) => _enabled.contains(e.key))
        .map((e) => e.value)
        .toList();
    final result = await ref.read(pendingCrateProvider.notifier).approve(
          token: token,
          orderId: widget.orderId,
          modifiedItems: enabledItems,
        );
    if (!mounted) return;
    if (result != null) {
      final clientSecret = result['clientSecret'] as String?;
      final orderId = result['orderId']?.toString() ?? '';

      if (clientSecret == null || clientSecret.isEmpty) {
        CustomToast.error(msg: 'Crate approved but payment setup failed. Please try again from your orders.');
        if (mounted) context.pop();
        return;
      }

      final isStripeTestMode = false;
      final googlePayCurrency =
          (result['currency']?.toString().trim().isNotEmpty ?? false)
              ? result['currency'].toString().trim().toUpperCase()
              : 'CAD';
      final googlePaySupported =
          defaultTargetPlatform == TargetPlatform.android
              ? await Stripe.instance.isPlatformPaySupported()
              : false;
      if (defaultTargetPlatform == TargetPlatform.android &&
          !googlePaySupported) {
        debugPrint(
          '[Stripe] Google Pay is not available on this device/profile.',
        );
      }

      try {
        // Initialize Stripe Payment Sheet
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Retro Route Co',
            applePay: defaultTargetPlatform == TargetPlatform.iOS
                ? const PaymentSheetApplePay(
                    merchantCountryCode: 'CA',
                  )
                : null,
            googlePay: defaultTargetPlatform == TargetPlatform.android
                ? PaymentSheetGooglePay(
                    merchantCountryCode: 'CA',
                    currencyCode: googlePayCurrency,
                    testEnv: false,
                  )
                : null,
            billingDetails: const BillingDetails(
              address: Address(
                city: '',
                country: 'CA',
                line1: '',
                line2: '',
                postalCode: '',
                state: '',
              ),
            ),
          ),
        );

        // Present Payment Sheet
        await Stripe.instance.presentPaymentSheet();

        // Confirm crate payment with dedicated endpoint
        try {
          final uri = Uri.parse(AppUrls.confirmCratePayment(orderId));
          await http.Client().put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${token.trim()}',
            },
          ).timeout(const Duration(seconds: 30));
        } catch (e) {
          debugPrint('[CratePayment] confirm failed: $e');
        }

        CustomToast.success(msg: 'Payment successful! Your crate is confirmed.');

        if (!mounted) return;
        context.go(AppRoutes.success, extra: {
          'orderId': orderId,
          'orderNumber': result['orderNumber']?.toString() ?? '',
          'total': (result['amount'] as num?)?.toDouble() ?? _total,
          'deliveryZone': result['deliveryZone']?.toString() ?? '',
          'deliveryDate': result['scheduledDeliveryDate'] != null
              ? DateTime.tryParse(result['scheduledDeliveryDate'].toString())
              : null,
          'deliveryAddress': _buildAddressString(result['deliveryAddress']),
          'customerName': result['customerName']?.toString() ?? '',
          'customerPhone': result['customerPhone']?.toString() ?? '',
        });
      } on StripeException catch (e) {
        if (e.error.code == FailureCode.Canceled) {
          CustomToast.error(msg: 'Payment cancelled');
        } else {
          CustomToast.error(msg: e.error.localizedMessage ?? 'Payment failed');
        }
      } catch (e) {
        CustomToast.error(msg: 'Payment error: $e');
      }
    } else {
      CustomToast.error(msg: ref.read(pendingCrateProvider).error ?? 'Approval failed');
    }
    } catch (e) {
      if (mounted) CustomToast.error(msg: 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  String _buildAddressString(dynamic addr) {
    if (addr == null) return '';
    if (addr is String) return addr;
    if (addr is Map) {
      final parts = <String>[
        addr['street']?.toString() ?? '',
        addr['city']?.toString() ?? '',
        addr['province']?.toString() ?? addr['state']?.toString() ?? '',
        addr['postalCode']?.toString() ?? addr['zipCode']?.toString() ?? '',
      ].where((s) => s.isNotEmpty).toList();
      return parts.join(', ');
    }
    return '';
  }

  Future<void> _decline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Decline Crate?', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to decline all recommended products?',
            style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Decline', style: TextStyle(color: Colors.red[700])),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = ref.read(authNotifierProvider).value?.data?.token ?? '';
    final ok = await ref.read(pendingCrateProvider.notifier).decline(
          token: token,
          orderId: widget.orderId,
        );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Crate declined'), backgroundColor: Colors.orange));
      context.go(AppRoutes.host);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to decline crate. Please try again.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final crateState = ref.watch(pendingCrateProvider);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: crateState.isLoading || !_loaded
          ? const Center(child: CircularProgressIndicator())
          : crateState.error != null
              ? Center(child: Text(crateState.error!, style: GoogleFonts.inter(color: Colors.red)))
              : Column(
                  children: [
                    // Header
                    Container(
                      color: AppColors.primary,
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => context.pop(),
                                    child: Container(
                                      width: 36.w,
                                      height: 36.w,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.arrow_back, color: Colors.white, size: 18.sp),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Crate Approval',
                                            style: GoogleFonts.inter(
                                                fontSize: 22.sp,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: -0.3)),
                                        Text('Review recommended products',
                                            style: GoogleFonts.inter(
                                                fontSize: 12.sp,
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.science_outlined, color: Colors.white70, size: 24.sp),
                                ],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Container(
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: AppColors.bgColor,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          children: [
                            // Info banner
                            Container(
                              padding: EdgeInsets.all(12.w),
                              margin: EdgeInsets.only(bottom: 8.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: AppColors.primary, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'Your driver tested your water today. Here\'s what your water needs:',
                                      style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Water Test FREE banner
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              margin: EdgeInsets.only(bottom: 12.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Text('✅', style: TextStyle(fontSize: 16.sp)),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text('Water Test   ✓ FREE',
                                        style: GoogleFonts.inter(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF2E7D32))),
                                  ),
                                  Text('Complimentary with products',
                                      style: GoogleFonts.inter(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2E7D32))),
                                ],
                              ),
                            ),

                            // Products list
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.cardBgColor,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
                                    child: Row(
                                      children: [
                                        Icon(Icons.inventory_2_outlined, size: 14.sp, color: Colors.grey),
                                        SizedBox(width: 6.w),
                                        Text('RECOMMENDED PRODUCTS',
                                            style: GoogleFonts.inter(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.grey,
                                                letterSpacing: 0.8)),
                                        const Spacer(),
                                        Text('${_items.length} items',
                                            style: GoogleFonts.inter(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[600])),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1, color: Colors.grey.shade200),
                                  ..._items.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final item = entry.value;
                                    final name = item['name'] ?? '';
                                    final reason = item['reason'] ?? '';
                                    final size = item['size'] ?? '';
                                    final qty = (item['qty'] as num?)?.toInt() ?? 1;
                                    final price = (item['price'] as num?)?.toDouble() ?? 0;
                                    final lineTotal = price * qty;
                                    final isOn = _enabled.contains(idx);

                                    return Opacity(
                                      opacity: isOn ? 1.0 : 0.45,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: idx < _items.length - 1
                                                  ? Colors.grey.shade200
                                                  : Colors.transparent,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Toggle checkbox
                                            GestureDetector(
                                              onTap: () => setState(() {
                                                if (isOn) { _enabled.remove(idx); } else { _enabled.add(idx); }
                                              }),
                                              child: Container(
                                                width: 22.w, height: 22.w,
                                                margin: EdgeInsets.only(top: 2.h, right: 8.w),
                                                decoration: BoxDecoration(
                                                  color: isOn ? AppColors.primary : Colors.transparent,
                                                  border: Border.all(
                                                    color: isOn ? AppColors.primary : Colors.grey.shade400,
                                                    width: 2,
                                                  ),
                                                  borderRadius: BorderRadius.circular(6.r),
                                                ),
                                                child: isOn
                                                    ? Icon(Icons.check, color: Colors.white, size: 14.sp)
                                                    : null,
                                              ),
                                            ),
                                            SizedBox(width: 10.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: RichText(
                                                        text: TextSpan(
                                                          children: [
                                                            TextSpan(
                                                              text: name,
                                                              style: GoogleFonts.inter(
                                                                  fontSize: 13.sp,
                                                                  fontWeight: FontWeight.w800,
                                                                  color: Colors.grey[900])),
                                                            TextSpan(
                                                              text: ' ×$qty',
                                                              style: GoogleFonts.inter(
                                                                  fontSize: 11.sp,
                                                                  fontWeight: FontWeight.w500,
                                                                  color: Colors.grey[600])),
                                                            if (size.isNotEmpty)
                                                              TextSpan(
                                                                text: ' · $size',
                                                                style: GoogleFonts.inter(
                                                                    fontSize: 11.sp,
                                                                    fontWeight: FontWeight.w600,
                                                                    color: Colors.grey[600])),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                  ],
                                                ),
                                                SizedBox(height: 2.h),
                                                Text(reason,
                                                    style: GoogleFonts.inter(
                                                        fontSize: 11.sp,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.grey[500])),
                                              ],
                                            ),
                                          ),
                                          // Qty controls
                                          Row(
                                            children: [
                                              _qtyBtn(Icons.remove, () => _updateQty(idx, -1)),
                                              Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                                child: Text('×$qty',
                                                    style: GoogleFonts.inter(
                                                        fontSize: 12.sp,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.grey[700])),
                                              ),
                                              _qtyBtn(Icons.add, () => _updateQty(idx, 1)),
                                              SizedBox(width: 8.w),
                                              Text('\$${lineTotal.toStringAsFixed(2)}',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 13.sp,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.grey[900])),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            SizedBox(height: 12.h),

                            // Price summary
                            Container(
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: AppColors.cardBgColor,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  _priceRow('Products (×$_enabledCount)', '\$${_subtotal.toStringAsFixed(2)}'),
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Divider(height: 1, color: Colors.grey.shade300),
                                  ),
                                  if (_crateCredit > 0)
                                    _priceRow(
                                      'Water Test Credit (incl. HST)',
                                      '-\$${_crateCredit.toStringAsFixed(2)}',
                                      valueColor: const Color(0xFF2E7D32),
                                    ),
                                  _priceRow('Subtotal', '\$${_afterCredit.toStringAsFixed(2)}'),
                                  _priceRow('HST (13%)', '\$${_hst.toStringAsFixed(2)}'),
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.h),
                                    child: Divider(height: 1, color: Colors.grey.shade300),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total Due Today',
                                          style: GoogleFonts.inter(
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.grey[900])),
                                      Text('\$${_total.toStringAsFixed(2)}',
                                          style: GoogleFonts.inter(
                                              fontSize: 22.sp,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.btnColor)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 20.h),

                            // Approve button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (crateState.isLoading || _approving) ? null : _approve,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                                  elevation: 0,
                                ),
                                child: (crateState.isLoading || _approving)
                                    ? SizedBox(
                                        height: 20.h,
                                        width: 20.w,
                                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text('✅ Approve Crate — \$${_total.toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                            fontSize: 15.sp, fontWeight: FontWeight.w800)),
                              ),
                            ),

                            SizedBox(height: 10.h),

                            // Decline button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: crateState.isLoading ? null : _decline,
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                                  side: BorderSide(color: Colors.red.shade300),
                                ),
                                child: Text('✕ Decline',
                                    style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.red[700])),
                              ),
                            ),

                            SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 32.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24.w,
        height: 24.w,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14.sp, color: Colors.grey[700]),
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w500, color: Colors.grey[600])),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? Colors.grey[800])),
        ],
      ),
    );
  }
}
