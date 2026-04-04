import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:retro_route/config/delivery_zones.dart';

class DeliveryZoneMapWidget extends StatefulWidget {
  /// Called when the user taps a zone card or the map polygon.
  final void Function(DeliveryZone zone)? onZoneSelect;

  /// Called when user taps anywhere on the map (provides position + detected zone).
  final void Function(LatLng position, DeliveryZone? zone)? onLocationSelect;

  /// Pre-selected zone id (from outside).
  final int? selectedZoneId;

  /// Whether to show the zone selector cards above the map.
  final bool showZoneSelector;

  /// Height of the map area.
  final double mapHeight;

  const DeliveryZoneMapWidget({
    super.key,
    this.onZoneSelect,
    this.onLocationSelect,
    this.selectedZoneId,
    this.showZoneSelector = true,
    this.mapHeight = 340,
  });

  @override
  State<DeliveryZoneMapWidget> createState() => _DeliveryZoneMapWidgetState();
}

class _DeliveryZoneMapWidgetState extends State<DeliveryZoneMapWidget> {
  final Completer<GoogleMapController> _mapController = Completer();

  DeliveryZone? _detectedZone;
  LatLng? _selectedPosition;
  bool _showInfoWindow = false;
  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};

  // Active zone = external prop OR internally detected
  int? get _activeZoneId => widget.selectedZoneId ?? _detectedZone?.id;

  @override
  void initState() {
    super.initState();
    _buildMapOverlays();
  }

  @override
  void didUpdateWidget(covariant DeliveryZoneMapWidget old) {
    super.didUpdateWidget(old);
    if (old.selectedZoneId != widget.selectedZoneId) {
      _buildMapOverlays();
    }
  }

  // ── Build polygons + city markers ──────────────────────────────────────
  void _buildMapOverlays() {
    final polygons = <Polygon>{};
    final markers = <Marker>{};

    for (final zone in deliveryZones) {
      final isActive = _activeZoneId == zone.id;
      final fillAlpha = isActive ? 0xCC : 0x66; // ~80% vs ~40%
      final strokeAlpha = isActive ? 0xFF : 0xCC;
      final fillColor = Color(
        (fillAlpha << 24) | (zone.color.value & 0x00FFFFFF),
      );
      final strokeColor = Color(
        (strokeAlpha << 24) | (zone.color.value & 0x00FFFFFF),
      );

      polygons.add(
        Polygon(
          polygonId: PolygonId('zone_${zone.id}'),
          points: zone.polygon,
          fillColor: fillColor,
          strokeColor: strokeColor,
          strokeWidth: isActive ? 3 : 2,
          consumeTapEvents: true,
          onTap: () => _handleZoneTap(zone),
        ),
      );

      // City dot markers
      for (final city in zone.cityMarkers) {
        markers.add(
          Marker(
            markerId: MarkerId('city_${city.name}'),
            position: city.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _colorToHue(zone.color),
            ),
            infoWindow: InfoWindow(title: city.name),
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
    }

    // Brockville Hub marker
    markers.add(
      Marker(
        markerId: const MarkerId('brockville_hub'),
        position: brockvilleHub,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(
          title: 'BROCKVILLE HUB',
          snippet: 'Delivery Hub',
        ),
        zIndex: 10,
      ),
    );

    // Selected user tap position
    if (_selectedPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected_pos'),
          position: _selectedPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          zIndex: 20,
        ),
      );
    }

    setState(() {
      _polygons = polygons;
      _markers = markers;
    });
  }

  // ── Hue helper (Google Maps uses 0-360 hue) ────────────────────────────
  double _colorToHue(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;
    final max = [r, g, b].reduce((a, c) => a > c ? a : c);
    final min = [r, g, b].reduce((a, c) => a < c ? a : c);
    if (max == min) return 0;
    double hue;
    final d = max - min;
    if (max == r) {
      hue = (g - b) / d + (g < b ? 6 : 0);
    } else if (max == g) {
      hue = (b - r) / d + 2;
    } else {
      hue = (r - g) / d + 4;
    }
    return (hue / 6) * 360;
  }

  // ── Map tap: detect zone, show info ───────────────────────────────────
  void _handleMapTap(LatLng position) {
    final zone = detectZone(position.latitude, position.longitude);
    setState(() {
      _selectedPosition = position;
      _detectedZone = zone;
      _showInfoWindow = true;
    });
    _buildMapOverlays();
    widget.onZoneSelect?.call(zone!);
    widget.onLocationSelect?.call(position, zone);
  }

  // ── Zone card / polygon tap: fit bounds ──────────────────────────────
  void _handleZoneTap(DeliveryZone zone) async {
    final controller = await _mapController.future;
    final bounds = _boundsFromPolygon(zone.polygon);
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    setState(() {
      _detectedZone = zone;
      _showInfoWindow = false;
    });
    _buildMapOverlays();
    widget.onZoneSelect?.call(zone);
  }

  LatLngBounds _boundsFromPolygon(List<LatLng> pts) {
    double minLat = pts[0].latitude, maxLat = pts[0].latitude;
    double minLng = pts[0].longitude, maxLng = pts[0].longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Zone selector cards ──────────────────────────────────────────
        if (widget.showZoneSelector) ...[
          SizedBox(
            height: 100.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: deliveryZones.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (context, i) => _ZoneCard(
                zone: deliveryZones[i],
                isActive: _activeZoneId == deliveryZones[i].id,
                onTap: () => _handleZoneTap(deliveryZones[i]),
              ),
            ),
          ),
          SizedBox(height: 12.h),
        ],

        // ── Google Map ───────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: SizedBox(
            height: widget.mapHeight.h,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: brockvilleHub,
                zoom: 8.8,
              ),
              onMapCreated: (c) => _mapController.complete(c),
              onTap: _handleMapTap,
              polygons: _polygons,
              markers: _markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              mapType: MapType.terrain,
            ),
          ),
        ),

        // ── Tap info window (shown below map) ────────────────────────────
        if (_showInfoWindow && _selectedPosition != null) ...[
          SizedBox(height: 10.h),
          _TapInfoBanner(
            zone: _detectedZone,
            onClose: () => setState(() => _showInfoWindow = false),
          ),
        ],

        // ── Zone info banner (after card / polygon tap) ──────────────────
        if (!_showInfoWindow && _detectedZone != null) ...[
          SizedBox(height: 12.h),
          _ZoneInfoBanner(zone: _detectedZone!),
        ],

        // ── Hint text ────────────────────────────────────────────────────
        if (_detectedZone == null && !_showInfoWindow) ...[
          SizedBox(height: 10.h),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 14.sp, color: Colors.grey[400]),
                SizedBox(width: 4.w),
                Text(
                  'Tap the map or select a zone to see delivery schedule',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Zone Selector Card ────────────────────────────────────────────────────
class _ZoneCard extends StatelessWidget {
  final DeliveryZone zone;
  final bool isActive;
  final VoidCallback onTap;

  const _ZoneCard({
    required this.zone,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160.w,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isActive
              ? zone.color.withOpacity(0.08)
              : Colors.white,
          border: Border.all(
            color: isActive ? zone.color : Colors.grey[200]!,
            width: isActive ? 2.2 : 1.2,
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: zone.color.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30.w,
                      height: 30.w,
                      decoration: BoxDecoration(
                        color: zone.color,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Z${zone.id}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        zone.name.split('—').last.trim(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.sp,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 11.sp, color: zone.color),
                    SizedBox(width: 3.w),
                    Text(
                      zone.deliveryDaysLabel,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: zone.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isActive)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    color: zone.color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 12.sp, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Tap info banner (outside / inside zone) ──────────────────────────────
class _TapInfoBanner extends StatelessWidget {
  final DeliveryZone? zone;
  final VoidCallback onClose;

  const _TapInfoBanner({required this.zone, required this.onClose});

  @override
  Widget build(BuildContext context) {
    if (zone == null) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.red[400], size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Outside delivery area. Please pick a location within Zone 1, 2 or 3.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: onClose,
              child: Icon(Icons.close, size: 18.sp, color: Colors.red[300]),
            ),
          ],
        ),
      );
    }

    final nextDate = getNextDeliveryDateFromDays(zone!.deliveryDays);
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: zone!.color.withOpacity(0.06),
        border: Border.all(color: zone!.color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: zone!.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone!.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                    color: zone!.color,
                  ),
                ),
                Text(
                  '📦 Delivery: ${zone!.deliveryDaysLabel}  •  📅 Next: ${formatDeliveryDate(nextDate)}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Icon(Icons.close, size: 18.sp, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// ── Full zone info banner (after zone card / polygon tap) ─────────────────
class _ZoneInfoBanner extends StatelessWidget {
  final DeliveryZone zone;
  const _ZoneInfoBanner({required this.zone});

  @override
  Widget build(BuildContext context) {
    final nextDate = getNextDeliveryDateFromDays(zone.deliveryDays);
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: zone.color.withOpacity(0.07),
        border: Border.all(color: zone.color.withOpacity(0.35), width: 1.5),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Container(
            width: 46.w,
            height: 46.w,
            decoration: BoxDecoration(
              color: zone.color,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.local_shipping, color: Colors.white, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Delivery every ${zone.deliveryDaysLabel}  ·  Cities: ${zone.cities.join(", ")}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Next: ${formatDeliveryDate(nextDate)}',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: zone.color,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              zone.deliveryDaysLabel,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
