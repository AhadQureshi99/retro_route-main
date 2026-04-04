import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/model/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String cartFreeWaterTestTag = '__water_test_free__';
const String waterTestFromSuppliesKey = 'water_test_from_supplies';

class CartItem {
  final Product product;
  final int quantity;
  final String? selectedSize;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedSize,
  });

  CartItem copyWith({int? quantity, String? selectedSize}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
    );
  }

  double get totalPrice => product.priceForSize(selectedSize) * quantity;
}


class CartState {
  final List<CartItem> items;

  CartState({this.items = const []});

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get itemCount => items.length;
  bool get isEmpty => items.isEmpty;
}

// ── Cart Notifier
class CartNotifier extends Notifier<CartState> {
  static const String _cartStorageKey = 'cart_items_v1';

  bool _storageLoaded = false;

  @override
  CartState build() {
    _loadCartFromStorage();
    return CartState(); // initial empty cart, then hydrate from storage
  }

  void add(Product product, {int quantity = 1, String? selectedSize}) {
    state = state.copyWith(
      items: _addOrUpdateItem(
        state.items,
        product,
        quantity,
        selectedSize: selectedSize,
      ),
    );
    _storageLoaded = true; // prevent async load from overwriting
    _saveCartToStorage(state.items);
  }

  void updateQuantity(Product product, int newQuantity, {String? selectedSize}) {
    if (newQuantity < 1) {
      remove(product, selectedSize: selectedSize);
      return;
    }

    state = state.copyWith(
      items: _addOrUpdateItem(
        state.items,
        product,
        newQuantity,
        selectedSize: selectedSize,
        replace: true,
      ),
    );
    _saveCartToStorage(state.items);
  }

  void remove(Product product, {String? selectedSize}) {
    final newItems = state.items.where((item) {
      final isSameProduct = item.product.id == product.id;
      final isSameSize = (item.selectedSize ?? '') == (selectedSize ?? '');
      return !(isSameProduct && isSameSize);
    }).toList();
    state = state.copyWith(items: newItems);
    _saveCartToStorage(state.items);
  }

  void clear() {
    state = CartState();
    _saveCartToStorage(state.items);
  }

  Future<void> _saveCartToStorage(List<CartItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        items
            .map(
              (item) => {
                'product': item.product.toJson(),
                'quantity': item.quantity,
                'selectedSize': item.selectedSize,
              },
            )
            .toList(),
      );
      await prefs.setString(_cartStorageKey, encoded);
    } catch (_) {
      // Fail silently to avoid breaking cart UX on storage errors.
    }
  }

  Future<void> _loadCartFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cartStorageKey);
      if (raw == null || raw.isEmpty) {
        _storageLoaded = true;
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _storageLoaded = true;
        return;
      }

      final restoredItems = decoded
          .whereType<Map>()
          .map(
            (entry) {
              final map = Map<String, dynamic>.from(entry);
              final productMap = map['product'];
              if (productMap is! Map) return null;
              final product = Product.fromJson(
                Map<String, dynamic>.from(productMap),
              );

              final quantity = (map['quantity'] as num?)?.toInt() ?? 1;
              final selectedSize = map['selectedSize'] as String?;

              return CartItem(
                product: product,
                quantity: quantity < 1 ? 1 : quantity,
                selectedSize: selectedSize,
              );
            },
          )
          .whereType<CartItem>()
          .toList();

      // Only restore from storage if no items were added in the meantime
      if (restoredItems.isNotEmpty && !_storageLoaded) {
        state = state.copyWith(items: restoredItems);
      }
      _storageLoaded = true;
    } catch (_) {
      _storageLoaded = true;
    }
  }

  // ── Helper: add new or increment existing
  List<CartItem> _addOrUpdateItem(
    List<CartItem> current,
    Product product,
    int quantity, {
    String? selectedSize,
    bool replace = false,
  }) {
    final existingIndex = current.indexWhere(
      (item) =>
          item.product.id == product.id &&
          (item.selectedSize ?? '') == (selectedSize ?? ''),
    );

    if (existingIndex != -1) {
      // already exists → update quantity
      final oldItem = current[existingIndex];
      final updatedQty = replace ? quantity : oldItem.quantity + quantity;

      final updatedList = List<CartItem>.from(current);
      updatedList[existingIndex] = oldItem.copyWith(
        quantity: updatedQty,
        selectedSize: selectedSize,
      );
      return updatedList;
    } else {
      // new item
      return [
        ...current,
        CartItem(
          product: product,
          quantity: quantity,
          selectedSize: selectedSize,
        ),
      ];
    }
  }
}

// ── Provider
final cartProvider = NotifierProvider<CartNotifier, CartState>(() {
  return CartNotifier();
});

// Optional: convenient getters
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).itemCount;
});

final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).subtotal;
});