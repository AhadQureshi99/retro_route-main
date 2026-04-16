import 'dart:io';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:retro_route/model/driver_delivery_model.dart';
import 'package:retro_route/model/water_test_result_model.dart';
import 'package:retro_route/repository/driver_repo.dart';
import 'package:retro_route/utils/driver_constants.dart';

// State class for driver deliveries
class DriverDeliveriesState {
  final bool isLoading;
  final List<DriverDelivery> activeDeliveries;
  final List<DriverDelivery> completedDeliveries;
  final DriverStats? stats;
  final String? error;
  final DateTime? dateFilter;
  final String currentTab; // 'active' or 'completed'
  final WaterTestResult? pendingWaterTest;
  final List<CrateItem> generatedCrate;
  final double? driverLat;
  final double? driverLon;

  DriverDeliveriesState({
    this.isLoading = false,
    this.activeDeliveries = const [],
    this.completedDeliveries = const [],
    this.stats,
    this.error,
    this.dateFilter,
    this.currentTab = 'active',
    this.pendingWaterTest,
    this.generatedCrate = const [],
    this.driverLat,
    this.driverLon,
  });

  DriverDeliveriesState copyWith({
    bool? isLoading,
    List<DriverDelivery>? activeDeliveries,
    List<DriverDelivery>? completedDeliveries,
    DriverStats? stats,
    String? error,
    DateTime? dateFilter,
    String? currentTab,
    bool clearDateFilter = false,
    WaterTestResult? pendingWaterTest,
    List<CrateItem>? generatedCrate,
    bool clearWaterTest = false,
    double? driverLat,
    double? driverLon,
  }) {
    return DriverDeliveriesState(
      isLoading: isLoading ?? this.isLoading,
      activeDeliveries: activeDeliveries ?? this.activeDeliveries,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      stats: stats ?? this.stats,
      error: error,
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
      currentTab: currentTab ?? this.currentTab,
      pendingWaterTest:
          clearWaterTest ? null : (pendingWaterTest ?? this.pendingWaterTest),
      generatedCrate: generatedCrate ?? this.generatedCrate,
      driverLat: driverLat ?? this.driverLat,
      driverLon: driverLon ?? this.driverLon,
    );
  }

  /// Haversine distance in km.
  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// Sort deliveries by nearest-neighbor greedy algorithm.
  /// Start from driver position, pick the closest delivery, then from that
  /// delivery pick the next closest, and so on.
  List<DriverDelivery> _sortByNearest(List<DriverDelivery> list) {
    if (driverLat == null || driverLon == null) return list;
    if (list.isEmpty) return list;

    final remaining = List<DriverDelivery>.from(list);
    final sorted = <DriverDelivery>[];
    double curLat = driverLat!;
    double curLon = driverLon!;

    while (remaining.isNotEmpty) {
      int nearestIdx = 0;
      double nearestDist = double.infinity;

      for (int i = 0; i < remaining.length; i++) {
        final lat = remaining[i].deliveryAddress?.deliveryLat;
        final lon = remaining[i].deliveryAddress?.deliveryLon;
        if (lat == null || lon == null) continue;
        final dist = _haversine(curLat, curLon, lat, lon);
        if (dist < nearestDist) {
          nearestDist = dist;
          nearestIdx = i;
        }
      }

      final next = remaining.removeAt(nearestIdx);
      sorted.add(next);

      // Move current position to this delivery's location
      final nextLat = next.deliveryAddress?.deliveryLat;
      final nextLon = next.deliveryAddress?.deliveryLon;
      if (nextLat != null && nextLon != null) {
        curLat = nextLat;
        curLon = nextLon;
      }
    }

    return sorted;
  }

  // Get filtered deliveries based on date, sorted by distance from driver
  List<DriverDelivery> get filteredActiveDeliveries {
    List<DriverDelivery> list;
    if (dateFilter == null) {
      list = activeDeliveries;
    } else {
      list = activeDeliveries.where((d) {
        if (d.scheduledDeliveryDate == null) return false;
        return _isSameDay(d.scheduledDeliveryDate!, dateFilter!);
      }).toList();
    }
    // Sort all active deliveries by distance from driver (nearest first)
    return _sortByDistanceFromDriver(list);
  }

  /// Sort deliveries by straight-line distance from driver's current position.
  List<DriverDelivery> _sortByDistanceFromDriver(List<DriverDelivery> list) {
    if (driverLat == null || driverLon == null) return list;
    if (list.isEmpty) return list;

    final sorted = List<DriverDelivery>.from(list);
    sorted.sort((a, b) {
      final aLat = a.deliveryAddress?.deliveryLat;
      final aLon = a.deliveryAddress?.deliveryLon;
      final bLat = b.deliveryAddress?.deliveryLat;
      final bLon = b.deliveryAddress?.deliveryLon;

      // Deliveries without coordinates go to the end
      if (aLat == null || aLon == null) return 1;
      if (bLat == null || bLon == null) return -1;

      final distA = _haversine(driverLat!, driverLon!, aLat, aLon);
      final distB = _haversine(driverLat!, driverLon!, bLat, bLon);
      return distA.compareTo(distB);
    });
    return sorted;
  }

  List<DriverDelivery> get filteredCompletedDeliveries {
    if (dateFilter == null) return completedDeliveries;
    return completedDeliveries.where((d) {
      if (d.deliveredAt == null && d.scheduledDeliveryDate == null) return false;
      final dateToCheck = d.deliveredAt ?? d.scheduledDeliveryDate!;
      return _isSameDay(dateToCheck, dateFilter!);
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Notifier
class DriverDeliveriesNotifier extends Notifier<DriverDeliveriesState> {
  @override
  DriverDeliveriesState build() => DriverDeliveriesState();

  /// Update the driver's current GPS position for nearest-first sorting.
  Future<void> updateDriverLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      state = state.copyWith(driverLat: pos.latitude, driverLon: pos.longitude);
    } catch (_) {
      // Location unavailable — keep existing order
    }
  }

  /// Fetch active deliveries (Pending + OnMyWay + water_tested)
  Future<void> fetchActiveDeliveries(String token) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(driverRepoProvider);
      
      // Fetch pending deliveries
      final pendingResponse = await repo.fetchMyDeliveries(
        token: token,
        status: 'Pending',
      );
      
      // Fetch on my way deliveries
      final onMyWayResponse = await repo.fetchMyDeliveries(
        token: token,
        status: 'On My Way',
      );

      // Fetch water_tested deliveries (awaiting customer crate approval)
      final waterTestedResponse = await repo.fetchMyDeliveries(
        token: token,
        status: 'water_tested',
      );

      final List<DriverDelivery> allActive = [
        ...(pendingResponse.data ?? <DriverDelivery>[]),
        ...(onMyWayResponse.data ?? <DriverDelivery>[]),
        ...(waterTestedResponse.data ?? <DriverDelivery>[]),
      ];

      state = state.copyWith(
        isLoading: false,
        activeDeliveries: allActive,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch completed deliveries
  Future<void> fetchCompletedDeliveries(String token) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(driverRepoProvider);
      final response = await repo.fetchMyDeliveries(
        token: token,
        status: 'Delivered',
      );

      state = state.copyWith(
        isLoading: false,
        completedDeliveries: response.data ?? [],
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch all deliveries and stats
  Future<void> fetchAllData(String token) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(driverRepoProvider);

      // Fetch all data in parallel
      // Active deliveries (Pending/On My Way) fetched WITHOUT date filter
      // so driver sees ALL assigned orders regardless of scheduled date.
      // Completed fetched without date filter so all delivered orders show.
      // Stats filtered to today only for the summary cards.
      final today = DateTime.now();
      final results = await Future.wait([
        repo.fetchMyDeliveries(token: token, status: 'Pending'),
        repo.fetchMyDeliveries(token: token, status: 'On My Way'),
        repo.fetchMyDeliveries(token: token, status: 'water_tested'),
        repo.fetchMyDeliveries(token: token, status: 'Delivered'),
        repo.fetchDriverStats(token: token, dateFilter: today),
      ]);

      final pendingResponse = results[0] as DriverDeliveriesResponse;
      final onMyWayResponse = results[1] as DriverDeliveriesResponse;
      final waterTestedResponse = results[2] as DriverDeliveriesResponse;
      final deliveredResponse = results[3] as DriverDeliveriesResponse;
      final statsResponse = results[4] as DriverStatsResponse;

      final List<DriverDelivery> allActive = [
        ...(pendingResponse.data ?? <DriverDelivery>[]),
        ...(onMyWayResponse.data ?? <DriverDelivery>[]),
        ...(waterTestedResponse.data ?? <DriverDelivery>[]),
      ];

      state = state.copyWith(
        isLoading: false,
        activeDeliveries: allActive,
        completedDeliveries: deliveredResponse.data ?? <DriverDelivery>[],
        stats: statsResponse.data,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch driver stats
  Future<void> fetchStats(String token) async {
    try {
      final repo = ref.read(driverRepoProvider);
      final response = await repo.fetchDriverStats(token: token);

      state = state.copyWith(stats: response.data);
    } catch (e) {
      print("Failed to fetch stats: $e");
    }
  }

  /// Update delivery status
  Future<bool> updateDeliveryStatus({
    required String token,
    required String orderId,
    required String status,
    String? driverNotes,
    double? driverLat,
    double? driverLon,
  }) async {
    try {
      final repo = ref.read(driverRepoProvider);
      await repo.updateDeliveryStatus(
        token: token,
        orderId: orderId,
        status: status,
        driverNotes: driverNotes,
        driverLat: driverLat,
        driverLon: driverLon,
      );

      // Refresh data in background — don't block the caller
      fetchAllData(token);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update delivery status with proof image
  Future<bool> updateDeliveryStatusWithProof({
    required String token,
    required String orderId,
    required String status,
    String? driverNotes,
    required File deliveryProofImage,
  }) async {
    try {
      final repo = ref.read(driverRepoProvider);
      await repo.updateDeliveryStatusWithProof(
        token: token,
        orderId: orderId,
        status: status,
        driverNotes: driverNotes,
        deliveryProofImage: deliveryProofImage,
      );

      // Refresh data in background — don't block the caller
      fetchAllData(token);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Set date filter
  void setDateFilter(DateTime? date) {
    if (date == null) {
      state = state.copyWith(clearDateFilter: true);
    } else {
      state = state.copyWith(dateFilter: date);
    }
  }

  /// Clear date filter
  void clearDateFilter() {
    state = state.copyWith(clearDateFilter: true);
  }

  /// Switch tab
  void switchTab(String tab) {
    state = state.copyWith(currentTab: tab);
  }

  /// Set water test result and generate crate
  void setWaterTestResult(WaterTestResult wt) {
    final crateData = AutoCrateLogic.generateCrate(
      results: wt.asMap,
      poolType: wt.poolType,
      sanitizerType: wt.sanitizerType,
      volume: wt.volume,
      hasFoam: wt.hasFoam,
      isCloudy: wt.isCloudy,
      filterDirty: wt.filterDirty,
      needsFlush: wt.needsFlush,
      hasScale: wt.hasScale,
      hasAlgae: wt.hasAlgae,
      lastDrain: wt.lastDrain,
      isFirstVisit: wt.isFirstVisit,
    );
    final items = crateData.map((m) => CrateItem.fromMap(m)).toList();
    state = state.copyWith(pendingWaterTest: wt, generatedCrate: items);
  }

  /// Submit water test + crate to backend
  Future<bool> submitWaterTest({required String token}) async {
    final wt = state.pendingWaterTest;
    final crate = state.generatedCrate;
    if (wt == null) return false;
    try {
      final repo = ref.read(driverRepoProvider);
      await repo.saveWaterTest(
        token: token,
        waterTest: wt,
        crateItems: crate,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update crate item quantity (removes if qty <= 0)
  void updateCrateQty(int index, int newQty) {
    final crate = List<CrateItem>.from(state.generatedCrate);
    if (index < 0 || index >= crate.length) return;
    if (newQty <= 0) {
      crate.removeAt(index);
    } else {
      final old = crate[index];
      crate[index] = CrateItem(
        sku: old.sku,
        name: old.name,
        qty: newQty,
        price: old.price,
        reason: old.reason,
        urgent: old.urgent,
      );
    }
    state = state.copyWith(generatedCrate: crate);
  }

  /// Restore crate items from backend data (used when resuming after app restart)
  void restoreCrate(List<CrateItem> items) {
    state = state.copyWith(generatedCrate: items);
  }

  /// Clear water test and crate state
  void clearWaterTest() {
    state = state.copyWith(clearWaterTest: true, generatedCrate: []);
  }

  /// Reset all driver state (used on EOD/logout)
  void reset() {
    state = DriverDeliveriesState();
  }

  /// Submit end of day report
  Future<bool> submitEodReport({
    required String token,
    required EodReport report,
    File? odometerImage,
    File? sodOdometerImage,
  }) async {
    try {
      final repo = ref.read(driverRepoProvider);
      await repo.submitEodReport(
        token: token,
        report: report,
        odometerImage: odometerImage,
        sodOdometerImage: sodOdometerImage,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// Providers
final driverRepoProvider = Provider<DriverRepo>((ref) => DriverRepo());

final driverDeliveriesProvider =
    NotifierProvider<DriverDeliveriesNotifier, DriverDeliveriesState>(
  () => DriverDeliveriesNotifier(),
);
