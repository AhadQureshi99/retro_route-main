import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/components/shimmer_loading.dart';
import 'package:retro_route/model/category_model.dart';
import 'package:retro_route/model/product_model.dart';
import 'package:retro_route/utils/app_assets.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view/dashboard/all_categories_view.dart';
import 'package:retro_route/view/dashboard/widgets/product_card.dart';
import 'package:retro_route/view_model/cart_view_model/cart_view_model.dart';
import 'package:retro_route/view_model/category_view_model/category_view_model.dart';
import 'package:retro_route/view_model/category_view_model/selected_category_view_model.dart';
import 'package:retro_route/view_model/product_view_model/product_view_model.dart';
import 'package:retro_route/view_model/slider_view_model/slider_view_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:retro_route/view/dashboard/widgets/water_test_popup.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/notification_view_model/notification_view_model.dart';
import 'package:retro_route/view_model/water_test_view_model/water_test_view_model.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  static bool _milkRunPopupShownThisSession = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'newest';
  int _currentCarouselIndex = 0;
  OverlayEntry? _filterOverlay;
  final LayerLink _filterLayerLink = LayerLink();

  // Guard flags – prevent dialog from re-showing on every rebuild
  bool _sliderErrorDialogShown = false;
  bool _categoriesErrorDialogShown = false;
  bool _productsErrorDialogShown = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotifications();
      _tryShowWaterTestPopup();
    });
  }

  void _fetchNotifications() {
    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token != null) {
      ref.read(notificationsProvider.notifier).fetchNotifications(token);
    }
  }

  Future<void> _tryShowWaterTestPopup() async {
    // Only show once per app session
    if (_milkRunPopupShownThisSession) return;

    // Wait a short moment to let the screen settle
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Only show for authenticated users (matches web: if (!isAuthenticated) return null)
    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token == null) return;

    // Force refresh the water test data each app launch
    ref.invalidate(waterTestProvider);

    // Wait for the provider to resolve
    final product = await ref.read(waterTestProvider.future);
    if (!mounted) return;

    if (product != null) {
      _milkRunPopupShownThisSession = true;
      WaterTestPopup.show(context, ref);
    }
  }

  @override
  void dispose() {
    _filterOverlay?.remove();
    _filterOverlay = null;
    _searchController.dispose();
    super.dispose();
  }

  List<Category> _filterCategories(List<Category> categories) {
    if (_searchQuery.isEmpty) return categories;
    return categories.where((cat) {
      return cat.safeName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  List<Product> _filterProducts(List<Product> products) {
    var result = _searchQuery.isEmpty
        ? List<Product>.from(products)
        : products.where((prod) {
            return prod.safeName.toLowerCase().contains(_searchQuery) ||
                prod.safeBrand.toLowerCase().contains(_searchQuery);
          }).toList();
    switch (_sortBy) {
      case 'price-low':
        result.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
        break;
      case 'price-high':
        result.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
        break;
      case 'name':
        result.sort((a, b) => a.safeName.compareTo(b.safeName));
        break;
      case 'rating':
        result.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      default:
        break;
    }
    return result;
  }

  void _toggleFilterOverlay() {
    if (_filterOverlay != null) {
      _hideFilterOverlay();
    } else {
      _showFilterOverlay();
    }
  }

  void _showFilterOverlay() {
    _filterOverlay = OverlayEntry(
      builder: (_) => _FilterDropdown(
        layerLink: _filterLayerLink,
        currentSort: _sortBy,
        onSortSelected: (sort) {
          setState(() => _sortBy = sort);
          _hideFilterOverlay();
        },
        onDismiss: _hideFilterOverlay,
      ),
    );
    Overlay.of(context).insert(_filterOverlay!);
  }

  void _hideFilterOverlay() {
    _filterOverlay?.remove();
    _filterOverlay = null;
  }

  Future<void> _onRefresh() async {
    // Clear selected category & subcategory so products reset to "all"
    ref.read(selectedCategoryProvider.notifier).clearSelection();
    ref.read(selectedSubcategoryProvider.notifier).clearSelection();
    // Clear search
    _searchController.clear();
    setState(() => _searchQuery = '');
    // Invalidate all data providers
    ref.invalidate(sliderProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(productsProvider(null));
    // Wait for categories + products to finish loading (ignore individual errors)
    await Future.wait([
      ref.read(categoriesProvider.future).then<void>((_) {}).catchError((_) {}),
      ref.read(productsProvider(null).future).then<void>((_) {}).catchError((_) {}),
    ]);
  }

  Widget _featureItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 4.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.btnColor, size: 24.sp),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff111827),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: Text(
                desc,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  Future<void> _showNoInternetDialog({required VoidCallback onRetry}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(28.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90.r,
                height: 90.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.08),
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 44.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 20.h),
              customText(
                text: "No Internet Connection",
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xff1C1F26),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10.h),
              customText(
                text:
                    "Oops! It looks like you're offline.\nPlease check your connection and try again.",
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xff6B7280),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  icon: Icon(Icons.refresh_rounded, size: 20.sp),
                  label: customText(
                    text: "Try Again",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onRetry();
                  },
                ),
              ),
              SizedBox(height: 10.h),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: customText(
                  text: "Dismiss",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedSubcategory = ref.watch(selectedSubcategoryProvider);
    final cart = ref.watch(cartProvider);
    final itemCount = cart.itemCount;
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCount = notificationsAsync.whenOrNull(
      data: (list) => list.where((n) => !n.isRead).length,
    ) ?? 0;
    // Use subcategory ID if selected, else category ID, else null (all products)
    final productCategoryId = selectedSubcategory?.id ?? selectedCategory?.id;
    final productsAsync = ref.watch(productsProvider(productCategoryId));
    final sliderAsync = ref.watch(sliderProvider);

    // Reset flags when providers succeed so the dialog can show again
    // if a NEW error occurs later (e.g. user loses connection again)
    if (sliderAsync.hasValue) _sliderErrorDialogShown = false;
    if (categoriesAsync.hasValue) _categoriesErrorDialogShown = false;
    if (productsAsync.hasValue) _productsErrorDialogShown = false;

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
            goRouter.go('${AppRoutes.onboarding}?screen=4');
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
                          color: AppColors.btnColor,
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 26.sp,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 18.w,
                        height: 18.w,
                        decoration: const BoxDecoration(
                          color: AppColors.btnColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$unreadCount',
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
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  verticalSpacer(height: 8),
                  CompositedTransformTarget(
                    link: _filterLayerLink,
                    child: Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: AppColors.greyBorder, width: 1.w),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 14.w),
                          Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 22.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search products, brands...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey.shade400,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                FocusScope.of(context).unfocus();
                              },
                              child: Padding(
                                padding: EdgeInsets.only(right: 2.w),
                                child: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18.sp),
                              ),
                            ),
                          Container(
                            width: 1,
                            height: 22.h,
                            color: Colors.grey.shade200,
                            margin: EdgeInsets.symmetric(horizontal: 10.w),
                          ),
                          GestureDetector(
                            onTap: _toggleFilterOverlay,
                            child: Padding(
                              padding: EdgeInsets.only(right: 14.w),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    color: _sortBy != 'newest'
                                        ? AppColors.primary
                                        : Colors.grey.shade500,
                                    size: 22.sp,
                                  ),
                                  if (_sortBy != 'newest')
                                    Positioned(
                                      top: -3,
                                      right: -3,
                                      child: Container(
                                        width: 7.w,
                                        height: 7.w,
                                        decoration: const BoxDecoration(
                                          color: Color(0xffef4444),
                                          shape: BoxShape.circle,
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
                  ),
                ],
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      verticalSpacer(height: 8),
                      sliderAsync.when(
                        data: (sliders) {
                          if (sliders.isEmpty) {
                            return const SizedBox();
                          }
                          return Stack(
                            children: [
                              CarouselSlider(
                                options: CarouselOptions(
                                  height: 200.h,
                                  autoPlay: true,
                                  autoPlayInterval: const Duration(seconds: 4),
                                  enlargeCenterPage: true,
                                  enlargeFactor: 0.25,
                                  viewportFraction: 1.0,
                                  onPageChanged: (index, reason) {
                                    setState(() {
                                      _currentCarouselIndex = index;
                                    });
                                  },
                                ),
                                items: sliders.map((slider) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.r),
                                      child: CachedNetworkImage(
                                        imageUrl: slider.image,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                color: Colors.white,
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xffF0F0F0),
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.image_not_supported_outlined,
                                                  size: 40.sp,
                                                  color: Colors.grey[400],
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              // Dots overlay — bottom-center inside the slider
                              Positioned(
                                bottom: 10.h,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10.w, vertical: 5.h),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.25),
                                      borderRadius:
                                          BorderRadius.circular(20.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: sliders
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final isActive =
                                            _currentCarouselIndex == entry.key;
                                        return GestureDetector(
                                          onTap: () => setState(() =>
                                              _currentCarouselIndex =
                                                  entry.key),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            width: isActive ? 20.w : 7.w,
                                            height: 7.h,
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 3.w),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.r),
                                              color: isActive
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withOpacity(0.45),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const ShimmerSliderBanner(),
                        error: (err, stack) {
                          if (!_sliderErrorDialogShown) {
                            _sliderErrorDialogShown = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _showNoInternetDialog(
                                  onRetry: () {
                                    _sliderErrorDialogShown = false;
                                    ref.invalidate(sliderProvider);
                                  },
                                );
                              }
                            });
                          }
                          return const ShimmerSliderBanner();
                        },
                      ),
                      verticalSpacer(height: 8),
                      // ── Features bar (matches web) ──────────────────────
                      Container(
                        margin: EdgeInsets.only(bottom: 8.sp),
                        padding: EdgeInsets.symmetric(vertical: 10.sp),
                        decoration: BoxDecoration(
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _featureItem(
                              icon: Icons.local_shipping_outlined,
                              title: 'Free Water Test',
                              desc: 'On first orders',
                            ),
                            _featureItem(
                              icon: Icons.shield_outlined,
                              title: 'Secure Payment',
                              desc: 'SSL encrypted checkout',
                            ),
                            _featureItem(
                              icon: Icons.headset_mic_outlined,
                              title: 'Expert Support',
                              desc: '24/7 customer service',
                            ),
                            _featureItem(
                              icon: Icons.eco_outlined,
                              title: 'Eco Friendly',
                              desc: 'Sustainable products',
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          customText(
                            text: "Shop by Category",
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff111827),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AllCategoriesScreen(),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                customText(
                                  text: "View All",
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.btnColor,
                                ),
                                const Icon(
                                  Icons.arrow_right_alt_rounded,
                                  color: AppColors.btnColor,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      verticalSpacer(height: 16),
                  
                      categoriesAsync.when(
                        data: (allCategories) {
                          final filteredCategories =
                              _filterCategories(allCategories);

                          if (filteredCategories.isEmpty &&
                              _searchQuery.isNotEmpty) {
                            return Center(
                              child: customText(
                                text: "No categories match your search",
                                fontSize: 15.sp,
                                color: Colors.grey[600]!,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }

                          if (allCategories.isEmpty) {
                            return const Center(
                              child: Text("No categories found"),
                            );
                          }

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: filteredCategories.map((cat) {
                                final isSelected = selectedCategory?.id == cat.id;

                                return GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(selectedSubcategoryProvider
                                            .notifier)
                                        .clearSelection();
                                    if (isSelected) {
                                      ref
                                          .read(selectedCategoryProvider
                                              .notifier)
                                          .clearSelection();
                                    } else {
                                      ref
                                          .read(selectedCategoryProvider
                                              .notifier)
                                          .selectCategory(cat);
                                    }
                                  },
                                  child: Container(
                                    width: 140.w,
                                    margin: EdgeInsets.only(right: 10.w),
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
                                        ClipRRect(
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(isSelected ? 9.r : 11.r),
                                            topRight: Radius.circular(isSelected ? 9.r : 11.r),
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: cat.safeImage,
                                            width: double.infinity,
                                            height: 85.h,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Shimmer.fromColors(
                                              baseColor: Colors.grey[300]!,
                                              highlightColor: Colors.grey[100]!,
                                              child: Container(
                                                height: 85.h,
                                                color: Colors.white,
                                              ),
                                            ),
                                            errorWidget: (context, url, error) =>
                                                Container(
                                              height: 85.h,
                                              color: Colors.grey[200],
                                              child: Center(
                                                child: Icon(
                                                  Icons.category_rounded,
                                                  size: 28.sp,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8.w, vertical: 6.h),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.btnColor
                                                : Colors.white,
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(
                                                  isSelected ? 9.r : 11.r),
                                              bottomRight: Radius.circular(
                                                  isSelected ? 9.r : 11.r),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  cat.safeName,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : const Color(0xff111827),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(width: 4.w),
                                              Icon(
                                                isSelected
                                                    ? Icons
                                                        .keyboard_arrow_up_rounded
                                                    : Icons
                                                        .keyboard_arrow_down_rounded,
                                                size: 16.sp,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.grey[600],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                        loading: () => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                              6,
                              (index) => Padding(
                                padding: EdgeInsets.only(right: 10.w),
                                child: const ShimmerCategoryItem(),
                              ),
                            ),
                          ),
                        ),
                        error: (err, stack) {
                          if (!_categoriesErrorDialogShown) {
                            _categoriesErrorDialogShown = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _showNoInternetDialog(
                                  onRetry: () {
                                    _categoriesErrorDialogShown = false;
                                    ref.invalidate(categoriesProvider);
                                  },
                                );
                              }
                            });
                          }
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(
                                6,
                                (index) => Padding(
                                  padding: EdgeInsets.only(right: 10.w),
                                  child: const ShimmerCategoryItem(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // ── Subcategories row (shown when a parent category with subcategories is selected) ──
                      if (selectedCategory != null &&
                          selectedCategory.hasSubcategories) ...[
                        verticalSpacer(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                selectedCategory.subcategories.map((sub) {
                              final isSubSelected =
                                  selectedSubcategory?.id == sub.id;
                              return GestureDetector(
                                onTap: () {
                                  if (isSubSelected) {
                                    ref
                                        .read(selectedSubcategoryProvider
                                            .notifier)
                                        .clearSelection();
                                  } else {
                                    ref
                                        .read(selectedSubcategoryProvider
                                            .notifier)
                                        .selectSubcategory(sub);
                                  }
                                },
                                child: Container(
                                  width: 110.w,
                                  height: 85.w,
                                  margin: EdgeInsets.only(right: 8.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: isSubSelected
                                        ? Border.all(
                                            color: AppColors.btnColor,
                                            width: 2.5,
                                          )
                                        : Border.all(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(isSubSelected ? 9.5.r : 11.r),
                                    child: CachedNetworkImage(
                                      imageUrl: sub.safeImage,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (ctx, url) =>
                                          Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(color: Colors.white),
                                      ),
                                      errorWidget: (ctx, url, err) =>
                                          Container(
                                        color: Colors.grey[200],
                                        child: Icon(Icons.category_rounded,
                                            size: 20.sp,
                                            color: Colors.grey[400]),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          customText(
                            text: selectedSubcategory != null
                                ? selectedSubcategory.safeName
                                : selectedCategory != null
                                    ? selectedCategory.safeName
                                    : "Products",
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff111827),
                          ),
                          if (selectedCategory != null)
                            GestureDetector(
                              onTap: () {
                                ref
                                    .read(selectedSubcategoryProvider.notifier)
                                    .clearSelection();
                                ref
                                    .read(selectedCategoryProvider.notifier)
                                    .clearSelection();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.btnColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Clear',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.btnColor,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Icon(Icons.close,
                                        size: 14.sp,
                                        color: AppColors.btnColor),
                                  ],
                                ),
                              ),
                            ),
                          ],
                      ),
                      verticalSpacer(height: 16),
                      productsAsync.when(
                        data: (response) {
                          final allProducts = response.data?.products ?? [];
                          final filteredProducts = _filterProducts(allProducts);

                          if (filteredProducts.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.w),
                                child: customText(
                                  text: _searchQuery.isEmpty
                                      ? "No products found in this category"
                                      : "No products match \"$_searchQuery\"",
                                  fontSize: 16.sp,
                                  color: Colors.grey[600]!,
                                  fontWeight: FontWeight.w500,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 200.w,
                                  mainAxisExtent: 340.w,
                                  crossAxisSpacing: 4.w,
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
                          );
                        },
                        loading: () => GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200.w,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16.w,
                            mainAxisSpacing: 16.h,
                          ),
                          itemCount: 6,
                          itemBuilder: (context, index) =>
                              const ShimmerProductCard(),
                        ),
                        error: (err, stack) {
                          if (!_productsErrorDialogShown) {
                            _productsErrorDialogShown = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                _showNoInternetDialog(
                                  onRetry: () {
                                    _productsErrorDialogShown = false;
                                    ref.invalidate(
                                        productsProvider(selectedCategory?.id));
                                  },
                                );
                              }
                            });
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200.w,
                              mainAxisExtent: 330.w,
                              crossAxisSpacing: 4.w,
                              mainAxisSpacing: 16.h,
                            ),
                            itemCount: 6,
                            itemBuilder: (context, index) =>
                                const ShimmerProductCard(),
                          );
                        },
                      ),
                      verticalSpacer(height: 40),
                    ],
                  ),
                ),
                ), // SingleChildScrollView
                ), // RefreshIndicator
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Filter Dropdown Overlay Widget
// ─────────────────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  final LayerLink layerLink;
  final String currentSort;
  final void Function(String) onSortSelected;
  final VoidCallback onDismiss;

  const _FilterDropdown({
    required this.layerLink,
    required this.currentSort,
    required this.onSortSelected,
    required this.onDismiss,
  });

  static const _sortOptions = [
    ('newest', 'Newest', Icons.access_time_rounded, 'Default order'),
    ('price-low', 'Price', Icons.trending_up_rounded, 'Low to High'),
    ('price-high', 'Price', Icons.trending_down_rounded, 'High to Low'),
    ('name', 'Name', Icons.sort_by_alpha_rounded, 'A to Z'),
    ('rating', 'Top Rated', Icons.star_rounded, 'Highest rated first'),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onDismiss,
          child: const SizedBox.expand(),
        ),
        CompositedTransformFollower(
          link: layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: Offset(0, 6.h),
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (_, scale, child) => Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: Opacity(opacity: ((scale - 0.85) / 0.15).clamp(0.0, 1.0), child: child),
              ),
              child: _buildCard(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 32.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: AppColors.btnColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.tune_rounded, color: AppColors.btnColor, size: 16.sp),
                ),
                SizedBox(width: 10.w),
                Text(
                  'Sort Products',
                  style: GoogleFonts.inter(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff111827),
                  ),
                ),
                const Spacer(),
                if (currentSort != 'newest')
                  GestureDetector(
                    onTap: () => onSortSelected('newest'),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.btnColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.btnColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Divider(color: Colors.grey.shade100, height: 1, indent: 16.w, endIndent: 16.w),
          SizedBox(height: 6.h),
          // ── Options ─────────────────────────────
          ..._sortOptions.map((opt) {
            final isSelected = currentSort == opt.$1;
            return GestureDetector(
              onTap: () => onSortSelected(opt.$1),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                  border: isSelected
                      ? Border.all(color: AppColors.primary.withOpacity(0.18), width: 1)
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.btnColor : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        opt.$3,
                        color: isSelected ? Colors.white : Colors.grey.shade500,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.$2,
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? AppColors.btnColor : const Color(0xff111827),
                            ),
                          ),
                          Text(
                            opt.$4,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        width: 20.w,
                        height: 20.w,
                        decoration: BoxDecoration(
                          color: AppColors.btnColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded, color: Colors.white, size: 12.sp),
                      ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }
}
