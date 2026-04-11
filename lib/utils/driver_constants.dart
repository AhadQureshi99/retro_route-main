import 'package:flutter/material.dart';

class DriverColors {
  static const Color orange = Color(0xFFF4511E);
  static const Color orangeLight = Color(0xFFFBE9E7);
  static const Color navy = Color(0xFF1A1A2E);
  static const Color green = Color(0xFF2E7D32);
  static const Color greenMid = Color(0xFF43A047);
  static const Color greenLight = Color(0xFFE8F5E9);
  static const Color amber = Color(0xFFE65100);
  static const Color amberLight = Color(0xFFFFF3E0);
  static const Color red = Color(0xFFC62828);
  static const Color redLight = Color(0xFFFFEBEE);
  static const Color blue = Color(0xFF1565C0);
  static const Color blueLight = Color(0xFFE3F2FD);
  static const Color purple = Color(0xFF6A1B9A);
  static const Color purpleLight = Color(0xFFF3E5F5);
  static const Color bg = Color(0xFFF4F6FA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1A1A2E);
  static const Color textMuted = Color(0xFF616161);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color border = Color(0xFFE8E8EC);
  static const Color divider = Color(0xFFF4F4F8);
}

class WaterTestRanges {
  static const Map<String, Map<String, double>> hotTub = {
    'freeChlorine': {'min': 3.0, 'max': 5.0},
    'totalChlorine': {'min': 0.0, 'max': 5.0},
    'bromine': {'min': 3.0, 'max': 5.0},
    'pH': {'min': 7.2, 'max': 7.6},
    'alkalinity': {'min': 80.0, 'max': 120.0},
    'hardness': {'min': 150.0, 'max': 250.0},
    'cyanuricAcid': {'min': 30.0, 'max': 50.0},
    'copper': {'min': 0.0, 'max': 0.2},
    'iron': {'min': 0.0, 'max': 0.2},
    'phosphate': {'min': 0.0, 'max': 200.0},
    'salt': {'min': 2700.0, 'max': 4000.0},
    'borate': {'min': 30.0, 'max': 50.0},
    'biguanide': {'min': 30.0, 'max': 50.0},
    'biguanideShock': {'min': 30.0, 'max': 50.0},
  };
  static const Map<String, Map<String, double>> pool = {
    'freeChlorine': {'min': 1.0, 'max': 3.0},
    'totalChlorine': {'min': 0.0, 'max': 5.0},
    'bromine': {'min': 1.0, 'max': 3.0},
    'pH': {'min': 7.2, 'max': 7.6},
    'alkalinity': {'min': 100.0, 'max': 150.0},
    'hardness': {'min': 200.0, 'max': 400.0},
    'cyanuricAcid': {'min': 30.0, 'max': 50.0},
    'copper': {'min': 0.0, 'max': 0.2},
    'iron': {'min': 0.0, 'max': 0.2},
    'phosphate': {'min': 0.0, 'max': 200.0},
    'salt': {'min': 2700.0, 'max': 4000.0},
    'borate': {'min': 30.0, 'max': 50.0},
    'biguanide': {'min': 30.0, 'max': 50.0},
    'biguanideShock': {'min': 30.0, 'max': 50.0},
  };
}

enum WtStatus { ok, low, high, na, pending }

WtStatus getWtStatus(String param, double? value, {String poolType = 'hottub', String sanitizer = 'chlorine'}) {
  // N/A rules — field doesn't apply at all
  if (param == 'bromine' && sanitizer != 'bromine') return WtStatus.na;
  if (param == 'freeChlorine' && sanitizer == 'bromine') return WtStatus.na;
  if (param == 'cyanuricAcid' && poolType == 'hottub') return WtStatus.na; // show for pool & both
  if (param == 'salt' && sanitizer != 'salt') return WtStatus.na;
  if (param == 'biguanide' && sanitizer != 'biguanide') return WtStatus.na;
  if (param == 'biguanideShock' && sanitizer != 'biguanide') return WtStatus.na;

  // No value entered yet but field is applicable
  if (value == null) return WtStatus.pending;

  final ranges = poolType == 'hottub' ? WaterTestRanges.hotTub : WaterTestRanges.pool; // 'both' uses pool ranges
  final range = ranges[param];
  if (range == null) return WtStatus.pending;
  if (value < range['min']!) return WtStatus.low;
  if (value > range['max']!) return WtStatus.high;
  return WtStatus.ok;
}

class AutoCrateLogic {
  // Canonical product names from JSON (applied after dedup)
  static const Map<String, String> _skuName = {
    // Hot Tub
    '909415': 'Bromine Tablets', '909416': 'Bromine Tablets',
    '909411': 'Bromine Granules', '909410': 'Bromine Granules',
    '907724': 'Chlorine Tablets', '907723': 'Chlorine Tablets',
    '909367': 'Chlorine Granules', '909371': 'Chlorine Granules',
    '909709': 'Spa Shock Oxidizer', '909711': 'Spa Shock Oxidizer',
    '909905': 'Floating Dispenser',
    '909358': 'PH Reducer', '909355': 'PH Increaser',
    '909356': 'Alkalinity Increaser', '909351': 'Calcium Hardness Increaser',
    '909500': 'Stain and Scale (Prevent)', '909340': 'Instant Cartridge Cleaner',
    '909600': 'Defoamer', '909365': 'Hot Tub Flush',
    '909906': 'Zorbie Oil & Scum Absorber', '903960': 'Carbon Block Pre-Filters',
    '909909': 'Cover Cleaner + UV',
    '904705-HT': 'Aqua Chek Yellow Test Strips', '904706-HT': 'Aqua Check Red Test Strips',
    // Pool
    'RRC-SALT-20K': 'Salt', '907210': 'Chlorine Tabs',
    '902404': 'Shock Granular Chlorine', '908002': 'Non Chlorine Shock',
    '907605': 'Pool Shock 65%',
    '907910': 'PH Down', '907909': 'PH Down',
    '907807': 'PH UP', '904124': 'Alkalinity Increaser',
    '907501': 'Pool Water Stabilizer (Cyanuric Acid)',
    '904809': 'Calcium Hardness Increaser',
    '904162': 'Natural Clarifier', '903460': 'Heavy Duty Clarifier',
    '908335': 'Quick Clear',
    '977162': 'Kill Algae (Algaecide)', '982163': 'Prevent Algae (60% Poly Quat)',
    '908237': 'Long Term Control (Copper Based)',
    '903308': 'Metal Remover', '903319': 'Stain Preventer',
    '904153': 'Phosphate Remover', '902410': 'Deluxe Opening Kit / Closing Kit',
    '903816': '6 Way Test Strip', '904720': 'Salt Test Strips',
    '904705': 'Aqua Chek Yellow Test Strips', '904706': 'Aqua Check Red Test Strips',
  };

  // Canonical sizes from JSON (applied after dedup)
  static const Map<String, String> _skuSize = {
    // Hot Tub
    '909415': '700 gm', '909416': '1.5 kg',
    '909411': '700 gm', '909410': '2 kg',
    '907724': '800 gm', '907723': '2 kg',
    '909367': '720 gm', '909371': '1.5 kg',
    '909709': '1 kg', '909711': '3 kg',
    '909905': '1 x Piece',
    '909358': '1 kg', '909355': '750 gm',
    '909356': '750 gm', '909351': '600 gm',
    '909500': '500 ml', '909340': '650 ml',
    '909600': '500 ml', '909365': '500 ml',
    '909906': '1 x Piece', '903960': '1 x Piece',
    '909909': '650 ml',
    '904705-HT': '50 Strips', '904706-HT': '50 Strips',
    // Pool
    'RRC-SALT-20K': '20 kg', '907210': '4 kg',
    '902404': '454 gm', '908002': '1 kg',
    '907605': '2 kg',
    '907910': '3 kg', '907909': '9 kg',
    '907807': '7 kg', '904124': '8 kg',
    '907501': '1.75 kg', '904809': '6 kg',
    '904162': '1 L', '903460': '1 L',
    '908335': '1 L',
    '977162': '1 L', '982163': '1 L',
    '908237': '1 L',
    '903308': '1 L', '903319': '1 kg',
    '904153': '1 L', '902410': 'Kit',
    '903816': '50 Strips', '904720': '10 Strips',
    '904705': '50 Strips', '904706': '50 Strips',
  };

  // Canonical prices from JSON (applied after dedup)
  static const Map<String, double> _skuPrice = {
    // Hot Tub
    '909415': 39.99, '909416': 59.99,
    '909411': 28.99, '909410': 55.99,
    '907724': 23.99, '907723': 39.99,
    '909367': 19.99, '909371': 29.99,
    '909709': 23.99, '909711': 54.99,
    '909905': 19.95,
    '909358': 9.99, '909355': 9.99,
    '909356': 9.99, '909351': 9.99,
    '909500': 14.99, '909340': 14.99,
    '909600': 13.99, '909365': 10.99,
    '909906': 22.99, '903960': 45.00,
    '909909': 16.99,
    '904705-HT': 15.99, '904706-HT': 15.99,
    // Pool
    'RRC-SALT-20K': 11.95, '907210': 59.95,
    '902404': 15.99, '908002': 21.99,
    '907605': 39.99,
    '907910': 21.99, '907909': 57.99,
    '907807': 39.99, '904124': 44.95,
    '907501': 29.99, '904809': 37.99,
    '904162': 21.99, '903460': 17.99,
    '908335': 19.99,
    '977162': 36.99, '982163': 39.99,
    '908237': 29.80,
    '903308': 17.99, '903319': 24.99,
    '904153': 34.99, '902410': 54.95,
    '903816': 18.99, '904720': 18.99,
    '904705': 15.99, '904706': 15.99,
  };

  static List<Map<String, dynamic>> generateCrate({
    required Map<String, double?> results,
    required String poolType,
    required String sanitizerType,
    double? volume,
    required bool hasFoam,
    required bool isCloudy,
    required bool filterDirty,
    required bool needsFlush,
    bool hasScale = false,
    bool hasAlgae = false,
    String? lastDrain,
    bool isFirstVisit = false,
  }) {
    final List<Map<String, dynamic>> crate = [];

    // For 'both', determine which rules to use based on volume
    // Hot tub volumes are ≤2500L, pool volumes are ≥15000L
    final effectiveType = poolType == 'both'
        ? (volume != null && volume <= 5000 ? 'hottub' : 'pool')
        : poolType;

    // Smart sizing: Small/Medium vs Large/XL per blueprint
    final bool isLarge = effectiveType == 'hottub'
        ? (volume != null && volume >= 1800)
        : (volume != null && volume >= 60000);
    final bool isXL = effectiveType != 'hottub'
        && volume != null && volume >= 80000;

    double? pH = results['pH'];
    double? alk = results['alkalinity'];
    double? hardness = results['hardness'];
    double? bromine = results['bromine'];
    double? freeCl = results['freeChlorine'];
    double? totalCl = results['totalChlorine'];
    double? copper = results['copper'];
    double? iron = results['iron'];
    double? phosphate = results['phosphate'];
    double? cya = results['cyanuricAcid'];
    double? salt = results['salt'];

    if (effectiveType == 'hottub') {
      // ── HOT TUB RULES ──

      // pH
      if (pH != null) {
        if (pH > 7.6) {
          crate.add({
            'sku': '909358', 'name': 'pH Reducer', 'qty': 1,
            'price': 9.99, 'reason': 'pH ${pH.toStringAsFixed(1)} — above 7.6',
            'urgent': pH > 7.8,
          });
        } else if (pH < 7.2) {
          crate.add({
            'sku': '909355', 'name': 'pH Increaser', 'qty': 1,
            'price': 9.99, 'reason': 'pH ${pH.toStringAsFixed(1)} — below 7.2',
            'urgent': true,
          });
        }
      }

      // Alkalinity
      if (alk != null && alk < 80) {
        crate.add({
          'sku': '909356', 'name': 'Alka-Rise 750g',
          'qty': alk < 60 ? 2 : 1,
          'price': 9.99,
          'reason': 'Alkalinity ${alk.toInt()} — ${alk < 60 ? "critically" : ""} below 80',
          'urgent': alk < 60,
        });
      }

      // Calcium (hot tub: <150)
      if (hardness != null && hardness < 150) {
        crate.add({
          'sku': '909351', 'name': 'Cal-Rise 600g', 'qty': 1,
          'price': 9.99, 'reason': 'Calcium ${hardness.toInt()} — below 150',
          'urgent': false,
        });
      }

      // Sanitizer
      if (sanitizerType == 'bromine') {
        if (bromine != null && bromine < 3.0) {
          if (bromine < 1.5) {
            // Urgent: tabs + granules
            crate.add({
              'sku': isLarge ? '909416' : '909415',
              'name': 'Bromine Tabs ${isLarge ? "1.5kg" : "700g"}',
              'qty': 1, 'price': isLarge ? 59.99 : 39.99,
              'reason': 'Bromine ${bromine.toStringAsFixed(1)} — bacteria risk!',
              'urgent': true,
            });
            crate.add({
              'sku': isLarge ? '909410' : '909411',
              'name': 'Bromine Granules ${isLarge ? "2kg" : "700g"}',
              'qty': 1, 'price': isLarge ? 55.99 : 28.99,
              'reason': 'Quick boost needed', 'urgent': true,
            });
          } else {
            crate.add({
              'sku': '909415', 'name': 'Bromine Tabs 700g', 'qty': 1,
              'price': 39.99,
              'reason': 'Bromine ${bromine.toStringAsFixed(1)} — below 3.0',
              'urgent': false,
            });
          }
        }
      } else if (sanitizerType == 'chlorine' || sanitizerType == 'salt') {
        if (freeCl != null && freeCl < 3.0) {
          if (freeCl < 1.0) {
            crate.add({
              'sku': isLarge ? '907723' : '907724',
              'name': 'Chlorine Tabs ${isLarge ? "2kg" : "800g"}',
              'qty': 1, 'price': isLarge ? 32.99 : 23.99,
              'reason': 'Free Cl ${freeCl.toStringAsFixed(1)} — below 3.0',
              'urgent': true,
            });
            crate.add({
              'sku': isLarge ? '909371' : '909367',
              'name': 'Chlorine Granules ${isLarge ? "1.5kg" : "720g"}',
              'qty': 1, 'price': isLarge ? 29.99 : 19.99,
              'reason': 'Boost chlorine quickly', 'urgent': true,
            });
          } else {
            crate.add({
              'sku': '907724', 'name': 'Chlorine Tabs 800g', 'qty': 1,
              'price': 23.99,
              'reason': 'Chlorine maintenance', 'urgent': false,
            });
          }
        }
      }

      // Combined chlorine — shock
      if (freeCl != null && totalCl != null) {
        final combined = totalCl - freeCl;
        if (combined > 0.5) {
          crate.add({
            'sku': isLarge ? '909711' : '909709',
            'name': 'Spa Shock ${isLarge ? "3kg" : "1kg"}',
            'qty': 1, 'price': isLarge ? 54.99 : 23.99,
            'reason': 'Combined Cl ${combined.toStringAsFixed(1)} — shock needed',
            'urgent': combined > 1.0,
          });
        }
      }

      // Copper
      if (copper != null && copper > 0.2) {
        crate.add({
          'sku': '909500', 'name': 'Stain & Scale', 'qty': 1,
          'price': 14.99,
          'reason': 'Copper ${copper.toStringAsFixed(1)} — staining risk',
          'urgent': false,
        });
      }

      // Iron
      if (iron != null && iron > 0.2) {
        crate.add({
          'sku': '909500', 'name': 'Stain & Scale', 'qty': 1,
          'price': 14.99,
          'reason': 'Iron ${iron.toStringAsFixed(1)} — above limit',
          'urgent': false,
        });
      }

      // Phosphate
      if (phosphate != null && phosphate > 200) {
        crate.add({
          'sku': '904153', 'name': 'Phosphate Remover 1L', 'qty': 1,
          'price': 34.99,
          'reason': 'Phosphate ${phosphate.toInt()} ppb — above 200',
          'urgent': false,
        });
      }

      // Visual: Foam
      if (hasFoam) {
        crate.add({
          'sku': '909600', 'name': 'Defoamer', 'qty': 1,
          'price': 13.99, 'reason': 'Foam visible', 'urgent': true,
        });
        crate.add({
          'sku': '909906', 'name': 'Zorbie', 'qty': 1,
          'price': 22.99, 'reason': 'Oil/scum absorber', 'urgent': false,
        });
      }

      // Visual: Cloudy
      if (isCloudy) {
        crate.add({
          'sku': isLarge ? '909711' : '909709',
          'name': 'Spa Shock ${isLarge ? "3kg" : "1kg"}',
          'qty': 1, 'price': isLarge ? 54.99 : 23.99,
          'reason': 'Cloudy water — shock treatment', 'urgent': true,
        });
      }

      // Visual: Filter
      if (filterDirty) {
        crate.add({
          'sku': '909340', 'name': 'Cartridge Cleaner', 'qty': 1,
          'price': 14.99, 'reason': 'Filter dirty', 'urgent': false,
        });
      }

      // Visual: Flush
      if (needsFlush) {
        crate.add({
          'sku': '909365', 'name': 'Whirlpool Rinse', 'qty': 1,
          'price': 10.99, 'reason': 'Full drain/flush needed', 'urgent': true,
        });
        crate.add({
          'sku': '903960', 'name': 'Carbon Pre-Filter', 'qty': 1,
          'price': 45.00, 'reason': 'Pre-filter for fresh fill water',
          'urgent': false,
        });
      }

      // Last drain rules
      if (lastDrain == 'over_1yr' || lastDrain == 'never') {
        if (!needsFlush) {
          crate.add({
            'sku': '909365', 'name': 'Whirlpool Rinse', 'qty': 1,
            'price': 10.99, 'reason': 'Last drain >1yr — flush overdue', 'urgent': true,
          });
          crate.add({
            'sku': '903960', 'name': 'Carbon Pre-Filter', 'qty': 1,
            'price': 45.00, 'reason': 'Pre-filter for fresh fill', 'urgent': true,
          });
        }
        crate.add({
          'sku': '909340', 'name': 'Cartridge Cleaner', 'qty': 1,
          'price': 14.99, 'reason': 'Deep clean after long drain cycle', 'urgent': true,
        });
      } else if (lastDrain == '6to12mo') {
        if (!needsFlush) {
          crate.add({
            'sku': '909365', 'name': 'Whirlpool Rinse', 'qty': 1,
            'price': 10.99, 'reason': 'Last drain 6-12mo — flush recommended', 'urgent': false,
          });
        }
      }

      // Scale buildup (HT)
      if (hasScale) {
        crate.add({
          'sku': '909500', 'name': 'Stain & Scale', 'qty': 1,
          'price': 14.99, 'reason': 'Scale deposits visible', 'urgent': false,
        });
        crate.add({
          'sku': '909909', 'name': 'Cover Cleaner', 'qty': 1,
          'price': 16.99, 'reason': 'Clean scale from cover', 'urgent': false,
        });
      }

      // First visit → Floating Dispenser
      if (isFirstVisit) {
        crate.add({
          'sku': '909905', 'name': 'Floating Dispenser', 'qty': 1,
          'price': 19.95, 'reason': 'First visit — starter dispenser', 'urgent': false,
        });
      }

      // High phosphate >500ppb → Prevent Algae 60%
      if (phosphate != null && phosphate > 500) {
        crate.add({
          'sku': '982163', 'name': 'Prevent Algae 60%', 'qty': 1,
          'price': 39.99, 'reason': 'Phosphate ${phosphate.toInt()} ppb — very high', 'urgent': true,
        });
      }

      // ALWAYS: AquaChek + Zorbie
      crate.add({
        'sku': '904706-HT', 'name': 'AquaChek Red', 'qty': 1,
        'price': 15.99, 'reason': 'Test strips — between visits',
        'urgent': false,
      });
      if (!hasFoam) {
        crate.add({
          'sku': '909906', 'name': 'Zorbie', 'qty': 1,
          'price': 22.99, 'reason': 'Routine oil absorber', 'urgent': false,
        });
      }
    } else {
      // ── POOL RULES ──

      // pH
      if (pH != null) {
        if (pH > 7.6) {
          crate.add({
            'sku': isXL ? '907909' : '907910',
            'name': 'pH Down ${isXL ? "9KG" : "3KG"}',
            'qty': 1, 'price': isXL ? 57.99 : 21.99,
            'reason': 'pH ${pH.toStringAsFixed(1)} — above 7.6', 'urgent': pH > 7.8,
          });
        } else if (pH < 7.2) {
          crate.add({
            'sku': '907807', 'name': 'pH Up 7KG', 'qty': 1,
            'price': 39.99,
            'reason': 'pH ${pH.toStringAsFixed(1)} — below 7.2', 'urgent': true,
          });
        }
      }

      // Alkalinity (pool: <100)
      if (alk != null && alk < 100) {
        crate.add({
          'sku': '904124', 'name': 'Alka Plus 8KG', 'qty': 1,
          'price': 44.95,
          'reason': 'Alkalinity ${alk.toInt()} — below 100', 'urgent': alk < 80,
        });
      }

      // Calcium (pool: <200)
      if (hardness != null && hardness < 200) {
        crate.add({
          'sku': '904809', 'name': 'Cal Plus 6KG', 'qty': 1,
          'price': 37.99,
          'reason': 'Calcium ${hardness.toInt()} — below 200', 'urgent': false,
        });
      }

      // Free Chlorine
      if (freeCl != null && freeCl < 1.0) {
        crate.add({
          'sku': '907210', 'name': 'Chlorine Tabs 4KG', 'qty': 1,
          'price': 59.95,
          'reason': 'Free Cl ${freeCl.toStringAsFixed(1)} — below 1.0',
          'urgent': true,
        });
      }

      // CYA
      if (cya != null && cya < 30) {
        crate.add({
          'sku': '907501', 'name': 'Pool Stabilizer 1.75KG', 'qty': 1,
          'price': 29.99,
          'reason': 'CYA ${cya.toInt()} — below 30', 'urgent': false,
        });
      }

      // Salt (salt systems)
      if (sanitizerType == 'salt' && salt != null && salt < 2700) {
        crate.add({
          'sku': 'RRC-SALT-20K', 'name': 'Salt', 'qty': 1,
          'price': 11.95,
          'reason': 'Salt ${salt.toInt()} — below 2700', 'urgent': true,
        });
      }

      // Phosphate
      if (phosphate != null && phosphate > 200) {
        crate.add({
          'sku': '904153', 'name': 'Phosphate Remover 1L', 'qty': 1,
          'price': 34.99,
          'reason': 'Phosphate ${phosphate.toInt()} ppb — above 200',
          'urgent': false,
        });
      }

      // Metals
      if (copper != null && copper > 0.2) {
        crate.add({
          'sku': '903308', 'name': 'Metal Remover 1L', 'qty': 1,
          'price': 17.99,
          'reason': 'Copper ${copper.toStringAsFixed(1)} — above 0.2',
          'urgent': false,
        });
        crate.add({
          'sku': '903319', 'name': 'Stain Prevention 1KG', 'qty': 1,
          'price': 24.99, 'reason': 'Prevent copper staining', 'urgent': false,
        });
      }
      if (iron != null && iron > 0.2) {
        crate.add({
          'sku': '903308', 'name': 'Metal Remover 1L', 'qty': 1,
          'price': 17.99,
          'reason': 'Iron ${iron.toStringAsFixed(1)} — above 0.2',
          'urgent': false,
        });
      }

      // Visual: Algae
      if (hasAlgae) {
        crate.add({
          'sku': '977162', 'name': 'Kill Algae 1L', 'qty': 1,
          'price': 36.99, 'reason': 'Algae visible', 'urgent': true,
        });
        crate.add({
          'sku': '907605', 'name': 'Shock 65% 2KG', 'qty': 1,
          'price': 39.99, 'reason': 'Shock after algae kill', 'urgent': true,
        });
      }

      // Visual: Cloudy
      if (isCloudy) {
        crate.add({
          'sku': '908335', 'name': 'Quick Clear 1L', 'qty': 1,
          'price': 19.99, 'reason': 'Cloudy water', 'urgent': true,
        });
      }

      // Last drain rules (pool)
      if (lastDrain == 'over_1yr' || lastDrain == 'never') {
        crate.add({
          'sku': '909365', 'name': 'Flush Treatment', 'qty': 1,
          'price': 10.99, 'reason': 'Last drain >1yr — flush overdue', 'urgent': true,
        });
        crate.add({
          'sku': '903960', 'name': 'Carbon Pre-Filter', 'qty': 1,
          'price': 45.00, 'reason': 'Pre-filter for fresh fill', 'urgent': true,
        });
        crate.add({
          'sku': '909340', 'name': 'Cartridge Cleaner', 'qty': 1,
          'price': 14.99, 'reason': 'Deep clean after long cycle', 'urgent': true,
        });
      }

      // Scale buildup (Pool)
      if (hasScale) {
        crate.add({
          'sku': '903319', 'name': 'Stain Prevention 1KG', 'qty': 1,
          'price': 24.99, 'reason': 'Scale deposits visible', 'urgent': false,
        });
      }

      // High phosphate >500ppb → Prevent Algae 60%
      if (phosphate != null && phosphate > 500) {
        crate.add({
          'sku': '982163', 'name': 'Prevent Algae 60%', 'qty': 1,
          'price': 39.99, 'reason': 'Phosphate ${phosphate.toInt()} ppb — very high', 'urgent': true,
        });
      }

      // Salt system → always Salt Test Strips
      if (sanitizerType == 'salt') {
        crate.add({
          'sku': '904720', 'name': 'Salt Test Strips', 'qty': 1,
          'price': 18.99, 'reason': 'Salt system — monitor levels', 'urgent': false,
        });
      }

      // ALWAYS: AquaChek Yellow
      crate.add({
        'sku': '904705', 'name': 'AquaChek Yellow', 'qty': 1,
        'price': 15.99, 'reason': 'Test strips — between visits',
        'urgent': false,
      });
    }

    // Dedup: same SKU → keep highest qty, merge reason
    final Map<String, Map<String, dynamic>> seen = {};
    for (final item in crate) {
      final sku = item['sku'] as String;
      if (seen.containsKey(sku)) {
        final existing = seen[sku]!;
        if ((item['qty'] as int) > (existing['qty'] as int)) {
          existing['qty'] = item['qty'];
        }
        if (item['urgent'] == true) existing['urgent'] = true;
      } else {
        seen[sku] = Map<String, dynamic>.from(item);
      }
    }

    // Apply canonical names, sizes, and prices from JSON
    for (final item in seen.values) {
      final sku = item['sku'] as String;
      if (_skuName.containsKey(sku)) item['name'] = _skuName[sku];
      item['size'] = _skuSize[sku] ?? '';
      if (_skuPrice.containsKey(sku)) item['price'] = _skuPrice[sku];
    }

    return seen.values.toList();
  }
}
