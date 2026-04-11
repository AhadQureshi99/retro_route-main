import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/model/product_model.dart';
import 'package:retro_route/model/review_model.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:retro_route/utils/app_assets.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/utils/auth_helper.dart';
import 'package:retro_route/view/checkout/checkout_view.dart';
import 'package:retro_route/view_model/cart_view_model/cart_view_model.dart';
import 'package:retro_route/view_model/favourite_view_model/favourite_view_model.dart';
import 'package:retro_route/view_model/review_view_model/review_view_model.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/view_model/bottom_nav_view_model.dart';
import 'package:share_plus/share_plus.dart';

/// Strip HTML tags and decode common HTML entities from a string.
String _stripHtml(String html) {
  // Remove HTML tags
  String text = html.replaceAll(RegExp(r'<[^>]*>'), '');
  // Decode common HTML entities
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
  // Collapse multiple spaces into one
  text = text.replaceAll(RegExp(r' {2,}'), ' ').trim();
  return text;
}

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late final bool isFavorited;
  int selectedImageIndex = 0;
  int quantity = 1;
  String? selectedSize;

  // ─── Web-matching color constants ───────────────────────────────────────────
  static const _sky700 = Color(0xff0369a1);
  static const _sky600 = Color(0xff0284c7);
  static const _sky500 = Color(0xff0ea5e9);
  static const _sky100 = Color(0xffe0f2fe);
  static const _red600 = Color(0xffdc2626);
  static const _gray500 = Color(0xff6b7280);

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final productImages = product.images ?? [];
    final mainImage =
        productImages.isNotEmpty && selectedImageIndex < productImages.length
            ? productImages[selectedImageIndex]
            : null;

    // Watch cart state
    final cart = ref.watch(cartProvider);
    final itemCount = cart.itemCount;
    final hasSizes = product.sizes != null && product.sizes!.isNotEmpty;
    final currentSizeKey = hasSizes ? (selectedSize ?? '') : '';
    final matchingIndex = cart.items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          (item.selectedSize ?? '') == currentSizeKey,
    );
    final currentQuantity = matchingIndex != -1
        ? cart.items[matchingIndex].quantity
        : quantity;
    final isInCart = matchingIndex != -1;

    final stockQty = product.stock ?? 0;
    final isOutOfStock = (product.status ?? '') == 'Out of Stock' || stockQty <= 0;
    final isAtMaxStock = currentQuantity >= stockQty && stockQty > 0;

    final favState = ref.watch(favoritesProvider);
    final isFavorited = favState.isFavorited(widget.product.id ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   elevation: 0,
      //   scrolledUnderElevation: 0,
      //   toolbarHeight: 62.h,
      //   // ── Back button: sky-100 rounded square ──
      //   leading: Center(
      //     child: Padding(
      //       padding: EdgeInsets.only(left: 12.w),
      //       child: GestureDetector(
      //         onTap: () => Navigator.pop(context),
      //         child: Container(
      //           width: 40.w,
      //           height: 40.w,
      //           decoration: BoxDecoration(
      //             color: _sky100,
      //             borderRadius: BorderRadius.circular(12.r),
      //           ),
      //           child: Center(
      //             child: Icon(
      //               Icons.arrow_back_ios_new_rounded,
      //               size: 18.sp,
      //               color: _sky700,
      //             ),
      //           ),
      //         ),
      //       ),
      //     ),
      //   ),
      //   titleSpacing: 10.w,
      //   // ── Product name + category subtitle ──
      //   title: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       Text(
      //         product.safeName,
      //         style: TextStyle(
      //           fontSize: 15.sp,
      //           fontWeight: FontWeight.bold,
      //           color: const Color(0xff1a1a1a),
      //         ),
      //         maxLines: 1,
      //         overflow: TextOverflow.ellipsis,
      //       ),
      //       if (product.category?.name != null &&
      //           product.category!.name!.isNotEmpty)
      //         Text(
      //           product.category!.name!,
      //           style: TextStyle(
      //             fontSize: 11.sp,
      //             color: _gray500,
      //             fontWeight: FontWeight.w500,
      //           ),
      //         ),
      //     ],
      //   ),
      //   actions: [
      //     // ── Share button ──
         
      //     // Cart
      //     GestureDetector(
      //       onTap: () => goRouter.push(AppRoutes.cart),
      //       child: Container(
      //         margin: EdgeInsets.only(right: 4.w),
      //         padding: EdgeInsets.all(8.w),
      //         decoration: BoxDecoration(
      //           color: Colors.white.withOpacity(0.15),
      //           borderRadius: BorderRadius.circular(12.r),
      //         ),
      //         child: Stack(
      //           clipBehavior: Clip.none,
      //           children: [
      //             Icon(
      //               itemCount > 0
      //                   ? Icons.shopping_bag_rounded
      //                   : Icons.shopping_bag_outlined,
      //               color: Colors.white,
      //               size: 26.sp,
      //             ),
      //             if (itemCount > 0)
      //               Positioned(
      //                 top: -4,
      //                 right: -4,
      //                 child: Container(
      //                   width: 18.w,
      //                   height: 18.w,
      //                   decoration: const BoxDecoration(
      //                     color: Color(0xffef4444),
      //                     shape: BoxShape.circle,
      //                   ),
      //                   child: Center(
      //                     child: Text(
      //                       '$itemCount',
      //                       style: GoogleFonts.inter(
      //                         fontSize: 12.sp,
      //                         fontWeight: FontWeight.w700,
      //                         color: Colors.white,
      //                       ),
      //                     ),
      //                   ),
      //                 ),
      //               ),
      //           ],
      //         ),
      //       ),
      //     ),
      //     SizedBox(width: 8.w),
      //     // ── Favourite button ──
      //     Padding(
      //       padding: EdgeInsets.only(top: 9.h, bottom: 9.h, right: 12.w),
      //       child: GestureDetector(
      //         onTap: favState.isLoading
      //             ? null
      //             : () async {
      //                 if (!AuthHelper.requireLogin(
      //                   context: context,
      //                   ref: ref,
      //                   message:
      //                       'Please log in to add items to your favorites.',
      //                 )) return;
      //                 final token = AuthHelper.getToken(ref);
      //                 if (token == null) return;
      //                 await ref
      //                     .read(favoritesProvider.notifier)
      //                     .toggleFavorite(
      //                       productId: widget.product.id ?? '',
      //                       token: token,
      //                       currentValue: isFavorited,
      //                       product: widget.product,
      //                     );
      //                 CustomToast.success(
      //                   msg: isFavorited
      //                       ? "Removed from favorites"
      //                       : "Added to favorites",
      //                 );
      //               },
      //         child: Container(
      //           width: 40.w,
      //           decoration: BoxDecoration(
      //             color: isFavorited
      //                 ? Colors.red.shade50
      //                 : Colors.grey.shade100,
      //             borderRadius: BorderRadius.circular(12.r),
      //           ),
      //           child: Center(
      //             child: Icon(
      //               isFavorited
      //                   ? Icons.favorite_rounded
      //                   : Icons.favorite_border_rounded,
      //               size: 20.sp,
      //               color: isFavorited ? Colors.red : Colors.black87,
      //             ),
      //           ),
      //         ),
      //       ),
      //     ),
      //   ],
      //   // ── Sky gradient accent line at the bottom ──
      //   bottom: PreferredSize(
      //     preferredSize: const Size.fromHeight(2),
      //     child: Container(
      //       height: 2,
      //       decoration: const BoxDecoration(
      //         gradient: LinearGradient(
      //           colors: [_sky500, _sky700, _sky500],
      //         ),
      //       ),
      //     ),
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
     
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Image.asset(
              AppImages.logos,
              height: 70.h,
              fit: BoxFit.contain,
            ),
          ],
        ),
        actions: [
          // Cart
          GestureDetector(
            onTap: () => goRouter.push(AppRoutes.cart),
            child: Container(
              margin: EdgeInsets.only(right: 4.w),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    itemCount > 0
                        ? Icons.shopping_bag_rounded
                        : Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 26.sp,
                  ),
                  if (itemCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: const BoxDecoration(
                          color: Color(0xffef4444),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$itemCount',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          horizontalSpacer(width: 4),
          GestureDetector(
            onTap: favState.isLoading
                ? null
                : () async {
                    if (!AuthHelper.requireLogin(
                      context: context,
                      ref: ref,
                      message:
                          'Please sign up to add items to your favorites.',
                    )) return;
                    final token = AuthHelper.getToken(ref);
                    if (token == null) return;
                    await ref
                        .read(favoritesProvider.notifier)
                        .toggleFavorite(
                          productId: widget.product.id ?? '',
                          token: token,
                          currentValue: isFavorited,
                          product: widget.product,
                        );
                    CustomToast.success(
                      msg: isFavorited
                          ? "Removed from favorites"
                          : "Added to favorites",
                    );
                  },
            child: Container(
              margin: EdgeInsets.only(right: 4.w),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isFavorited
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorited ? Colors.red : Colors.white,
                    size: 26.sp,
                  ),
                ],
              ),
            ),
          ),
      
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── IMAGE SECTION ────────────────────────────────────────
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.sp, 8.sp, 16.sp, 8.sp),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: mainImage != null
                              ? Image.network(
                                  mainImage,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  // Thumbnails
                  if (productImages.length > 1)
                    SizedBox(
                      height: 80.h,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        scrollDirection: Axis.horizontal,
                        itemCount: productImages.length,
                        itemBuilder: (context, index) {
                          final isSelected = selectedImageIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => selectedImageIndex = index),
                            child: Container(
                              width: 68.w,
                              margin: EdgeInsets.only(right: 8.w, bottom: 8.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: isSelected ? _sky500 : Colors.grey.shade200,
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9.r),
                                child: Image.network(
                                  productImages[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            // ─── PRODUCT INFO ─────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand
                  if (product.brand != null && product.brand!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        product.brand!.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: _gray500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                  // Product name — sky-700 uppercase bold
                  Text(
                    product.safeName.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Stars + review count
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < (product.rating ?? 0)
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xfffbbf24),
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "${product.totalReviews ?? 0} Reviews",
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Quantity selector
                  if (isOutOfStock)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(children: [
                          Icon(Icons.block, color: const Color(0xFFDC2626), size: 16.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'This product is currently out of stock',
                            style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626)),
                          ),
                        ]),
                      ),
                    )
                  else ...[
                  Row(
                    children: [
                      Text(
                        "QUANTITY:",
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400, width: 2),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _qtyButton(
                                icon: Icons.remove,
                                onTap: currentQuantity > 1
                                    ? () {
                                        if (isInCart) {
                                          ref
                                              .read(cartProvider.notifier)
                                              .updateQuantity(
                                                product,
                                                currentQuantity - 1,
                                                selectedSize: hasSizes
                                                    ? selectedSize
                                                    : null,
                                              );
                                        } else {
                                          setState(() => quantity = quantity - 1);
                                        }
                                      }
                                    : null,
                              ),
                              Container(width: 1, color: Colors.grey.shade400),
                              SizedBox(
                                width: 44.w,
                                child: Center(
                                  child: Text(
                                    "$currentQuantity",
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      color: _gray500,
                                    ),
                                  ),
                                ),
                              ),
                              Container(width: 1, color: Colors.grey.shade400),
                              _qtyButton(
                                icon: Icons.add,
                                onTap: isAtMaxStock ? null : () {
                                  if (isInCart) {
                                    ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                          product,
                                          currentQuantity + 1,
                                          selectedSize:
                                              hasSizes ? selectedSize : null,
                                        );
                                  } else {
                                    final maxQty = stockQty > 0 ? stockQty : 999;
                                    if (quantity < maxQty) {
                                      setState(() => quantity = quantity + 1);
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isAtMaxStock)
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: Text(
                        'Max available: $stockQty',
                        style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600, color: Colors.orange),
                      ),
                    ),
                  ], // end of else (not out of stock)
                  SizedBox(height: 12.h),

                  const Divider(color: Color(0xffB6B6B6), thickness: 0.8),
                  SizedBox(height: 8.h),

                  // Stock status
                  _buildStockStatus(product),
                  SizedBox(height: 8.h),
                  const Divider(color: Color(0xffB6B6B6), thickness: 0.8),
                  // SizedBox(height: 6.h),

                  // Sale Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: 8.sp,
                    children: [
                      Text(
                        "SALE PRICE: ",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: _red600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "\$${product.priceForSize(selectedSize).toStringAsFixed(2)}",
                        style: GoogleFonts.inter(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: _red600,
                        ),
                      ),
                      if ((product.discount ?? 0) > 0) ...[
                        SizedBox(width: 10.w),
                        Text(
                          "\$${product.originalPriceForSize(selectedSize).toStringAsFixed(2)}",
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            color: Colors.grey.shade400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // SizedBox(height: 6.h),
                  const Divider(color: Color(0xffB6B6B6), thickness: 0.8),
                  SizedBox(height: 20.h),

                  // Size Selection (web parity)
                  if (hasSizes || (product.unit != null && product.unit!.isNotEmpty)) ...[
                    Row(
                      children: [
                        Text(
                          hasSizes && product.sizes!.length > 1 ? 'Select Size' : 'Size',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff374151),
                          ),
                        ),
                        Text(
                          ' *',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xffef4444),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: hasSizes
                          ? product.sizes!
                              .map(
                                (sizeObj) => GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedSize = sizeObj.size;
                                      quantity = 1;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 10.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selectedSize == sizeObj.size
                                          ? const Color(0xfff0f9ff)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: selectedSize == sizeObj.size
                                            ? AppColors.btnColor
                                            : const Color(0xffe5e7eb),
                                        width: selectedSize == sizeObj.size ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          sizeObj.size,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: selectedSize == sizeObj.size
                                                ? AppColors.btnColor
                                                : const Color(0xff374151),
                                          ),
                                        ),
                                        if (sizeObj.price > 0)
                                          Text(
                                            '\$${sizeObj.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w500,
                                              color: selectedSize == sizeObj.size
                                                  ? AppColors.btnColor
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList()
                          : [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 10.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xfff0f9ff),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: AppColors.btnColor,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  product.unit!,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.btnColor,
                                  ),
                                ),
                              ),
                            ],
                    ),
                    SizedBox(height: 20.h),
                  ],

                  // Save to Wishlist + Share
                  Row(
                    children: [
                      GestureDetector(
                        onTap: favState.isLoading
                            ? null
                            : () async {
                                if (!AuthHelper.requireLogin(
                                  context: context,
                                  ref: ref,
                                  message: 'Please log in to save favorites.',
                                )) return;
                                final token = AuthHelper.getToken(ref);
                                if (token == null) return;
                                await ref
                                    .read(favoritesProvider.notifier)
                                    .toggleFavorite(
                                      productId: widget.product.id ?? '',
                                      token: token,
                                      currentValue: isFavorited,
                                      product: widget.product,
                                    );
                                CustomToast.success(
                                  msg: isFavorited
                                      ? "Removed from favorites"
                                      : "Added to favorites",
                                );
                              },
                        child: Row(
                          children: [
                            Icon(
                              isFavorited
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorited ? Colors.red : _gray500,
                              size: 20.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              isFavorited ? "Saved" : "Save to Wishlist",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: isFavorited ? Colors.red : _gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 24.w),
                      GestureDetector(
                        onTap: () {
                          final p = widget.product;
                          final price = p.price != null ? '\$${p.price}' : '';
                          Share.share(
                            'Check out ${p.name ?? 'this product'} $price on Retro Route!',
                          );
                        },
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined, color: _gray500, size: 20.sp),
                            SizedBox(width: 6.w),
                            Text(
                              "Share",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: _gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            // ─── FEATURES BAR ─────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _featureItem(Icons.local_shipping_outlined, "FREE", "DELIVERY"),
                  _featureItem(Icons.science_outlined, "FREE WATER", "TEST"),
                  _featureItem(Icons.payments_outlined, "INCREDIBLE", "VALUE"),
                  _featureItemWidget(
                    SizedBox(
                      height: 28.sp,
                      width: 28.sp,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text('🍁', style: TextStyle(fontSize: 28.sp, height: 1.0)),
                        ),
                      ),
                    ),
                    "CANADIAN", "OWNED",
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.h),

            // ─── DESCRIPTION ──────────────────────────────────────────
            if (product.description != null && product.description!.isNotEmpty) ...[
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customText(
                      text: 
                      "DESCRIPTION",
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _stripHtml(product.description!),
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: const Color(0xff1f2937),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],

            // ─── KEY FEATURES ─────────────────────────────────────────
            if (product.keyFeatures != null && product.keyFeatures!.isNotEmpty) ...[
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                       customText(
                      text: 
                      "KEY FEATURES",
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  
                    SizedBox(height: 12.h),
                    ...product.keyFeatures!.map(
                      (feature) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: Container(
                                width: 22.w,
                                height: 22.w,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check, size: 13.sp, color: AppColors.primary),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                feature.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"').replaceAll('&#39;', "'").replaceAll('by Retro Route Co', 'by\nRetro Route Co'),
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: const Color(0xff1f2937),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],

            // ─── REVIEWS SECTION ──────────────────────────────────────
            _ReviewSection(productId: widget.product.id ?? ''),

            SizedBox(height: 20.h),
          ],
        ),
      ),

      bottomNavigationBar: isOutOfStock
          ? Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.grey.shade600,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    elevation: 0,
                  ),
                  child: Text("Out of Stock", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                ),
              ),
            )
          : Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
          16.w,
          12.h,
          16.w,
          16.h + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  if (hasSizes && (selectedSize == null || selectedSize!.isEmpty)) {
                    CustomToast.error(msg: 'Please select a size');
                    return;
                  }
                  final cartNotifier = ref.read(cartProvider.notifier);
                  final sizeArg = hasSizes ? selectedSize : null;
                  final freshCart = ref.read(cartProvider);
                  final freshIndex = freshCart.items.indexWhere(
                    (item) =>
                        item.product.id == product.id &&
                        (item.selectedSize ?? '') == (sizeArg ?? ''),
                  );
                  if (freshIndex != -1) {
                    final freshQty = freshCart.items[freshIndex].quantity;
                    cartNotifier.updateQuantity(
                      product,
                      freshQty + 1,
                      selectedSize: sizeArg,
                    );
                    CustomToast.success(
                      msg: "${freshQty + 1} × ${product.safeName} in cart",
                    );
                  } else {
                    cartNotifier.add(
                      product,
                      quantity: quantity,
                      selectedSize: sizeArg,
                    );
                    CustomToast.success(
                      msg: "$quantity × ${product.safeName} added to cart",
                    );
                  }
                },
                icon: Icon(Icons.shopping_cart_outlined, size: 18.sp),
                label: const Text("Add to Cart"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.btnColor,
                  side: const BorderSide(color: AppColors.btnColor, width: 2),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  textStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (hasSizes && (selectedSize == null || selectedSize!.isEmpty)) {
                    CustomToast.error(msg: 'Please select a size');
                    return;
                  }
                  final cartNotifier = ref.read(cartProvider.notifier);
                  final sizeArg = hasSizes ? selectedSize : null;
                  // Fresh check to avoid stale closure issues on rapid taps
                  final freshCart = ref.read(cartProvider);
                  final freshIndex = freshCart.items.indexWhere(
                    (item) =>
                        item.product.id == product.id &&
                        (item.selectedSize ?? '') == (sizeArg ?? ''),
                  );
                  if (freshIndex != -1) {
                    cartNotifier.updateQuantity(
                      product,
                      currentQuantity,
                      selectedSize: sizeArg,
                    );
                  } else {
                    cartNotifier.add(
                      product,
                      quantity: quantity,
                      selectedSize: sizeArg,
                    );
                  }
                  goRouter.push(AppRoutes.cart);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.btnColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  textStyle: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  elevation: 0,
                ),
                child: const Text("Buy Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Qty stepper button ───────────────────────────────────────────────────
  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 40.w,
        height: 30.h,
        child: Icon(
          icon,
          size: 20.sp,
          color: onTap == null ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
      ),
    );
  }

  // ─── Feature item for the features bar ───────────────────────────────────
  Widget _featureItem(IconData icon, String line1, String line2) {
    return _featureItemWidget(
      Icon(icon, size: 28.sp, color: AppColors.btnColor),
      line1, line2,
    );
  }

  Widget _featureItemWidget(Widget iconWidget, String line1, String line2) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        SizedBox(height: 6.h),
        Text(
          line1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            height: 1.2,
          ),
        ),
        Text(
          line2,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  // ─── Stock status row ─────────────────────────────────────────────────────
  Widget _buildStockStatus(Product product) {
    final status = product.status ?? '';
    if (status == 'Out of Stock') {
      return Row(
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: const BoxDecoration(
              color: Color(0xfffee2e2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: Color(0xffdc2626),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            "OUT OF STOCK",
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xffdc2626),
            ),
          ),
        ],
      );
    } else if (status == 'Low Stock') {
      return Row(
        children: [
          Icon(Icons.check_circle, size: 18.sp, color: Colors.orange),
          SizedBox(width: 8.w),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "LOW STOCK ",
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                TextSpan(
                  text: "— ORDER SOON",
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(Icons.check_circle, size: 16.sp, color: Colors.green),
          SizedBox(width: 8.w),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "IN STOCK ",
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                TextSpan(
                  text: "AND READY TO SHIP",
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1f2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  // ── Bottom Sheet for Write / Edit Review ────────────────────────────────────
  void _showReviewBottomSheet(
    BuildContext context,
    WidgetRef ref, {
    required String productId,
    Review? existingReview,
  }) {
    int selectedRating = existingReview?.rating ?? 3;
    final titleController = TextEditingController(
      text: existingReview?.title ?? '',
    );
    final commentController = TextEditingController(
      text: existingReview?.comment ?? '',
    );

    const int titleMaxLength = 100;
    const int commentMaxLength = 500;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24.w,
              right: 24.w,
              top: 24.h,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customText(
                        text: existingReview == null
                            ? "Write a Review"
                            : "Edit Your Review",
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      verticalSpacer(height: 24.h),

                      // Rating stars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < selectedRating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: Colors.amber,
                              size: 36.sp,
                            ),
                            onPressed: () =>
                                setModalState(() => selectedRating = index + 1),
                          );
                        }),
                      ),
                      verticalSpacer(height: 16.h),

                      // Title field
                      TextField(
                        controller: titleController,
                        maxLength: titleMaxLength,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: "Title (optional)",
                          border: const OutlineInputBorder(),
                          counterText: '',
                          suffixText:
                              '${titleController.text.length}/$titleMaxLength',
                          suffixStyle: TextStyle(
                            fontSize: 12.sp,
                            color: titleController.text.length >= titleMaxLength
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                      ),
                      verticalSpacer(height: 16.h),

                      // Comment field
                      TextField(
                        controller: commentController,
                        maxLines: 5,
                        maxLength: commentMaxLength,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          labelText: "Your comment...",
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                          counterText: '',
                          helperText:
                              '${commentController.text.length}/$commentMaxLength characters',
                          helperStyle: TextStyle(
                            fontSize: 12.sp,
                            color:
                                commentController.text.length >= commentMaxLength
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                        ),
                      ),
                      verticalSpacer(height: 24.h),

                      customButton(
                        context: context,
                        text: existingReview == null
                            ? "Submit Review"
                            : "Update Review",
                        onPressed: () async {
                          if (selectedRating == 0) {
                            CustomToast.error(msg: "Please select a rating");
                            return;
                          }

                          bool success;
                          if (existingReview == null) {
                            success = await ref
                                .read(reviewProvider(productId).notifier)
                                .submitReview(
                                  rating: selectedRating,
                                  title: titleController.text.trim().isEmpty
                                      ? null
                                      : titleController.text.trim(),
                                  comment: commentController.text.trim().isEmpty
                                      ? null
                                      : commentController.text.trim(),
                                );
                          } else {
                            success = await ref
                                .read(reviewProvider(productId).notifier)
                                .updateOwnReview(
                                  reviewId: existingReview.id ?? '',
                                  rating: selectedRating,
                                  title: titleController.text.trim().isEmpty
                                      ? null
                                      : titleController.text.trim(),
                                  comment: commentController.text.trim().isEmpty
                                      ? null
                                      : commentController.text.trim(),
                                );
                          }

                          if (success) {
                            CustomToast.success(
                              msg: existingReview == null
                                  ? "Review submitted!"
                                  : "Review updated!",
                            );
                            Navigator.pop(context);
                          } else {
                            CustomToast.error(msg: "Something went wrong");
                          }
                        },
                        fontSize: 16,
                        height: 48,
                        borderColor: AppColors.btnColor,
                        bgColor: AppColors.btnColor,
                        fontColor: AppColors.white,
                        borderRadius: 16,
                        isCircular: false,
                        fontWeight: FontWeight.w500,
                      ),
                      verticalSpacer(height: 32.h),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ─── Self-contained Review Section widget (mirrors web layout exactly) ─────
class _ReviewSection extends ConsumerStatefulWidget {
  final String productId;
  const _ReviewSection({required this.productId});

  @override
  ConsumerState<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<_ReviewSection> {
  static const _sky700 = Color(0xff0369a1);
  static const _sky600 = Color(0xff0284c7);
  static const _sky100 = Color(0xffe0f2fe);
  static const _gray500 = Color(0xff6b7280);

  bool _showForm = false;
  int _formRating = 5;
  final _titleCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formRating == 0) {
      CustomToast.error(msg: "Please select a rating");
      return;
    }
    setState(() => _submitting = true);
    final success = await ref
        .read(reviewProvider(widget.productId).notifier)
        .submitReview(
          rating: _formRating,
          title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
          comment:
              _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
        );
    setState(() => _submitting = false);
    if (success) {
      CustomToast.success(msg: "Review submitted!");
      _titleCtrl.clear();
      _commentCtrl.clear();
      setState(() {
        _showForm = false;
        _formRating = 5;
      });
    } else {
      CustomToast.error(msg: "Failed to submit review");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthHelper.isLoggedIn(ref);
    final reviewState =
        ref.watch(reviewProvider(widget.productId));
    final reviews = reviewState.response?.message?.reviews ?? [];
    final avg = reviewState.response?.message?.averageRating ?? 0.0;
    final total = reviewState.response?.message?.totalReviews ?? 0;
    final ownReview = reviewState.userOwnReview;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.message_outlined, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Customer Reviews ",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: "($total)",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: _gray500,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Write a Review / Cancel button — only for logged-in users
              if (isLoggedIn && ownReview == null)
                GestureDetector(
                  onTap: () => setState(() => _showForm = !_showForm),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.btnColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showForm ? Icons.close : Icons.send_outlined,
                          color: Colors.white,
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _showForm ? "Cancel" : "Write a Review",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!isLoggedIn)
                GestureDetector(
                  onTap: () => goRouter.push(AppRoutes.login),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.btnColor),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      "Login to Review",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.btnColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),

          if (reviewState.isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            // ── Average rating summary ─────────────────────────────
            if (total > 0)
              Container(
                padding: EdgeInsets.all(16.w),
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: _sky100,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                        color: _sky700,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < avg.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xfffbbf24),
                          size: 16.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "$total review${total == 1 ? '' : 's'}",
                      style: TextStyle(fontSize: 11.sp, color: _gray500),
                    ),
                  ],
                ),
              ),

            // ── Inline write-review form (shown on toggle) ─────────
            if (_showForm && isLoggedIn && ownReview == null)
              _buildInlineForm(),

            // ── Own review card ────────────────────────────────────
            if (ownReview != null)
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _buildReviewCard(
                  review: ownReview,
                  isOwn: true,
                  productId: widget.productId,
                ),
              ),

            // ── Reviews list ───────────────────────────────────────
            if (reviews.isEmpty && !_showForm)
              Container(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cardBgColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Icon(Icons.message_outlined,
                        size: 40.sp, color: Colors.grey),
                    SizedBox(height: 12.h),
                    Text(
                      "No reviews yet",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Be the first to review this product!",
                      style: TextStyle(
                          color: Colors.grey, fontSize: 12.sp),
                    ),
                  ],
                ),
              )
            else
              ...reviews
                  .where((r) => r.id != ownReview?.id)
                  .map((rev) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _buildReviewCard(
                          review: rev,
                          isOwn: false,
                          productId: widget.productId,
                        ),
                      )),
          ],
        ],
      ),
    );
  }

  // ── Inline write form ───────────────────────────────────────────────────────
  Widget _buildInlineForm() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: StatefulBuilder(builder: (context, setLocal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Write Your Review",
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xff1f2937),
              ),
            ),
            SizedBox(height: 14.h),
            // Stars picker
            Text(
              "Rating",
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: _gray500),
            ),
            SizedBox(height: 6.h),
            Row(
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _formRating = i + 1),
                  child: Padding(
                    padding: EdgeInsets.only(right: 4.w),
                    child: Icon(
                      i < _formRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: i < _formRating
                          ? const Color(0xfffbbf24)
                          : Colors.grey.shade300,
                      size: 28.sp,
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 14.h),
            // Title
            Text(
              "Title",
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: _gray500),
            ),
            SizedBox(height: 6.h),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: "Summary of your review",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: _sky600),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Comment
            Text(
              "Comment",
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: _gray500),
            ),
            SizedBox(height: 6.h),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              style: TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                hintText: "Share your experience with this product...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: _sky600),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.btnColor,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                  textStyle: TextStyle(
                      fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
                child: Text(_submitting ? "Submitting..." : "Submit Review"),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Single review card (own or others) ─────────────────────────────────────
  Widget _buildReviewCard({
    required Review review,
    required bool isOwn,
    required String productId,
  }) {
    final name = review.userId?.name ?? 'Anonymous';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: avatar + name + verified + date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: const BoxDecoration(
                    color: _sky100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: _sky700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff1f2937),
                            ),
                          ),
                          if (isOwn) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 5.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                color: const Color(0xfff0fdf4),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                "Your Review",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (review.rating ?? 0)
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xfffbbf24),
                            size: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  review.createdAt?.toString().substring(0, 10) ?? '',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            // Title
            if (review.title?.isNotEmpty ?? false) ...[
              SizedBox(height: 10.h),
              Text(
                review.title!,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff1f2937),
                ),
              ),
            ],
            // Comment
            SizedBox(height: 6.h),
            Text(
              review.comment ?? '',
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xff4b5563),
                height: 1.5,
              ),
            ),
            // Edit/Delete actions for own review
            ],
        ),
      ),
    );
  }

  }
