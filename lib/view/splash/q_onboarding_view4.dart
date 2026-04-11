import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:retro_route/config/delivery_zones.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 5 (0-indexed: 4) — "Book My Stop"
// Mirrors web OnboardingScreen4Content closely.
// ─────────────────────────────────────────────────────────────────────────────
class BookMyStopContent extends StatefulWidget {
  final Map<String, dynamic>? routeInfo;
  final Future<void> Function(Map<String, dynamic>) onBringSupplies;
  final Future<void> Function(Map<String, dynamic>) onWaterTestFirst;
  final VoidCallback onBack;
  final ValueChanged<Map<String, dynamic>>? onRouteChanged;

  const BookMyStopContent({
    required this.onBringSupplies,
    required this.onWaterTestFirst,
    required this.onBack,
    this.routeInfo,
    this.onRouteChanged,
    super.key,
  });

  @override
  State<BookMyStopContent> createState() => _BookMyStopContentState();
}

class _BookMyStopContentState extends State<BookMyStopContent> {
  String? _stopType; // 'supplies' | 'waterTest'
  String? _waterTestChoice; // 'yes' | 'no'

  // ── Address input state ─────────────────────────────────────────────────
  bool _showAddressInput = false;
  bool _isSearching = false;
  final TextEditingController _addressCtrl = TextEditingController();
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB_8gavyfzAIRyMl4eD18iGe_s27fjBSDo',
  );
  Timer? _debounce;
  List<Map<String, dynamic>> _placeSuggestions = [];
  bool _showPlaceSuggestions = false;
  bool _isSelectingSuggestion = false;

  String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Google Places autocomplete ──────────────────────────────────────────
  void _onAddressChanged(String value) {
    if (_isSelectingSuggestion) return;
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _placeSuggestions = [];
        _showPlaceSuggestions = false;
      });
      return;
    }
    setState(() {}); // refresh clear icon visibility
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchPlaceSuggestions(value.trim());
    });
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&types=address'
        '&components=country:ca'
        '&language=en'
        '&key=$_googleMapsApiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200 || !mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final predictions = (body['predictions'] as List?) ?? const [];
      final suggestions = predictions.map<Map<String, dynamic>>((item) {
        final p = (item as Map).cast<String, dynamic>();
        return {
          'placeId': p['place_id'] as String? ?? '',
          'description': p['description'] as String? ?? '',
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        _placeSuggestions = suggestions;
        _showPlaceSuggestions = suggestions.isNotEmpty;
      });
    } catch (_) {}
  }

  Future<void> _selectPlaceSuggestion(Map<String, dynamic> suggestion) async {
    _isSelectingSuggestion = true;
    final placeId = suggestion['placeId'] as String;
    final description = suggestion['description'] as String;
    setState(() {
      _addressCtrl.text = description;
      _placeSuggestions = [];
      _showPlaceSuggestions = false;
      _isSearching = true;
    });
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?place_id=${Uri.encodeComponent(placeId)}'
        '&key=$_googleMapsApiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (body['results'] as List?) ?? [];
        if (results.isNotEmpty) {
          final firstResult = (results[0] as Map).cast<String, dynamic>();
          final components =
              (firstResult['address_components'] as List?) ?? [];
          // Extract lat/lng from geometry
          final geometry = firstResult['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;
          final double? lat = (location?['lat'] as num?)?.toDouble();
          final double? lng = (location?['lng'] as num?)?.toDouble();

          String streetNumber = '';
          String route = '';
          String city = '';
          String postal = '';
          for (final c in components) {
            final types = ((c as Map)['types'] as List?) ?? [];
            final longName = (c['long_name'] as String?) ?? '';
            if (types.contains('street_number')) {
              streetNumber = longName;
            } else if (types.contains('route')) {
              route = longName;
            } else if (types.contains('locality')) {
              city = longName;
            } else if (types.contains('sublocality_level_1') &&
                city.isEmpty) {
              city = longName;
            } else if (types.contains('postal_code')) {
              postal = longName;
            }
          }
          final streetLine = [streetNumber, route]
              .where((p) => p.trim().isNotEmpty)
              .join(' ')
              .trim();

          // Try zone detection by coordinates first, then fall back to city name
          DeliveryZone? zone;
          if (lat != null && lng != null) {
            zone = detectZone(lat, lng);
          }
          zone ??= city.isNotEmpty ? detectZoneByCity(city) : null;

          if (zone != null) {
              final addressLine = streetLine.isNotEmpty
                  ? streetLine
                  : description.split(',').first.trim();
              final fullAddress =
                  '$addressLine, $city${postal.isNotEmpty ? ' $postal' : ''}';
              final nextDate =
                  getNextDeliveryDateFromDays(zone.deliveryDays);
              if (mounted) {
                setState(() {
                  _showAddressInput = false;
                  _addressCtrl.clear();
                  _isSearching = false;
                });
                widget.onRouteChanged?.call({
                  'zone': zone,
                  'address': fullAddress,
                  'nextDate': nextDate,
                });
              }
              _isSelectingSuggestion = false;
              CustomToast.success(msg: 'Address updated');
              return;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isSearching = false);
    _isSelectingSuggestion = false;
    CustomToast.error(
        msg:
            'Your city is not in the delivery zone. We are working on it, but for now, please visit www.retrorouteco.com to place an order, and we will ship it to you.');
  }

  void _handleAddressSearch() {
    final input = _addressCtrl.text.trim();
    if (input.isEmpty) return;
    setState(() => _isSearching = true);
    final zone = detectZoneByCity(input);
    if (zone != null) {
      final nextDate = getNextDeliveryDateFromDays(zone.deliveryDays);
      setState(() {
        _showAddressInput = false;
        _addressCtrl.clear();
        _isSearching = false;
      });
      widget.onRouteChanged?.call({
        'zone': zone,
        'address': input,
        'nextDate': nextDate,
      });
      CustomToast.success(msg: 'Found your route');
    } else {
      setState(() => _isSearching = false);
      CustomToast.error(
          msg:
              'Your city is not in the delivery zone. We are working on it, but for now, please visit www.retrorouteco.com to place an order, and we will ship it to you.');
    }
  }

  Future<void> _handleUseMyLocation() async {
    setState(() => _isSearching = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        CustomToast.error(msg: 'Please enable location services');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        CustomToast.error(msg: 'Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 10));
      final zone = detectZone(pos.latitude, pos.longitude);
      if (zone != null) {
        final geo = await _reverseGeocode(pos.latitude, pos.longitude);
        final city = geo['city']?.isNotEmpty == true
            ? geo['city']!
            : zone.cities.first;
        final street = geo['street'] ?? '';
        final postal = geo['postal'] ?? '';
        final addressLine = street.isNotEmpty
            ? '$street, $city${postal.isNotEmpty ? ' $postal' : ''}'
            : city;
        final nextDate = getNextDeliveryDateFromDays(zone.deliveryDays);
        setState(() {
          _showAddressInput = false;
          _addressCtrl.clear();
          _placeSuggestions = [];
          _showPlaceSuggestions = false;
        });
        widget.onRouteChanged?.call({
          'zone': zone,
          'address': addressLine,
          'nextDate': nextDate,
        });
        CustomToast.success(msg: 'Found your route');
      } else {
        CustomToast.error(
            msg:
                'Your city is not in the delivery zone. We are working on it, but for now, please visit www.retrorouteco.com to place an order, and we will ship it to you.');
      }
    } catch (_) {
      CustomToast.error(msg: 'Unable to get your location.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<Map<String, String>> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&key=$_googleMapsApiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return {};
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (body['results'] as List?) ?? [];
      if (results.isEmpty) return {};
      final components =
          (results[0]['address_components'] as List?) ?? [];
      String street = '';
      String city = '';
      String postal = '';
      String streetNumber = '';
      String route = '';
      for (final c in components) {
        final types = ((c as Map)['types'] as List?) ?? [];
        final longName = (c['long_name'] as String?) ?? '';
        if (types.contains('street_number')) {
          streetNumber = longName;
        } else if (types.contains('route')) {
          route = longName;
        } else if (types.contains('locality')) {
          city = longName;
        } else if (types.contains('sublocality_level_1') && city.isEmpty) {
          city = longName;
        } else if (types.contains('postal_code')) {
          postal = longName;
        }
      }
      street = [streetNumber, route]
          .where((p) => p.trim().isNotEmpty)
          .join(' ')
          .trim();
      return {'city': city, 'street': street, 'postal': postal};
    } catch (_) {
      return {};
    }
  }

  void _select(String type) {
    setState(() {
      _stopType = type;
      if (type != 'supplies') {
        _waterTestChoice = null;
      }
    });
  }

  bool get _canContinue {
    if (_stopType == null) return false;
    if (_stopType == 'supplies' && _waterTestChoice == null) return false;
    return true;
  }

  bool _isProcessing = false;

  Future<void> _handleContinue() async {
    if (!_canContinue || _isProcessing) return;
    setState(() => _isProcessing = true);
    final routeData = widget.routeInfo;
    try {
      if (_stopType == 'supplies') {
        if (_waterTestChoice == 'yes') {
          await widget.onWaterTestFirst({
            'stopType': 'supplies',
            'route': routeData,
            'redirectTo': '/',
          });
        } else {
          await widget.onBringSupplies({
            'stopType': 'supplies',
            'route': routeData,
          });
        }
        return;
      }
      await widget.onWaterTestFirst({
        'stopType': 'waterTest',
        'route': routeData,
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _fmtDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${wd[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}';
  }

  // ── Address input widget (same style as water_test_popup) ─────────────
  Widget _buildAddressInputWidget() {
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Street Address',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                SizedBox(width: 10.w),
                Icon(Icons.location_on,
                    size: 18.sp, color: Colors.red.shade400),
                SizedBox(width: 6.w),
                Expanded(
                  child: TextField(
                    controller: _addressCtrl,
                    autofocus: false,
                    onChanged: _onAddressChanged,
                    onSubmitted: (_) => _handleAddressSearch(),
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: Colors.grey.shade900),
                    decoration: InputDecoration(
                      hintText: 'Enter street address or city',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 14.sp, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                if (_showPlaceSuggestions)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _placeSuggestions = [];
                        _showPlaceSuggestions = false;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Icon(Icons.close_rounded,
                          size: 18.sp, color: Colors.grey.shade500),
                    ),
                  ),
                TextButton(
                  onPressed: _isSearching ? null : _handleAddressSearch,
                  child: Text(
                    _isSearching ? '...' : 'Search',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.btnColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Suggestions dropdown
          if (_showPlaceSuggestions && _placeSuggestions.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 4.h),
              constraints: BoxConstraints(maxHeight: 200.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _placeSuggestions.length,
                itemBuilder: (_, i) {
                  final s = _placeSuggestions[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.location_on_outlined,
                        size: 16.sp, color: AppColors.primary),
                    title: Text(
                      s['description'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectPlaceSuggestion(s),
                  );
                },
              ),
            ),
          SizedBox(height: 6.h),
          // Use my location button
          GestureDetector(
            onTap: _isSearching ? null : _handleUseMyLocation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.my_location,
                      size: 14.sp, color: AppColors.primary),
                  SizedBox(width: 4.w),
                  Text(
                    'Use my location',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zone = widget.routeInfo?['zone'];
    final nextDate = widget.routeInfo?['nextDate'] as DateTime?;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + subtitle
                Center(
                  child: Text(
                    'Book my stop',
                    style: GoogleFonts.inter(
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900),
                  ),
                ),
                SizedBox(height: 4.h),
                Center(
                  child: Text(
                    "Choose what we're doing on this stop, then confirm where to leave your order.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.grey.shade700,
                        height: 1.4),
                  ),
                ),
                SizedBox(height: 16.h),

                // ── Milk run summary card ──────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                    ],
                    color: Colors.white,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 112.h,
                        width: double.infinity,
                        child: Image.asset('assets/images/retro.jpeg', fit: BoxFit.cover),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Your Milk Run',
                                        style: GoogleFonts.inter(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey.shade900)),
                                    Text(
                                      zone != null
                                          ? 'Every ${(zone as dynamic).deliveryDaysLabel}'
                                          : 'Select a zone',
                                      style: GoogleFonts.inter(
                                          fontSize: 14.sp, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('You Have Chosen',
                                        style: GoogleFonts.inter(
                                            fontSize: 14.sp, color: Colors.grey.shade400)),
                                    Text(
                                      nextDate != null ? _fmtDate(nextDate) : 'Next run',
                                      style: GoogleFonts.inter(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade900),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Row(
                              children: [
                                Icon(Icons.local_shipping_outlined,
                                    size: 14.sp, color: AppColors.primary),
                                SizedBox(width: 4.w),
                                Text(
                                  zone != null ? 'Zone ${(zone as dynamic).id}' : 'Zone information',
                                  style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade900),
                                ),
                              ],
                            ),

                            if (widget.routeInfo?['address'] != null) ...[
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 13.sp, color: Colors.grey.shade500),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      '${widget.routeInfo!['address']}',
                                      style: GoogleFonts.inter(
                                          fontSize: 13.sp, color: Colors.grey.shade600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Text('What are we doing on this stop?',
                    style: GoogleFonts.inter(
                  fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade900)),
                SizedBox(height: 12.h),

                // Card 1 – Bring Supplies
                _buildStopTypeCard(
                  id: 'supplies',
                  badge: 'Most Common',
                  badgeStyle: _BadgeStyle.gray,
                  title: 'Bring supplies',
                  desc: 'You already know what you need — build your crate now.',
                  bullets: [],
                  emoji: '🧺',
                  ctaLabel: 'Select this option',
                  showSuppliesInfo: true,
                ),
                SizedBox(height: 10.h),

                // Card 2 – Water Test First
                _buildStopTypeCard(
                  id: 'waterTest',
                  badge: 'Recommended',
                  badgeStyle: _BadgeStyle.blue,
                  title: 'Water Test First',
                  desc: 'Not sure what to buy? We test first, then recommend exactly what you need.',
                  bullets: [
                    'We test your water and upload results',
                    'The app builds a Recommended Crate',
                    'You approve with one tap',
                  ],
                  emoji: '',
                  ctaLabel: 'Select this option',
                  showFeeNote: true,
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),

        // ── Bottom bar: Back + CTA ─────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
                  child: Text(
                    'Back',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: (_canContinue && !_isProcessing) ? _handleContinue : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      color: _canContinue ? null : const Color(0xFFFB923C).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: _canContinue
                          ? [const BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))]
                          : [],
                    ),
                    foregroundDecoration: (!_canContinue || _isProcessing)
                        ? BoxDecoration(
                            color: Colors.white.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(12.r),
                          )
                        : null,
                    child: _isProcessing
                        ? Center(
                            child: SizedBox(
                              height: 20.h,
                              width: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _stopType == 'waterTest'
                                ? 'Book Water Test First'
                                : 'Continue → Build my crate',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStopTypeCard({
    required String id,
    required String badge,
    required _BadgeStyle badgeStyle,
    required String title,
    required String desc,
    required List<String> bullets,
    required String emoji,
    required String ctaLabel,
    bool showFeeNote = false,
    bool showSuppliesInfo = false,
  }) {
    final selected = _stopType == id;
    return GestureDetector(
      onTap: () => _select(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? const Color.fromARGB(255, 239, 254, 255) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _badge(badge, badgeStyle),
                      const Spacer(),
                      // Checkmark circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 20.w,
                        height: 20.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? Colors.grey.shade500 : Colors.grey.shade300,
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: 13.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(title, style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade900)),
                  SizedBox(height: 4.h),
                  Text(desc, style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade900, height: 1.4)),
                  if (showSuppliesInfo) ...[
                    SizedBox(height: 8.h),
                    _buildSuppliesInfoBox(),
                  ],
                  if (bullets.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text('How Water Test First works',
                        style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade900)),
                    SizedBox(height: 4.h),
                    ...bullets.map((b) => Padding(
                      padding: EdgeInsets.only(bottom: 3.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade900)),
                          Expanded(child: Text(b, style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade900, height: 1.4))),
                        ],
                      ),
                    )),
                  ],
                  if (showFeeNote) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade900, fontWeight: FontWeight.w700),
                              children: const [
                                TextSpan(text: 'Visit fee today '),
                                TextSpan(text: r'$39', style: TextStyle(color: Color(0xFF0369a1), fontWeight: FontWeight.w900)),
                                TextSpan(text: ' → 100% credit after the test'),
                              ],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text('There is a visit fee but 100% becomes a credit on your account toward any supplies you purchase after your test.',
                              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade900, height: 1.4)),
                          SizedBox(height: 4.h),
                          Text(r'100% of your $39 visit fee comes back as credit on any supplies you purchase after your test.',
                              style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade900, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                  if (emoji.isNotEmpty)
                    Center(
                      child: Text(emoji, style: TextStyle(fontSize: 40.sp)),
                    ),
                ],
              ),
            ),
            // CTA strip at bottom of card
            GestureDetector(
              onTap: () {
                _select(id);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                color: selected ? Colors.grey.shade500 : AppColors.btnColor,
                child: Text(
                  ctaLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (id == 'supplies' && _stopType == 'supplies') ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                color: selected ? const Color(0xFFeff6ff) : Colors.white,
                child: _buildSuppliesWaterChoice(inCard: true),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, _BadgeStyle style) {
    final bg = style == _BadgeStyle.blue ? const Color(0xFFe0f2fe) : Colors.grey.shade200;
    final fg = style == _BadgeStyle.blue ? const Color(0xFF0369a1) : Colors.grey.shade900;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20.r)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.5)),
    );
  }

  Widget _buildSuppliesInfoBox() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💧 Water Test!',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0369A1),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Your can also request a free water test during you visit',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
         
           ],
      ),
    );
  }

  Widget _buildSuppliesWaterChoice({bool inCard = false}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 239, 254, 255),
        border: inCard ? null : Border.all(color: const Color(0xFFBAE6FD)),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey.shade900,
                height: 1.35,
              ),
              children: const [
                TextSpan(text: 'As you click "'),
                TextSpan(
                  text: 'Yes',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      '", the water test will be automatically added to your cart. Please proceed by creating your crate and on the checkout page you will be able to see the water test.',
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _waterTestChoice = 'yes'),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      gradient: _waterTestChoice == 'yes'
                          ? const LinearGradient(
                              colors: [Color(0xFFFB923C), Color(0xFFF97316)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: _waterTestChoice == 'yes' ? null : Colors.white,
                      border: Border.all(
                        color: _waterTestChoice == 'yes'
                            ? Colors.transparent
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      'Yes, add water test',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: _waterTestChoice == 'yes'
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _waterTestChoice = 'no'),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: _waterTestChoice == 'no'
                          ? Colors.grey.shade600
                          : Colors.white,
                      border: Border.all(
                        color: _waterTestChoice == 'no'
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      'No Thanks',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: _waterTestChoice == 'no'
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_waterTestChoice == 'yes') ...[
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFFBBF7D0)),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'The water test has been added to your cart. Please proceed by creating your supplies crate.',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: const Color(0xFF166534),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}

enum _BadgeStyle { gray, blue }
