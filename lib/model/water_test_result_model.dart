class WaterTestResult {
  final String orderId;
  final String customerId;
  final String poolType; // 'hottub' | 'pool'
  final String sanitizerType; // 'chlorine' | 'bromine' | 'salt' | 'biguanide'
  final double? volume; // liters
  final DateTime testedAt;

  // Parameters
  final double? freeChlorine;
  final double? totalChlorine;
  final double? bromine;
  final double? pH;
  final double? alkalinity;
  final double? hardness;
  final double? cyanuricAcid;
  final double? copper;
  final double? iron;
  final double? phosphate;
  final double? salt;
  final double? borate;
  final double? biguanide;
  final double? biguanideShock;

  // Visual observations
  final bool hasFoam;
  final bool isCloudy;
  final bool filterDirty;
  final bool hasScale;
  final bool needsFlush;
  final bool hasAlgae;

  // Pool history
  final String? lastDrain;
  final bool isFirstVisit;

  WaterTestResult({
    required this.orderId,
    required this.customerId,
    required this.poolType,
    this.sanitizerType = 'chlorine',
    this.volume,
    required this.testedAt,
    this.freeChlorine,
    this.totalChlorine,
    this.bromine,
    this.pH,
    this.alkalinity,
    this.hardness,
    this.cyanuricAcid,
    this.copper,
    this.iron,
    this.phosphate,
    this.salt,
    this.borate,
    this.biguanide,
    this.biguanideShock,
    required this.hasFoam,
    required this.isCloudy,
    required this.filterDirty,
    required this.hasScale,
    required this.needsFlush,
    this.hasAlgae = false,
    this.lastDrain,
    this.isFirstVisit = false,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'customerId': customerId,
        'poolType': poolType,
        'sanitizerType': sanitizerType,
        'volume': volume,
        'testedAt': testedAt.toIso8601String(),
        'freeChlorine': freeChlorine,
        'totalChlorine': totalChlorine,
        'bromine': bromine,
        'pH': pH,
        'alkalinity': alkalinity,
        'hardness': hardness,
        'cyanuricAcid': cyanuricAcid,
        'copper': copper,
        'iron': iron,
        'phosphate': phosphate,
        'salt': salt,
        'borate': borate,
        'biguanide': biguanide,
        'biguanideShock': biguanideShock,
        'hasFoam': hasFoam,
        'isCloudy': isCloudy,
        'filterDirty': filterDirty,
        'hasScale': hasScale,
        'needsFlush': needsFlush,
        'hasAlgae': hasAlgae,
        'lastDrain': lastDrain,
        'isFirstVisit': isFirstVisit,
      };

  Map<String, double?> get asMap => {
        'freeChlorine': freeChlorine,
        'totalChlorine': totalChlorine,
        'bromine': bromine,
        'pH': pH,
        'alkalinity': alkalinity,
        'hardness': hardness,
        'cyanuricAcid': cyanuricAcid,
        'copper': copper,
        'iron': iron,
        'phosphate': phosphate,
        'salt': salt,
        'borate': borate,
        'biguanide': biguanide,
        'biguanideShock': biguanideShock,
      };
}

class CrateItem {
  final String sku;
  final String name;
  final int qty;
  final double price;
  final String reason;
  final bool urgent;
  final String size;

  CrateItem({
    required this.sku,
    required this.name,
    required this.qty,
    required this.price,
    required this.reason,
    required this.urgent,
    this.size = '',
  });

  factory CrateItem.fromMap(Map<String, dynamic> map) => CrateItem(
        sku: map['sku'],
        name: map['name'],
        qty: map['qty'],
        price: (map['price'] as num).toDouble(),
        reason: map['reason'],
        urgent: map['urgent'] ?? false,
        size: map['size'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'sku': sku,
        'name': name,
        'qty': qty,
        'price': price,
        'reason': reason,
        'urgent': urgent,
        'size': size,
      };

  double get lineTotal => price * qty;
}

class EodReport {
  final String driverId;
  final String date;
  final int totalStops;
  final int delivered;
  final int pending;
  final double totalRevenue;
  final int waterTestsDone;
  final double kmDriven;
  final double sodReading;
  final double eodReading;
  final double avgMinPerStop;
  final String? notes;

  EodReport({
    required this.driverId,
    required this.date,
    required this.totalStops,
    required this.delivered,
    required this.pending,
    required this.totalRevenue,
    required this.waterTestsDone,
    required this.kmDriven,
    required this.sodReading,
    required this.eodReading,
    required this.avgMinPerStop,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'driverId': driverId,
        'date': date,
        'totalStops': totalStops,
        'delivered': delivered,
        'pending': pending,
        'totalRevenue': totalRevenue,
        'waterTestsDone': waterTestsDone,
        'kmDriven': kmDriven,
        'sodReading': sodReading,
        'eodReading': eodReading,
        'avgMinPerStop': avgMinPerStop,
        'notes': notes,
      };
}
