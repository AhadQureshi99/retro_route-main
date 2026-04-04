class AddressResponse {
  final int? statusCode;
  final String? message;
  final List<Address>? data;
  final bool? success;

  AddressResponse({
    this.statusCode,
    this.message,
    this.data,
    this.success,
  });

  factory AddressResponse.fromJson(Map<String, dynamic> json) {
    return AddressResponse(
      statusCode: json['statusCode'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((e) => Address.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      success: json['success'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'statusCode': statusCode,
        'message': message,
        'data': data?.map((e) => e.toJson()).toList(),
        'success': success,
      };
}

class Address {
  final String? id;
  final String? userId;
  final String? fullName;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? pinCode;
  final String? country;
  final String? mobile;
  final Map<String, double>? currentLoc;
  final Map<String, double>? deliveryLoc;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  Address({
    this.id,
    this.userId,
    this.fullName,
    this.addressLine,
    this.city,
    this.state,
    this.pinCode,
    this.country,
    this.mobile,
    this.currentLoc,
    this.deliveryLoc,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    Map<String, double>? _parseLatLon(dynamic raw) {
      if (raw is Map) {
        final lat = (raw['lat'] as num?)?.toDouble();
        final lon = (raw['lon'] as num?)?.toDouble();
        if (lat != null && lon != null) return {'lat': lat, 'lon': lon};
      }
      return null;
    }

    return Address(
      id: json['_id'] as String?,
      userId: json['userId'] as String?,
      fullName: json['fullName'] as String?,
      addressLine: json['addressLine'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pinCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      mobile: json['phoneNumber'] as String?,
      currentLoc: _parseLatLon(json['currentLoc']),
      deliveryLoc: _parseLatLon(json['deliveryLoc']),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      v: json['__v'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'fullName': fullName,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pinCode': pinCode,
        'country': country,
        'phoneNumber': mobile,
        if (currentLoc != null) 'currentLoc': currentLoc,
        if (deliveryLoc != null) 'deliveryLoc': deliveryLoc,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        '__v': v,
      };

  // Safe getters for UI
  String get safeId => id ?? '';
  String get safeFullName => fullName ?? 'No Name';
  String get safeAddressLine => addressLine ?? '';
  String get safeCity => city ?? '';
  String get safeState => state ?? '';
  String get safePinCode => pinCode ?? '';
  String get safeCountry => country ?? '';
  String get safeMobile => mobile ?? '';
  String get displayAddress =>
      '$safeAddressLine, $safeCity, $safeState $safePinCode, $safeCountry';
}