import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/view_model/category_view_model/category_view_model.dart';
import 'package:retro_route/view_model/category_view_model/selected_category_view_model.dart';

class AllCategoriesScreen extends ConsumerWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: customText(
          text: "All Categories",
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text("No categories available"));
          }

          return GridView.builder(
            padding: EdgeInsets.all(20.w),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140.w,
              childAspectRatio: 0.9,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 16.h,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = selectedCat?.id == cat.id;

              return GestureDetector(
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).selectCategory(cat);
                  Navigator.pop(context); 
                },
                child: Column(
                  children: [
                    Container(
                      width: 90.r,
                      height: 90.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          width: isSelected ? 3 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          cat.safeImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.category, color: Colors.grey),
                        ),
                      ),
                    ),
                    verticalSpacer(height: 8),
                    customText(
                      text: cat.safeName,
                      fontSize: 14,
                      textAlign: TextAlign.center,
                      // maxLines: 2,
                      // overflow: TextOverflow.ellipsis,
                      color: isSelected ? AppColors.primary : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stk) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Error loading categories: $err"),
              TextButton(
                onPressed: () => ref.invalidate(categoriesProvider),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}