import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/model/category_model.dart';        // ← your model
import 'package:retro_route/repository/product_repo.dart';     // adjust path

// We expose AsyncValue<List<Category>>
final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    // This runs automatically when provider is first watched
    return _fetchCategories();
  }

  Future<List<Category>> _fetchCategories() async {
    final repo = ProductRepo(); // or better: inject via constructor / ref.read
    final response = await repo.getAllCategories();

    // Assuming your API returns success + data list
    if (response.success == true && response.data != null) {
      return response.data!;
    } else {
      // You can throw exception → AsyncValue will catch it as error
      throw Exception(response.message ?? "Failed to load categories");
    }
  }

  // Optional: refresh method if you want pull-to-refresh later
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchCategories);
  }
}