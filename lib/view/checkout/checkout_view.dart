import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/components/custom_textfield.dart';
import 'package:retro_route/model/address_model.dart' as app_address;
import 'package:retro_route/repository/order_repo.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view/address/address_view.dart';
import 'package:retro_route/view_model/address_view_model/address_view_model.dart';
import 'package:retro_route/view_model/address_view_model/selected_delivery_address_view_model.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/cart_view_model/cart_view_model.dart';
import 'package:retro_route/view_model/bottom_nav_view_model.dart';
import 'package:retro_route/config/delivery_zones.dart';
import 'package:retro_route/view_model/selected_delivery_date_provider.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  DateTime? _selectedDeliveryDate;
  final _deliveryNoteController = TextEditingController();
  bool _isProcessing = false;

  // ── Delivery zone state ──────────────────────────────────────────────
  DeliveryZone? _detectedZone;
  bool _isOutOfZone = false;
  String? _outOfZoneDay;
  DateTime? _outOfZoneDate;
  String? _lastDetectedAddressId;

  static const double _outOfZoneFee = 40.00;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).value?.data;
    final address = ref.read(addressProvider);
    if (user?.token != null) {
      if (address.addresses.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(addressProvider.notifier).fetchAddresses(user!.token);
          
        },);
      }
    }
  }

  @override
  void dispose() {
    _deliveryNoteController.dispose();
    super.dispose();
  }

  // ── Auto-detect zone from address city ──────────────────────────────
  void _detectZoneFromAddress(app_address.Address? address) {
    if (address == null || address.safeCity.isEmpty) {
      setState(() {
        _detectedZone = null;
      });
      return;
    }
    final zone = detectZoneByCity(address.safeCity);
    setState(() {
      _detectedZone = zone;
      if (zone != null) {
        _isOutOfZone = false;
        _outOfZoneDay = null;
        // Use user-selected date from milk run if available, otherwise auto-compute
        final userPickedDate = ref.read(selectedDeliveryDateProvider);
        if (userPickedDate != null) {
          _selectedDeliveryDate = userPickedDate;
        } else {
          // Set auto-computed as default first
          _selectedDeliveryDate = getNextDeliveryDateFromDays(zone.deliveryDays);
          // Then try loading per-address persisted date
          final addrId = address.safeId as String? ?? '';
          if (addrId.isNotEmpty) {
            loadAddressDeliveryDate(addrId).then((persistedDate) {
              if (persistedDate != null && mounted) {
                setState(() => _selectedDeliveryDate = persistedDate);
                ref.read(selectedDeliveryDateProvider.notifier).state = persistedDate;
              } else {
                // No per-address date — fall back to global onboarding date
                loadSelectedDeliveryDate().then((globalDate) {
                  if (globalDate != null && mounted) {
                    setState(() => _selectedDeliveryDate = globalDate);
                    ref.read(selectedDeliveryDateProvider.notifier).state = globalDate;
                  }
                });
              }
            });
          } else {
            // No address ID — try global onboarding date
            loadSelectedDeliveryDate().then((globalDate) {
              if (globalDate != null && mounted) {
                setState(() => _selectedDeliveryDate = globalDate);
                ref.read(selectedDeliveryDateProvider.notifier).state = globalDate;
              }
            });
          }
        }
      }
    });
  }

  /// Delivery is free for in-zone; flat $40 for out-of-zone only.
  double _computeShipping(double subtotal) {
    if (_isOutOfZone) return _outOfZoneFee;
    return 0.0;
  }

  List<DateTime> _getScheduleDates() {
    if (_detectedZone == null) return [];
    const days = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday'];
    final targetDays = _detectedZone!.deliveryDays.map((d) => days.indexOf(d.toLowerCase())).where((i) => i >= 0).toList();
    if (targetDays.isEmpty) return [];
    final dates = <DateTime>[];
    var check = DateTime.now().add(const Duration(days: 1));
    while (dates.length < 8) {
      final currentDay = check.weekday % 7;
      if (targetDays.contains(currentDay)) dates.add(check);
      check = check.add(const Duration(days: 1));
    }
    return dates;
  }

  void _showChangeDateSheet() {
    final dates = _getScheduleDates();
    if (dates.isEmpty) return;
    final fmt = DateFormat('EEE, MMM d');
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Delivery Date',
                  style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700)),
              SizedBox(height: 14.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8.h,
                  crossAxisSpacing: 8.w,
                  childAspectRatio: 3.2,
                ),
                itemCount: dates.length,
                itemBuilder: (_, idx) {
                  final date = dates[idx];
                  final current = _selectedDeliveryDate ?? getNextDeliveryDateFromDays(_detectedZone!.deliveryDays);
                  final isSelected = date.year == current.year && date.month == current.month && date.day == current.day;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDeliveryDate = date);
                      ref.read(selectedDeliveryDateProvider.notifier).state = date;
                      saveSelectedDeliveryDate(date);
                      // Also save per-address
                      final selAddr = ref.read(selectedDeliveryAddressProvider);
                      final addrId = selAddr?.safeId ?? '';
                      if (addrId.isNotEmpty) saveAddressDeliveryDate(addrId, date);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF9EF) : Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: isSelected ? AppColors.btnColor : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        fmt.format(date),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.btnColor : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final addressState = ref.watch(addressProvider);

    final selectedAddress = ref.watch(selectedDeliveryAddressProvider);

    // ── Auto-detect zone when address changes ──────────────────────────
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Ensure checkout always has a default selected address when available.
      if (selectedAddress == null && addressState.addresses.isNotEmpty) {
        ref
            .read(selectedDeliveryAddressProvider.notifier)
            .selectAddress(addressState.addresses.first);
        return;
      }

      // Re-detect zone whenever the selected address changes
      final addrId = selectedAddress?.safeId ?? '';
      if (addrId.isNotEmpty && addrId != _lastDetectedAddressId) {
        _lastDetectedAddressId = addrId;
        _detectZoneFromAddress(selectedAddress);
      }
    });

    // Sync delivery date when user picks one on the Change Delivery Date page
    final pickedDate = ref.watch(selectedDeliveryDateProvider);
    if (pickedDate != null && pickedDate != _selectedDeliveryDate) {
      _selectedDeliveryDate = pickedDate;
    }

    final subtotal = cart.subtotal;
    final hasOtherProducts = cart.items.any((item) => item.product.isService != true);
    final waterTestDiscount = cart.items.fold<double>(0, (sum, item) {
      final isService = item.product.isService == true;
      final shouldBeFree = isService && hasOtherProducts;
      if (!shouldBeFree) return sum;
      return sum + item.totalPrice;
    });
    final adjustedSubtotal = subtotal - waterTestDiscount;
    final shipping = _computeShipping(adjustedSubtotal);
    final tax = adjustedSubtotal * 0.13; // HST 13%
    final total = adjustedSubtotal + shipping + tax;

    return PopScope(
      canPop: !_isProcessing,
      child: AbsorbPointer(
        absorbing: _isProcessing,
        child: Stack(
          children: [
            Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: _isProcessing ? const SizedBox.shrink() : null,
        title: customText(
          text: "Checkout",
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verticalSpacer(height: 16),

              // ── 1. Delivery Address & Zone (merged) ────────────────────────
              _buildSectionTitle("Delivery Address"),
              verticalSpacer(height: 12),
              Container(
                padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 20.w),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectedAddress != null) ...[
                      customText(
                        text: selectedAddress.safeFullName,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      verticalSpacer(height: 6),
                      customText(
                        text: selectedAddress.displayAddress,
                        fontSize: 15.sp,
                        color: Colors.grey[700]!,
                        maxLine: 3,
                        fontWeight: FontWeight.w500,
                      ),
                      verticalSpacer(height: 6),
                      Builder(builder: (_) {
                        final phone = selectedAddress.safeMobile.isNotEmpty
                            ? selectedAddress.safeMobile
                            : (ref.read(authNotifierProvider).value?.data?.user.phone ?? '');
                        if (phone.isEmpty) return const SizedBox.shrink();
                        return customText(
                          text: "Phone: $phone",
                          fontSize: 14.sp,
                          color: Colors.grey[600]!,
                          fontWeight: FontWeight.w500,
                        );
                      }),
                    ] else
                      customText(
                        text: "No address selected",
                        fontSize: 16.sp,
                        color: Colors.grey[600]!,
                        fontWeight: FontWeight.w500,
                      ),

                    // ── Zone & delivery date info (inside same card) ────────
                    if (_detectedZone != null && !_isOutOfZone) ...[
                      verticalSpacer(height: 10),
                      Divider(color: Colors.grey[300], height: 1),
                      verticalSpacer(height: 10),
                      customText(
                        text: "Your Zone: Zone ${_detectedZone!.id}",
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      verticalSpacer(height: 4),
                      customText(
                        text: "Milk Run: Every ${_detectedZone!.deliveryDaysLabel}",
                        fontSize: 14.sp,
                        color: Colors.grey[700]!,
                        fontWeight: FontWeight.w500,
                      ),
                      verticalSpacer(height: 4),
                      customText(
                        text: "Your Delivery Date: ${formatDeliveryDate(_selectedDeliveryDate ?? getNextDeliveryDateFromDays(_detectedZone!.deliveryDays))}",
                        fontSize: 14.sp,
                        color: Colors.grey[600]!,
                        fontWeight: FontWeight.w500,
                      ),
                    ],

                    verticalSpacer(height: 8),

                    // Single button for both address & delivery date change
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => context.push(AppRoutes.myAddress),
                        icon: Icon(
                          Icons.edit_location_outlined,
                          size: 20.sp,
                          color: AppColors.primary,
                        ),
                        label: customText(
                          text: "Change Address & Delivery Date",
                          fontSize: 14.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              verticalSpacer(height: 8),

              // No zone detected warning
              if (_detectedZone == null &&
                  selectedAddress != null &&
                  selectedAddress.safeCity.isNotEmpty &&
                  !_isOutOfZone)
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700, size: 24.sp),
                      horizontalSpacer(width: 12.w),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade800,
                            ),
                            children: [
                              const TextSpan(text: "Your city is not in the delivery zone. We are working on it, but for now, please visit "),
                              TextSpan(
                                text: "www.retrorouteco.com",
                                style: const TextStyle(
                                  color: Color(0xFFE8751A),
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()..onTap = () {
                                  launchUrl(Uri.parse('https://www.retrorouteco.com/?from=app'), mode: LaunchMode.externalApplication);
                                },
                              ),
                              const TextSpan(text: " to place an order, and we will ship it to you."),
                            ],
                          ),
                          maxLines: 6,
                        ),
                      ),
                    ],
                  ),
                ),

              verticalSpacer(height: 6.h),

              // Delivery instructions
              _buildSectionTitle("Delivery Instructions"),
              verticalSpacer(height: 6.h),

              CustomTextField(
                controller: _deliveryNoteController,
                hintText: "e.g. Call before delivery, leave at gate...",
                maxLines: 3,
                borderRadius: 16.r,
                width: 1.sw,
                minLines: 2,
                hintFontSize: 14,
              ),

              verticalSpacer(height: 16.h),
              _buildSectionTitle("Order Summary"),
              verticalSpacer(height: 12.h),
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...cart.items.map((cartItem) {
                      final product = cartItem.product;
                      final itemTotal =
                          product.priceForSize(cartItem.selectedSize) * cartItem.quantity;
                      final isService = product.isService == true;
                      final isWaterTestFree = isService && hasOtherProducts;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 14.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: CachedNetworkImage(
                                imageUrl: product.firstImage,
                                width: 50.w,
                                height: 50.w,
                                fit: BoxFit.cover,
                              ),
                            ),
                            horizontalSpacer(width: 12.w),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  customText(
                                    text: product.safeName,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    maxLine: 2,
                                  ),
                                  verticalSpacer(height: 4.h),
                                  Row(
                                    children: [
                                      customText(
                                        text: "${cartItem.quantity} × ",
                                        fontSize: 14.sp,
                                        color: Colors.grey[600]!,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      customText(
                                        text:
                                            "\$${product.priceForSize(cartItem.selectedSize).toStringAsFixed(2)}",
                                        fontSize: 14.sp,
                                        color: Colors.grey[700]!,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            if (isWaterTestFree)
                              customText(
                                text: "FREE",
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                              )
                            else
                              customText(
                                text: "\$${itemTotal.toStringAsFixed(2)}",
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      );
                    }).toList(),

                    verticalSpacer(height: 8),
                    Divider(color: Colors.grey[300], height: 1),
                    verticalSpacer(height: 8),

                    // Subtotal
                    _buildPriceRow("Subtotal", subtotal),
                    if (waterTestDiscount > 0) ...[
                      verticalSpacer(height: 8),
                      _buildPriceRow(
                        "Water Test Discount",
                        -waterTestDiscount,
                        valueColor: Colors.green,
                        labelColor: Colors.green,
                      ),
                      verticalSpacer(height: 8),
                      _buildPriceRow(
                        "After Discount",
                        adjustedSubtotal,
                        isBold: true,
                      ),
                    ],
                    verticalSpacer(height: 8),

                    // Delivery — dynamic label
                    _buildShippingRow(shipping, adjustedSubtotal),
                    verticalSpacer(height: 8),

                    // Tax
                    _buildPriceRow("Tax (HST 13%)", tax),
                    verticalSpacer(height: 4),

                    Divider(color: Colors.grey[300]),
                    verticalSpacer(height: 4),

                    // Total (highlighted)
                    _buildPriceRow("Total", total, isBold: true, isLarge: true),
                  ],
                ),
              ),

              verticalSpacer(height: 40.h),

              // Bottom safe area space
              SizedBox(height: 100.h),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
          24.w,
          20.h,
          24.w,
          24.h + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            customButton(
          context: context,
          text: _isProcessing ? "Processing..." : "Pay \$${total.toStringAsFixed(2)} CAD",
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          fontColor: Colors.white,
          bgColor: AppColors.btnColor,
          borderRadius: 20.r,
          height: 48,
          width: double.infinity,
          isLoading: _isProcessing,
          onPressed: _isProcessing ? null : () async {
            if (selectedAddress == null) {
              CustomToast.info(msg: "Please select a delivery address");
              return;
            }

            if (_isOutOfZone && (_outOfZoneDay == null || _outOfZoneDay!.isEmpty)) {
              CustomToast.info(msg: "Please select a preferred delivery day");
              return;
            }

            if (_isOutOfZone && _outOfZoneDate == null) {
              CustomToast.info(msg: "Please select a preferred delivery date");
              return;
            }

            if (cart.items.isEmpty) return;

            setState(() => _isProcessing = true);
            ref.read(paymentProcessingProvider.notifier).state = true;

            try {
              final userToken =
                  ref.read(authNotifierProvider).value?.data?.token;
              if (userToken == null) throw Exception("Not authenticated");

              // Prepare products list
              final products = cart.items.map((item) {
                return {
                  "productId": item.product.id,
                  "quantity": item.quantity,
                  if (item.selectedSize != null) "selectedSize": item.selectedSize,
                };
              }).toList();

              // Sync local cart to backend (so server-side cart has selectedSize)
              await ref.read(orderRepoProvider).syncCartToBackend(
                    token: userToken,
                    cartItems: products,
                  );

              // Determine delivery date
              final deliveryDate = _selectedDeliveryDate ?? DateTime.now().add(const Duration(days: 3));

              // Call backend
              final orderData = await ref
                  .read(orderRepoProvider)
                  .createOrderAndGetPaymentIntent(
                    token: userToken,
                    products: products,
                    customerNote: _deliveryNoteController.text.trim(),
                    addressId: selectedAddress.safeId,
                    totalPrice: total,
                    deliveryCharges: shipping,
                    scheduledDeliveryDate: deliveryDate,
                    deliveryZone: _isOutOfZone
                        ? 'Out of Zone'
                        : _detectedZone != null
                            ? 'Zone ${_detectedZone!.id}'
                            : '',
                    deliveryDay: _isOutOfZone
                        ? _outOfZoneDay ?? ''
                        : _detectedZone?.deliveryDaysLabel ?? '',
                    isOutOfZone: _isOutOfZone,
                  );

              // Initialize Payment Sheet
              await Stripe.instance.initPaymentSheet(
                paymentSheetParameters: SetupPaymentSheetParameters(
                  paymentIntentClientSecret: orderData.clientSecret,
                  merchantDisplayName: 'Retro Route Co',
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

              // Confirm payment status with backend
              try {
                await ref.read(orderRepoProvider).confirmPayment(
                      token: userToken,
                      orderId: orderData.orderId,
                    );
              } catch (_) {}

              CustomToast.success(
                  msg: "Payment successful! Thank you for your order.");

              // Clear cart
              ref.read(cartProvider.notifier).clear();

              // Navigate to success
              if (!mounted) return;
              goRouter.go(AppRoutes.success, extra: {
                'orderId': orderData.orderId,
                'orderNumber': orderData.orderNumber,
                'deliveryDate': deliveryDate,
                'deliveryZone': _isOutOfZone
                    ? 'Out of Zone'
                    : _detectedZone != null
                        ? _detectedZone!.name
                        : '',
                'deliveryAddress': selectedAddress.displayAddress.isNotEmpty
                    ? selectedAddress.displayAddress
                    : selectedAddress.safeCity,
                'total': total,
                'customerName': selectedAddress.safeFullName,
                'customerPhone': selectedAddress.safeMobile.isNotEmpty
                    ? selectedAddress.safeMobile
                    : (ref.read(authNotifierProvider).value?.data?.user.phone ?? ''),
              });
            } on StripeException catch (e) {
              String message = 'Payment failed';
              if (e.error.localizedMessage != null) {
                message = e.error.localizedMessage!;
              }
              CustomToast.error(msg: message);
            } on Exception catch (e) {
              CustomToast.error(msg: e.toString());
            } finally {
              if (mounted) {
                setState(() => _isProcessing = false);
                ref.read(paymentProcessingProvider.notifier).state = false;
              }
            }
          },
          borderColor: _isOutOfZone ? Colors.grey.shade400 : AppColors.btnColor,
          isCircular: false,
        ),
          ],
        ),
      ),
    ),
    if (_isProcessing)
      Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16.h),
                    Text(
                      'Processing payment…',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Please wait, do not close this screen.',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isLarge = false,
    Color? labelColor,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        customText(
          text: label,
          fontSize: isLarge ? 20 : 17,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: labelColor ?? Colors.black87,
        ),
        customText(
          text: "\$${amount.toStringAsFixed(2)}",
          fontSize: isLarge ? 24 : 18,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: valueColor ?? (isBold ? AppColors.primary : Colors.black87),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return customText(
      text: title,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
    );
  }


  // ── Out-of-Zone Delivery Card ────────────────────────────────────────
  Widget _buildOutOfZoneCard() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Icon(Icons.local_shipping_outlined,
                      color: Colors.white, size: 22.sp),
                ),
              ),
              horizontalSpacer(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customText(
                      text: "Delivery Outside Our Zones?",
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    verticalSpacer(height: 4.h),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                "If your address is outside our regular delivery zones, we can still deliver to you for a flat rate of ",
                          ),
                          TextSpan(
                            text:
                                "\$${_outOfZoneFee.toStringAsFixed(0)}.00",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          const TextSpan(
                              text:
                                  ". Simply select your preferred delivery day and date below."),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          verticalSpacer(height: 16.h),

          // Checkbox
          InkWell(
            onTap: () {
              setState(() {
                _isOutOfZone = !_isOutOfZone;
                if (_isOutOfZone) {
                  _detectedZone = null;
                } else {
                  _outOfZoneDay = null;
                  _outOfZoneDate = null;
                  // Re-detect zone from current address
                  final addr = ref.read(selectedDeliveryAddressProvider);
                  _detectZoneFromAddress(addr);
                }
              });
            },
            borderRadius: BorderRadius.circular(8.r),
            child: Row(
              children: [
                SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: Transform.scale(
                    scale: 0.7,
                    child: Checkbox(
                      value: _isOutOfZone,
                      activeColor: Colors.amber.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r)),
                      onChanged: (val) {
                        setState(() {
                          _isOutOfZone = val ?? false;
                          if (_isOutOfZone) {
                            _detectedZone = null;
                          } else {
                            _outOfZoneDay = null;
                            _outOfZoneDate = null;
                            final addr =
                                ref.read(selectedDeliveryAddressProvider);
                            _detectZoneFromAddress(addr);
                          }
                        });
                      },
                    ),
                  ),
                ),
                horizontalSpacer(width: 10.w),
                customText(
                  text: "I need out-of-zone delivery",
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ],
            ),
          ),

          // Day picker & Date picker (shown when out-of-zone is checked)
          if (_isOutOfZone) ...[
            verticalSpacer(height: 14.h),
            customText(
              text: "Preferred Delivery Day",
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700]!,
            ),
            verticalSpacer(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _outOfZoneDay,
                  isExpanded: true,
                  hint: customText(
                    text: "Select a day...",
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500]!,
                  ),
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.amber.shade700),
                  items: days.map((day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: customText(
                        text: day,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _outOfZoneDay = val;
                      // Reset the date when day changes
                      _outOfZoneDate = null;
                      _selectedDeliveryDate = null;
                    });
                  },
                ),
              ),
            ),

            // ── Date Picker ────────────────────────────────────────────
            verticalSpacer(height: 14.h),
            customText(
              text: "Preferred Delivery Date",
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700]!,
            ),
            verticalSpacer(height: 8.h),
            GestureDetector(
              onTap: () async {
                final tomorrow = DateTime.now().add(const Duration(days: 1));
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _outOfZoneDate ?? tomorrow,
                  firstDate: tomorrow,
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.amber.shade700,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black87,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _outOfZoneDate = picked;
                    _selectedDeliveryDate = picked;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: customText(
                        text: _outOfZoneDate != null
                            ? formatDeliveryDate(_outOfZoneDate!)
                            : "Select a date...",
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: _outOfZoneDate != null
                            ? Colors.black87
                            : Colors.grey[500]!,
                      ),
                    ),
                    Icon(Icons.calendar_today_rounded,
                        color: Colors.amber.shade700, size: 20.sp),
                  ],
                ),
              ),
            ),

            if (_outOfZoneDay != null && _outOfZoneDate != null) ...[
              verticalSpacer(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.amber.shade800, size: 16.sp),
                    horizontalSpacer(width: 8.w),
                    Expanded(
                      child: customText(
                        text:
                            "📦 Delivery: $_outOfZoneDay, ${formatDeliveryDate(_outOfZoneDate!)} — Fee: \$${_outOfZoneFee.toStringAsFixed(0)}.00",
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                        maxLine: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Shipping Row with dynamic label ──────────────────────────────────
  Widget _buildShippingRow(double shipping, double subtotal) {
    String label = "Shipping";
    Color valueColor = Colors.black87;
    String valueText;

    if (_isOutOfZone) {
      label = "Shipping (Out-of-zone)";
      valueText = "\$${shipping.toStringAsFixed(2)}";
      valueColor = Colors.amber.shade800;
    } else if (shipping == 0) {
      valueText = "FREE";
      valueColor = const Color(0xFF22c55e);
    } else {
      valueText = "\$${shipping.toStringAsFixed(2)}";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: customText(
            text: label,
            fontSize: 17.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        customText(
          text: valueText,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: valueColor,
        ),
      ],
    );
  }
}
