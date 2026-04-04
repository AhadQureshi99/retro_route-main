import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:retro_route/config/delivery_zones.dart';
import 'package:retro_route/model/product_model.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view/splash/q_onboarding_view4.dart';
import 'package:retro_route/view_model/address_view_model/address_view_model.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/cart_view_model/cart_view_model.dart';
import 'package:retro_route/view_model/water_test_view_model/water_test_view_model.dart';
import 'package:retro_route/view_model/bottom_nav_view_model.dart';
import 'package:retro_route/view_model/selected_delivery_date_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterTestPopup {
  static void show(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => const _MilkRunDialog(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Milk Run Dialog — mirrors web WaterTestPopup design
// ─────────────────────────────────────────────────────────────────────────────
class _MilkRunDialog extends ConsumerStatefulWidget {
  const _MilkRunDialog();

  @override
  ConsumerState<_MilkRunDialog> createState() => _MilkRunDialogState();
}

class _MilkRunDialogState extends ConsumerState<_MilkRunDialog> {
  // ── Data ─────────────────────────────────────────────────────────────────
  Product? _waterTestProduct;
  DeliveryZone? _zone;
  DateTime? _firstDate;
  String? _userCity;
  String _userAddress = '';
  String _userFullAddress = '';

  // ── UI State ─────────────────────────────────────────────────────────────
  bool _loading = true;
  bool _showSchedule = false;
  bool _showAddressInput = false;
  bool _isSearching = false;
  bool _showBookingScreen = false;
  DateTime? _selectedDate;

  final TextEditingController _addressCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // ── Google Places autocomplete ──────────────────────────────────────────
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB_8gavyfzAIRyMl4eD18iGe_s27fjBSDo',
  );
  Timer? _debounce;
  List<Map<String, dynamic>> _placeSuggestions = [];
  bool _showPlaceSuggestions = false;
  bool _isSelectingSuggestion = false;

  void _closeDialog() {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      goRouter.go(AppRoutes.host);
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // 1. Fetch water test product
    final product = await ref.read(waterTestProvider.future).catchError((_) => null);

    // 1b. Check SharedPreferences for a previously-selected address
    final prefs = await SharedPreferences.getInstance();
    final savedCity = prefs.getString('milkrun_city') ?? '';
    final savedAddress = prefs.getString('milkrun_address') ?? '';
    final savedFull = prefs.getString('milkrun_full_address') ?? '';
    if (savedCity.isNotEmpty) {
      final zone = detectZoneByCity(savedCity);
      if (zone != null) {
        _applyCity(savedCity);
        _userAddress = savedAddress;
        _userFullAddress = savedFull;
      }
    }

    // 2. Try to auto-detect zone from saved addresses (only if no persisted selection)
    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token != null && _zone == null) {
      final addrNotifier = ref.read(addressProvider.notifier);
      if (!ref.read(addressProvider).hasFetched) {
        await addrNotifier.fetchAddresses(token);
      }
      final addresses = ref.read(addressProvider).addresses;
      if (addresses.isNotEmpty) {
        // Always populate address from first saved address
        final firstAddr = addresses.first;
        _userAddress = firstAddr.addressLine ?? '';
        _userFullAddress = '${firstAddr.addressLine ?? ''}, ${firstAddr.city ?? ''} ${firstAddr.pinCode ?? ''}'.trim();

        // Try all addresses for zone detection
        for (final addr in addresses) {
          final city = addr.city ?? '';
          if (city.isNotEmpty) {
            final zone = detectZoneByCity(city);
            if (zone != null) {
              _applyCity(city);
              _userAddress = addr.addressLine ?? '';
              _userFullAddress = '${addr.addressLine ?? ''}, ${addr.city ?? ''} ${addr.pinCode ?? ''}'.trim();
              break;
            }
          }
        }
        // If no zone found from city, try coordinates from first address
        if (_zone == null) {
          for (final addr in addresses) {
            final lat = addr.deliveryLoc?['lat'] as double?;
            final lon = addr.deliveryLoc?['lon'] as double?;
            if (lat != null && lon != null) {
              final zone = detectZone(lat, lon);
              if (zone != null) {
                _zone = zone;
                _firstDate = getNextDeliveryDateFromDays(zone.deliveryDays);
                _userCity = addr.city ?? zone.cities.first;
                _userAddress = addr.addressLine ?? '';
                _userFullAddress = '${addr.addressLine ?? ''}, ${addr.city ?? ''} ${addr.pinCode ?? ''}'.trim();
                _selectedDate = null;
                break;
              }
            }
          }
        }
      }
      
      // 3. If still no zone, try GPS-based detection
      if (_zone == null) {
        try {
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            var perm = await Geolocator.checkPermission();
            if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
              final pos = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.medium,
              ).timeout(const Duration(seconds: 5));
              final zone = detectZone(pos.latitude, pos.longitude);
              if (zone != null) {
                final geo = await _reverseGeocode(pos.latitude, pos.longitude);
                final city = geo['city']?.isNotEmpty == true ? geo['city']! : zone.cities.first;
                _applyCity(city);
              }
            }
          }
        } catch (_) {
          // GPS fallback failed silently
        }
      }
    }

    if (mounted) {
      setState(() {
        _waterTestProduct = product;
        _loading = false;
      });
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  void _applyCity(String city) {
    final zone = detectZoneByCity(city);
    if (zone != null) {
      _zone = zone;
      _firstDate = getNextDeliveryDateFromDays(zone.deliveryDays);
      _userCity = city;
      _selectedDate = null;
    }
  }

  /// Persist the selected city/address so the dialog remembers on next open
  Future<void> _persistSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('milkrun_city', _userCity ?? '');
    await prefs.setString('milkrun_address', _userAddress);
    await prefs.setString('milkrun_full_address', _userFullAddress);
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  List<DateTime> _getScheduleDates() {
    if (_zone == null) return [];
    const days = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday'];
    final targetDays = _zone!.deliveryDays.map((d) => days.indexOf(d.toLowerCase())).where((i) => i >= 0).toList();
    if (targetDays.isEmpty) return [];
    final dates = <DateTime>[];
    var check = DateTime.now().add(const Duration(days: 1));
    while (dates.length < 8) {
      final currentDay = check.weekday % 7;
      if (targetDays.contains(currentDay)) {
        dates.add(check);
      }
      check = check.add(const Duration(days: 1));
    }
    return dates;
  }

  // ── Address autocomplete ───────────────────────────────────────────────
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
    } catch (_) {
      // Silently fail
    }
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
      // Get place details to extract city via geocode
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
          final components = (results[0]['address_components'] as List?) ?? [];
          final geometry = (results[0]['geometry'] as Map?)?.cast<String, dynamic>() ?? {};
          final location = (geometry['location'] as Map?)?.cast<String, dynamic>() ?? {};

          String streetNumber = '';
          String route = '';
          String city = '';
          String province = '';
          String postal = '';
          String country = '';

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
            } else if (types.contains('administrative_area_level_1')) {
              province = longName;
            } else if (types.contains('postal_code')) {
              postal = longName;
            } else if (types.contains('country')) {
              country = longName;
            }
          }

          final streetLine = [streetNumber, route]
              .where((p) => p.trim().isNotEmpty)
              .join(' ')
              .trim();

          if (city.isNotEmpty) {
            final zone = detectZoneByCity(city);
            if (zone != null) {
              final addressLine = streetLine.isNotEmpty ? streetLine : description.split(',').first.trim();
              final fullAddress = '$addressLine, $city${province.isNotEmpty ? ', $province' : ''}${postal.isNotEmpty ? ' $postal' : ''}';

              if (mounted) {
                setState(() {
                  _applyCity(city);
                  _userAddress = fullAddress;
                  _userFullAddress = fullAddress;
                  _showAddressInput = false;
                  _addressCtrl.clear();
                  _isSearching = false;
                });
              }
              _isSelectingSuggestion = false;
              _persistSelection();

              // Update the backend address
              _updateBackendAddress(
                addressLine: addressLine,
                city: city,
                province: province,
                postal: postal,
                country: country,
                lat: (location['lat'] as num?)?.toDouble(),
                lon: (location['lng'] as num?)?.toDouble(),
              );

              CustomToast.success(msg: 'Found your route');
              return;
            }
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isSearching = false);
    _isSelectingSuggestion = false;
    CustomToast.error(msg: "Your city is not in the delivery zone. We are working on it, but for now, please visit www.retrorouteco.com/home to place an order, and we will ship it to you.");
  }

  /// Update or create the user's address in the backend
  Future<void> _updateBackendAddress({
    required String addressLine,
    required String city,
    required String province,
    required String postal,
    required String country,
    double? lat,
    double? lon,
  }) async {
    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token == null) return;

    final addrNotifier = ref.read(addressProvider.notifier);
    final addresses = ref.read(addressProvider).addresses;

    final deliveryLoc = (lat != null && lon != null)
        ? {'lat': lat, 'lon': lon}
        : null;

    if (addresses.isNotEmpty) {
      // Update the first (primary) address
      final existing = addresses.first;
      await addrNotifier.updateAddress(
        token: token,
        addressId: existing.safeId,
        addressLine: addressLine,
        city: city,
        statess: province,
        country: country.isNotEmpty ? country : 'Canada',
        postalCode: postal,
        phone: existing.mobile ?? '',
        fullName: existing.fullName,
        deliveryLoc: deliveryLoc,
      );
    } else {
      // Create a new address
      await addrNotifier.addAddress(
        token: token,
        addressLine: addressLine,
        city: city,
        statess: province,
        country: country.isNotEmpty ? country : 'Canada',
        postalCode: postal,
        phone: '',
        deliveryLoc: deliveryLoc,
      );
    }
  }

  // ── Address Search (manual) ─────────────────────────────────────────────
  void _handleAddressSearch() {
    final input = _addressCtrl.text.trim();
    if (input.isEmpty) return;
    setState(() => _isSearching = true);
    final zone = detectZoneByCity(input);
    if (zone != null) {
      setState(() {
        _applyCity(input);
        _showAddressInput = false;
        _addressCtrl.clear();
        _isSearching = false;
      });
      _persistSelection();
      CustomToast.success(msg: 'Found your route');
    } else {
      setState(() => _isSearching = false);
      CustomToast.error(msg: "Your city is not in the delivery zone. We are working on it, but for now, please visit www.retrorouteco.com/home to place an order, and we will ship it to you.");
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
        setState(() {
          _applyCity(city);
          _showAddressInput = false;
          _addressCtrl.clear();
          _placeSuggestions = [];
          _showPlaceSuggestions = false;
        });
        _persistSelection();
        CustomToast.success(msg: 'Found your route');
      } else {
        CustomToast.error(msg: "Your city is not in the delivery zone. We are working on it, but for now, please visit www.retrorouteco.com/home to place an order, and we will ship it to you.");
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
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=${lat.toStringAsFixed(6)}&lon=${lng.toStringAsFixed(6)}'
        '&zoom=18&addressdetails=1',
      );
      final res = await http
          .get(uri, headers: {'Accept-Language': 'en'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return {};
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final a = (data['address'] as Map<String, dynamic>?) ?? {};
      final city = (a['city'] as String?) ??
          (a['town'] as String?) ??
          (a['village'] as String?) ??
          (a['municipality'] as String?) ??
          '';
      return {'city': city};
    } catch (_) {
      return {};
    }
  }

  // ── Cart / Booking ────────────────────────────────────────────────────────
  void _handleBookStop() {
    if (_zone == null) return;
    final effectiveDate = _selectedDate ?? _firstDate;
    if (effectiveDate != null) {
      ref.read(selectedDeliveryDateProvider.notifier).state = effectiveDate;
    }
    Navigator.of(context).pop();
    goRouter.go('${AppRoutes.onboarding}?screen=4');
  }

  Future<void> _handleWaterTestFirst(Map<String, dynamic> data) async {
    final comingFromSupplies = data['stopType'] == 'supplies';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(waterTestFromSuppliesKey, comingFromSupplies);

    // Add water test product to cart
    if (_waterTestProduct != null) {
      final cart = ref.read(cartProvider);
      final alreadyIn = cart.items.any((i) => i.product.id == _waterTestProduct!.id);
      if (!alreadyIn) {
        ref.read(cartProvider.notifier).add(_waterTestProduct!, quantity: 1);
        CustomToast.success(msg: 'Water Test added to cart!');
      } else {
        CustomToast.warning(msg: 'Water Test is already in your cart');
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop();

    // Option 1 (supplies + water test): go Home so user can build their crate
    // Option 2 (pure water test): go Cart
    ref.read(bottomNavProvider.notifier).state = comingFromSupplies
        ? BottomNavIndex.home
        : BottomNavIndex.cart;
    goRouter.go(AppRoutes.host);
  }

  Future<void> _handleBringSupplies(Map<String, dynamic> data) async {
    if (!mounted) return;
    Navigator.of(context).pop();
    ref.read(bottomNavProvider.notifier).state = BottomNavIndex.home;
    goRouter.go(AppRoutes.host);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Only render if user is authenticated (mirrors web: if (!isAuthenticated) return null)
    final token = ref.watch(authNotifierProvider).value?.data?.token;
    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Navigator.of(context, rootNavigator: true).maybePop());
      return const SizedBox.shrink();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        constraints: BoxConstraints(maxWidth: 420.w, maxHeight: 0.9.sh),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // ─── Main content ─────────────────────────────────────────
            _buildMainContent(),

            // ─── Close button ─────────────────────────────────────────────
            Positioned(
              top: 8.h,
              right: 8.w,
              child: Material(
                color: AppColors.btnColor,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  onTap: _closeDialog,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Icon(Icons.close, size: 20.sp, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Booking screen (BookMyStopContent embedded) ───────────────────────────
  Widget _buildBookingScreen() {
    final effectiveDate = _selectedDate ?? _firstDate;
    return SizedBox(
      height: 0.85.sh,
      child: BookMyStopContent(
        routeInfo: _zone != null
            ? {
                'zone': _zone,
                'nextDate': effectiveDate,
                'address': _userCity ?? '',
              }
            : null,
        onBack: () => setState(() => _showBookingScreen = false),
        onBringSupplies: _handleBringSupplies,
        onWaterTestFirst: _handleWaterTestFirst,
      ),
    );
  }

  // ── Main milk-run content ─────────────────────────────────────────────────
  Widget _buildMainContent() {
    if (_loading) {
      return SizedBox(
        height: 200.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final effectiveDate = _selectedDate ?? _firstDate;

    return SingleChildScrollView(
      controller: _scrollCtrl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 44.w, 4.h),
            child: Column(
              children: [
                Text(
                  'Find My Milk Run',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Enter your address to see your next run.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // ── Milk Run Card ────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                ],
                color: AppColors.cardBgColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Blue banner
                  Container(
                    color: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Text(
                      'Your Milk Run',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Truck image
                  SizedBox(
                    height: 130.h,
                    child: Image.asset(
                      'assets/images/retro.jpeg',
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Route info + buttons
                  Padding(
                    padding: EdgeInsets.all(14.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Zone info – always show when available
                        if (_zone != null) ...[
                          Row(
                            children: [
                              Icon(Icons.local_shipping_outlined,
                                  size: 16.sp, color: AppColors.btnColor),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  'Your Milk Run: Every ${_zone!.deliveryDaysLabel}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Zone ${_zone!.id}',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900,
                            ),
                          ),
                        ],
                        // Address – always show when available
                        if (_userFullAddress.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14.sp, color: Colors.grey.shade600),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  _userFullAddress,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_zone == null && _userFullAddress.isEmpty) ...[
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Text(
                              'Please add your delivery address to see your milk run',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 12.h),

                        // Book my stop button
                        SizedBox(
                          height: 46.h,
                          child: ElevatedButton(
                            onPressed: _zone != null ? _handleBookStop : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.btnColor,
                              disabledBackgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            child: Text(
                              _zone != null && effectiveDate != null
                                  ? 'Book my stop for ${_fmtDate(effectiveDate)}'
                                  : 'Book my stop',
                              style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 8.h),

                        // See full schedule toggle
                        _outlineBtn(
                          label: _showSchedule ? 'Hide Schedule' : 'See Full Schedule',
                          onTap: () => setState(() => _showSchedule = !_showSchedule),
                        ),

                        // Schedule dates grid
                        if (_showSchedule) ...[
                          _buildScheduleGrid(),
                          // Proceed with earliest date – inside schedule
                          if (_zone != null && _firstDate != null) ...[
                            SizedBox(height: 10.h),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = _firstDate;
                                });
                              },
                              child: Text(
                                'Proceed with earliest date',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.btnColor,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.btnColor,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: 8.h),
                        ],

                        SizedBox(height: 8.h),

                        // Change address toggle
                        _outlineBtn(label: 'Change Address', onTap: (){
                            setState(() {
                              _showAddressInput = !_showAddressInput;
                              if (!_showAddressInput) _addressCtrl.clear();
                            });
                            if (_showAddressInput) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_scrollCtrl.hasClients) {
                                  _scrollCtrl.animateTo(
                                    _scrollCtrl.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              });
                            }
                        }),

                        // Address input
                        if (_showAddressInput) _buildAddressInput(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  // ── Schedule grid ─────────────────────────────────────────────────────────
  Widget _buildScheduleGrid() {
    final dates = _getScheduleDates();
    if (dates.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: Text(
          'Enter your address to see your schedule.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade900),
        ),
      );
    }
    final zone = _zone!;
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10.r,
                height: 10.r,
                decoration: BoxDecoration(
                  color: zone.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                'Zone ${zone.id} — ${zone.deliveryDaysLabel}',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 6.h,
              crossAxisSpacing: 6.w,
              childAspectRatio: 3.0,
            ),
            itemCount: dates.length,
            itemBuilder: (_, idx) {
              final date = dates[idx];
              final isNext = idx == 0;
              final isSelected = _selectedDate != null
                  ? date.toDateString() == _selectedDate!.toDateString()
                  : isNext;
              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color.fromARGB(255, 255, 249, 239)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected
                          ?  AppColors.btnColor
                          : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _fmtDate(date),
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ?  AppColors.btnColor
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (isNext)
                        Text(
                          'Next run',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color:  AppColors.btnColor,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        
        ],
      ),
    );
  }

  // ── Address input row ─────────────────────────────────────────────────────
  Widget _buildAddressInput() {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
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
          // Google Places autocomplete suggestions
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

  // ── Shared outline button ─────────────────────────────────────────────────
  Widget _outlineBtn({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 42.h,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade700),
          foregroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade900
          ),
        ),
      ),
    );
  }
}

extension _DateExt on DateTime {
  String toDateString() => '$year-$month-$day';
}
