import 'dart:convert';

// Top-level response model
class OrdersHistoryResponse {
  final int statusCode;
  final String message;
  final List<Order> data;
  final bool success;

  OrdersHistoryResponse({
    required this.statusCode,
    required this.message,
    required this.data,
    required this.success,
  });

  factory OrdersHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final List<Order> orders = [];
    if (rawData is List) {
      for (final e in rawData) {
        if (e is Map<String, dynamic>) {
          try {
            orders.add(Order.fromJson(e));
          } catch (_) {
            // Skip malformed orders rather than crashing the whole list
          }
        }
      }
    }
    return OrdersHistoryResponse(
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 200,
      message: json['message']?.toString() ?? '',
      data: orders,
      success: json['success'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data.map((e) => e.toJson()).toList(),
        'success': success,
      };
}

// ─────────────────────────────────────────────────────────────
// Single Order model
class Order {
  final String id;
  final String userId;
  final String orderId;
  final List<OrderProduct> products;
  final String paymentStatus;
  final String? stripePaymentIntentId;
  final DeliveryAddress? deliveryAddress;
  final String deliveryStatus;
  final String customerNote;
  final DateTime? scheduledDeliveryDate;
  final dynamic assignedDriver; // null in your data
  final DateTime? driverAssignedAt;
  final DateTime? deliveredAt;
  final String driverNotes;
  final double deliveryCharges;
  final double subtotal;
  final double waterTestDiscount;
  final double hst;
  final double total;
  final String deliveryZone;
  final String deliveryDay;
  final Map<String, dynamic>? pendingCrate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  Order({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.products,
    required this.paymentStatus,
    this.stripePaymentIntentId,
    this.deliveryAddress,
    required this.deliveryStatus,
    required this.customerNote,
    this.scheduledDeliveryDate,
    this.assignedDriver,
    this.driverAssignedAt,
    this.deliveredAt,
    required this.driverNotes,
    required this.deliveryCharges,
    required this.subtotal,
    required this.waterTestDiscount,
    required this.hst,
    required this.total,
    required this.deliveryZone,
    required this.deliveryDay,
    this.pendingCrate,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Filter out products with null/deleted productId
    final rawProducts = json['products'] as List<dynamic>? ?? [];
    final validProducts = <OrderProduct>[];
    for (final e in rawProducts) {
      if (e is Map<String, dynamic> && e['productId'] != null && e['productId'] is Map) {
        validProducts.add(OrderProduct.fromJson(e));
      }
    }

    return Order(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      products: validProducts,
      paymentStatus: json['paymentStatus']?.toString() ?? 'Pending',
      stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
      deliveryAddress: json['deliveryAddress'] != null && json['deliveryAddress'] is Map
          ? DeliveryAddress.fromJson(json['deliveryAddress'] as Map<String, dynamic>)
          : null,
      deliveryStatus: json['deliveryStatus']?.toString() ?? 'Pending',
      customerNote: json['customerNote']?.toString() ?? '',
      scheduledDeliveryDate: json['scheduledDeliveryDate'] != null
          ? DateTime.tryParse(json['scheduledDeliveryDate'].toString())
          : null,
      assignedDriver: json['assignedDriver'],
      driverAssignedAt: json['driverAssignedAt'] != null
          ? DateTime.tryParse(json['driverAssignedAt'].toString())
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : null,
      driverNotes: json['driverNotes']?.toString() ?? '',
      deliveryCharges: (json['deliveryCharges'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      waterTestDiscount: (json['waterTestDiscount'] as num?)?.toDouble() ?? 0,
      hst: (json['hst'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      deliveryZone: json['deliveryZone']?.toString() ?? '',
      deliveryDay: json['deliveryDay']?.toString() ?? '',
      pendingCrate: json['pendingCrate'] is Map<String, dynamic>
          ? json['pendingCrate'] as Map<String, dynamic>
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      version: json['__v'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'orderId': orderId,
        'products': products.map((e) => e.toJson()).toList(),
        'paymentStatus': paymentStatus,
        'stripePaymentIntentId': stripePaymentIntentId,
        'deliveryAddress': deliveryAddress?.toJson(),
        'deliveryStatus': deliveryStatus,
        'customerNote': customerNote,
        'scheduledDeliveryDate': scheduledDeliveryDate?.toIso8601String(),
        'assignedDriver': assignedDriver,
        'driverAssignedAt': driverAssignedAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'driverNotes': driverNotes,
        'deliveryCharges': deliveryCharges,
        'subtotal': subtotal,
        'waterTestDiscount': waterTestDiscount,
        'hst': hst,
        'total': total,
        'deliveryZone': deliveryZone,
        'deliveryDay': deliveryDay,
        'pendingCrate': pendingCrate,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        '__v': version,
      };
}

// ─────────────────────────────────────────────────────────────
// Nested: Order Product (inside products array)
class OrderProduct {
  final ProductDetail productId;
  final int quantity;
  final double priceAtPurchase;
  final String id;

  OrderProduct({
    required this.productId,
    required this.quantity,
    required this.priceAtPurchase,
    required this.id,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      productId: ProductDetail.fromJson(json['productId'] as Map<String, dynamic>),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      priceAtPurchase: (json['priceAtPurchase'] as num?)?.toDouble() ?? 0,
      id: json['_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId.toJson(),
        'quantity': quantity,
        'priceAtPurchase': priceAtPurchase,
        '_id': id,
      };
}

// Nested: Product details inside order product
class ProductDetail {
  final String id;
  final String name;
  final List<String> images;
  final String category;
  final String unit;
  final String status;
  final int stock;
  final double price;
  final int discount;
  final String description;
  final int quantity;
  final String brand;
  final List<String> keyFeatures;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  ProductDetail({
    required this.id,
    required this.name,
    required this.images,
    required this.category,
    required this.unit,
    required this.status,
    required this.stock,
    required this.price,
    required this.discount,
    required this.description,
    required this.quantity,
    required this.brand,
    required this.keyFeatures,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Product',
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      category: json['category']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Active',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      brand: json['brand']?.toString() ?? '',
      keyFeatures: (json['keyFeatures'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      version: (json['__v'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'images': images,
        'category': category,
        'unit': unit,
        'status': status,
        'stock': stock,
        'price': price,
        'discount': discount,
        'description': description,
        'quantity': quantity,
        'brand': brand,
        'keyFeatures': keyFeatures,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        '__v': version,
      };
}

// Nested: Delivery Address
class DeliveryAddress {
  final String id;
  final String userId;
  final String addressLine;
  final String city;
  final String state;
  final String country;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  DeliveryAddress({
    required this.id,
    required this.userId,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.country,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      addressLine: json['addressLine']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      version: (json['__v'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'country': country,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        '__v': version,
      };
}