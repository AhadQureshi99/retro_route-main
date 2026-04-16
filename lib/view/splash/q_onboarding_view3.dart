import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:retro_route/config/delivery_zones.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/view_model/address_view_model/address_view_model.dart';
import 'package:retro_route/view_model/address_view_model/selected_delivery_address_view_model.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/selected_delivery_date_provider.dart';

class FindMilkRunScreen extends ConsumerStatefulWidget {
  const FindMilkRunScreen({super.key});

  @override
  ConsumerState<FindMilkRunScreen> createState() => _FindMilkRunScreenState();
}

class _FindMilkRunScreenState extends ConsumerState<FindMilkRunScreen> {
  final _addressController = TextEditingController();

  bool _isSearching = false;
  DeliveryZone? _selectedRoute;
  bool _showOutOfArea = false;
  String _waitlistEmail = '';
  bool _waitlistSubmitted = false;
  List<DeliveryZone>? _multipleRoutes;
  bool _showDatePicker = false;
  DateTime? _customDate;
  bool _useCustomDate = false;
  bool _showChangeAddress = false;
  List<String> _citySuggestions = [];
  bool _isUsingMyLocation = false;
  // Google Places Autocomplete state
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB_8gavyfzAIRyMl4eD18iGe_s27fjBSDo',
  );
  Timer? _placesDebounce;
  List<Map<String, dynamic>> _placeSuggestions = [];
  bool _showPlaceSuggestions = false;
  bool _isSelectingSuggestion = false;

  // Structured address fields extracted from geocode
  String _parsedStreet = '';
  String _parsedCity = '';
  String _parsedPostal = '';

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
  }

  void _onAddressChanged() {
    if (_isUsingMyLocation || _isSelectingSuggestion) return;
    final text = _addressController.text.trim();

    // Local city suggestions (fast-path)
    if (text.isEmpty) {
      if (_citySuggestions.isNotEmpty || _placeSuggestions.isNotEmpty) {
        setState(() {
          _citySuggestions = [];
          _placeSuggestions = [];
          _showPlaceSuggestions = false;
        });
      }
      return;
    }
    final lowerText = text.toLowerCase();
    final matches = deliveryZones
        .expand((z) => z.cities)
        .where((c) => c.toLowerCase().contains(lowerText))
        .toList();
    final isExact =
        matches.length == 1 && matches.first.toLowerCase() == lowerText;
    setState(() => _citySuggestions = isExact ? [] : matches);

    // Google Places autocomplete (debounced)
    _placesDebounce?.cancel();
    if (text.length < 3) {
      if (_placeSuggestions.isNotEmpty) {
        setState(() { _placeSuggestions = []; _showPlaceSuggestions = false; });
      }
      return;
    }
    _placesDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchPlaceSuggestions(text);
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
      _addressController.text = description;
      _placeSuggestions = [];
      _showPlaceSuggestions = false;
      _citySuggestions = [];
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
          final geometry = firstResult['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;
          final double? lat = (location?['lat'] as num?)?.toDouble();
          final double? lng = (location?['lng'] as num?)?.toDouble();

          final components = (firstResult['address_components'] as List?) ?? [];
          String city = '';
          String streetNumber = '';
          String route = '';
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
            } else if (types.contains('sublocality_level_1') && city.isEmpty) {
              city = longName;
            } else if (types.contains('postal_code')) {
              postal = longName;
            }
          }
          final street = [streetNumber, route].where((p) => p.trim().isNotEmpty).join(' ').trim();

          // Try zone detection by coordinates first, then city name
          DeliveryZone? zone;
          if (lat != null && lng != null) {
            zone = detectZone(lat, lng);
          }
          zone ??= city.isNotEmpty ? detectZoneByCity(city) : null;

          if (zone != null) {
            _parsedStreet = street;
            _parsedCity = city;
            _parsedPostal = postal;
            setState(() {
              _selectedRoute = zone;
              _isSearching = false;
              _showOutOfArea = false;
            });
            _isSelectingSuggestion = false;
            return;
          }
        }
      }
    } catch (_) {}
    setState(() { _isSearching = false; _showOutOfArea = true; });
    _isSelectingSuggestion = false;
  }

  @override
  void dispose() {
    _placesDebounce?.cancel();
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  DateTime _getNextDeliveryDate(DeliveryZone zone) {
    return getNextDeliveryDateFromDays(zone.deliveryDays);
  }

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  /// Next 4 occurrences of the zone's delivery days.
  List<DateTime> _getAvailableDeliveryDates(DeliveryZone zone) {
    const dayNames = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday',
    ];
    final targetDays = zone.deliveryDays.map((d) => dayNames.indexOf(d)).where((i) => i >= 0).toList();
    final dates = <DateTime>[];
    var checkDate = DateTime.now().add(const Duration(days: 1));

    while (dates.length < 4) {
      final currentDay = checkDate.weekday % 7; // 0=Sun
      if (targetDays.contains(currentDay)) {
        dates.add(checkDate);
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }
    return dates;
  }

  DateTime? _getSelectedDeliveryDate() {
    if (_useCustomDate && _customDate != null) return _customDate;
    return _selectedRoute != null
        ? _getNextDeliveryDate(_selectedRoute!)
        : null;
  }

  // ── Address search ──────────────────────────────────────────────────

  Future<void> _handleAddressSearch() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _isSearching = true;
      _showOutOfArea = false;
      _multipleRoutes = null;
      _selectedRoute = null;
    });

    // Simulate geocoding delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Try exact city match
    final zone = detectZoneByCity(address);
    if (zone != null) {
      _parsedCity = address;
      _parsedStreet = '';
      _parsedPostal = '';
      setState(() {
        _selectedRoute = zone;
        _isSearching = false;
      });
      return;
    }

    // Check partial matches across all zones
    final possibleZones = deliveryZones.where((z) {
      return z.cities.any((city) =>
          city.toLowerCase().contains(address.toLowerCase()) ||
          address.toLowerCase().contains(city.toLowerCase()));
    }).toList();

    setState(() {
      if (possibleZones.length > 1) {
        _multipleRoutes = possibleZones;
      } else if (possibleZones.length == 1) {
        _selectedRoute = possibleZones.first;
        _parsedCity = possibleZones.first.cities.isNotEmpty
            ? possibleZones.first.cities.first
            : address;
        _parsedStreet = '';
        _parsedPostal = '';
      } else {
        _showOutOfArea = true;
      }
      _isSearching = false;
    });
  }

  // ── Geolocation ─────────────────────────────────────────────────────

  Future<void> _handleUseMyLocation() async {
    setState(() {
      _isSearching = true;
      _showOutOfArea = false;
      _multipleRoutes = null;
      _selectedRoute = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError(
            'Location services are disabled. Please enable them.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError(
              'Location permission denied. Please enter your address manually.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
            'Location permission permanently denied. Please enter your address manually.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final zone = detectZone(position.latitude, position.longitude);

      _isUsingMyLocation = true;
      setState(() {
        _citySuggestions = [];
        _placeSuggestions = [];
        _showPlaceSuggestions = false;
        if (zone != null) {
          _selectedRoute = zone;
          _addressController.text = 'Current Location';
        } else {
          _showOutOfArea = true;
        }
        _isSearching = false;
      });
      _isUsingMyLocation = false;
    } catch (e) {
      _showLocationError(
          'Unable to get your location. Please enter your address manually.');
    }
  }

  void _showLocationError(String message) {
    setState(() => _isSearching = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message), backgroundColor: Colors.red.shade600),
      );
    }
  }

  // ── Route selection (boundary case) ─────────────────────────────────

  void _handleRouteSelect(DeliveryZone zone) {
    _parsedCity = zone.cities.isNotEmpty ? zone.cities.first : '';
    _parsedStreet = '';
    _parsedPostal = '';
    setState(() {
      _selectedRoute = zone;
      _multipleRoutes = null;
      _customDate = null;
      _useCustomDate = false;
      _showDatePicker = false;
    });
  }

  // ── Custom date ─────────────────────────────────────────────────────

  void _handleCustomDateSelect(DateTime date) {
    setState(() {
      _customDate = date;
      _useCustomDate = true;
      _showDatePicker = false;
    });
  }

  // ── Proceed ─────────────────────────────────────────────────────────

  Future<void> _handleProceed() async {
    if (_selectedRoute == null) return;
    // Persist the selected delivery date so checkout picks it up
    final deliveryDate = _getSelectedDeliveryDate();
    if (deliveryDate != null) {
      saveSelectedDeliveryDate(deliveryDate);
      ref.read(selectedDeliveryDateProvider.notifier).state = deliveryDate;
    }

    // Save the address to the backend so it appears in saved addresses
    await _saveAddressToBackend(deliveryDate);

    goRouter.go(AppRoutes.host);
  }

  Future<void> _saveAddressToBackend(DateTime? deliveryDate) async {
    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token == null || token.isEmpty) return;

    // Build addressLine from parsed fields or fall back to text field
    final addressLine = _parsedStreet.isNotEmpty
        ? '$_parsedStreet, $_parsedCity $_parsedPostal'
        : _addressController.text.trim();
    final city = _parsedCity.isNotEmpty
        ? _parsedCity
        : (_selectedRoute?.cities.isNotEmpty == true
            ? _selectedRoute!.cities.first
            : '');
    final postal = _parsedPostal;
    if (city.isEmpty && addressLine.isEmpty) return;

    final user = ref.read(authNotifierProvider).value?.data?.user;

    try {
      // Always fetch addresses first so we know if one already exists
      await ref.read(addressProvider.notifier).fetchAddresses(token);
      final existingAddresses = ref.read(addressProvider).addresses;
      bool success;

      if (existingAddresses.isNotEmpty) {
        // Update the first (most recent) existing address
        final existingId = existingAddresses.first.safeId;
        success = await ref.read(addressProvider.notifier).updateAddress(
              token: token,
              addressId: existingId,
              addressLine: addressLine,
              city: city,
              statess: 'ON',
              country: 'CA',
              postalCode: postal,
              phone: user?.phone ?? '',
              fullName: user?.name ?? '',
              deliveryZone: _selectedRoute?.name,
              deliveryDay: _selectedRoute?.deliveryDay,
              outOfZoneDate: deliveryDate,
            );
      } else {
        // No existing address — create a new one
        success = await ref.read(addressProvider.notifier).addAddress(
              token: token,
              addressLine: addressLine,
              city: city,
              statess: 'ON',
              country: 'CA',
              postalCode: postal,
              phone: user?.phone ?? '',
              fullName: user?.name ?? '',
              deliveryZone: _selectedRoute?.name,
              deliveryDay: _selectedRoute?.deliveryDay,
              outOfZoneDate: deliveryDate,
            );
      }

      if (success) {
        final addresses = ref.read(addressProvider).addresses;
        if (addresses.isNotEmpty) {
          final savedAddress = addresses.first;
          ref
              .read(selectedDeliveryAddressProvider.notifier)
              .selectAddress(savedAddress);
          // Also persist the delivery date for this specific address
          if (deliveryDate != null && savedAddress.safeId.isNotEmpty) {
            saveAddressDeliveryDate(savedAddress.safeId, deliveryDate);
          }
        }
      }
    } catch (e) {
      debugPrint('[FindMilkRun] Failed to save address: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 70),
                      Text(
                        "Find my milk run",
                        style: GoogleFonts.inter(
                          fontSize: 22.sp,
                          color: AppColors.primary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => goRouter.go(AppRoutes.host),
                        child: SizedBox(
                          width: 70,
                          child: Text(
                            "Skip",
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Enter your address to see your next run.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            // ── Scrollable ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    _buildMilkRunCard(),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ══════════════════════════════════════════════════════════════════════

  // ── Milk run card ─────────────────────────────────────────────────────

  Widget _buildMilkRunCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Blue banner
          Container(
            width: double.infinity,
            color: AppColors.primary,
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              "Your milk run",
              textAlign: TextAlign.center,
              style: GoogleFonts.pacifico(
                fontSize: 20.sp,
                color: Colors.white,
              ),
            ),
          ),
          // Truck image
          SizedBox(
            height: 160.h,
            width: double.infinity,
            child: Image.asset(
              "assets/images/brokli.png",
              fit: BoxFit.cover,
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route info / loading / placeholder
                if (_isSearching)
                  _buildLoadingState()
                else if (_multipleRoutes != null)
                  _buildMultipleRoutesCard()
                else if (_selectedRoute != null)
                  _buildRouteInfo()
                else if (_showOutOfArea)
                  _buildOutOfAreaCard()
                else
                  _buildEmptyPlaceholder(),

                SizedBox(height: 16.h),

                // Book button
                _buildBookButton(),
                SizedBox(height: 8.h),

                // See full schedule toggle
                _buildOutlinedToggleButton(
                  label: _showDatePicker ? "Hide schedule" : "See full schedule",
                  onTap: () =>
                      setState(() => _showDatePicker = !_showDatePicker),
                ),

                // Schedule section
                if (_showDatePicker && _selectedRoute != null) ...[
                  SizedBox(height: 12.h),
                  _buildScheduleSection(),
                ],

                SizedBox(height: 8.h),

                // Change address toggle
                _buildOutlinedToggleButton(
                  label: _showChangeAddress ? "Cancel" : "Change address",
                  onTap: () =>
                      setState(() => _showChangeAddress = !_showChangeAddress),
                ),

                // Address input
                if (_showChangeAddress) ...[
                  SizedBox(height: 12.h),
                  _buildChangeAddressSection(),
                ],

                SizedBox(height: 8.h),

                // Add Address
                _buildOutlinedToggleButton(
                  label: "Add Address",
                  onTap: () => goRouter.go(AppRoutes.host),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty placeholder ──────────────────────────────────────────────────

  Widget _buildEmptyPlaceholder() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        "Please add your delivery address to see your milk run",
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF92400E),
        ),
      ),
    );
  }

  // ── Route info (zone found) ────────────────────────────────────────────

  Widget _buildRouteInfo() {
    final route = _selectedRoute!;
    final deliveryDate =
        _getSelectedDeliveryDate() ?? _getNextDeliveryDate(route);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_shipping_rounded,
                size: 18.sp, color: AppColors.primary),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                "Your milk run : every ${route.deliveryDaysLabel}",
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          route.name,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade900,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Icon(Icons.local_shipping_rounded,
                size: 16.sp, color: AppColors.primary),
            SizedBox(width: 6.w),
            Text(
              "Next Delivery: ${_formatDate(deliveryDate)}",
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Book button ────────────────────────────────────────────────────────

  Widget _buildBookButton() {
    final deliveryDate = _selectedRoute != null
        ? (_getSelectedDeliveryDate() ?? _getNextDeliveryDate(_selectedRoute!))
        : null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedRoute != null ? _handleProceed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          elevation: 0,
        ),
        child: Text(
          _selectedRoute != null && deliveryDate != null
              ? "Book my stop for ${_formatDate(deliveryDate)}"
              : "Book my stop",
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Outlined toggle button ─────────────────────────────────────────────

  Widget _buildOutlinedToggleButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          foregroundColor: Colors.grey.shade700,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Schedule section (8-date grid) ────────────────────────────────────

  Widget _buildScheduleSection() {
    final route = _selectedRoute!;
    final dates = _getAvailableDeliveryDates(route);
    final allDates = List<DateTime>.from(dates);
    while (allDates.length < 8) {
      allDates.add(allDates.last.add(const Duration(days: 7)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10.r,
              height: 10.r,
              decoration: BoxDecoration(
                color: route.color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                "${route.cities.isNotEmpty ? route.cities.first : route.name} — ${route.deliveryDaysLabel}, 2–6 PM",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
            childAspectRatio: 3.4,
          ),
          itemCount: allDates.length,
          itemBuilder: (context, idx) {
            final date = allDates[idx];
            final isNext = idx == 0;
            final isSelected = _customDate != null
                ? (_customDate!.year == date.year &&
                    _customDate!.month == date.month &&
                    _customDate!.day == date.day)
                : isNext;
            return GestureDetector(
              onTap: () => _handleCustomDateSelect(date),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.07)
                      : Colors.grey.shade50,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDate(date),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? AppColors.primary : Colors.grey.shade700,
                      ),
                    ),
                    if (isNext)
                      Text(
                        "Next run",
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => goRouter.go(AppRoutes.host),
          child: Text(
            "View delivery map →",
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
        if (_useCustomDate && _customDate != null) ...[
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: () => setState(() {
              _customDate = null;
              _useCustomDate = false;
            }),
            child: Text(
              'Proceed with earliest date — ${_formatDate(dates.first)}',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Change address section ─────────────────────────────────────────────

  Widget _buildChangeAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 18.sp, color: Colors.grey.shade400),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: "Enter your address",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 10.h),
                        ),
                        style: GoogleFonts.inter(fontSize: 13.sp),
                        onSubmitted: (_) => _handleAddressSearch(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),
            ElevatedButton(
              onPressed: _isSearching ? null : _handleAddressSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                elevation: 0,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
              ),
              child: Text(
                _isSearching ? "..." : "Search",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (_citySuggestions.isNotEmpty)
          _citySuggestionDropdown(
            cities: _citySuggestions,
            onSelect: (suggestion) {
              _isSelectingSuggestion = true;
              _addressController.text = suggestion;
              _addressController.selection = TextSelection.fromPosition(
                  TextPosition(offset: suggestion.length));
              setState(() { _citySuggestions = []; _placeSuggestions = []; _showPlaceSuggestions = false; });
              _isSelectingSuggestion = false;
              _handleAddressSearch();
            },
            onClose: () => setState(() => _citySuggestions = []),
          ),
        // Google Places address suggestions
        if (_showPlaceSuggestions && _placeSuggestions.isNotEmpty && _citySuggestions.isEmpty)
          Container(
            margin: EdgeInsets.only(top: 4.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _placeSuggestions.length.clamp(0, 5),
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (_, i) {
                final s = _placeSuggestions[i];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.location_on_outlined,
                      size: 16.sp, color: AppColors.primary),
                  title: Text(
                    s['description'] as String? ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
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
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _isSearching ? null : _handleUseMyLocation,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.my_location_rounded,
                  size: 14.sp, color: Colors.grey.shade600),
              SizedBox(width: 4.w),
              Text(
                "Use my location",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(
            width: 28.w,
            height: 28.w,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "Finding your milk run...",
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Multiple routes ────────────────────────────────────────────────────

  Widget _buildMultipleRoutesCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Which milk run is best for you?",
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          SizedBox(height: 12.h),
          ...(_multipleRoutes ?? []).map((zone) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: GestureDetector(
                onTap: () => _handleRouteSelect(zone),
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              zone.name,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            Text(
                              '${zone.deliveryDaysLabel}',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: zone.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Out of area ────────────────────────────────────────────────────────

  Widget _buildOutOfAreaCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_off_rounded,
                size: 22.sp, color: Colors.grey.shade500),
          ),
          SizedBox(height: 14.h),
          Text(
            "We're not in your area yet",
            style: GoogleFonts.inter(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          SizedBox(height: 8.h),
          Text.rich(
            TextSpan(
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: "Your city is not in the delivery zone. We are working on it, but for now, please visit "),
                TextSpan(
                  text: "www.retrorouteco.com",
                  style: const TextStyle(
                    color: Color(0xFFE8751A),
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    launchUrl(Uri.parse('https://www.retrorouteco.com/?from=app'), mode: LaunchMode.externalApplication);
                  },
                ),
                const TextSpan(text: " to place an order, and we will ship it to you."),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── City suggestion dropdown (shared by both screens) ───────────────────────
Widget _citySuggestionDropdown({
  required List<String> cities,
  required void Function(String) onSelect,
  VoidCallback? onClose,
}) {
  return Container(
    margin: EdgeInsets.only(top: 4.h),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade200),
      borderRadius: BorderRadius.circular(10.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Column(
        children: [
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: Padding(
                padding: EdgeInsets.only(right: 8.w, top: 6.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Close',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500)),
                    SizedBox(width: 2.w),
                    Icon(Icons.close_rounded,
                        size: 14.sp, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),
          ...cities.map((city) {
            return InkWell(
              onTap: () => onSelect(city),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 16.sp, color: AppColors.primary),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        city,
                        style: GoogleFonts.inter(
                            fontSize: 13.sp, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 3 widget — used by the onboarding orchestrator (q_onboarding_view.dart)
// Mirrors web OnboardingScreen3Content: address form + zone detection.
// ─────────────────────────────────────────────────────────────────────────────
class FindMilkRunContent extends StatefulWidget {
  final VoidCallback onNext;
  final ValueChanged<Map<String, dynamic>> onSelectRoute;
  final VoidCallback onSkip;

  const FindMilkRunContent({
    required this.onNext,
    required this.onSelectRoute,
    required this.onSkip,
    super.key,
  });

  @override
  State<FindMilkRunContent> createState() => _FindMilkRunContentState();
}

class _FindMilkRunContentState extends State<FindMilkRunContent> {
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB_8gavyfzAIRyMl4eD18iGe_s27fjBSDo',
  );

  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();

  DeliveryZone? _zone;
  bool _loading = false;
  bool _outOfArea = false;
  String _waitlistEmail = '';
  bool _waitlistDone = false;
  List<String> _citySuggestions = [];
  List<Map<String, dynamic>> _streetSuggestions = [];
  Timer? _streetDebounce;
  bool _isSelectingStreetSuggestion = false;
  bool _isUsingMyLocation = false;
  bool _showDatePicker = false;
  DateTime? _customDate;
  bool _useCustomDate = false;

  List<DateTime> _getAvailableDates(DeliveryZone zone) {
    const dayNames = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday',
    ];
    final targetDays = zone.deliveryDays.map((d) => dayNames.indexOf(d)).where((i) => i >= 0).toList();
    final dates = <DateTime>[];
    final now = DateTime.now();
    const cutoffHour = 12; // noon
    var check = DateTime(now.year, now.month, now.day);
    while (dates.length < 4) {
      final currentDay = check.weekday % 7;
      if (targetDays.contains(currentDay)) {
        final cutoff = DateTime(check.year, check.month, check.day - 1, cutoffHour);
        if (now.isBefore(cutoff)) dates.add(check);
      }
      check = DateTime(check.year, check.month, check.day + 1);
    }
    return dates;
  }

  String _fmtDateFull(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${wd[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}';
  }

  @override
  void initState() {
    super.initState();
    _cityCtrl.addListener(_onCityChanged);
    _streetCtrl.addListener(_onStreetChanged);
  }

  @override
  void dispose() {
    _streetDebounce?.cancel();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  void _onStreetChanged() {
    if (_isSelectingStreetSuggestion || _isUsingMyLocation) return;
    _streetDebounce?.cancel();
    final query = _streetCtrl.text.trim();
    if (query.length < 3) {
      if (_streetSuggestions.isNotEmpty) {
        setState(() => _streetSuggestions = []);
      }
      return;
    }
    _streetDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchStreetSuggestions(query);
    });
  }

  Future<void> _fetchStreetSuggestions(String query) async {
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
      final status = body['status'] as String? ?? '';
      final predictions = (body['predictions'] as List?) ?? const [];

      List<Map<String, dynamic>> next = [];
      if (status == 'OK') {
        next = predictions.map<Map<String, dynamic>>((item) {
          final map = (item as Map).cast<String, dynamic>();
          return {
            'placeId': map['place_id'] as String? ?? '',
            'description': map['description'] as String? ?? '',
          };
        }).toList();
      }

      if (mounted) setState(() => _streetSuggestions = next);
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _fetchGeocodeByPlaceId(String placeId) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?place_id=${Uri.encodeComponent(placeId)}'
        '&language=en'
        '&key=$_googleMapsApiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';
      final results = (body['results'] as List?) ?? const [];
      if (status != 'OK' || results.isEmpty) return null;

      return (results.first as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectStreetSuggestion(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['placeId'] as String? ?? '';
    final description = suggestion['description'] as String? ?? '';

    _isSelectingStreetSuggestion = true;
    try {
      if (description.isNotEmpty) {
        _streetCtrl.text = description.split(',').first.trim();
        _streetCtrl.selection = TextSelection.collapsed(
          offset: _streetCtrl.text.length,
        );
      }

      if (placeId.isEmpty) return;

      final geocode = await _fetchGeocodeByPlaceId(placeId);
      if (geocode == null || !mounted) return;

      final components =
          (geocode['address_components'] as List?)?.whereType<Map>().toList() ?? const [];

      String streetNumber = '';
      String route = '';
      String city = '';
      String postal = '';

      for (final c in components) {
        final map = c.cast<String, dynamic>();
        final types = (map['types'] as List?)?.whereType<String>().toList() ?? const <String>[];
        final longName = (map['long_name'] as String?) ?? '';

        if (types.contains('street_number')) {
          streetNumber = longName;
        } else if (types.contains('route')) {
          route = longName;
        } else if (types.contains('locality')) {
          city = longName;
        } else if (types.contains('postal_town') && city.isEmpty) {
          city = longName;
        } else if (types.contains('administrative_area_level_3') && city.isEmpty) {
          city = longName;
        } else if (types.contains('administrative_area_level_2') && city.isEmpty) {
          city = longName;
        } else if (types.contains('postal_code')) {
          postal = longName;
        }
      }

      final street =
          [streetNumber, route].where((p) => p.trim().isNotEmpty).join(' ').trim();

      if (street.isNotEmpty) _streetCtrl.text = street;
      _cityCtrl.text = city;
      _postalCtrl.text = postal;

      final zone = city.isNotEmpty ? detectZoneByCity(city) : null;
      setState(() {
        _streetSuggestions = [];
        _zone = zone;
        _outOfArea = zone == null && city.isNotEmpty;
      });

      if (zone != null) {
        widget.onSelectRoute({
          'zone': zone,
          'address': '${_streetCtrl.text.trim()}, $city ${_postalCtrl.text.trim()}',
          'street': _streetCtrl.text.trim(),
          'city': city,
          'postal': _postalCtrl.text.trim(),
          'nextDate': getNextDeliveryDateFromDays(zone.deliveryDays),
        });
      }
    } finally {
      _isSelectingStreetSuggestion = false;
    }
  }

  void _onCityChanged() {
    if (_isUsingMyLocation) return;
    final city = _cityCtrl.text.trim();
    // Live suggestions
    if (city.isEmpty) {
      if (_citySuggestions.isNotEmpty || _zone != null || _outOfArea) {
        setState(() { _citySuggestions = []; _zone = null; _outOfArea = false; });
      }
      return;
    }
    final text = city.toLowerCase();
    final matches = deliveryZones
        .expand((z) => z.cities)
        .where((c) => c.toLowerCase().contains(text))
        .toList();
    final isExact = matches.length == 1 && matches.first.toLowerCase() == text;
    setState(() => _citySuggestions = isExact ? [] : matches);
    // Zone detection
    if (city.length < 3) {
      if (_zone != null || _outOfArea) setState(() { _zone = null; _outOfArea = false; });
      return;
    }
    _detectZone(city);
  }

  void _detectZone(String city) {
    final z = detectZoneByCity(city);
    setState(() {
      _zone = z;
      _outOfArea = z == null && city.isNotEmpty;
    });
    if (z != null) {
      widget.onSelectRoute({
        'zone': z,
        'address': '${_streetCtrl.text.trim()}, $city ${_postalCtrl.text.trim()}',
        'street': _streetCtrl.text.trim(),
        'city': city,
        'postal': _postalCtrl.text.trim(),
        'nextDate': getNextDeliveryDateFromDays(z.deliveryDays),
      });
    }
  }

  Future<void> _useMyLocation() async {
    _isUsingMyLocation = true;
    setState(() { _loading = true; _zone = null; _outOfArea = false; _citySuggestions = []; _streetSuggestions = []; });
    try {
      // 1. Check location service
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showSnack('Location services are disabled. Please enable them.');
        return;
      }
      // 2. Check / request permission
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          _showSnack('Location permission denied. Enter your address manually.');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        _showSnack('Permission permanently denied. Please enable it in Settings.');
        return;
      }
      // 3. Get coordinates
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      // 4. Reverse-geocode via Nominatim (free, no key)
      final addr = await _reverseGeocode(pos.latitude, pos.longitude);
      if (mounted) {
        _streetCtrl.text = addr['street'] ?? '';
        _cityCtrl.text = addr['city'] ?? '';
        _postalCtrl.text = addr['postal'] ?? '';
      }
      // 5. Detect zone from the city (or fall back to coordinates)
      final city = addr['city'] ?? '';
      DeliveryZone? z = city.isNotEmpty ? detectZoneByCity(city) : null;
      z ??= detectZone(pos.latitude, pos.longitude);
      setState(() { _zone = z; _outOfArea = z == null; _citySuggestions = []; _streetSuggestions = []; });
      if (z != null) {
        widget.onSelectRoute({
          'zone': z,
          'address': '${_streetCtrl.text.trim()}, $city ${_postalCtrl.text.trim()}',
          'street': _streetCtrl.text.trim(),
          'city': city,
          'postal': _postalCtrl.text.trim(),
          'nextDate': getNextDeliveryDateFromDays(z.deliveryDays),
        });
      }
    } catch (e) {
      _showSnack('Unable to get your location. Please enter your address manually.');
    } finally {
      _isUsingMyLocation = false;
      if (mounted) setState(() { _loading = false; });
    }
  }

  /// Calls the Google Maps Geocoding API for reverse geocoding.
  /// Returns a map with keys: street, city, postal.
  Future<Map<String, String>> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}'
        '&language=en'
        '&key=$_googleMapsApiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return {};
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';
      final results = (body['results'] as List?) ?? const [];
      if (status != 'OK' || results.isEmpty) return {};

      final first = (results.first as Map).cast<String, dynamic>();
      final components =
          (first['address_components'] as List?)?.whereType<Map>().toList() ?? const [];

      String streetNumber = '';
      String route = '';
      String city = '';
      String postal = '';

      for (final c in components) {
        final map = c.cast<String, dynamic>();
        final types = (map['types'] as List?)?.whereType<String>().toList() ?? const <String>[];
        final longName = (map['long_name'] as String?) ?? '';

        if (types.contains('street_number')) {
          streetNumber = longName;
        } else if (types.contains('route')) {
          route = longName;
        } else if (types.contains('locality')) {
          city = longName;
        } else if (types.contains('postal_town') && city.isEmpty) {
          city = longName;
        } else if (types.contains('administrative_area_level_3') && city.isEmpty) {
          city = longName;
        } else if (types.contains('administrative_area_level_2') && city.isEmpty) {
          city = longName;
        } else if (types.contains('postal_code')) {
          postal = longName;
        }
      }

      final street =
          [streetNumber, route].where((p) => p.trim().isNotEmpty).join(' ').trim();

      return {
        'street': street,
        'city': city,
        'postal': postal,
      };
    } catch (_) {
      return {};
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade600),
      );
    }
  }

  void _proceed() {
    if (_zone == null) return;
    final z = _zone!;
    final city = _cityCtrl.text.trim();
    final street = _streetCtrl.text.trim();
    final postal = _postalCtrl.text.trim();
    final selectedDate = _useCustomDate && _customDate != null
        ? _customDate!
        : getNextDeliveryDateFromDays(z.deliveryDays);
    widget.onSelectRoute({
      'zone': z,
      'address': '$street, $city $postal',
      'street': street,
      'city': city,
      'postal': postal,
      'nextDate': selectedDate,
    });
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header banner
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          child: Column(
            children: [
              Text('Find My Milk Run',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: widget.onSkip,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.white38, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Skip for now',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 10.sp, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              if (_streetSuggestions.isNotEmpty || _citySuggestions.isNotEmpty) {
                setState(() {
                  _streetSuggestions = [];
                  _citySuggestions = [];
                });
              }
            },
            behavior: HitTestBehavior.translucent,
            child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
               
                SizedBox(height: 8.h),
             
                 
                 Text(
                  'Enter your address to see your delivery zone',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _field(_streetCtrl, 'Street Address', Icons.home_outlined),
                      if (_streetSuggestions.isNotEmpty)
                        _streetSuggestionDropdown(
                          suggestions: _streetSuggestions,
                          onSelect: _selectStreetSuggestion,
                          onClose: () => setState(() => _streetSuggestions = []),
                        ),
                      SizedBox(height: 12.h),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _field(_cityCtrl, 'City', Icons.location_city_outlined),
                          if (_citySuggestions.isNotEmpty)
                            _citySuggestionDropdown(
                              cities: _citySuggestions,
                              onSelect: (suggestion) {
                                _cityCtrl.text = suggestion;
                                _cityCtrl.selection = TextSelection.fromPosition(
                                    TextPosition(offset: suggestion.length));
                                // listener fires → zone auto-detected
                              },
                              onClose: () => setState(() => _citySuggestions = []),
                            ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _field(_postalCtrl, 'Postal Code', Icons.local_post_office_outlined, isPostal: true),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Use my location chip
                GestureDetector(
                  onTap: _loading ? null : _useMyLocation,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.btnColor),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _loading
                            ? SizedBox(width: 16.w, height: 16.h, child: const CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.my_location, size: 16.sp, color: AppColors.btnColor),
                        SizedBox(width: 6.w),
                        Text('Use my location',
                            style: GoogleFonts.inter(fontSize: 13.sp, color: AppColors.btnColor, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Zone result card
                if (_zone != null) ...[_buildZoneCard(), SizedBox(height: 16.h), _buildCtaButton()],

                // Out-of-area card
                if (_outOfArea) _buildOutOfAreaCard(),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }

  // ── Sky-gradient zone card (matches web) ──────────────────────────────

  Widget _buildZoneCard() {
    final zone = _zone!;
    final deliveryDate =
        _useCustomDate && _customDate != null
            ? _customDate!
            : getNextDeliveryDateFromDays(zone.deliveryDays);
    final city = _cityCtrl.text.trim();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284c7).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Row(
            children: [
               Icon(Icons.local_shipping_rounded,
                  size: 18.sp, color: Colors.white),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Your milk run : Every ${zone.deliveryDaysLabel}',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Zone + city frosted panel
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zone ${zone.id}',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (_streetCtrl.text.trim().isNotEmpty || _cityCtrl.text.trim().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13.sp, color: Colors.white70),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            [
                              _streetCtrl.text.trim(),
                              _cityCtrl.text.trim(),
                              _postalCtrl.text.trim(),
                            ].where((s) => s.isNotEmpty).join(', '),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                     Icon(Icons.calendar_today_rounded,
                        size: 12, color:Colors.amber.shade200),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        'Next Delivery: ${_fmtDateFull(deliveryDate)}',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade200
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // Date picker frosted panel
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose a different date?',
                          style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                        if (_useCustomDate && _customDate != null)
                          Text(
                            'Selected: ${_fmtDateFull(_customDate!)}',
                            style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: const Color(0xFFfde68a)),
                          ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showDatePicker = !_showDatePicker),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          children: [
                             Icon(Icons.calendar_month_rounded,
                                size: 16.sp, color: Colors.white),
                            SizedBox(width: 4.w),
                            Text(
                              _showDatePicker ? 'Close' : 'Pick Date',
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showDatePicker) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select your preferred delivery date:',
                          style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800),
                        ),
                        SizedBox(height: 8.h),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth = (constraints.maxWidth - 6.w) / 2;
                            return Wrap(
                              spacing: 6.w,
                              runSpacing: 6.h,
                              children: _getAvailableDates(zone).map((date) {
                                final isSelected = _customDate != null &&
                                    _customDate!.year == date.year &&
                                    _customDate!.month == date.month &&
                                    _customDate!.day == date.day;
                                return SizedBox(
                                  width: itemWidth,
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _customDate = date;
                                      _useCustomDate = true;
                                      _showDatePicker = false;
                                    }),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      child: Text(
                                        _fmtDateFull(date),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                if (_useCustomDate && _customDate != null) ...[
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: () => setState(
                        () { _customDate = null; _useCustomDate = false; }),
                    child: Text(
                      'Proceed with earliest date',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: const Color(0xFFfde68a),
                        decorationColor: const Color(0xFFfde68a),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Free backyard delivery · Water testing available on request.',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Colors.amber.shade200,
            ),
          ),
        ],
      ),
    );
  }

  // ── Orange CTA ─────────────────────────────────────────────────────────

  Widget _buildCtaButton() {
    final zone = _zone!;
    final deliveryDate =
        _useCustomDate && _customDate != null
            ? _customDate!
            : getNextDeliveryDateFromDays(zone.deliveryDays);
    return GestureDetector(
      onTap: _proceed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF97316),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8.w),
            Text(
              'Book my stop for ${_fmtDateFull(deliveryDate)}',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Out-of-area card (matches web) ──────────────────────────────────────

  Widget _buildOutOfAreaCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on_rounded,
                size: 20.sp, color: Colors.grey.shade500),
          ),
          SizedBox(height: 12.h),
          Text(
            "We're not in your area yet",
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          SizedBox(height: 6.h),
          Text.rich(
            TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: "Your city is not in the delivery zone. We are working on it, but for now, please visit "),
                TextSpan(
                  text: "www.retrorouteco.com",
                  style: const TextStyle(
                    color: Color(0xFFE8751A),
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    launchUrl(Uri.parse('https://www.retrorouteco.com/?from=app'), mode: LaunchMode.externalApplication);
                  },
                ),
                const TextSpan(text: " to place an order, and we will ship it to you."),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool isPostal = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4.h),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.text,
          inputFormatters: isPostal ? [_PostalCodeFormatter()] : null,
          style: GoogleFonts.inter(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: isPostal ? 'K1G 0A1' : label,
            hintStyle: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey),
            prefixIcon: Icon(icon, size: 20.sp, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFF0284c7), width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }

  Widget _streetSuggestionDropdown({
    required List<Map<String, dynamic>> suggestions,
    required void Function(Map<String, dynamic>) onSelect,
    VoidCallback? onClose,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Column(
          children: [
            if (onClose != null)
              GestureDetector(
                onTap: onClose,
                child: Padding(
                  padding: EdgeInsets.only(right: 8.w, top: 6.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Close',
                          style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500)),
                      SizedBox(width: 2.w),
                      Icon(Icons.close_rounded,
                          size: 14.sp, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ),
            ...suggestions.map((item) {
              final text = item['description'] as String? ?? '';
              return InkWell(
                onTap: () => onSelect(item),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pin_drop_outlined,
                        size: 16.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          text,
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PostalCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Uppercase and strip non-alphanumeric characters
    final raw = newValue.text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    // Limit to 6 alphanumeric characters
    final limited = raw.length > 6 ? raw.substring(0, 6) : raw;
    // Insert space after 3rd character → A1A 1A1
    final formatted = limited.length > 3
        ? '${limited.substring(0, 3)} ${limited.substring(3)}'
        : limited;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}