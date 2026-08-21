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

class CrateThresholds {
  static const double htLargeVolume    = 1800;   // L — Large/XL hot tub
  static const double poolBothThreshold = 5000;  // L — 'both' type: ≤ this → use hot tub rules
  static const double poolLargeVolume  = 60000;  // L — Large in-ground pool
  static const double poolXLVolume     = 80000;  // L — XL / Commercial pool
}

enum WtStatus { ok, low, high, na, pending }

WtStatus getWtStatus(String param, double? value, {String poolType = 'hottub', String sanitizer = 'chlorine', double? volume}) {
  // N/A rules — field doesn't apply at all
  if (param == 'bromine' && sanitizer != 'bromine') return WtStatus.na;
  if (param == 'freeChlorine' && sanitizer == 'bromine') return WtStatus.na;
  if (param == 'cyanuricAcid' && poolType == 'hottub') return WtStatus.na; // show for pool & both
  if (param == 'salt' && sanitizer != 'salt') return WtStatus.na;
  if (param == 'biguanide' && sanitizer != 'biguanide') return WtStatus.na;
  if (param == 'biguanideShock' && sanitizer != 'biguanide') return WtStatus.na;

  // No value entered yet but field is applicable
  if (value == null) return WtStatus.pending;

  // For 'both', use the same volume-based rule as generateCrate to keep ranges consistent
  final effectivePoolType = poolType == 'both'
      ? (volume != null && volume <= CrateThresholds.poolBothThreshold ? 'hottub' : 'pool')
      : poolType;
  final ranges = effectivePoolType == 'hottub' ? WaterTestRanges.hotTub : WaterTestRanges.pool;
  final range = ranges[param];
  if (range == null) return WtStatus.pending;
  if (value < range['min']!) return WtStatus.low;
  if (value > range['max']!) return WtStatus.high;
  return WtStatus.ok;
}

class AutoCrateLogic {
  // Canonical product names from JSON (applied after dedup)
  // NOTE: 904705-HT / 904706-HT are intentional -HT variants used in hot tub crates.
  // 904705 / 904706 are the pool equivalents. In 'both' mode they are treated as
  // separate SKUs so the customer receives the correct product label per water body.
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

  /// Full product catalog — used by the driver "Add Products" sheet.
  static List<Map<String, dynamic>> get catalogProducts {
    return _skuName.entries.map((e) => {
      'sku': e.key,
      'name': e.value,
      'size': _skuSize[e.key] ?? '',
      'price': _skuPrice[e.key] ?? 0.0,
    }).toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  }

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

    // If no chemical values were entered at all, return empty crate — nothing to recommend
    final hasAnyChemicalValue = results.values.any((v) => v != null);
    final hasAnyVisual = hasFoam || isCloudy || filterDirty || needsFlush || hasScale || hasAlgae;
    if (!hasAnyChemicalValue && !hasAnyVisual) {
      return crate;
    }

    // For 'both', determine which rules to use based on volume
    final effectiveType = poolType == 'both'
        ? (volume != null && volume <= CrateThresholds.poolBothThreshold ? 'hottub' : 'pool')
        : poolType;

    // Smart sizing: Small/Medium vs Large/XL per blueprint
    final bool isLarge = effectiveType == 'hottub'
        ? (volume != null && volume >= CrateThresholds.htLargeVolume)
        : (volume != null && volume >= CrateThresholds.poolLargeVolume);
    final bool isXL = effectiveType != 'hottub'
        && volume != null && volume >= CrateThresholds.poolXLVolume;

    // #19 — volume null safety: log a warning for pool/both when volume is missing
    assert(
      effectiveType == 'hottub' || volume != null,
      'generateCrate: volume should be provided for pool/both poolType. Falling back to small-pool sizing.',
    );

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
    double? biguanide = results['biguanide'];
    double? biguanideShock = results['biguanideShock'];

    // Helper: build item with SKU + qty + reason + urgent only.
    // Name / size / price are resolved from canonical maps at the end.
    void add(String sku, {int qty = 1, required String reason, bool urgent = false}) {
      crate.add({'sku': sku, 'qty': qty, 'reason': reason, 'urgent': urgent});
    }

    if (effectiveType == 'hottub') {
      // ── HOT TUB RULES ──

      // pH
      if (pH != null) {
        if (pH > 7.6) {
          add('909358', reason: 'pH ${pH.toStringAsFixed(1)} — above 7.6', urgent: pH > 7.8);
        } else if (pH < 7.2) {
          add('909355', reason: 'pH ${pH.toStringAsFixed(1)} — below 7.2', urgent: true);
        }
      }

      // Alkalinity
      if (alk != null && alk < 80) {
        add('909356',
            qty: alk < 60 ? 2 : 1,
            reason: 'Alkalinity ${alk.toInt()} — ${alk < 60 ? "critically " : ""}below 80',
            urgent: alk < 60);
      }

      // Calcium (hot tub ideal: 150–250)
      if (hardness != null && hardness < 150) {
        add('909351', reason: 'Calcium ${hardness.toInt()} — below 150');
      } else if (hardness != null && hardness > 250) {
        // High calcium → scale risk; Stain & Scale to protect surfaces
        add('909500',
            reason: 'Calcium ${hardness.toInt()} — above 250, scale risk; partial drain recommended');
      }

      // Sanitizer
      if (sanitizerType == 'bromine') {
        if (bromine != null && bromine < 3.0) {
          if (bromine < 1.5) {
            add(isLarge ? '909416' : '909415',
                reason: 'Bromine ${bromine.toStringAsFixed(1)} — bacteria risk!', urgent: true);
            add(isLarge ? '909410' : '909411',
                reason: 'Quick boost needed', urgent: true);
          } else {
            add('909415', reason: 'Bromine ${bromine.toStringAsFixed(1)} — below 3.0');
          }
        }
      } else if (sanitizerType == 'chlorine' || sanitizerType == 'salt') {
        if (freeCl != null && freeCl < 3.0) {
          if (freeCl < 1.0) {
            add(isLarge ? '907723' : '907724',
                reason: 'Free Cl ${freeCl.toStringAsFixed(1)} — below 3.0', urgent: true);
            add(isLarge ? '909371' : '909367',
                reason: 'Boost chlorine quickly', urgent: true);
          } else {
            add('907724', reason: 'Chlorine maintenance');
          }
        }
      }

      // Combined chlorine — shock
      // Guard: skip if totalCl < freeCl (invalid test entry)
      if (freeCl != null && totalCl != null && totalCl >= freeCl) {
        final combined = totalCl - freeCl;
        if (combined > 0.5) {
          add(isLarge ? '909711' : '909709',
              reason: 'Combined Cl ${combined.toStringAsFixed(1)} — shock needed',
              urgent: combined > 1.0);
        }
      }
      // Total Cl high with no freeCl reading → likely combined Cl issue
      if (totalCl != null && totalCl > 5.0 && freeCl == null) {
        add(isLarge ? '909711' : '909709',
            reason: 'Total Cl ${totalCl.toStringAsFixed(1)} — shock recommended', urgent: true);
      }

      // Copper
      if (copper != null && copper > 0.2) {
        add('909500', reason: 'Copper ${copper.toStringAsFixed(1)} — staining risk');
      }

      // Iron
      if (iron != null && iron > 0.2) {
        add('909500', reason: 'Iron ${iron.toStringAsFixed(1)} — above limit');
      }

      // Phosphate > 200
      if (phosphate != null && phosphate > 200) {
        add('904153', reason: 'Phosphate ${phosphate.toInt()} ppb — above 200');
      }

      // Visual: Foam
      if (hasFoam) {
        add('909600', reason: 'Foam visible', urgent: true);
        add('909906', reason: 'Oil/scum absorber');
      }

      // Visual: Cloudy
      if (isCloudy) {
        add(isLarge ? '909711' : '909709',
            reason: 'Cloudy water — shock treatment', urgent: true);
      }

      // Visual: Filter
      if (filterDirty) {
        add('909340', reason: 'Filter dirty');
      }

      // Visual: Flush
      if (needsFlush) {
        add('909365', reason: 'Full drain/flush needed', urgent: true);
        add('903960', reason: 'Pre-filter for fresh fill water');
      }

      // Last drain rules
      if (lastDrain == 'over_1yr') {
        if (!needsFlush) {
          add('909365', reason: 'Last drain >1yr — flush overdue', urgent: true);
          add('903960', reason: 'Pre-filter for fresh fill', urgent: true);
        }
        if (!filterDirty) {
          add('909340', reason: 'Deep clean after long drain cycle', urgent: true);
        }
      } else if (lastDrain == '6to12mo') {
        if (!needsFlush) {
          add('909365', reason: 'Last drain 6-12mo — flush recommended');
        }
      }

      // Scale buildup
      if (hasScale) {
        add('909500', reason: 'Scale deposits visible');
        add('909909', reason: 'Clean scale from cover');
      }

      // First visit → Floating Dispenser
      if (isFirstVisit) {
        add('909905', reason: 'First visit — starter dispenser');
      }

      // High phosphate >500ppb → Prevent Algae 60%
      if (phosphate != null && phosphate > 500) {
        add('982163', reason: 'Phosphate ${phosphate.toInt()} ppb — very high', urgent: true);
      }

      // Biguanide system (#13)
      if (sanitizerType == 'biguanide') {
        if (biguanide != null && biguanide < 30) {
          // No biguanide SKU in catalog — recommend closest equivalent: Non-Chlorine Shock as oxidizer
          add('908002', reason: 'Biguanide ${biguanide.toStringAsFixed(1)} — below 30; check biguanide supply', urgent: true);
        }
        if (biguanideShock != null && biguanideShock < 30) {
          add('909709', reason: 'Biguanide shock ${biguanideShock.toStringAsFixed(1)} — below 30; oxidizer needed', urgent: true);
        }
      }

      // Add companion items only when there are actual issues to address
      if (crate.isNotEmpty) {
        add('904706-HT', reason: 'Test strips — between visits');
        if (!hasFoam) {
          add('909906', reason: 'Routine oil absorber');
        }
      }
    } else {
      // ── POOL RULES ──

      // pH
      if (pH != null) {
        if (pH > 7.6) {
          add(isXL ? '907909' : '907910',
              reason: 'pH ${pH.toStringAsFixed(1)} — above 7.6', urgent: pH > 7.8);
        } else if (pH < 7.2) {
          add('907807', reason: 'pH ${pH.toStringAsFixed(1)} — below 7.2', urgent: true);
        }
      }

      // Alkalinity (pool: <100)
      if (alk != null && alk < 100) {
        add('904124', reason: 'Alkalinity ${alk.toInt()} — below 100', urgent: alk < 80);
      }

      // Calcium (pool ideal: 200–400)
      if (hardness != null && hardness < 200) {
        add('904809', reason: 'Calcium ${hardness.toInt()} — below 200');
      } else if (hardness != null && hardness > 400) {
        // High calcium → scale risk
        add('903319',
            reason: 'Calcium ${hardness.toInt()} — above 400, scale risk; partial drain recommended');
      }

      // Free Chlorine
      if (freeCl != null && freeCl < 1.0) {
        add('907210', reason: 'Free Cl ${freeCl.toStringAsFixed(1)} — below 1.0', urgent: true);
      }

      // CYA
      if (cya != null && cya < 30) {
        add('907501', reason: 'CYA ${cya.toInt()} — below 30');
      } else if (cya != null && cya > 100) {
        // Chlorine lock — only non-chlorine shock helps; partial drain required
        add('908002',
            reason: 'CYA ${cya.toInt()} — chlorine lock; partial drain required',
            urgent: true);
      }

      // Salt (salt systems)
      if (sanitizerType == 'salt' && salt != null) {
        if (salt < 2700) {
          add('RRC-SALT-20K', reason: 'Salt ${salt.toInt()} — below 2700', urgent: true);
        } else if (salt > 4000) {
          // Oversalted — Natural Clarifier helps post-dilution; partial drain needed
          add('904162',
              reason: 'Salt ${salt.toInt()} — above 4000; partial drain + refill needed',
              urgent: true);
        }
      }

      // Total Cl high with no freeCl reading → likely combined Cl issue
      if (totalCl != null && totalCl > 5.0 && freeCl == null) {
        add('908002',
            reason: 'Total Cl ${totalCl.toStringAsFixed(1)} — shock recommended', urgent: true);
      }

      // Phosphate > 200
      if (phosphate != null && phosphate > 200) {
        add('904153', reason: 'Phosphate ${phosphate.toInt()} ppb — above 200');
      }

      // Metals
      if (copper != null && copper > 0.2) {
        add('903308', reason: 'Copper ${copper.toStringAsFixed(1)} — above 0.2');
        add('903319', reason: 'Prevent copper staining');
      }
      if (iron != null && iron > 0.2) {
        add('903308', reason: 'Iron ${iron.toStringAsFixed(1)} — above 0.2');
      }

      // Visual: Algae
      // Guard: skip shock if free chlorine is already very high (> 5 ppm)
      if (hasAlgae) {
        add('977162', reason: 'Algae visible', urgent: true);
        if (freeCl == null || freeCl <= 5.0) {
          add('907605', reason: 'Shock after algae kill', urgent: true);
        }
      }

      // Visual: Cloudy
      if (isCloudy) {
        add('908335', reason: 'Cloudy water', urgent: true);
      }

      // Visual: Foam (pool)
      if (hasFoam) {
        add('909600', reason: 'Foam visible', urgent: true);
        add('904162', reason: 'Clarifier for foam cause');
      }

      // Visual: Filter dirty (pool)
      if (filterDirty) {
        add('909340', reason: 'Filter dirty');
      }

      // Visual: Flush / Drain (pool)
      if (needsFlush) {
        add('909365', reason: 'Full drain/flush needed', urgent: true);
        add('903960', reason: 'Pre-filter for fresh fill');
      }

      // Last drain rules (pool)
      if (lastDrain == 'over_1yr') {
        if (!needsFlush) {
          add('909365', reason: 'Last drain >1yr — flush overdue', urgent: true);
          add('903960', reason: 'Pre-filter for fresh fill', urgent: true);
        }
        if (!filterDirty) {
          add('909340', reason: 'Deep clean after long cycle', urgent: true);
        }
      }

      // Scale buildup
      if (hasScale) {
        add('903319', reason: 'Scale deposits visible');
      }

      // High phosphate >500ppb → Prevent Algae 60%
      if (phosphate != null && phosphate > 500) {
        add('982163', reason: 'Phosphate ${phosphate.toInt()} ppb — very high', urgent: true);
      }

      // Salt system test strips — only when crate has other items
      if (sanitizerType == 'salt' && crate.isNotEmpty) {
        add('904720', reason: 'Salt system — monitor levels');
      }

      // First visit → Deluxe Opening Kit
      if (isFirstVisit) {
        add('902410', reason: 'First visit — deluxe opening/closing kit');
      }

      // Add test strips only when there are actual issues to address
      if (crate.isNotEmpty) {
        add('904705', reason: 'Test strips — between visits');
      }
    }

    // Dedup: same SKU → keep highest qty, merge reasons, propagate urgent
    final Map<String, Map<String, dynamic>> seen = {};
    for (final item in crate) {
      final sku = item['sku'] as String;
      if (seen.containsKey(sku)) {
        final existing = seen[sku]!;
        if ((item['qty'] as int) > (existing['qty'] as int)) {
          existing['qty'] = item['qty'];
        }
        if (item['urgent'] == true) existing['urgent'] = true;
        // Concatenate reasons so all triggers are visible in the UI
        final existingReason = existing['reason'] as String? ?? '';
        final newReason = item['reason'] as String? ?? '';
        if (newReason.isNotEmpty && !existingReason.contains(newReason)) {
          existing['reason'] = '$existingReason + $newReason';
        }
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

    // Sort: urgent items first
    final result = seen.values.toList()
      ..sort((a, b) {
        final aUrgent = a['urgent'] == true ? 0 : 1;
        final bUrgent = b['urgent'] == true ? 0 : 1;
        return aUrgent.compareTo(bUrgent);
      });

    // Cap at 10 items (highest-priority already sorted to front)
    return result.length > 10 ? result.sublist(0, 10) : result;
  }
}
