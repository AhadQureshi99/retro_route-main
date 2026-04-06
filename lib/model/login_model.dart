import 'dart:convert';

class LoginResponse {
  final int statusCode;
  final String message;
  final LoginData? data;
  final bool success;

  LoginResponse({
    required this.statusCode,
    required this.message,
    this.data,
    required this.success,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      statusCode: json['statusCode'] as int? ?? 0,
      message: json['message'] as String? ?? 'No message',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
      success: json['success'] as bool? ?? false,
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

class LoginData {
  final User user;
  final String token;

  LoginData({
    required this.user,
    required this.token,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      token: json['token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
    };
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final bool verifyEmail;
  final DateTime? lastLoginDate;
  final String status;
  final String role;
  final bool isAvailable;
  final List<dynamic> assignedDeliveries;
  final String? forgotPasswordOTP;
  final DateTime? forgotPasswordOTPExpires;
  final bool isOTPVerified;
  final List<dynamic> permissions;
  final List<dynamic> addressDetails;
  final List<dynamic> shoppingCart;
  final List<dynamic> orderHistory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.verifyEmail,
    this.lastLoginDate,
    required this.status,
    required this.role,
    required this.isAvailable,
    required this.assignedDeliveries,
    this.forgotPasswordOTP,
    this.forgotPasswordOTPExpires,
    required this.isOTPVerified,
    required this.permissions,
    required this.addressDetails,
    required this.shoppingCart,
    required this.orderHistory,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      verifyEmail: json['verifyEmail'] as bool? ?? false,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.tryParse(json['lastLoginDate'] as String)
          : null,
      status: json['status'] as String? ?? 'Unknown',
      role: json['role'] as String? ?? 'User',
      isAvailable: json['isAvailable'] as bool? ?? false,
      assignedDeliveries: json['assignedDeliveries'] as List? ?? [],
      forgotPasswordOTP: json['forgotPasswordOTP'] as String?,
      forgotPasswordOTPExpires: json['forgotPasswordOTPExpires'] != null
          ? DateTime.tryParse(json['forgotPasswordOTPExpires'] as String)
          : null,
      isOTPVerified: json['isOTPVerified'] as bool? ?? false,
      permissions: json['permissions'] as List? ?? [],
      addressDetails: json['addressDetails'] as List? ?? [],
      shoppingCart: json['shoppingCart'] as List? ?? [],
      orderHistory: json['orderHistory'] as List? ?? [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime(2000),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime(2000),
      version: json['__v'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'verifyEmail': verifyEmail,
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'status': status,
      'role': role,
      'isAvailable': isAvailable,
      'assignedDeliveries': assignedDeliveries,
      'forgotPasswordOTP': forgotPasswordOTP,
      'forgotPasswordOTPExpires': forgotPasswordOTPExpires?.toIso8601String(),
      'isOTPVerified': isOTPVerified,
      'permissions': permissions,
      'addressDetails': addressDetails,
      'shoppingCart': shoppingCart,
      'orderHistory': orderHistory,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': version,
    };
  }
}