import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/components/shimmer_loading.dart';
import 'package:retro_route/utils/app_assets.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/utils/auth_helper.dart';
import 'package:retro_route/view/dashboard/widgets/product_card.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/cart_view_model/cart_view_model.dart';
import 'package:retro_route/view_model/favourite_view_model/favourite_view_model.dart';

class FavouriteScreen extends ConsumerStatefulWidget {
  const FavouriteScreen({super.key});

  @override
  ConsumerState<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends ConsumerState<FavouriteScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch favorites every time the screen is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFavorites();
    });
  }

  void _fetchFavorites() {
    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token != null && token.isNotEmpty) {
      ref.read(favoritesProvider.notifier).fetchFavorites(token);
    }
  }

  Future<void> _onRefresh() async {
    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token != null && token.isNotEmpty) {
      await ref.read(favoritesProvider.notifier).fetchFavorites(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favState = ref.watch(favoritesProvider);
    ref.watch(authNotifierProvider);
    final isLoggedIn = AuthHelper.isLoggedIn(ref);
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
      body: isLoggedIn ? _buildBody(favState) : _buildLoginRequiredState(),
    );
  }

  Widget _buildLoginRequiredState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 100.sp,
              color: AppColors.btnColor,
            ),
            verticalSpacer(height: 24.h),
            customText(
              text: "Login to View Favourites",
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            verticalSpacer(height: 12.h),
            customText(
              text:
                  "Sign in to save your favorite items\nand access them anytime",
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.black,
              textAlign: TextAlign.center,
            ),
            verticalSpacer(height: 32.h),
            customButton(
              context: context,
              text: "Log In",
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontColor: Colors.white,
              bgColor: AppColors.btnColor ?? Colors.deepPurple,
              borderColor: Colors.transparent,
              borderRadius: 16,
              height: 50,
              width: 240.w,
              isCircular: false,
              onPressed: () {
                goRouter.push(AppRoutes.login);
              },
            ),
            verticalSpacer(height: 16.h),
            GestureDetector(
              onTap: () {
                goRouter.push(AppRoutes.register);
              },
              child: customText(
                text: "Don't have an account? Sign Up",
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.btnColor ?? Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(FavoritesState favState) {
    if (favState.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: GridView.builder(
          padding: EdgeInsets.only(top: 16.h, bottom: 100.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.0,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 20.h,
          ),
          itemCount: 8,
          itemBuilder: (context, index) => const ShimmerFavoriteCard(),
        ),
      );
    }

    if (favState.error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 64.sp,
                  color: Colors.red.shade400,
                ),
              ),
              verticalSpacer(height: 24.h),
              customText(
                text: "Failed to Load",
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              verticalSpacer(height: 8.h),
              customText(
                text: "Something went wrong while fetching\nyour favourites. Please try again.",
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600]!,
                textAlign: TextAlign.center,
              ),
              verticalSpacer(height: 32.h),
              customButton(
                context: context,
                text: "Try Again",
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontColor: Colors.white,
                bgColor: AppColors.primary,
                borderColor: AppColors.primary,
                borderRadius: 16,
                height: 52,
                width: 180.w,
                isCircular: false,
                onPressed: () {
                  final token = ref.read(authNotifierProvider).value?.data?.token;
                  if (token != null && token.isNotEmpty) {
                    ref.read(favoritesProvider.notifier).fetchFavorites(token);
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    if (favState.favorites.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(children: [SizedBox(height: 200.h), _buildEmptyState()]),
      );
    }
    final cart = ref.watch(cartProvider);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: 16.h, bottom: 100.h),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200.w,
            mainAxisExtent: 340.w,
            crossAxisSpacing: 4.w,
            mainAxisSpacing: 16.h,
          ),
        itemCount: favState.favorites.length,
        itemBuilder: (context, index) {
          final favItem = favState.favorites[index];
          final product = favItem.product;

          if (product == null) return const SizedBox.shrink();

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
                  msg: "${product.safeName} is already in the cart",
                );
                return;
              }
              ref.read(cartProvider.notifier).add(product, quantity: 1);
              CustomToast.success(msg: "${product.safeName} added to cart");
            },
          );
        },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 100.sp,
            color: Colors.grey[400],
          ),
          verticalSpacer(height: 24.h),
          customText(
            text: "No favourites yet",
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
          verticalSpacer(height: 12.h),
          customText(
            text: "Tap the heart on items you love\nto see them here",
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600]!,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
