import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/model/product_model.dart';
import 'package:retro_route/repository/product_repo.dart';

final featuredProductsProvider = FutureProvider<ProductResponse>(
  (ref) async {
    final repo = ProductRepo();
    final response = await repo.getFeaturedProducts();
    final filtered = response.data?.products
        ?.where((p) => p.isService != true)
        .toList();
    return ProductResponse(
      statusCode: response.statusCode,
      message: response.message,
      success: response.success,
      data: ProductData(
        products: filtered,
        pagination: response.data?.pagination,
      ),
    );
  },
);

final productsProvider = FutureProvider.family<ProductResponse, String?>(
  (ref, categoryId) async {
    final repo = ProductRepo();
    final response = await repo.getProductsByCategory(categoryId: categoryId);
    // Mirror web: filter out service products (e.g. "Water Test First")
    final filtered = response.data?.products
        ?.where((p) => p.isService != true)
        .toList();
    return ProductResponse(
      statusCode: response.statusCode,
      message: response.message,
      success: response.success,
      data: ProductData(
        products: filtered,
        pagination: response.data?.pagination,
      ),
    );
  },
);