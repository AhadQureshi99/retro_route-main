import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/utils/app_assets.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/auth_helper.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view/checkout/checkout_view.dart';
import 'package:retro_route/view/splash/q_onboarding_view.dart';
import 'package:retro_route/view_model/bottom_nav_view_model.dart';
import 'package:retro_route/view_model/cart_view_model/cart_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<bool> _isWaterTestFromSupplies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(waterTestFromSuppliesKey) ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final items = cart.items;
    final subtotal = cart.subtotal;
    final hasOtherProducts = items.any((item) => item.product.isService != true);
    final waterTestDiscount = items.fold<double>(0, (sum, item) {
      final isService = item.product.isService == true;
      final shouldBeFree = isService && hasOtherProducts;
      if (!shouldBeFree) return sum;
      return sum + item.totalPrice;
    });
    final adjustedSubtotal = subtotal - waterTestDiscount;
    final tax = adjustedSubtotal * 0.13; // Ontario HST 13%
    final total = adjustedSubtotal + tax;

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      // appBar: AppBar(
      //   backgroundColor: AppColors.primary,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      //   centerTitle: true,
      //   leading: IconButton(
      //     onPressed: () {
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(
      //           builder: (_) => const QuestionOnboardingScreenOne(initialScreen: 4),
      //         ),
      //       );
      //     },
      //     icon: const Icon(Icons.arrow_back),
      //   ),
      //   title: customText(
      //     text: "My Cart",
      //     fontSize: 24,
      //     fontWeight: FontWeight.bold,
      //     color: Colors.white,
      //   ),
      // ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70.h,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),

        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () {
            ref.read(cartProvider.notifier).clear();
            goRouter.go('${AppRoutes.onboarding}?screen=3');
          },
          child: Container(
            margin: EdgeInsets.only(left: 10.w, top: 8.h, bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B00).withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, color: Colors.white, size: 16.sp),
                SizedBox(width: 5.w),
                Text(
                  'Start Over',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
        leadingWidth: 130.w,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: false,
        title: Row(

          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(AppImages.logos, height: 70.h, fit: BoxFit.contain),
          ],
        ),
        actions: [
          // Notifications
          GestureDetector(
            onTap: () => context.go(AppRoutes.notifications),
            child: Container(
              margin: EdgeInsets.only(right: 16.w),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 26.sp,
              ),
            ),
          ),
        ],
      ),

      body: items.isEmpty
          ? _buildEmptyCart(context, ref)
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Shopping Cart',
                              style: GoogleFonts.inter(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            if (items.isNotEmpty)
                              TextSpan(
                                text: ' (${items.length} items)',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clear();
                        },
                        child: customText(
                          text: "Clear Cart",
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final cartItem = items[index];
                      return _buildCartItemCard(context, ref, cartItem);
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    24.w,
                    24.h,
                    24.w,
                    34.h + MediaQuery.paddingOf(context).bottom,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBgColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
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
                      _buildPriceRow("Tax (HST 13%)", tax),
                      verticalSpacer(height: 4),
                      Divider(color: Colors.grey[300]),
                      verticalSpacer(height: 4),
                      _buildPriceRow(
                        "Total",
                        total,
                        isBold: true,
                        isLarge: true,
                      ),
                      verticalSpacer(height: 12),
                      customButton(
                        context: context,
                        text: "Continue Shopping",
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontColor: AppColors.btnColor,
                        bgColor: Colors.white,
                        borderRadius: 20.r,
                        height: 48,
                        width: double.infinity,
                        onPressed: () {
                          ref.read(bottomNavProvider.notifier).state =
                              BottomNavIndex.home;
                          goRouter.go(AppRoutes.host);
                        },
                        borderColor: AppColors.btnColor,
                        isCircular: false,
                      ),
                      verticalSpacer(height: 12),
                      customButton(
                        context: context,
                        text: "Proceed to Checkout",
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontColor: Colors.white,
                        bgColor: AppColors.btnColor,
                        borderRadius: 20.r,
                        height: 48,
                        width: double.infinity,
                        onPressed: () {
                          if (!AuthHelper.requireLogin(
                            context: context,
                            ref: ref,
                            message: 'Please signup or signin to proceed to checkout.',
                          )) {
                            return;
                          }
                          context.push(AppRoutes.checkout);
                        },
                        borderColor: AppColors.btnColor,
                        isCircular: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    WidgetRef ref,
    CartItem cartItem,
  ) {
    final product = cartItem.product;
    final hasImage = product.firstImage.isNotEmpty;
    final cart = ref.watch(cartProvider);
    final hasOtherProducts = cart.items.any(
      (item) => item.product.isService != true,
    );
    final isService = product.isService == true;
    final isWaterTestFree = isService && hasOtherProducts;
    final waterTestFromSuppliesFuture = _isWaterTestFromSupplies();

    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(14.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color:AppColors.cardBgColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: SizedBox(
              width: 98.w,
              height: 130.h,
              child: hasImage
                  ? CachedNetworkImage(
                      imageUrl: product.firstImage,

                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
          ),
          horizontalSpacer(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: customText(
                        text: product.safeName,
                        maxLine: 2,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref
                          .read(cartProvider.notifier)
                          .remove(product, selectedSize: cartItem.selectedSize),
                      child: Padding(
                        padding: EdgeInsets.only(left: 6.w),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 26.sp,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
                if (product.safeBrand.trim().isNotEmpty) ...[
                  verticalSpacer(height: 4.h),
                  customText(
                    text: product.safeBrand,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ],
                if (cartItem.selectedSize != null &&
                    cartItem.selectedSize!.isNotEmpty) ...[
                  verticalSpacer(height: 4.h),
                  customText(
                    text: 'Size: ${cartItem.selectedSize!}',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ],
                verticalSpacer(height: 8.h),
                if (isService && isWaterTestFree) ...[
                  Row(
                    children: [
                      customText(
                        text: 'FREE',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                      horizontalSpacer(width: 8.w),
                      Text(
                        "\$${product.priceForSize(cartItem.selectedSize).toStringAsFixed(2)}",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  verticalSpacer(height: 2.h),
                  customText(
                    text: 'Free with your supplies order!',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ] else ...[
                  customText(
                    text: "\$${product.priceForSize(cartItem.selectedSize).toStringAsFixed(2)} CAD",
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  if (isService) ...[
                    verticalSpacer(height: 2.h),
                    FutureBuilder<bool>(
                      future: waterTestFromSuppliesFuture,
                      builder: (context, snapshot) {
                        final waterTestFromSupplies = snapshot.data ?? false;
                        return customText(
                          text: waterTestFromSupplies
                              ? 'Free with purchase — add any item to remove this \$39 fee'
                              : '100% credited toward any supplies purchase',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: waterTestFromSupplies
                              ? AppColors.btnColor
                              : Colors.green,
                        );
                      },
                    ),
                  ],
                ],
                verticalSpacer(height: 8.h),
                if (isService)
                  Row(
                    children: [
                      SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: Transform.scale(
                          scale: 0.8,
                          child: Checkbox(
                            value: cartItem.quantity > 0,
                            activeColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            onChanged: (checked) {
                              if (checked == true) {
                                ref
                                    .read(cartProvider.notifier)
                                    .add(
                                      product,
                                      quantity: 1,
                                      selectedSize: cartItem.selectedSize,
                                    );
                                CustomToast.success(
                                  msg: '${product.safeName} added',
                                );
                              } else {
                                ref
                                    .read(cartProvider.notifier)
                                    .remove(
                                      product,
                                      selectedSize: cartItem.selectedSize,
                                    );
                                CustomToast.success(
                                  msg: '${product.safeName} removed',
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      horizontalSpacer(width: 8.w),
                      customText(
                        text: cartItem.quantity > 0 ? 'Active' : 'Inactive',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(
                                    product,
                                    cartItem.quantity - 1,
                                    selectedSize: cartItem.selectedSize,
                                  ),
                              child: Icon(
                                Icons.remove,
                                size: 24.sp,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            horizontalSpacer(width: 12.w),
                            customText(
                              text: '${cartItem.quantity}',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900,
                            ),
                            horizontalSpacer(width: 12.w),
                            GestureDetector(
                              onTap: () {
                                final stock = product.stock ?? 0;
                                if (stock > 0 && cartItem.quantity >= stock) {
                                  CustomToast.warning(msg: 'Max available: $stock');
                                  return;
                                }
                                ref
                                  .read(cartProvider.notifier)
                                  .updateQuantity(
                                    product,
                                    cartItem.quantity + 1,
                                    selectedSize: cartItem.selectedSize,
                                  );
                              },
                              child: Icon(
                                Icons.add,
                                size: 24.sp,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      customText(
                        text: "\$${cartItem.totalPrice.toStringAsFixed(2)}",
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade400,
        size: 22.sp,
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

  Widget _buildEmptyCart(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64.sp,
              color: AppColors.btnColor,
            ),
            verticalSpacer(height: 16.h),
            customText(
              text: "Your cart is empty",
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
            verticalSpacer(height: 10.h),
            customText(
              text: "Looks like you haven't added anything yet",
              fontSize: 18,
              color: Colors.black,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.w500,
            ),
            verticalSpacer(height: 22.h),
            GestureDetector(
              onTap: () {
                ref.read(bottomNavProvider.notifier).state =
                    BottomNavIndex.home;
                goRouter.go(AppRoutes.host);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.btnColor,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 24.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6.w),
                    customText(
                      text: "Continue Shopping",
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
