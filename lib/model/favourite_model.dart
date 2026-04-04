import 'dart:developer';
import 'package:retro_route/model/product_model.dart'; // assuming your Product model is here

class FavoritesResponse {
  final int? statusCode;
  final String? message;
  final FavoritesData? data;
  final bool? success;

  FavoritesResponse({
    this.statusCode,
    this.message,
    this.data,
    this.success,
  });

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    return FavoritesResponse(
      statusCode: json['statusCode'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null ? FavoritesData.fromJson(json['data']) : null,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'data': data?.toJson(),
      'success': success,
    };
  }
}

class FavoritesData {
  final List<FavoriteItem>? favorites;
  final int? totalFavorites;
  final int? currentPage;
  final int? totalPages;

  FavoritesData({
    this.favorites,
    this.totalFavorites,
    this.currentPage,
    this.totalPages,
  });

  factory FavoritesData.fromJson(Map<String, dynamic> json) {
    List<FavoriteItem> parsedFavorites = [];

    if (json['favorites'] != null) {
      for (final e in (json['favorites'] as List)) {
        try {
          final item = FavoriteItem.fromJson(e as Map<String, dynamic>);
          // Only keep items that have a valid product (not deleted)
          if (item.product != null) {
            parsedFavorites.add(item);
          }
        } catch (err) {
          // Skip any item that fails to parse (e.g. corrupted or deleted product)
          log('FavoritesData: skipping malformed favourite item: $err');
        }
      }
    }

    return FavoritesData(
      favorites: parsedFavorites,
      totalFavorites: json['totalFavorites'] as int?,
      currentPage: json['currentPage'] as int?,
      totalPages: json['totalPages'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favorites': favorites?.map((e) => e.toJson()).toList(),
      'totalFavorites': totalFavorites,
      'currentPage': currentPage,
      'totalPages': totalPages,
    };
  }
}

class FavoriteItem {
  final String? id;
  final String? userId;
  final Product? product; // ← reusing your existing Product model
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  FavoriteItem({
    this.id,
    this.userId,
    this.product,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    // productId can be null (deleted product) or a full populated object
    Product? product;
    final rawProduct = json['productId'];
    if (rawProduct != null && rawProduct is Map<String, dynamic>) {
      try {
        product = Product.fromJson(rawProduct);
      } catch (e) {
        log('FavoriteItem: failed to parse product: $e');
        product = null;
      }
    }

    return FavoriteItem(
      id: json['_id'] as String?,
      userId: json['userId'] as String?,
      product: product,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'productId': product?.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
    };
  }

  // Convenience getters
  String get safeId => id ?? '';
  Product? get productInfo => product;
}

