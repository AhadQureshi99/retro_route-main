import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/model/product_model.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/favourite_view_model/favourite_view_model.dart';
import 'package:shimmer/shimmer.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favState = ref.watch(favoritesProvider);
    final isFavorited = favState.isFavorited(product.id ?? '');

    final hasDiscount = (product.discount ?? 0) > 0;
    final originalPrice = product.price ?? 0;
    final discounted = product.discountedPrice;
    final brandOrCategory =
        (product.brand?.isNotEmpty == true ? product.brand : null) ??
            product.category?.safeName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.cardBgColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // ── IMAGE ──────────────────────────────────────
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    color: AppColors.cardBgColor,
                    child: CachedNetworkImage(
                      imageUrl: product.firstImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.grey[50]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 28.sp,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'No Image',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Discount pill — top left
                if (hasDiscount)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.btnColor,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '-${product.discount?.toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),

                // Favourite button — top right (frosted circle)
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: GestureDetector(
                    onTap: () async {
                      final productId = product.id ?? '';
                      if (productId.isEmpty) return;
                      final token =
                          ref.read(authNotifierProvider).value?.data?.token;
                      if (token == null) return;
                      await ref.read(favoritesProvider.notifier).toggleFavorite(
                            productId: productId,
                            token: token,
                            currentValue: isFavorited,
                            product: product,
                          );
                    },
                    child: Container(
                      width: 38.w,
                      height: 38.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: isFavorited
                            ? const Color(0xffef4444)
                            : Colors.grey.shade500,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── CONTENT ────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Brand / Category
                    if (brandOrCategory != null && brandOrCategory.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Text(
                          brandOrCategory.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.btnColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                    // Product Name
                    Text(
                      product.safeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff111827),
                        height: 1.35,
                      ),
                    ),

                    SizedBox(height: 5.h),

                    // Star Rating
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          final filled = i < (product.rating ?? 0);
                          return Icon(
                            Icons.star_rounded,
                            size: 18.sp,
                            color: filled
                                ? const Color(0xfffbbf24)
                                : const Color(0xffE5E7EB),
                          );
                        }),
                        if ((product.totalReviews ?? 0) > 0) ...[
                          SizedBox(width: 4.w),
                          Text(
                            '(${product.totalReviews})',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const Spacer(),

                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$${hasDiscount ? discounted.toStringAsFixed(2) : originalPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xff111827),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        if (hasDiscount)
                          Text(
                            '\$${originalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey.shade400,
                            ),
                          ),
                        SizedBox(width: 4.w),
                        Text(
                          'CAD',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
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
