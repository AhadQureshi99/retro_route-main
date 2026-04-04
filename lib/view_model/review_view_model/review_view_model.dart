import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:retro_route/model/review_model.dart'; // ReviewResponse, Review, etc.
import 'package:retro_route/repository/review_repo.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';

// Repository provider (unchanged)
final reviewRepoProvider = Provider<ReviewRepo>((ref) => ReviewRepo());

// ── State class (unchanged) ────────────────────────────────────────────────
class ReviewState {
  final bool isLoading;
  final ReviewResponse? response;
  final String? error;
  final Review? userOwnReview;

  ReviewState({
    this.isLoading = false,
    this.response,
    this.error,
    this.userOwnReview,
  });

  ReviewState copyWith({
    bool? isLoading,
    ReviewResponse? response,
    String? error,
    Review? userOwnReview,
  }) {
    return ReviewState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      error: error ?? this.error,
      userOwnReview: userOwnReview ?? this.userOwnReview,
    );
  }
}

// ── Notifier using StateNotifier ───────────────────────────────────────────
class ReviewNotifier extends StateNotifier<ReviewState> {
  final Ref ref;               // We keep ref to read other providers
  final String productId;      // Family parameter stored here

  ReviewNotifier({
    required this.ref,
    required this.productId,
  }) : super(ReviewState(isLoading: true)) {
    // Start loading right after construction
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = ref.read(authNotifierProvider).value?.data?.token;

      // Guest user — no token, skip API call and show empty reviews silently
      if (token == null) {
        state = state.copyWith(
          isLoading: false,
          response: null,
          error: null,
        );
        return;
      }

      final repo = ref.read(reviewRepoProvider);
      final resp = await repo.getProductReviews(
        token: token,
        productId: productId,
      );

      final userId = ref.read(authNotifierProvider).value?.data?.user.id;

      final ownReview = resp.message?.reviews?.firstWhereOrNull(
        (r) => r.userId?.id == userId,
      );
      state = state.copyWith(
        isLoading: false,
        response: resp,
        userOwnReview: ownReview,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> submitReview({
    required int rating,
    String? title,
    String? comment,
  }) async {
    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token == null) return false;

    try {
      final repo = ref.read(reviewRepoProvider);
      await repo.createReview(
        token: token,
        productId: productId,
        rating: rating,
        title: title,
        comment: comment,
      );
      await _loadReviews();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateOwnReview({
    required String reviewId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token == null) return false;

    try {
      final repo = ref.read(reviewRepoProvider);
      await repo.updateReview(
        token: token,
        reviewId: reviewId,
        rating: rating,
        title: title,
        comment: comment,
      );
      await _loadReviews();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteOwnReview({
    required String reviewId,
  }) async {
    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token == null) return false;

    try {
      final repo = ref.read(reviewRepoProvider);
      await repo.deleteReview(token: token, reviewId: reviewId);
      await _loadReviews();
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ── Provider definition ─────────────────────────────────────────────────────
final reviewProvider = StateNotifierProvider.autoDispose
    .family<ReviewNotifier, ReviewState, String>(
  (ref, productId) {
    return ReviewNotifier(
      ref: ref,
      productId: productId,
    );
  },
);