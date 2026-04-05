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
import 'package:retro_route/components/custom_textfield.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view_model/selected_delivery_date_provider.dart';
import 'package:retro_route/view_model/address_view_model/selected_delivery_address_view_model.dart';

class ChangeDeliveryDateScreen extends ConsumerStatefulWidget {
  const ChangeDeliveryDateScreen({super.key});

  @override
  ConsumerState<ChangeDeliveryDateScreen> createState() =>
      _ChangeDeliveryDateScreenState();
}

class _ChangeDeliveryDateScreenState
    extends ConsumerState<ChangeDeliveryDateScreen> {
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB_8gavyfzAIRyMl4eD18iGe_s27fjBSDo',
  );

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController(text: 'Ontario');
  final _postalCtrl = TextEditingController();

  /// Formats phone as "111 111 1111" (3-3-4 with spaces).
  String _formatPhoneNumber(String input) {
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');
    final clipped = digits.length > 10 ? digits.substring(0, 10) : digits;
    if (clipped.length <= 3) return clipped;
    if (clipped.length <= 6) {
      return '${clipped.substring(0, 3)} ${clipped.substring(3)}';
    }
    return '${clipped.substring(0, 3)} ${clipped.substring(3, 6)} ${clipped.substring(6)}';
  }

  DeliveryZone? _zone;
  DateTime? _customDate;
  bool _useCustomDate = false;
  bool _showDatePicker = false;
  bool _loading = false;

  // Google Places autocomplete
  List<Map<String, dynamic>> _streetSuggestions = [];
  Timer? _streetDebounce;
  bool _isSelectingSuggestion = false;
  bool _isUsingMyLocation = false;

  @override
  void initState() {
    super.initState();
    _streetCtrl.addListener(_onStreetChanged);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCtrl.dispose();
    _streetDebounce?.cancel();
    super.dispose();
  }

  // ── Zone detection ──────────────────────────────────────────────────────
  void _detectZone() {
    final city = _cityCtrl.text.trim();
    if (city.isEmpty) {
      setState(() => _zone = null);
      return;
    }
    final zone = detectZoneByCity(city);
    setState(() => _zone = zone);
  }

  // ── Use my location ─────────────────────────────────────────────────────
  Future<void> _useMyLocation() async {
    _isUsingMyLocation = true;
    setState(() { _loading = true; _streetSuggestions = []; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        CustomToast.error(msg: 'Location services are disabled');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          CustomToast.error(msg: 'Location permission denied');
          return;
        }
      }
      if (perm == LocationPermission.deniedForever) {
        CustomToast.error(msg: 'Permission permanently denied. Enable in Settings.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final addr = await _reverseGeocode(pos.latitude, pos.longitude);
      if (mounted) {
        _streetCtrl.text = addr['street'] ?? '';
        _cityCtrl.text = addr['city'] ?? '';
        _postalCtrl.text = addr['postal'] ?? '';
      }
      final city = addr['city'] ?? '';
      DeliveryZone? z = city.isNotEmpty ? detectZoneByCity(city) : null;
      z ??= detectZone(pos.latitude, pos.longitude);
      setState(() { _zone = z; _streetSuggestions = []; });
    } catch (_) {
      CustomToast.error(msg: 'Unable to get your location');
    } finally {
      _isUsingMyLocation = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Reverse geocode (Google Maps) ────────────────────────────────────────
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

      return {
        'street': [streetNumber, route].where((p) => p.trim().isNotEmpty).join(' ').trim(),
        'city': city,
        'postal': postal,
      };
    } catch (_) {
      return {};
    }
  }

  // ── Street autocomplete (Google Places) ──────────────────────────────────
  void _onStreetChanged() {
    if (_isSelectingSuggestion || _isUsingMyLocation) return;
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

  // ── Geocode by place ID ──────────────────────────────────────────────────
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

  // ── Select street suggestion ─────────────────────────────────────────────
  Future<void> _selectStreetSuggestion(Map<String, dynamic> suggestion) async {
    final placeId = suggestion['placeId'] as String? ?? '';
    final description = suggestion['description'] as String? ?? '';

    _isSelectingSuggestion = true;
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
      });
    } finally {
      _isSelectingSuggestion = false;
    }
  }

  // ── Date helpers ────────────────────────────────────────────────────────
  List<DateTime> _getAvailableDates(DeliveryZone zone) {
    const dayNames = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday',
    ];
    final targetDays = zone.deliveryDays
        .map((d) => dayNames.indexOf(d))
        .where((i) => i >= 0)
        .toList();
    final dates = <DateTime>[];
    var check = DateTime.now().add(const Duration(days: 1));
    while (dates.length < 4) {
      final currentDay = check.weekday % 7;
      if (targetDays.contains(currentDay)) dates.add(check);
      check = check.add(const Duration(days: 1));
    }
    return dates;
  }

  String _fmtDateFull(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${wd[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}';
  }

  // ── Save ────────────────────────────────────────────────────────────────
  void _save() {
    if (_zone == null) {
      CustomToast.error(msg: 'Enter a city in our delivery zone');
      return;
    }
    final deliveryDate = _useCustomDate && _customDate != null
        ? _customDate!
        : getNextDeliveryDateFromDays(_zone!.deliveryDays);
    ref.read(selectedDeliveryDateProvider.notifier).state = deliveryDate;
    saveSelectedDeliveryDate(deliveryDate);
    // Save per-address date
    final selAddr = ref.read(selectedDeliveryAddressProvider);
    final addrId = selAddr?.safeId ?? '';
    if (addrId.isNotEmpty) saveAddressDeliveryDate(addrId, deliveryDate);
    CustomToast.success(msg: 'Delivery date updated');
    Navigator.pop(context);
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Change Delivery Date',
            style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Name & Number Card ──────────────────────────────────────
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: _cardDeco(),
              child: Column(
                children: [
                  _inputField(_nameCtrl, 'Full Name', Icons.person_outline),
                  SizedBox(height: 14.h),
                  CustomTextField(
                    controller: _phoneCtrl,
                    hintText: "Phone Number",
                    width: double.infinity,
                    hintFontSize: 18,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone,
                    borderRadius: 16,
                    fillColor: Colors.grey[50],
                    onChanged: (v) {
                      final formatted = _formatPhoneNumber(v);
                      if (_phoneCtrl.text != formatted) {
                        _phoneCtrl.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please enter your phone number";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // ── Delivery Address Card ───────────────────────────────────
            Text('Delivery Address',
                style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900])),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: _cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Street Address
                  _inputField(
                    _streetCtrl,
                    'Street Address',
                    Icons.home_outlined,
                  ),
                  // Street suggestions
                  if (_streetSuggestions.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _streetSuggestions.map((item) {
                            final text = item['description'] as String? ?? '';
                            return InkWell(
                              onTap: () => _selectStreetSuggestion(item),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 10.h),
                                child: Row(children: [
                                  Icon(Icons.pin_drop_outlined,
                                      size: 16.sp, color: Colors.grey),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(text,
                                        style: GoogleFonts.inter(
                                            fontSize: 13.sp),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ]),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  SizedBox(height: 14.h),

                  // City & Province side by side
                  Row(
                    children: [
                      Expanded(
                        child: _inputField(
                          _cityCtrl, 'City', Icons.location_city_outlined,
                          onChanged: (_) => _detectZone(),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _inputField(
                          _provinceCtrl, 'Province', Icons.map_outlined,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Postal Code
                  _inputField(
                      _postalCtrl, 'Postal Code', Icons.local_post_office_outlined),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // ── Locate Me button ────────────────────────────────────────
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
                        ? SizedBox(
                            width: 16.w,
                            height: 16.h,
                            child: const CircularProgressIndicator(
                                strokeWidth: 2))
                        : Icon(Icons.my_location,
                            size: 16.sp, color: AppColors.btnColor),
                    SizedBox(width: 6.w),
                    Text('Locate me',
                        style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: AppColors.btnColor,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // ── Delivery Zone Card (teal) ───────────────────────────────
            if (_zone != null) _buildZoneCard(),

            SizedBox(height: 24.h),

            // ── Save Button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.btnColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                  elevation: 2,
                ),
                child: Text('Save',
                    style: GoogleFonts.inter(
                        fontSize: 16.sp, fontWeight: FontWeight.w700)),
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  // ── Teal Zone Card ────────────────────────────────────────────────────
  Widget _buildZoneCard() {
    final zone = _zone!;
    final deliveryDate = _useCustomDate && _customDate != null
        ? _customDate!
        : getNextDeliveryDateFromDays(zone.deliveryDays);

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
          // ── Heading
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
                      color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // ── Zone + address frosted panel
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zone ${zone.id}',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                if (_streetCtrl.text.trim().isNotEmpty ||
                    _cityCtrl.text.trim().isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Row(children: [
                      Icon(Icons.location_on_outlined,
                          size: 13.sp, color: Colors.white70),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          [
                            _streetCtrl.text.trim(),
                            _cityCtrl.text.trim(),
                            _postalCtrl.text.trim()
                          ].where((s) => s.isNotEmpty).join(', '),
                          style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ),
                SizedBox(height: 4.h),
                Row(children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 12, color: Colors.amber.shade200),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      'Next Delivery: ${_fmtDateFull(deliveryDate)}',
                      style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade200),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          SizedBox(height: 8.h),

          // ── Date picker frosted panel
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
                          Text('Choose a different date?',
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white)),
                          if (_useCustomDate && _customDate != null)
                            Text('Selected: ${_fmtDateFull(_customDate!)}',
                                style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: const Color(0xFFfde68a))),
                        ]),
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
                        child: Row(children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 16.sp, color: Colors.white),
                          SizedBox(width: 4.w),
                          Text(_showDatePicker ? 'Close' : 'Pick Date',
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ]),
                      ),
                    ),
                  ],
                ),
                // Date grid
                if (_showDatePicker) ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select your preferred delivery date:',
                            style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800)),
                        SizedBox(height: 8.h),
                        LayoutBuilder(builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth - 6.w) / 2;
                          return Wrap(
                            spacing: 6.w,
                            runSpacing: 6.h,
                            children:
                                _getAvailableDates(zone).map((date) {
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
                                            BorderRadius.circular(8.r)),
                                    child: Text(_fmtDateFull(date),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade700)),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
                // Proceed with earliest
                if (_useCustomDate && _customDate != null) ...[
                  SizedBox(height: 6.h),
                  GestureDetector(
                    onTap: () => setState(
                        () { _customDate = null; _useCustomDate = false; }),
                    child: Text('Proceed with earliest date',
                        style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: const Color(0xFFfde68a),
                            decorationColor: const Color(0xFFfde68a),
                            decoration: TextDecoration.underline)),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Text(
              'Free backyard delivery · Water testing available on request.',
              style: GoogleFonts.inter(
                  fontSize: 14.sp, color: Colors.amber.shade200)),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      );

  Widget _inputField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    void Function(String)? onChanged,
    String? hintText,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        SizedBox(height: 4.h),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          onChanged: onChanged,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: GoogleFonts.inter(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hintText ?? label,
            hintStyle: GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey),
            prefixIcon: Icon(icon, size: 20.sp, color: Colors.grey),
            counterText: '',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(
                    color: Color(0xFF0284c7), width: 1.5)),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }
}
