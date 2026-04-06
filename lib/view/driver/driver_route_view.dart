import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/model/driver_delivery_model.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/driver_constants.dart';
import 'package:retro_route/view/driver/widgets/driver_widgets.dart';
import 'package:retro_route/view_model/driver_view_model/driver_view_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverRouteScreen extends ConsumerStatefulWidget {
  const DriverRouteScreen({super.key});

  @override
  ConsumerState<DriverRouteScreen> createState() => _DriverRouteScreenState();
}

class _DriverRouteScreenState extends ConsumerState<DriverRouteScreen> {
  @override
  void initState() {
    super.initState();
    // Update driver location for nearest-first sorting
    Future.microtask(() {
      ref.read(driverDeliveriesProvider.notifier).updateDriverLocation();
    });
  }

  Future<void> _openGoogleMaps(List<DriverDelivery> orders) async {
    if (orders.isEmpty) return;

    // Use GPS coordinates when available, otherwise fall back to text address
    final stops = <String>[];
    for (final o in orders) {
      final lat = o.deliveryAddress?.deliveryLat;
      final lon = o.deliveryAddress?.deliveryLon;
      if (lat != null && lon != null) {
        stops.add('$lat,$lon');
      } else {
        final addr = o.deliveryAddress?.fullAddress;
        if (addr != null && addr.isNotEmpty) {
          stops.add(Uri.encodeComponent(addr));
        }
      }
    }
    if (stops.isEmpty) return;

    // Always fetch driver's current GPS position before opening maps
    double? driverLat;
    double? driverLon;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        driverLat = pos.latitude;
        driverLon = pos.longitude;
      }
    } catch (_) {}

    final destination = stops.last;
    final String origin;
    final List<String> waypointList;

    if (driverLat != null && driverLon != null) {
      // Start from driver's live location
      origin = '$driverLat,$driverLon';
      // All delivery stops are waypoints except the last (destination)
      waypointList = stops.length > 1
          ? stops.sublist(0, stops.length - 1)
          : [];
    } else {
      origin = stops.first;
      waypointList = stops.length > 2
          ? stops.sublist(1, stops.length - 1)
          : [];
    }

    final waypoints = waypointList.join('|');

    String url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '&travelmode=driving';
    if (waypoints.isNotEmpty) url += '&waypoints=$waypoints';

    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback: open in browser
      await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication)
          .catchError((_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverState = ref.watch(driverDeliveriesProvider);
    final orders = driverState.filteredActiveDeliveries;

    return Scaffold(
      backgroundColor: DriverColors.bg,
      body: Column(children: [
        DriverHeader(
          title: 'Optimized route',
          subtitle: "Today's stops in order",
          bgColor: DriverColors.orange,
          onBack: () => context.pop(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(children: [
              // Map card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                    color: DriverColors.navy,
                    borderRadius: BorderRadius.circular(16.r)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.location_on,
                            color: DriverColors.orange, size: 18.sp),
                        SizedBox(width: 6.w),
                        Text('Brockville, Ontario',
                            style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ]),
                      SizedBox(height: 4.h),
                      Text(
                          '${orders.length} stops · optimized for shortest distance',
                          style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.white54,
                              fontWeight: FontWeight.w500)),
                      SizedBox(height: 14.h),
                      GestureDetector(
                        onTap: () => _openGoogleMaps(orders),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 10.h),
                          decoration: BoxDecoration(
                              color: DriverColors.orange,
                              borderRadius: BorderRadius.circular(10.r)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.map, color: Colors.white, size: 16.sp),
                            SizedBox(width: 6.w),
                            Text('Open in Google Maps ↗',
                                style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ]),
                        ),
                      ),
                    ]),
              ),
              SizedBox(height: 12.h),

              // Stop list
              Container(
                decoration: BoxDecoration(
                    color: DriverColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 8)
                    ]),
                child: Column(children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
                    child: Row(children: [
                      Text('STOP SEQUENCE',
                          style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: DriverColors.textHint,
                              letterSpacing: 0.8)),
                      const Spacer(),
                      Text('${orders.length} total',
                          style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: DriverColors.textMuted)),
                    ]),
                  ),
                  Divider(height: 1, color: DriverColors.bg),
                  ...orders.asMap().entries.map((e) {
                    final i = e.key;
                    final o = e.value;
                    return GestureDetector(
                      onTap: () {
                        context.push(AppRoutes.driverOrderDetail, extra: o);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: i < orders.length - 1
                                      ? DriverColors.bg
                                      : Colors.transparent)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 28.w,
                            height: 28.w,
                            decoration: BoxDecoration(
                              color: DriverColors.greenLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                                child: Text('${i + 1}',
                                    style: GoogleFonts.inter(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w800,
                                        color: DriverColors.green))),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.safeCustomerName,
                                  style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      color: DriverColors.text)),
                              Text(
                                  o.deliveryAddress?.fullAddress ?? 'No address',
                                  style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      color: DriverColors.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              if ((o.deliveryZone ?? '').isNotEmpty ||
                                  (o.deliveryDay ?? '').isNotEmpty)
                                Text(
                                  [
                                    if ((o.deliveryZone ?? '').isNotEmpty)
                                      o.deliveryZone!,
                                    if ((o.deliveryDay ?? '').isNotEmpty)
                                      o.deliveryDay!,
                                  ].join(' · '),
                                  style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: DriverColors.orange),
                                )
                              else
                                Text('Crate delivery',
                                  style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                      color: DriverColors.textHint)),
                            ],
                          )),
                          Text(o.formattedTotal,
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w900,
                                  color: DriverColors.orange)),
                        ]),
                      ),
                    );
                  }),
                ]),
              ),
              SizedBox(height: 16.h),
              if (orders.isNotEmpty)
                DriverOrangeButton(
                  text:
                      'Start Stop 1 — ${orders.first.safeCustomerName} →',
                  onPressed: () {
                    context.push(AppRoutes.driverOrderDetail,
                        extra: orders.first);
                  },
                ),
              SizedBox(height: 20.h),
            ]),
          ),
        ),
      ]),
    );
  }
}
