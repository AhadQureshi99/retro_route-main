import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/components/custom_textfield.dart';
import 'package:retro_route/components/shimmer_loading.dart';
import 'package:retro_route/model/category_model.dart';
import 'package:retro_route/model/product_model.dart';
import 'package:retro_route/utils/app_assets.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view/dashboard/widgets/product_card.dart';
import 'package:retro_route/view_model/cart_view_model/cart_view_model.dart';
import 'package:retro_route/view_model/category_view_model/category_view_model.dart';
import 'package:retro_route/view_model/product_view_model/product_view_model.dart';
import 'package:shimmer/shimmer.dart';

// Local providers scoped to this screen (independent from dashboard)
final _searchCategoryProvider = StateProvider<Category?>((ref) => null);
final _searchSubcategoryProvider = StateProvider<Category?>((ref) => null);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
      FocusScope.of(context).requestFocus(FocusNode());
    });

    _searchController.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _searchQuery = _searchController.text.trim().toLowerCase();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── Filter logic ───────────────────────────────────────────────────────
  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;
    return products.where((p) {
      return p.safeName.toLowerCase().contains(_searchQuery) ||
          (p.safeBrand?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  List<Category> _filterCategories(List<Category> categories) {
    if (_searchQuery.isEmpty) return categories;
    return categories.where((c) {
      return c.safeName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCat = ref.watch(_searchCategoryProvider);
    final selectedSub = ref.watch(_searchSubcategoryProvider);
    // When searching, always fetch ALL products so results span every category/subcategory.
    // Only filter by category when no search text is entered.
    final productCatId = _searchQuery.isNotEmpty
        ? null
        : (selectedSub?.id ?? selectedCat?.id);
    final productsAsync = ref.watch(productsProvider(productCatId));
    final cart = ref.watch(cartProvider);
    final itemCount = cart.itemCount;
    return Scaffold(
      backgroundColor: AppColors.bgColor,
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
  
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
            color: AppColors.bgColor,
            child: CustomTextField(
              controller: _searchController,
              hintText: "Search products",
              prefixIcon: Icons.search_rounded,
              borderRadius: 20.r,
              fillColor: AppColors.cardBgColor,

              hintFontSize: 16.sp,
              suffixIcon: _searchQuery.isNotEmpty ? Icons.clear_rounded : null,
              showSuffixIcon: _searchQuery.isNotEmpty,
              suffixIconColor: AppColors.primary,
              onSuffixTap: _searchQuery.isNotEmpty
                  ? () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    }
                  : null, width: 1.sw,
            ),
          ),

          // ── Results ─────────────────────────────────────────────────────
          Expanded(
            child: Builder(
              builder: (context) {
                // Show shimmer only on initial load (no cached data yet)
                if ((categoriesAsync.isLoading && !categoriesAsync.hasValue) ||
                    (productsAsync.isLoading && !productsAsync.hasValue)) {
                  return _buildShimmerGrid();
                }

                // Get filtered data
                final categories = categoriesAsync.value ?? [];
                final products = productsAsync.value?.data?.products ?? [];

                final filteredCategories = _filterCategories(categories);
                final filteredProducts = _filterProducts(products);

                // No results at all
                if (filteredCategories.isEmpty && filteredProducts.isEmpty) {
                  return _buildEmptyState();
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Filtered Categories ───────────────────────────────
                      if (filteredCategories.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            customText(
                              text: "Categories",
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            if (selectedCat != null)
                              GestureDetector(
                                onTap: () {
                                  ref.read(_searchSubcategoryProvider.notifier).state = null;
                                  ref.read(_searchCategoryProvider.notifier).state = null;
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: AppColors.btnColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Clear', style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.btnColor)),
                                      SizedBox(width: 4.w),
                                      Icon(Icons.close, size: 14.sp, color: AppColors.btnColor),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        verticalSpacer(height: 12.h),
                        SizedBox(
                          height: 120.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredCategories.length,
                            itemBuilder: (context, index) {
                              final cat = filteredCategories[index];
                              final isSelected = selectedCat?.id == cat.id;
                              return Padding(
                                padding: EdgeInsets.only(right: 10.w),
                                child: GestureDetector(
                                  onTap: () {
                                    ref.read(_searchSubcategoryProvider.notifier).state = null;
                                    if (isSelected) {
                                      ref.read(_searchCategoryProvider.notifier).state = null;
                                    } else {
                                      ref.read(_searchCategoryProvider.notifier).state = cat;
                                    }
                                  },
                                  child: Container(
                                    width: 140.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: isSelected
                                          ? Border.all(
                                              color: AppColors.btnColor,
                                              width: 3,
                                            )
                                          : Border.all(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(isSelected ? 9.r : 11.r),
                                              topRight: Radius.circular(isSelected ? 9.r : 11.r),
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: cat.safeImage,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Shimmer.fromColors(
                                                baseColor: Colors.grey[300]!,
                                                highlightColor: Colors.grey[100]!,
                                                child: Container(color: Colors.white),
                                              ),
                                              errorWidget: (context, url, error) =>
                                                  Container(
                                                color: Colors.grey[200],
                                                child: Icon(Icons.category, size: 28.sp, color: Colors.grey[500]),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.btnColor : Colors.white,
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(isSelected ? 9.r : 11.r),
                                              bottomRight: Radius.circular(isSelected ? 9.r : 11.r),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  cat.safeName,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected ? Colors.white : const Color(0xff111827),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(width: 4.w),
                                              Icon(
                                                isSelected
                                                    ? Icons.keyboard_arrow_up_rounded
                                                    : Icons.keyboard_arrow_down_rounded,
                                                size: 16.sp,
                                                color: isSelected ? Colors.white : Colors.grey[600],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // ── Subcategory chips (when category with subs is selected) ──
                        if (selectedCat != null && selectedCat.hasSubcategories) ...[
                          verticalSpacer(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: selectedCat.subcategories.map((sub) {
                                final isSubSelected = selectedSub?.id == sub.id;
                                return Padding(
                                  padding: EdgeInsets.only(right: 10.w),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (isSubSelected) {
                                        ref.read(_searchSubcategoryProvider.notifier).state = null;
                                      } else {
                                        ref.read(_searchSubcategoryProvider.notifier).state = sub;
                                      }
                                    },
                                    child: Container(
                                      width: 160.w,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12.r),
                                        border: isSubSelected
                                            ? Border.all(
                                                color: AppColors.btnColor,
                                                width: 3,
                                              )
                                            : Border.all(
                                                color: Colors.grey[300]!,
                                                width: 1,
                                              ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(isSubSelected ? 9.r : 11.r),
                                        child: CachedNetworkImage(
                                          imageUrl: sub.safeImage,
                                          width: double.infinity,
                                          height: 110.h,
                                          fit: BoxFit.cover,
                                          placeholder: (ctx, url) => Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child: Container(
                                              height: 110.h,
                                              color: Colors.white,
                                            ),
                                          ),
                                          errorWidget: (ctx, url, err) => Container(
                                            height: 110.h,
                                            color: Colors.grey[200],
                                            child: Icon(Icons.category_rounded, size: 24.sp, color: Colors.grey[400]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],

                        verticalSpacer(height: 8),
                      ],

                      // ── Filtered Products ─────────────────────────────────
                      if (filteredProducts.isNotEmpty) ...[
                        customText(
                          text: selectedSub != null
                              ? selectedSub.safeName
                              : selectedCat != null
                                  ? selectedCat.safeName
                                  : "Products",
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        GridView.builder(
                          shrinkWrap: true,
        padding: EdgeInsets.only(top: 16.h, bottom: 100.h),

                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200.w,
                            mainAxisExtent: 300.h,
                            crossAxisSpacing: 12.w,
                            mainAxisSpacing: 16.h,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                goRouter.push(AppRoutes.productdetails, extra: product);
                              },
                              onAddToCart: () {
                                  if ((product.status ?? '') == 'Out of Stock' || (product.stock ?? 0) <= 0) {
                                    CustomToast.error(msg: '${product.safeName} is out of stock');
                                    return;
                                  }
                                 final isInCart = cart.items.any(
                                    (item) => item.product.id == product.id,
                                  );
                                  if (isInCart) {
                                    CustomToast.warning(
                                      msg:
                                          "${product.safeName} is already in the cart",
                                    );

                                    return;
                                  }

                                  ref
                                      .read(cartProvider.notifier)
                                      .add(product, quantity: 1);

                                  CustomToast.success(
                                    msg: "${product.safeName} added to cart",
                                  );
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(20.w),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.w,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => const ShimmerProductCard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 90.sp, color: Colors.grey[400]),
          verticalSpacer(height: 24.h),
          customText(
            text: "No results found",
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
          verticalSpacer(height: 12.h),
          customText(
            text: "Try searching with different keywords",
            fontSize: 16.sp,
            color: Colors.grey,
            textAlign: TextAlign.center, fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}