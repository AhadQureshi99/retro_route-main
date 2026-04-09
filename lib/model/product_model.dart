import 'package:retro_route/model/category_model.dart';
import 'package:retro_route/utils/app_urls.dart';

class ProductSize {
  final String size;
  final num price;

  ProductSize({required this.size, required this.price});

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      size: json['size'] as String? ?? '',
      price: json['price'] as num? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'size': size, 'price': price};

  @override
  String toString() => size;
}

class ProductResponse {
  final int? statusCode;
  final String? message;
  final ProductData? data;
  final bool? success;

  ProductResponse({
    this.statusCode,
    this.message,
    this.data,
    this.success,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      statusCode: json['statusCode'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null ? ProductData.fromJson(json['data']) : null,
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

class ProductData {
  final List<Product>? products;
  final Pagination? pagination;

  ProductData({
    this.products,
    this.pagination,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      products: json['products'] != null
          ? List<Product>.from(
              (json['products'] as List).map(
                (x) => Product.fromJson(x as Map<String, dynamic>),
              ),
            )
          : null,
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products?.map((x) => x.toJson()).toList(),
      'pagination': pagination?.toJson(),
    };
  }
}

class Product {
  final String? id;
  final String? name;
  final List<String>? images;
  final Category? category;
  final String? unit;
  final String? status;
  final int? stock;
  final num? price;          // using num to handle both int and double
  final int? discount;
  final String? description;
  final int? quantity;
  final int? rating;
  final int? totalReviews;
  final String? brand;
  final List<ProductSize>? sizes;
  final List<String>? keyFeatures;
  final bool? isService;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  Product({
    this.id,
    this.name,
    this.images,
    this.category,
    this.unit,
    this.status,
    this.stock=0,
    this.price,
    this.discount,
    this.description,
    this.rating,
    this.totalReviews,
    this.quantity,
    this.brand,
    this.sizes,
    this.keyFeatures,
    this.isService,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle category safely - check if it exists and is a valid map
    Category? parsedCategory;
    if (json['category'] != null) {
      try {
        final categoryData = json['category'];
        if (categoryData is Map<String, dynamic>) {
          parsedCategory = Category.fromJson(categoryData);
        }
      } catch (e) {
        // Log but don't crash if category parsing fails
        print('Warning: Failed to parse category: $e');
        parsedCategory = null;
      }
    }

    return Product(
      id: json['_id'] as String? ?? json['id'] as String?,
      name: json['name'] as String?,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : null,
      category: parsedCategory,
      unit: json['unit'] as String?,
      status: json['status'] as String?,
      stock: (json['stock'] as num?)?.toInt(),
      price: json['price'] as num?,
      discount: (json['discount'] as num?)?.toInt(),
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toInt(),
      brand: json['brand'] as String?,
        sizes: json['sizes'] != null
          ? (json['sizes'] as List).map((s) {
              if (s is Map<String, dynamic>) {
                return ProductSize.fromJson(s);
              }
              // Backward compat: plain string
              return ProductSize(size: s.toString(), price: json['price'] as num? ?? 0);
            }).toList()
          : null,
      rating: (json['rating'] as num?)?.toInt(),
      totalReviews: (json['totalReviews'] as num?)?.toInt(),
      keyFeatures: json['keyFeatures'] != null
          ? List<String>.from(json['keyFeatures'] as List)
          : null,
      isService: json['isService'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      v: (json['__v'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'images': images,
      'category': category?.toJson(),
      'unit': unit,
      'status': status,
      'stock': stock,
      'price': price,
      'discount': discount,
      'description': description,
      'quantity': quantity,
      'brand': brand,
      'sizes': sizes?.map((s) => s.toJson()).toList(),
      'keyFeatures': keyFeatures,
      'isService': isService,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      '__v': v,
      'id': id, // if API returns both _id and id
    };
  }

  // Helpers for safer usage
  String get safeName => name ?? 'Unnamed Product';
  String get firstImage {
    if (images == null || images!.isEmpty) return '';
    final img = images!.first;
    if (img.startsWith('/')) return '${AppUrls.baseUrl}$img';
    return img;
  }
  String get safeBrand => brand ?? 'Unknown Brand';
  double get discountedPrice {
    if (price == null) return 0;
    final disc = (discount ?? 0) / 100;
    return price! * (1 - disc);
  }

  /// Returns the effective price for a specific size, with discount applied.
  double priceForSize(String? selectedSize) {
    if (selectedSize != null && sizes != null && sizes!.isNotEmpty) {
      final match = sizes!.where((s) => s.size == selectedSize);
      if (match.isNotEmpty && match.first.price > 0) {
        final sizePrice = match.first.price.toDouble();
        final disc = (discount ?? 0) / 100;
        return sizePrice * (1 - disc);
      }
    }
    return discountedPrice;
  }

  /// Returns the original (pre-discount) price for a specific size.
  double originalPriceForSize(String? selectedSize) {
    if (selectedSize != null && sizes != null && sizes!.isNotEmpty) {
      final match = sizes!.where((s) => s.size == selectedSize);
      if (match.isNotEmpty && match.first.price > 0) {
        return match.first.price.toDouble();
      }
    }
    return (price ?? 0).toDouble();
  }
}

class ProductCategory {
  final String? id;
  final String? name;
  final String? image;

  ProductCategory({
    this.id,
    this.name,
    this.image,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'image': image,
    };
  }

  String get safeName => name ?? 'Unknown Category';
  String get safeImage => image ?? '';
}

class Pagination {
  final int? totalDocs;
  final int? limit;
  final int? totalPages;
  final int? page;
  final int? pagingCounter;
  final bool? hasPrevPage;
  final bool? hasNextPage;
  final dynamic prevPage;
  final dynamic nextPage;

  Pagination({
    this.totalDocs,
    this.limit,
    this.totalPages,
    this.page,
    this.pagingCounter,
    this.hasPrevPage,
    this.hasNextPage,
    this.prevPage,
    this.nextPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      totalDocs: json['totalDocs'] as int?,
      limit: json['limit'] as int?,
      totalPages: json['totalPages'] as int?,
      page: json['page'] as int?,
      pagingCounter: json['pagingCounter'] as int?,
      hasPrevPage: json['hasPrevPage'] as bool?,
      hasNextPage: json['hasNextPage'] as bool?,
      prevPage: json['prevPage'],
      nextPage: json['nextPage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDocs': totalDocs,
      'limit': limit,
      'totalPages': totalPages,
      'page': page,
      'pagingCounter': pagingCounter,
      'hasPrevPage': hasPrevPage,
      'hasNextPage': hasNextPage,
      'prevPage': prevPage,
      'nextPage': nextPage,
    };
  }

  bool get hasMore => hasNextPage == true;
}