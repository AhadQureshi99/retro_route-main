import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/model/driver_delivery_model.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/driver_constants.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/driver_view_model/driver_view_model.dart';
import 'package:retro_route/view/driver/driver_sod_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(driverDeliveriesProvider.notifier).switchTab(
              _tabController.index == 0 ? 'active' : 'completed',
            );
      }
    });

    // Fetch data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
      _checkSodStatus();
    });
  }

  Future<void> _checkSodStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final sodDate = prefs.getString('sod_date') ?? '';
    if (sodDate != today && mounted) {
      // SOD not done for today — show SOD screen
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DriverSodScreen()),
      );
    }
  }

  void _fetchData() {
    final token = ref.read(authNotifierProvider).value?.data?.token ?? '';
    if (token.isNotEmpty) {
      // Update driver location first so deliveries are sorted nearest-first
      ref.read(driverDeliveriesProvider.notifier).updateDriverLocation().then((_) {
        ref.read(driverDeliveriesProvider.notifier).fetchAllData(token);
      });
    }
  }

  /// Opens Google Maps with all active delivery locations as waypoints,
  /// sorted nearest-first from the driver's current GPS position.
  Future<void> _openRouteInMaps() async {
    final activeDeliveries =
        ref.read(driverDeliveriesProvider).filteredActiveDeliveries;

    if (activeDeliveries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No active deliveries.')),
        );
      }
      return;
    }

    // Get driver's current location
    Position? currentPos;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }
      currentPos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      // If location fails, just use the stops in original order
    }

    // Only use stops that have valid GPS coordinates
    final stops = <String>[];
    final deliveriesWithStops = <MapEntry<DriverDelivery, String>>[];

    for (final d in activeDeliveries) {
      final lat = d.deliveryAddress?.deliveryLat;
      final lon = d.deliveryAddress?.deliveryLon;
      if (lat != null && lon != null) {
        deliveriesWithStops.add(MapEntry(d, '$lat,$lon'));
      }
    }

    if (deliveriesWithStops.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No active deliveries with location data.')),
        );
      }
      return;
    }

    // Sort stops by distance from driver (nearest first) if we have location
    if (currentPos != null) {
      deliveriesWithStops.sort((a, b) {
        final aLat = a.key.deliveryAddress?.deliveryLat;
        final aLon = a.key.deliveryAddress?.deliveryLon;
        final bLat = b.key.deliveryAddress?.deliveryLat;
        final bLon = b.key.deliveryAddress?.deliveryLon;

        // Orders without coordinates go to the end
        if (aLat == null || aLon == null) return 1;
        if (bLat == null || bLon == null) return -1;

        final distA = _haversine(
          currentPos!.latitude, currentPos.longitude, aLat, aLon,
        );
        final distB = _haversine(
          currentPos.latitude, currentPos.longitude, bLat, bLon,
        );
        return distA.compareTo(distB);
      });
    }

    // Extract sorted stop strings
    for (final entry in deliveriesWithStops) {
      stops.add(entry.value);
    }

    // Build Google Maps directions URL (web format — works on all devices)
    final String origin = currentPos != null
        ? '${currentPos.latitude},${currentPos.longitude}'
        : stops.first;

    final destination = stops.last;
    final waypointList = currentPos != null
        ? stops.sublist(0, stops.length - 1)
        : (stops.length > 2 ? stops.sublist(1, stops.length - 1) : <String>[]);

    final waypointsParam = waypointList.join('|');

    String url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '&travelmode=driving';
    if (waypointsParam.isNotEmpty) url += '&waypoints=$waypointsParam';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    }
  }

  /// Haversine distance in km between two lat/lon points.
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final driverState = ref.watch(driverDeliveriesProvider);
    final user = authState.value?.data?.user;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            customText(
              text: 'Hello, ${user?.name ?? 'Driver'}',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            customText(
              text: 'Manage your deliveries',
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.white70,
            ),
          ],
        ),
        actions: const [],
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          final active = ref
              .watch(driverDeliveriesProvider)
              .filteredActiveDeliveries
              .where((d) =>
                  d.deliveryAddress?.deliveryLat != null &&
                  d.deliveryAddress?.deliveryLon != null)
              .toList();
          if (active.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: _openRouteInMaps,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: CircleBorder(),
            child: Transform.rotate(
              angle:0.9 ,
              child: const Icon(Icons.navigation_rounded)),
            
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stats Card
            _buildStatsCard(driverState.stats),

            // Quick Actions
            _buildQuickActions(),
        
            // Date Filter
            _buildDateFilter(driverState),
        
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(
                    text:
                        'Active (${driverState.filteredActiveDeliveries.length})',
                  ),
                  Tab(
                    text:
                        'Completed (${driverState.filteredCompletedDeliveries.length})',
                  ),
                ],
              ),
            ),
        
            // Tab Views
            Expanded(
              child: driverState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDeliveryList(
                          driverState.filteredActiveDeliveries,
                          isActive: true,
                        ),
                        _buildDeliveryList(
                          driverState.filteredCompletedDeliveries,
                          isActive: false,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(DriverStats? stats) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Today',
            '${stats?.todayDeliveries ?? 0}',
            Icons.today,
          ),
          _buildStatItem(
            'Pending',
            '${stats?.pendingDeliveries ?? 0}',
            Icons.pending_actions,
          ),
          _buildStatItem(
            'On Way',
            '${stats?.onMyWayDeliveries ?? 0}',
            Icons.local_shipping,
          ),
          _buildStatItem(
            'Completed',
            '${stats?.completedDeliveries ?? 0}',
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24.sp),
        verticalSpacer(height: 4),
        customText(
          text: value,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        customText(
          text: label,
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.white70,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(children: [
        _quickAction(
          icon: Icons.route,
          label: 'Route',
          color: DriverColors.orange,
          onTap: () => goRouter.push(AppRoutes.driverRoute),
        ),
        SizedBox(width: 8.w),
        _quickAction(
          icon: Icons.nightlight_round,
          label: 'EOD Report',
          color: DriverColors.navy,
          onTap: () => goRouter.push(AppRoutes.driverEod),
        ),
      ]),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18.sp),
              SizedBox(width: 8.w),
              Text(label,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilter(DriverDeliveriesState state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 18.sp, color: AppColors.primary),
                    horizontalSpacer(width: 8),
                    Expanded(
                      child: customText(
                        text: state.dateFilter != null
                            ? DateFormat('MMM dd, yyyy')
                                .format(state.dateFilter!)
                            : 'Filter by date',
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: state.dateFilter != null
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                    if (state.dateFilter != null)
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(driverDeliveriesProvider.notifier)
                              .clearDateFilter();
                        },
                        child: Icon(Icons.close,
                            size: 18.sp, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ),
          ),
          horizontalSpacer(width: 8),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _fetchData,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          ref.read(driverDeliveriesProvider).dateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(driverDeliveriesProvider.notifier).setDateFilter(picked);
    }
  }

  Widget _buildDeliveryList(List<DriverDelivery> deliveries,
      {required bool isActive}) {
    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.local_shipping_outlined : Icons.check_circle_outline,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            verticalSpacer(height: 16),
            customText(
              text: isActive ? 'No active deliveries' : 'No completed deliveries',
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.grey[600]!,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchData(),
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final delivery = deliveries[index];
          return _buildDeliveryCard(delivery, isActive: isActive);
        },
      ),
    );
  }

  Widget _buildDeliveryCard(DriverDelivery delivery, {required bool isActive}) {
    final statusColor = _getStatusColor(delivery.deliveryStatus);
    final isOnMyWay = delivery.deliveryStatus?.toLowerCase() == 'on my way';

    return GestureDetector(
      onTap: () {
        goRouter.push(AppRoutes.driverOrderDetail, extra: delivery);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: isOnMyWay
              ? Border.all(color: Colors.blue.shade400, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: isOnMyWay
                  ? Colors.blue.withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isOnMyWay ? 14 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: statusColor, size: 20.sp),
                      horizontalSpacer(width: 8),
                      customText(
                        text: delivery.safeOrderId,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: customText(
                      text: delivery.safeDeliveryStatus,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                children: [
                  // Customer Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20.r,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child:
                            Icon(Icons.person, color: AppColors.primary, size: 20.sp),
                      ),
                      horizontalSpacer(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            customText(
                              text: delivery.safeCustomerName,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            customText(
                              text: delivery.safeCustomerEmail,
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey[600]!,
                            ),
                          ],
                        ),
                      ),
                      customText(
                        text: delivery.formattedTotal,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ],
                  ),

                  verticalSpacer(height: 12),

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 18.sp),
                      horizontalSpacer(width: 8),
                      Expanded(
                        child: customText(
                          text: delivery.deliveryAddress?.fullAddress ??
                              'No address assigned',
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey[700]!,
                          maxLine: 2,
                        ),
                      ),
                    ],
                  ),

                  verticalSpacer(height: 8),

                  // Scheduled Date
                  if (delivery.scheduledDeliveryDate != null)
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.orange, size: 18.sp),
                        horizontalSpacer(width: 8),
                        customText(
                          text:
                              'Scheduled: ${DateFormat('MMM dd, yyyy - hh:mm a').format(delivery.scheduledDeliveryDate!)}',
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey[600]!,
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Footer with items count
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12.r),
                  bottomRight: Radius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  customText(
                    text: '${delivery.products?.length ?? 0} item(s)',
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[600]!,
                  ),
                  Row(
                    children: [
                      customText(
                        text: 'View Details',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 12.sp, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'on my way':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
