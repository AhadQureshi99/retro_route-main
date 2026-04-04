import 'package:flutter_riverpod/legacy.dart';
import 'package:retro_route/model/category_model.dart';


final selectedCategoryProvider = StateNotifierProvider<SelectedCategoryNotifier, Category?>(
  (ref) => SelectedCategoryNotifier(),
);

class SelectedCategoryNotifier extends StateNotifier<Category?> {
  SelectedCategoryNotifier() : super(null);

  void selectCategory(Category? category) {
    state = category;
  }

  void clearSelection() {
    state = null;
  }
}

final selectedSubcategoryProvider = StateNotifierProvider<SelectedSubcategoryNotifier, Category?>(
  (ref) => SelectedSubcategoryNotifier(),
);

class SelectedSubcategoryNotifier extends StateNotifier<Category?> {
  SelectedSubcategoryNotifier() : super(null);

  void selectSubcategory(Category? subcategory) {
    state = subcategory;
  }

  void clearSelection() {
    state = null;
  }
}