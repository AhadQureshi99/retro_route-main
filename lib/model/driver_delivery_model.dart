import 'package:retro_route/model/setup_profile_model.dart';

class DriverDeliveriesResponse {
  final int? statusCode;
  final String? message;
  final List<DriverDelivery>? data;
  final bool? success;

  DriverDeliveriesResponse({
    this.statusCode,
    this.message,
    this.data,
    this.success,
  });

  factory DriverDeliveriesResponse.fromJson(Map<String, dynamic> json) {
    return DriverDeliveriesResponse(
      statusCode: json['statusCode'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => DriverDelivery.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'data': data?.map((e) => e.toJson()).toList(),
      'success': success,
    };
  }
}

class DriverDelivery {
  final String? id;
  final DeliveryUser? userId;
  final String? orderId;
  final List<DeliveryProduct>? products;
  final String? paymentStatus;
  final String? stripePaymentIntentId;
  final DeliveryAddress? deliveryAddress;
  final String? deliveryStatus;
  final String? customerNote;
  final DateTime? scheduledDeliveryDate;
  final String? assignedDriver;
  final DateTime? driverAssignedAt;
  final DateTime? deliveredAt;
  final String? driverNotes;
  final num? deliveryCharges;
  final String? deliveryZone;
  final String? deliveryDay;
  final bool? isOutOfZone;
  final num? subtotal;
  final num? total;
  final num? waterTestDiscount;
  final num? hst;
  final Map<String, dynamic>? pendingCrate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DriverDelivery({
    this.id,
    this.userId,
    this.orderId,
    this.products,
    this.paymentStatus,
    this.stripePaymentIntentId,
    this.deliveryAddress,
    this.deliveryStatus,
    this.customerNote,
    this.scheduledDeliveryDate,
    this.assignedDriver,
    this.driverAssignedAt,
    this.deliveredAt,
    this.driverNotes,
    this.deliveryCharges,
    this.deliveryZone,
    this.deliveryDay,
    this.isOutOfZone,
    this.subtotal,
    this.total,
    this.waterTestDiscount,
    this.hst,
    this.pendingCrate,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverDelivery.fromJson(Map<String, dynamic> json) {
    return DriverDelivery(
      id: json['_id'] as String?,
      userId: json['userId'] != null
          ? DeliveryUser.fromJson(json['userId'] as Map<String, dynamic>)
          : null,
      orderId: json['orderId'] as String?,
      products: json['products'] != null
          ? (json['products'] as List)
              .map((e) => DeliveryProduct.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      paymentStatus: json['paymentStatus'] as String?,
      stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
      deliveryAddress: json['deliveryAddress'] != null
          ? DeliveryAddress.fromJson(json['deliveryAddress'] as Map<String, dynamic>)
          : null,
      deliveryStatus: json['deliveryStatus'] as String?,
      customerNote: json['customerNote'] as String?,
      scheduledDeliveryDate: json['scheduledDeliveryDate'] != null
          ? DateTime.tryParse(json['scheduledDeliveryDate'] as String)
          : null,
      assignedDriver: json['assignedDriver'] as String?,
      driverAssignedAt: json['driverAssignedAt'] != null
          ? DateTime.tryParse(json['driverAssignedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'] as String)
          : null,
      driverNotes: json['driverNotes'] as String?,
      deliveryCharges: json['deliveryCharges'] as num?,
        deliveryZone: json['deliveryZone'] as String?,
        deliveryDay: json['deliveryDay'] as String?,
        isOutOfZone: json['isOutOfZone'] as bool?,
      subtotal: json['subtotal'] as num?,
      total: json['total'] as num?,
      waterTestDiscount: json['waterTestDiscount'] as num?,
      hst: json['hst'] as num?,
      pendingCrate: json['pendingCrate'] != null
          ? Map<String, dynamic>.from(json['pendingCrate'] as Map)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId?.toJson(),
      'orderId': orderId,
      'products': products?.map((e) => e.toJson()).toList(),
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
      'deliveryZone': deliveryZone,
      'deliveryDay': deliveryDay,
      'isOutOfZone': isOutOfZone,
      'subtotal': subtotal,
      'total': total,
      'waterTestDiscount': waterTestDiscount,
      'hst': hst,
      'pendingCrate': pendingCrate,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helper getters
  String get safeOrderId => orderId ?? 'N/A';
  String get safeCustomerName => userId?.name ?? 'Unknown Customer';
  String get safeCustomerEmail => userId?.email ?? '';
  String get safeDeliveryStatus => deliveryStatus ?? 'Unknown';
  String get safePaymentStatus => paymentStatus ?? 'Unknown';
  double get safeTotal => (total ?? 0).toDouble();
  String get formattedTotal => '\$${safeTotal.toStringAsFixed(2)}';
  String? get crateStatus => pendingCrate?['status'] as String?;
  bool get crateApproved => crateStatus == 'approved' || crateStatus == 'paid' || crateStatus == 'delivered';
  bool get cratePending => crateStatus == 'pending_approval';
}

class DeliveryUser {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final DriverOnboardingData? onboardingData;
  final DeliverySafety? deliverySafety;
  final WaterSetup? waterSetup;

  DeliveryUser({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.onboardingData,
    this.deliverySafety,
    this.waterSetup,
  });

  factory DeliveryUser.fromJson(Map<String, dynamic> json) {
    return DeliveryUser(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone']?.toString(),
      onboardingData: json['onboardingData'] != null
          ? DriverOnboardingData.fromJson(
              json['onboardingData'] as Map<String, dynamic>,
            )
          : null,
      deliverySafety: json['deliverySafety'] != null
          ? DeliverySafety.fromJson(
              json['deliverySafety'] as Map<String, dynamic>,
            )
          : null,
      waterSetup: json['waterSetup'] != null
          ? WaterSetup.fromJson(json['waterSetup'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'onboardingData': onboardingData?.toJson(),
      'deliverySafety': deliverySafety?.toJson(),
      'waterSetup': waterSetup?.toJson(),
    };
  }
}

class DriverOnboardingData {
  final DriverOnboardingNotifications? notifications;
  final String? preferredStopType;
  final DateTime? selectedDeliveryDate;
  final bool addWaterTest;
  final String? testingType;

  DriverOnboardingData({
    this.notifications,
    this.preferredStopType,
    this.selectedDeliveryDate,
    this.addWaterTest = false,
    this.testingType,
  });

  factory DriverOnboardingData.fromJson(Map<String, dynamic> json) {
    return DriverOnboardingData(
      notifications: json['notifications'] != null
          ? DriverOnboardingNotifications.fromJson(
              json['notifications'] as Map<String, dynamic>,
            )
          : null,
      preferredStopType: json['preferredStopType'] as String?,
      selectedDeliveryDate: json['selectedDeliveryDate'] != null
          ? DateTime.tryParse(json['selectedDeliveryDate'] as String)
          : null,
      addWaterTest: json['addWaterTest'] as bool? ?? false,
      testingType: json['testingType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications?.toJson(),
      'preferredStopType': preferredStopType,
      'selectedDeliveryDate': selectedDeliveryDate?.toIso8601String(),
      'addWaterTest': addWaterTest,
      'testingType': testingType,
    };
  }
}

class DriverOnboardingNotifications {
  final bool onTheWay;
  final bool resultsReady;

  DriverOnboardingNotifications({
    this.onTheWay = false,
    this.resultsReady = false,
  });

  factory DriverOnboardingNotifications.fromJson(Map<String, dynamic> json) {
    return DriverOnboardingNotifications(
      onTheWay: json['onTheWay'] as bool? ?? false,
      resultsReady: json['resultsReady'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'onTheWay': onTheWay,
      'resultsReady': resultsReady,
    };
  }
}

class DeliveryProduct {
  final DeliveryProductInfo? productId;
  final int? quantity;
  final num? priceAtPurchase;
  final String? id;

  DeliveryProduct({
    this.productId,
    this.quantity,
    this.priceAtPurchase,
    this.id,
  });

  factory DeliveryProduct.fromJson(Map<String, dynamic> json) {
    return DeliveryProduct(
      productId: json['productId'] != null
          ? DeliveryProductInfo.fromJson(json['productId'] as Map<String, dynamic>)
          : null,
      quantity: json['quantity'] as int?,
      priceAtPurchase: json['priceAtPurchase'] as num?,
      id: json['_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId?.toJson(),
      'quantity': quantity,
      'priceAtPurchase': priceAtPurchase,
      '_id': id,
    };
  }
}

class DeliveryProductInfo {
  final String? id;
  final String? name;
  final num? price;
  final List<String>? images;

  DeliveryProductInfo({
    this.id,
    this.name,
    this.price,
    this.images,
  });

  factory DeliveryProductInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryProductInfo(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      price: json['price'] as num?,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'images': images,
    };
  }

  String? get firstImageUrl {
    if (images == null || images!.isEmpty) return null;
    return images!.first;
  }
}

class DeliveryAddress {
  final String? id;
  final String? userId;
  final String? fullName;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? phoneNumber;
  final double? currentLat;
  final double? currentLon;
  final double? deliveryLat;
  final double? deliveryLon;

  DeliveryAddress({
    this.id,
    this.userId,
    this.fullName,
    this.addressLine,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.phoneNumber,
    this.currentLat,
    this.currentLon,
    this.deliveryLat,
    this.deliveryLon,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    final currentLoc = json['currentLoc'] as Map<String, dynamic>?;
    final deliveryLoc = json['deliveryLoc'] as Map<String, dynamic>?;
    return DeliveryAddress(
      id: json['_id'] as String?,
      userId: json['userId'] as String?,
      fullName: json['fullName'] as String?,
      addressLine: json['addressLine'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      phoneNumber: (json['phoneNumber'] ?? json['mobile']) as String?,
      currentLat: (currentLoc?['lat'] as num?)?.toDouble(),
      currentLon: (currentLoc?['lon'] as num?)?.toDouble(),
      deliveryLat: (deliveryLoc?['lat'] as num?)?.toDouble(),
      deliveryLon: (deliveryLoc?['lon'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'fullName': fullName,
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'phoneNumber': phoneNumber,
      'currentLoc': {'lat': currentLat, 'lon': currentLon},
      'deliveryLoc': {'lat': deliveryLat, 'lon': deliveryLon},
    };
  }

  String get fullAddress {
    final parts = [addressLine, city, state, postalCode, country]
        .where((e) => e != null && e.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}

// Driver Stats Model
class DriverStatsResponse {
  final int? statusCode;
  final String? message;
  final DriverStats? data;
  final bool? success;

  DriverStatsResponse({
    this.statusCode,
    this.message,
    this.data,
    this.success,
  });

  factory DriverStatsResponse.fromJson(Map<String, dynamic> json) {
    return DriverStatsResponse(
      statusCode: json['statusCode'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? DriverStats.fromJson(json['data'] as Map<String, dynamic>)
          : null,
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

class DriverStats {
  final int? totalDeliveries;
  final int? completedDeliveries;
  final int? pendingDeliveries;
  final int? onMyWayDeliveries;
  final int? todayDeliveries;
  final int? todayCompletedDeliveries;
  final num? completionRate;

  DriverStats({
    this.totalDeliveries,
    this.completedDeliveries,
    this.pendingDeliveries,
    this.onMyWayDeliveries,
    this.todayDeliveries,
    this.todayCompletedDeliveries,
    this.completionRate,
  });

  factory DriverStats.fromJson(Map<String, dynamic> json) {
    return DriverStats(
      totalDeliveries: json['totalDeliveries'] as int?,
      completedDeliveries: json['completedDeliveries'] as int?,
      pendingDeliveries: json['pendingDeliveries'] as int?,
      onMyWayDeliveries: json['onMyWayDeliveries'] as int?,
      todayDeliveries: json['todayDeliveries'] as int?,
      todayCompletedDeliveries: json['todayCompletedDeliveries'] as int?,
      completionRate: json['completionRate'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalDeliveries': totalDeliveries,
      'completedDeliveries': completedDeliveries,
      'pendingDeliveries': pendingDeliveries,
      'onMyWayDeliveries': onMyWayDeliveries,
      'todayDeliveries': todayDeliveries,
      'todayCompletedDeliveries': todayCompletedDeliveries,
      'completionRate': completionRate,
    };
  }
}
