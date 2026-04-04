import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retro_route/model/favourite_model.dart';
import 'package:retro_route/model/product_model.dart';
import 'package:retro_route/repository/favourites_repo.dart';

class FavoritesState {
  final bool isLoading;
  final List<FavoriteItem> favorites;
  final String? error;
  final bool hasFetched;

  FavoritesState({
    this.isLoading = false,
    this.favorites = const [],
    this.error,
    this.hasFetched = false,
  });

  static const _sentinel = Object();

  FavoritesState copyWith({
    bool? isLoading,
    List<FavoriteItem>? favorites,
    Object? error = _sentinel,
    bool? hasFetched,
  }) {
    return FavoritesState(
      isLoading: isLoading ?? this.isLoading,
      favorites: favorites ?? this.favorites,
      error: identical(error, _sentinel) ? this.error : error as String?,
      hasFetched: hasFetched ?? this.hasFetched,
    );
  }

  bool isFavorited(String productId) {
    return favorites.any((item) => item.product?.id == productId);
  }
}

// Notifier
class FavoritesNotifier extends Notifier<FavoritesState> {
  @override
  FavoritesState build() => FavoritesState();

  // Fetch once (can be called on app start or on favorites screen)
 Future<void> fetchFavorites(String token) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final repo = ref.read(favoritesRepoProvider);
    final response = await repo.fetchFavourites(token: token);  
    final items = (response.data?.favorites ?? [])
        .where((item) => item.product != null)
        .toList();

    state = state.copyWith(
      isLoading: false,
      favorites: items,
      hasFetched: true,
      error: null,
    );
  } catch (e) {
    state = state.copyWith(
      isLoading: false,
      error: e.toString(),
    );
  }
}

  // Toggle favorite — fully optimistic for both add & remove, API in background
  Future<void> toggleFavorite({
    required String productId,
    required String token,
    required bool currentValue,
    Product? product, // needed for optimistic add
  }) async {
    // ── Snapshot current list for rollback ──
    final previousList = List<FavoriteItem>.from(state.favorites);

    if (currentValue) {
      // ── Optimistic REMOVE ──
      state = state.copyWith(
        favorites: state.favorites
            .where((f) => f.product?.id != productId)
            .toList(),
      );
    } else if (product != null) {
      // ── Optimistic ADD — build a temporary FavoriteItem ──
      final tempItem = FavoriteItem(
        id: 'temp_$productId',
        product: product,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        favorites: [...state.favorites, tempItem],
      );
    }

    final repo = ref.read(favoritesRepoProvider);

    try {
      if (currentValue) {
        await repo.removeFavourites(productId: productId, token: token);
      } else {
        await repo.addFavourites(productId: productId, token: token);
      }
    } catch (e) {
      // ── Rollback to previous list on failure ──
      state = state.copyWith(favorites: previousList, error: e.toString());
    }
  }
}

// Providers
final favoritesRepoProvider = Provider<FavouritesRepo>((ref) => FavouritesRepo());

final favoritesProvider = NotifierProvider<FavoritesNotifier, FavoritesState>(
  () => FavoritesNotifier(),
);

// Optional: just check if a product is favorited (for quick UI)
final isFavoriteProvider = Provider.family<bool, String>((ref, productId) {
  final state = ref.watch(favoritesProvider);
  return state.isFavorited(productId);
});