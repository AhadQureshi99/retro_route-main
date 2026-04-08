class SetupProfileData {
  final bool hasCompletedSetup;
  final DeliverySafety? deliverySafety;
  final WaterSetup? waterSetup;

  SetupProfileData({
    this.hasCompletedSetup = false,
    this.deliverySafety,
    this.waterSetup,
  });

  factory SetupProfileData.fromJson(Map<String, dynamic> json) {
    return SetupProfileData(
      hasCompletedSetup: json['hasCompletedSetup'] as bool? ?? false,
      deliverySafety: json['deliverySafety'] != null
          ? DeliverySafety.fromJson(json['deliverySafety'])
          : null,
      waterSetup: json['waterSetup'] != null
          ? WaterSetup.fromJson(json['waterSetup'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'hasCompletedSetup': hasCompletedSetup,
        'deliverySafety': deliverySafety?.toJson(),
        'waterSetup': waterSetup?.toJson(),
      };
}

// ── Delivery Safety ──────────────────────────────────────────────────────────

class DeliverySafety {
  String address;
  String street;
  String city;
  String postalCode;
  String addressLabel;
  String dropOffSpot;
  String dropOffDetails;
  String backyardAccess;
  bool backyardPermission;
  DogSafety dogSafety;
  GateEntry gateEntry;
  String contactPreference;

  DeliverySafety({
    this.address = '',
    this.street = '',
    this.city = '',
    this.postalCode = '',
    this.addressLabel = 'Home',
    this.dropOffSpot = '',
    this.dropOffDetails = '',
    this.backyardAccess = '',
    this.backyardPermission = false,
    DogSafety? dogSafety,
    GateEntry? gateEntry,
    this.contactPreference = '',
  })  : dogSafety = dogSafety ?? DogSafety(),
        gateEntry = gateEntry ?? GateEntry();

  factory DeliverySafety.fromJson(Map<String, dynamic> json) {
    return DeliverySafety(
      address: json['address'] as String? ?? '',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      addressLabel: json['addressLabel'] as String? ?? 'Home',
      dropOffSpot: json['dropOffSpot'] as String? ?? '',
      dropOffDetails: json['dropOffDetails'] as String? ?? '',
      backyardAccess: json['backyardAccess'] as String? ?? '',
      backyardPermission: json['backyardPermission'] as bool? ?? false,
      dogSafety: json['dogSafety'] != null
          ? DogSafety.fromJson(json['dogSafety'])
          : DogSafety(),
      gateEntry: json['gateEntry'] != null
          ? GateEntry.fromJson(json['gateEntry'])
          : GateEntry(),
      contactPreference: json['contactPreference'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'street': street,
        'city': city,
        'postalCode': postalCode,
        'addressLabel': addressLabel,
        'dropOffSpot': dropOffSpot,
        'dropOffDetails': dropOffDetails,
        'backyardAccess': backyardAccess,
        'backyardPermission': backyardPermission,
        'dogSafety': dogSafety.toJson(),
        'gateEntry': gateEntry.toJson(),
        'contactPreference': contactPreference,
      };

  DeliverySafety copyWith({
    String? address,
    String? street,
    String? city,
    String? postalCode,
    String? addressLabel,
    String? dropOffSpot,
    String? dropOffDetails,
    String? backyardAccess,
    bool? backyardPermission,
    DogSafety? dogSafety,
    GateEntry? gateEntry,
    String? contactPreference,
  }) {
    return DeliverySafety(
      address: address ?? this.address,
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      addressLabel: addressLabel ?? this.addressLabel,
      dropOffSpot: dropOffSpot ?? this.dropOffSpot,
      dropOffDetails: dropOffDetails ?? this.dropOffDetails,
      backyardAccess: backyardAccess ?? this.backyardAccess,
      backyardPermission: backyardPermission ?? this.backyardPermission,
      dogSafety: dogSafety ?? this.dogSafety,
      gateEntry: gateEntry ?? this.gateEntry,
      contactPreference: contactPreference ?? this.contactPreference,
    );
  }
}

class DogSafety {
  bool hasDogs;
  String dogsContained;
  String dogNotes;
  bool petsSecuredConfirm;

  DogSafety({
    this.hasDogs = false,
    this.dogsContained = '',
    this.dogNotes = '',
    this.petsSecuredConfirm = false,
  });

  factory DogSafety.fromJson(Map<String, dynamic> json) {
    return DogSafety(
      hasDogs: json['hasDogs'] as bool? ?? false,
      dogsContained: json['dogsContained'] as String? ?? '',
      dogNotes: json['dogNotes'] as String? ?? '',
      petsSecuredConfirm: json['petsSecuredConfirm'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'hasDogs': hasDogs,
        'dogsContained': dogsContained,
        'dogNotes': dogNotes,
        'petsSecuredConfirm': petsSecuredConfirm,
      };

  DogSafety copyWith({
    bool? hasDogs,
    String? dogsContained,
    String? dogNotes,
    bool? petsSecuredConfirm,
  }) {
    return DogSafety(
      hasDogs: hasDogs ?? this.hasDogs,
      dogsContained: dogsContained ?? this.dogsContained,
      dogNotes: dogNotes ?? this.dogNotes,
      petsSecuredConfirm: petsSecuredConfirm ?? this.petsSecuredConfirm,
    );
  }
}

class GateEntry {
  String accessMethod;
  String gateLocation;
  String gateLocationOther;
  String gateCode;

  GateEntry({
    this.accessMethod = '',
    this.gateLocation = '',
    this.gateLocationOther = '',
    this.gateCode = '',
  });

  factory GateEntry.fromJson(Map<String, dynamic> json) {
    return GateEntry(
      accessMethod: json['accessMethod'] as String? ?? '',
      gateLocation: json['gateLocation'] as String? ?? '',
      gateLocationOther: json['gateLocationOther'] as String? ?? '',
      gateCode: json['gateCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'accessMethod': accessMethod,
        'gateLocation': gateLocation,
        'gateLocationOther': gateLocationOther,
        'gateCode': gateCode,
      };

  GateEntry copyWith({
    String? accessMethod,
    String? gateLocation,
    String? gateLocationOther,
    String? gateCode,
  }) {
    return GateEntry(
      accessMethod: accessMethod ?? this.accessMethod,
      gateLocation: gateLocation ?? this.gateLocation,
      gateLocationOther: gateLocationOther ?? this.gateLocationOther,
      gateCode: gateCode ?? this.gateCode,
    );
  }
}

// ── Water Setup ──────────────────────────────────────────────────────────────

class WaterSetup {
  String waterType;
  PoolSetup pool;
  HotTubSetup hotTub;

  WaterSetup({
    this.waterType = '',
    PoolSetup? pool,
    HotTubSetup? hotTub,
  })  : pool = pool ?? PoolSetup(),
        hotTub = hotTub ?? HotTubSetup();

  factory WaterSetup.fromJson(Map<String, dynamic> json) {
    return WaterSetup(
      waterType: json['waterType'] as String? ?? '',
      pool: json['pool'] != null
          ? PoolSetup.fromJson(json['pool'])
          : PoolSetup(),
      hotTub: json['hotTub'] != null
          ? HotTubSetup.fromJson(json['hotTub'])
          : HotTubSetup(),
    );
  }

  Map<String, dynamic> toJson() => {
        'waterType': waterType,
        'pool': pool.toJson(),
        'hotTub': hotTub.toJson(),
      };

  WaterSetup copyWith({
    String? waterType,
    PoolSetup? pool,
    HotTubSetup? hotTub,
  }) {
    return WaterSetup(
      waterType: waterType ?? this.waterType,
      pool: pool ?? this.pool,
      hotTub: hotTub ?? this.hotTub,
    );
  }
}

class PoolSetup {
  String volumeMethod;
  String volumeUnit;
  String shape;
  double length;
  double width;
  double avgDepth;
  int estimatedVolume;
  String customVolumeText;
  String sanitizerSystem;
  String customSanitizer;
  String moreDetails;

  PoolSetup({
    this.volumeMethod = '',
    this.volumeUnit = 'gallons',
    this.shape = '',
    this.length = 0,
    this.width = 0,
    this.avgDepth = 0,
    this.estimatedVolume = 0,
    this.customVolumeText = '',
    this.sanitizerSystem = '',
    this.customSanitizer = '',
    this.moreDetails = '',
  });

  factory PoolSetup.fromJson(Map<String, dynamic> json) {
    return PoolSetup(
      volumeMethod: json['volumeMethod'] as String? ?? '',
      volumeUnit: json['volumeUnit'] as String? ?? 'gallons',
      shape: json['shape'] as String? ?? '',
      length: (json['length'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      avgDepth: (json['avgDepth'] as num?)?.toDouble() ?? 0,
      estimatedVolume: (json['estimatedVolume'] as num?)?.toInt() ?? 0,
      customVolumeText: json['customVolumeText'] as String? ?? '',
      sanitizerSystem: json['sanitizerSystem'] as String? ?? '',
      customSanitizer: json['customSanitizer'] as String? ?? '',
      moreDetails: json['moreDetails'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'volumeMethod': volumeMethod,
        'volumeUnit': volumeUnit,
        'shape': shape,
        'length': length,
        'width': width,
        'avgDepth': avgDepth,
        'estimatedVolume': estimatedVolume,
        'customVolumeText': customVolumeText,
        'sanitizerSystem': sanitizerSystem,
        'customSanitizer': customSanitizer,
        'moreDetails': moreDetails,
      };

  PoolSetup copyWith({
    String? volumeMethod,
    String? volumeUnit,
    String? shape,
    double? length,
    double? width,
    double? avgDepth,
    int? estimatedVolume,
    String? customVolumeText,
    String? sanitizerSystem,
    String? customSanitizer,
    String? moreDetails,
  }) {
    return PoolSetup(
      volumeMethod: volumeMethod ?? this.volumeMethod,
      volumeUnit: volumeUnit ?? this.volumeUnit,
      shape: shape ?? this.shape,
      length: length ?? this.length,
      width: width ?? this.width,
      avgDepth: avgDepth ?? this.avgDepth,
      estimatedVolume: estimatedVolume ?? this.estimatedVolume,
      customVolumeText: customVolumeText ?? this.customVolumeText,
      sanitizerSystem: sanitizerSystem ?? this.sanitizerSystem,
      customSanitizer: customSanitizer ?? this.customSanitizer,
      moreDetails: moreDetails ?? this.moreDetails,
    );
  }
}

class HotTubSetup {
  String coverLock;
  String coverKeyLocation;
  String volume;
  String customVolume;
  String sanitizerSystem;
  String customSanitizer;
  String usage;
  String filterModel;

  HotTubSetup({
    this.coverLock = '',
    this.coverKeyLocation = '',
    this.volume = '',
    this.customVolume = '',
    this.sanitizerSystem = '',
    this.customSanitizer = '',
    this.usage = '',
    this.filterModel = '',
  });

  factory HotTubSetup.fromJson(Map<String, dynamic> json) {
    return HotTubSetup(
      coverLock: json['coverLock'] as String? ?? '',
      coverKeyLocation: json['coverKeyLocation'] as String? ?? '',
      volume: json['volume']?.toString() ?? '',
      customVolume: json['customVolume'] as String? ?? '',
      sanitizerSystem: json['sanitizerSystem'] as String? ?? '',
      customSanitizer: json['customSanitizer'] as String? ?? '',
      usage: json['usage'] as String? ?? '',
      filterModel: json['filterModel'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'coverLock': coverLock,
        'coverKeyLocation': coverKeyLocation,
        'volume': volume,
        'customVolume': customVolume,
        'sanitizerSystem': sanitizerSystem,
        'customSanitizer': customSanitizer,
        'usage': usage,
        'filterModel': filterModel,
      };

  HotTubSetup copyWith({
    String? coverLock,
    String? coverKeyLocation,
    String? volume,
    String? customVolume,
    String? sanitizerSystem,
    String? customSanitizer,
    String? usage,
    String? filterModel,
  }) {
    return HotTubSetup(
      coverLock: coverLock ?? this.coverLock,
      coverKeyLocation: coverKeyLocation ?? this.coverKeyLocation,
      volume: volume ?? this.volume,
      customVolume: customVolume ?? this.customVolume,
      sanitizerSystem: sanitizerSystem ?? this.sanitizerSystem,
      customSanitizer: customSanitizer ?? this.customSanitizer,
      usage: usage ?? this.usage,
      filterModel: filterModel ?? this.filterModel,
    );
  }
}
