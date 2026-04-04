import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:retro_route/config/delivery_zones.dart';
import 'package:retro_route/model/setup_profile_model.dart';
import 'package:retro_route/utils/app_colors.dart';

class DeliverySafetyForm extends StatefulWidget {
  final DeliverySafety data;
  final ValueChanged<DeliverySafety> onChange;

  const DeliverySafetyForm({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<DeliverySafetyForm> createState() => _DeliverySafetyFormState();
}

class _DeliverySafetyFormState extends State<DeliverySafetyForm> {
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB_8gavyfzAIRyMl4eD18iGe_s27fjBSDo',
  );
  static const Color _darkBlue = AppColors.primary;
  static  Color _lightBlue = Color(0xFFF0FDFA);
  static const Color _borderBlue = Color(0xFFBAE6FD);

  late TextEditingController _streetCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _postalCtrl;
  late TextEditingController _dropOffDetailsCtrl;
  late TextEditingController _dogNotesCtrl;
  late TextEditingController _gateCodeCtrl;
  bool _isLoadingLocation = false;
  bool _isSelectingStreetSuggestion = false;
  DeliveryZone? _detectedZone;
  DateTime? _selectedDeliveryDate;
  bool _showDateOptions = false;
  double? _selectedLat;
  double? _selectedLon;

  List<String> _citySuggestions = [];
  List<Map<String, dynamic>> _streetSuggestions = [];
  Timer? _cityDebounce;
  Timer? _streetDebounce;

  DeliverySafety get d => widget.data;

  @override
  void initState() {
    super.initState();
    String streetVal = d.street;
    String cityVal = d.city;
    String postalVal = d.postalCode;

    // If individual fields are empty but combined address exists, parse it
    if (streetVal.isEmpty && cityVal.isEmpty && postalVal.isEmpty && d.address.isNotEmpty) {
      final parts = d.address.split(', ');
      if (parts.length >= 3) {
        streetVal = parts[0];
        cityVal = parts[1];
        postalVal = parts.sublist(2).join(', ');
      } else if (parts.length == 2) {
        streetVal = parts[0];
        cityVal = parts[1];
      } else {
        streetVal = d.address;
      }
    }

    _streetCtrl = TextEditingController(text: streetVal);
    _cityCtrl = TextEditingController(text: cityVal);
    _postalCtrl = TextEditingController(text: _formatPostalInput(postalVal));
    _dropOffDetailsCtrl = TextEditingController(text: d.dropOffDetails);
    _dogNotesCtrl = TextEditingController(text: d.dogSafety.dogNotes);
    _gateCodeCtrl = TextEditingController(text: d.gateEntry.gateCode);

    _cityCtrl.addListener(_onCityChanged);
    _detectedZone = cityVal.trim().isNotEmpty ? detectZoneByCity(cityVal) : null;
  }

  void _onCityChanged() {
    _cityDebounce?.cancel();
    final text = _cityCtrl.text.trim().toLowerCase();
    if (text.isEmpty) {
      if (_citySuggestions.isNotEmpty) setState(() => _citySuggestions = []);
      return;
    }
    _cityDebounce = Timer(const Duration(milliseconds: 250), () {
      final zone = detectZoneByCity(_cityCtrl.text.trim());
      final matches = deliveryZones
          .expand((z) => z.cities)
          .where((c) => c.toLowerCase().contains(text))
          .toList();
      final isExact =
          matches.length == 1 && matches.first.toLowerCase() == text;
      if (mounted) {
        setState(() {
          _citySuggestions = isExact ? [] : matches;
          _detectedZone = zone;
          if (_detectedZone == null) {
            _selectedDeliveryDate = null;
            _showDateOptions = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _cityDebounce?.cancel();
    _streetDebounce?.cancel();
    _cityCtrl.removeListener(_onCityChanged);
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _dropOffDetailsCtrl.dispose();
    _dogNotesCtrl.dispose();
    _gateCodeCtrl.dispose();
    super.dispose();
  }

  void _update(DeliverySafety updated) => widget.onChange(updated);

  Future<void> _useMyLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoadingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack(messenger, 'Location services are disabled. Please enable them.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack(messenger, 'Location permission denied. Please enter your address manually.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack(messenger, 'Location permission permanently denied. Please enter your address manually.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _selectedLat = position.latitude;
      _selectedLon = position.longitude;
      final geo = await _reverseGeocode(position.latitude, position.longitude);
      final street = geo['street'] ?? '';
      final city = geo['city'] ?? '';
      final postal = geo['postal'] ?? '';
      _streetCtrl.text = street;
      _cityCtrl.text = city;
      _postalCtrl.text = _formatPostalInput(postal);
      final zone = city.isNotEmpty ? detectZoneByCity(city) : null;
      setState(() {
        _streetSuggestions = [];
        _detectedZone = zone;
        if (zone == null) {
          _selectedDeliveryDate = null;
          _showDateOptions = false;
        }
      });
      final parts = [street, city, postal].where((p) => p.isNotEmpty).toList();
      _update(d.copyWith(
        street: street,
        city: city,
        postalCode: _formatPostalInput(postal),
        address: parts.join(', '),
      ));
    } catch (_) {
      _showSnack(messenger, 'Unable to get your location. Please enter your address manually.');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<Map<String, String>> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&language=en'
        '&key=$_googleMapsApiKey',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';
        final results = (data['results'] as List?) ?? const [];
        if (status != 'OK' || results.isEmpty) return {};

        final first = (results.first as Map).cast<String, dynamic>();
        final components =
            (first['address_components'] as List?)?.whereType<Map>().toList() ??
                const [];

        String streetNumber = '';
        String route = '';
        String city = '';
        String postal = '';
        String postalSuffix = '';

        for (final c in components) {
          final map = c.cast<String, dynamic>();
          final types = (map['types'] as List?)?.whereType<String>().toList() ??
              const <String>[];
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
          } else if (types.contains('postal_code_suffix')) {
            postalSuffix = longName;
          }
        }

        final street = [streetNumber, route]
            .where((p) => p.trim().isNotEmpty)
            .join(' ')
            .trim();
        if (postalSuffix.isNotEmpty) {
          postal = '$postal-$postalSuffix';
        }

        return {'street': street, 'city': city, 'postal': postal};
      }
    } catch (_) {}
    return {};
  }

  void _showSnack(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  void _onStreetChanged(String value) {
    if (_isSelectingStreetSuggestion) return;

    _streetDebounce?.cancel();
    final query = value.trim();
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

      setState(() {
        _streetSuggestions = next;
      });
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
          (geocode['address_components'] as List?)?.whereType<Map>().toList() ??
          const [];
      final geometry = (geocode['geometry'] as Map?)?.cast<String, dynamic>() ?? {};
      final location =
          (geometry['location'] as Map?)?.cast<String, dynamic>() ?? {};

      String streetNumber = '';
      String route = '';
      String city = '';
      String postal = '';
      String postalSuffix = '';

      for (final c in components) {
        final map = c.cast<String, dynamic>();
        final types = (map['types'] as List?)?.whereType<String>().toList() ??
            const <String>[];
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
        } else if (types.contains('postal_code_suffix')) {
          postalSuffix = longName;
        }
      }

      if (postalSuffix.isNotEmpty) {
        postal = '$postal-$postalSuffix';
      }

      final street =
          [streetNumber, route].where((p) => p.trim().isNotEmpty).join(' ').trim();
      final lat = (location['lat'] as num?)?.toDouble();
      final lon = (location['lng'] as num?)?.toDouble();

      _streetCtrl.text = street.isNotEmpty ? street : _streetCtrl.text;
      _cityCtrl.text = city;
      _postalCtrl.text = _formatPostalInput(postal);

      final parts = [
        _streetCtrl.text,
        _cityCtrl.text,
        _postalCtrl.text,
      ].where((p) => p.trim().isNotEmpty).toList();

      final zone = city.isNotEmpty ? detectZoneByCity(city) : null;
      setState(() {
        _streetSuggestions = [];
        _selectedLat = lat;
        _selectedLon = lon;
        _detectedZone = zone;
        _selectedDeliveryDate = null;
        _showDateOptions = false;
      });

      _update(d.copyWith(
        street: _streetCtrl.text,
        city: city,
        postalCode: _postalCtrl.text,
        address: parts.join(', '),
      ));
    } finally {
      _isSelectingStreetSuggestion = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        _buildHeader(),
        SizedBox(height: 20.h),

        // ── Address ──
        _buildSection(
          color: Colors.white,
          borderColor: Colors.grey[300]!,
          children: [
            _label("Address"),
            _sublabel("We'll match you to the right milk run."),
            SizedBox(height: 10.h),

            // Use my location button
            _isLoadingLocation
                ? Row(
                    children: [
                      SizedBox(
                        width: 14.w,
                        height: 14.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                      SizedBox(width: 8.w),
                      Text('Getting location…',
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, color: Colors.grey.shade500)),
                    ],
                  )
                : GestureDetector(
                    onTap: _useMyLocation,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.my_location_rounded,
                              size: 14.sp, color: Colors.white),
                          SizedBox(width: 6.w),
                          Text('Use my location',
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),

            SizedBox(height: 12.h),

            // Street Address
            _fieldLabel("Street Address"),
            SizedBox(height: 4.h),
            _textField(
              controller: _streetCtrl,
              hint: "123 King St W",
              prefixIcon: Icons.location_on,
              prefixColor: Colors.red,
              onChanged: (v) {
                final parts = [v, _cityCtrl.text, _postalCtrl.text]
                    .where((p) => p.trim().isNotEmpty)
                    .toList();
                _update(d.copyWith(street: v, address: parts.join(', ')));
                _onStreetChanged(v);
              },
            ),
            if (_streetSuggestions.isNotEmpty) ...[
              SizedBox(height: 4.h),
              _streetSuggestionDropdown(
                suggestions: _streetSuggestions,
                onSelect: _selectStreetSuggestion,
                onClose: () => setState(() => _streetSuggestions = []),
              ),
            ],
            SizedBox(height: 10.h),

            // City
            _fieldLabel("City"),
            SizedBox(height: 4.h),
            _textField(
              controller: _cityCtrl,
              hint: "Cornwall",
              onChanged: (v) {
                final parts = [_streetCtrl.text, v, _postalCtrl.text]
                    .where((p) => p.trim().isNotEmpty)
                    .toList();
                _update(d.copyWith(city: v, address: parts.join(', ')));
              },
            ),
            if (_citySuggestions.isNotEmpty) ...
              [
                SizedBox(height: 4.h),
                _citySuggestionDropdown(
                  cities: _citySuggestions,
                  onClose: () => setState(() => _citySuggestions = []),
                  onSelect: (city) {
                    _cityCtrl.text = city;
                    _cityCtrl.selection = TextSelection.collapsed(
                        offset: city.length);
                    final parts = [_streetCtrl.text, city, _postalCtrl.text]
                        .where((p) => p.trim().isNotEmpty)
                        .toList();
                    _update(d.copyWith(city: city, address: parts.join(', ')));
                    setState(() => _citySuggestions = []);
                  },
                ),
              ],
            SizedBox(height: 10.h),

            // Postal Code
            _fieldLabel("Postal Code"),
            SizedBox(height: 4.h),
            _textField(
              controller: _postalCtrl,
              hint: "K6V 1B1",
              onChanged: (v) {
                final formatted = _formatPostalInput(v);
                if (_postalCtrl.text != formatted) {
                  _postalCtrl.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
                final parts = [_streetCtrl.text, _cityCtrl.text, formatted]
                    .where((p) => p.trim().isNotEmpty)
                    .toList();
                _update(d.copyWith(postalCode: formatted, address: parts.join(', ')));
              },
            ),
            if (_detectedZone != null) ...[
              SizedBox(height: 10.h),
              _detectedZoneCard(),
            ] else if (_cityCtrl.text.trim().length >= 3 && _citySuggestions.isEmpty) ...[
              SizedBox(height: 10.h),
              _outOfAreaCard(),
            ],
            if (_selectedLat != null && _selectedLon != null) ...[
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  'Latitude: ${_selectedLat!.toStringAsFixed(6)}  |  Longitude: ${_selectedLon!.toStringAsFixed(6)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
            SizedBox(height: 10.h),

            Row(
              children: [
                _smallLabel("Label:"),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: d.addressLabel.isEmpty ? 'Home' : d.addressLabel,
                      isDense: true,
                      style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[700]),
                      items: ['Home', 'Work', 'Other']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => _update(d.copyWith(addressLabel: v ?? 'Home')),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // ── Drop-off spot ──
        _buildSection(
          color: Colors.orange[50]!,
          borderColor: Colors.orange[200]!,
          children: [
            _label("Drop-off spot"),
            _sublabel("Choose a clear place so we can be in and out fast."),
            SizedBox(height: 8.h),
            _smallLabel("Where should we leave your order?"),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                'Beside the pool',
                'Beside the hot tub',
                'Inside shed',
                'Front door / porch',
                'By the gate',
                'Other',
              ]
                  .map((opt) => _chip(
                        label: opt,
                        selected: d.dropOffSpot == opt,
                        onTap: () => _update(d.copyWith(dropOffSpot: opt)),
                    activeColor: AppColors.primary,
                      ))
                  .toList(),
            ),
            SizedBox(height: 10.h),
            _textField(
              controller: _dropOffDetailsCtrl,
              hint: "Drop-off details (optional)",
              onChanged: (v) => _update(d.copyWith(dropOffDetails: v)),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // ── Backyard access ──
        _buildSection(
          color: Colors.grey[50]!,
          borderColor: Colors.grey[300]!,
          children: [
            _label("Backyard access"),
            _sublabel(
                "We only enter backyards with permission and safe conditions."),
            SizedBox(height: 8.h),
            _smallLabel("Can we enter your backyard for delivery?"),
            SizedBox(height: 8.h),
            ..._backyardOptions(),
            if (d.backyardAccess == 'yes') ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _lightBlue,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16.sp, color: _darkBlue),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        "Backyard access is required for water testing. We'll need to reach your pool or hot tub to collect a water sample.",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: _darkBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              _checkboxTile(
                value: d.backyardPermission,
                label:
                    "I give permission to enter my backyard during the delivery window.",
                color: AppColors.primary,
                onChanged: (v) =>
                    _update(d.copyWith(backyardPermission: v ?? false)),
              ),
            ],
            if (d.backyardAccess == 'no') ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16.sp, color: Colors.orange[700]),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        "Without backyard access, we won't be able to test your water. Deliveries will be left at your front door only.",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (d.backyardAccess == 'onlyIfHome') ...[
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16.sp, color: Colors.blue[700]),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        "We'll only enter your backyard and perform water testing when you're home. If you're not available, we'll leave your order at the front door.",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 16.h),

        // ── Dog safety (read-only in profile) ──
        IgnorePointer(
          ignoring: true,
          child: Opacity(
            opacity: 0.6,
            child: _buildSection(
          color: Colors.orange[50]!,
          borderColor: Colors.orange[200]!,
          children: [
            _label("Dog safety (required)"),
            _sublabel("This step protects your delivery and our driver."),
            SizedBox(height: 8.h),
            _smallLabel(
                "Are there dogs that could access the yard during delivery?"),
            SizedBox(height: 8.h),
            Row(
              children: [
                _chip(
                  label: "No",
                  selected: !d.dogSafety.hasDogs,
                  onTap: () => _update(d.copyWith(
                      dogSafety: d.dogSafety.copyWith(hasDogs: false))),
                  activeColor: Colors.grey,
                ),
                SizedBox(width: 8.w),
                _chip(
                  label: "Yes",
                  selected: d.dogSafety.hasDogs,
                  onTap: () => _update(d.copyWith(
                      dogSafety: d.dogSafety.copyWith(hasDogs: true))),
                  activeColor: Colors.orange,
                ),
              ],
            ),
            if (d.dogSafety.hasDogs) ...[
              SizedBox(height: 12.h),
              _smallLabel(
                  "During your delivery window, will the dog be inside or securely contained?"),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _chip(
                    label: "Yes (guaranteed)",
                    selected: d.dogSafety.dogsContained == 'yes',
                    onTap: () => _update(d.copyWith(
                        dogSafety:
                            d.dogSafety.copyWith(dogsContained: 'yes'))),
                    activeColor: AppColors.primary,
                  ),
                  _chip(
                    label: "No",
                    selected: d.dogSafety.dogsContained == 'no',
                    onTap: () => _update(d.copyWith(
                        dogSafety:
                            d.dogSafety.copyWith(dogsContained: 'no'))),
                    activeColor: Colors.grey,
                  ),
                  _chip(
                    label: "Not sure",
                    selected: d.dogSafety.dogsContained == 'notSure',
                    onTap: () => _update(d.copyWith(
                        dogSafety:
                            d.dogSafety.copyWith(dogsContained: 'notSure'))),
                    activeColor: Colors.grey,
                  ),
                ],
              ),
              if (d.dogSafety.dogsContained == 'no' ||
                  d.dogSafety.dogsContained == 'notSure') ...[
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Safety Warning",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "Due to loose animals in the yard, we will automatically revert to front door delivery and will be unable to perform the scheduled water test.",
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (d.dogSafety.dogsContained == 'yes') ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Safety rule",
                          style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[800])),
                      SizedBox(height: 4.h),
                      Text(
                          "If a dog is loose when we arrive, we'll switch to front-door drop-off or reschedule.",
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, color: Colors.grey[700])),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                _smallLabel("Dog notes (optional)"),
                SizedBox(height: 6.h),
                _textField(
                  controller: _dogNotesCtrl,
                  hint: "e.g., please keep gate closed behind you",
                  onChanged: (v) => _update(d.copyWith(
                      dogSafety: d.dogSafety.copyWith(dogNotes: v))),
                ),
                SizedBox(height: 10.h),
                _checkboxTile(
                  value: d.dogSafety.petsSecuredConfirm,
                  label:
                      "I confirm pets will be secured during the delivery window.",
                  color: Colors.orange,
                  onChanged: (v) => _update(d.copyWith(
                      dogSafety: d.dogSafety
                          .copyWith(petsSecuredConfirm: v ?? false))),
                ),
              ],
            ],
          ],
        ),
        ),
        ),
        SizedBox(height: 16.h),

        // ── Gate & entry details ──
        if (d.backyardAccess == 'yes') ...[
          _buildSection(
            color: _lightBlue,
            borderColor: _borderBlue,
            children: [
              _label("Gate & entry details"),
              _sublabel("Shown only when backyard drop-off is selected."),
              SizedBox(height: 8.h),
              _smallLabel("How do we get in?"),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  {'value': 'noGate', 'label': 'No gate (open access)'},
                  {'value': 'unlocked', 'label': 'Gate is unlocked'},
                  {'value': 'codeLock', 'label': 'Gate has a code/lock'},
                ]
                    .map((opt) => _chip(
                          label: opt['label']!,
                          selected:
                              d.gateEntry.accessMethod == opt['value'],
                          onTap: () => _update(d.copyWith(
                              gateEntry: d.gateEntry
                                  .copyWith(accessMethod: opt['value']))),
                        activeColor: AppColors.primary,
                        ))
                    .toList(),
              ),
              SizedBox(height: 12.h),
              _smallLabel("Gate location"),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  {'value': 'left', 'label': 'Left side'},
                  {'value': 'right', 'label': 'Right side'},
                  {'value': 'back', 'label': 'Back'},
                  {'value': 'other', 'label': 'Other'},
                ]
                    .map((opt) => _chip(
                          label: opt['label']!,
                          selected:
                              d.gateEntry.gateLocation == opt['value'],
                          onTap: () => _update(d.copyWith(
                              gateEntry: d.gateEntry
                                  .copyWith(gateLocation: opt['value']))),
                        activeColor: AppColors.primary,
                        ))
                    .toList(),
              ),
              if (d.gateEntry.accessMethod == 'codeLock') ...[
                SizedBox(height: 10.h),
                _textField(
                  controller: _gateCodeCtrl,
                  hint: "Gate code / lock combo (optional)",
                  onChanged: (v) => _update(d.copyWith(
                      gateEntry: d.gateEntry.copyWith(gateCode: v))),
                ),
              ],
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: _borderBlue,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14.sp, color: _darkBlue),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text("Please re-latch gate behind you",
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, color: _darkBlue)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],

        // ── Contact & proof ──
        _buildSection(
          color: Colors.white,
          borderColor: Colors.grey[300]!,
          children: [
            _label("Contact & proof"),
            _sublabel("If there's an issue, we'll handle it quickly."),
            SizedBox(height: 8.h),
            _smallLabel("If we have a quick question at your stop..."),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                {'value': 'emailNotification', 'label': 'Email/App notification'},
                {'value': 'callMe', 'label': 'Call me'},
                {'value': 'onlyIfNecessary', 'label': 'Only if necessary'},
              ]
                  .map((opt) => _chip(
                        label: opt['label']!,
                        selected: d.contactPreference == opt['value'],
                        onTap: () =>
                            _update(d.copyWith(contactPreference: opt['value'])),
                        activeColor: AppColors.primary,
                      ))
                  .toList(),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _lightBlue,
                border: Border.all(color: _borderBlue),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16.sp, color: _darkBlue),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "You'll be notified when the driver is on the way to your address.",
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: _darkBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Shared Widgets ─────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: 0.5,
              minHeight: 6,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          SizedBox(height: 14.h),
          Text("Delivery & safety",
              style: GoogleFonts.inter(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          SizedBox(height: 4.h),
          Text(
              "We'll only enter backyards when it's safe. This keeps everyone protected.",
              style: GoogleFonts.inter(
                  fontSize: 16.sp, color: Colors.white.withValues(alpha: 0.9))),
        ],
      ),
    );
  }

  Widget _detectedZoneCard() {
    final zone = _detectedZone;
    if (zone == null) return const SizedBox.shrink();
    final cityText = _cityCtrl.text.trim();
    final selected = _selectedDeliveryDate ?? _nextDeliveryDate(zone.deliveryDays);
    final options = _nextDeliveryDates(zone.deliveryDays, count: 4);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: 
        [AppColors.primary, AppColors.primary]),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, 
              color: Colors.white, size: 18.sp),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Your milk run: Every ${zone.deliveryDaysLabel}',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cityText.isNotEmpty
                      ? 'Zone ${zone.id} - $cityText'
                      : 'Zone ${zone.id}',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Delivery Day: ${_formatDate(selected)}',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a different date?',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (_selectedDeliveryDate != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'Selected: ${_formatDate(_selectedDeliveryDate!)}',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: const Color(0xFFFDE68A),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showDateOptions = !_showDateOptions),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 16.sp, color: Colors.white),
                      SizedBox(width: 4.w),
                      Text(
                        _showDateOptions ? 'Close' : 'Pick Date',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showDateOptions) ...[
            SizedBox(height: 8.h),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 6.w) / 2;
                return Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: options.map((date) {
                    final active = _sameDate(date, selected);
                    return SizedBox(
                      width: itemWidth,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedDeliveryDate = date;
                          _showDateOptions = false;
                        }),
                        child: Container(
                          width: double.infinity,
                          padding:
                              EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.btnColor
                                : Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            _formatDate(date),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
          if (_selectedDeliveryDate != null) ...
            [
              SizedBox(height: 6.h),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedDeliveryDate = null;
                }),
                child: Text(
                  'Proceed with earliest date',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0xFFFDE68A),
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFFFDE68A),
                  ),
                ),
              ),
            ],
          SizedBox(height: 8.h),
          Text(
            'Free backyard delivery · Water testing available on request.',
            style: GoogleFonts.inter(fontSize: 14.sp, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _outOfAreaCard() {
    return Container(
      width: double.infinity,
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
                  text: "www.retrorouteco.com/home",
                  style: const TextStyle(
                    color: Color(0xFFE8751A),
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    launchUrl(Uri.parse('https://www.retrorouteco.com/home'), mode: LaunchMode.externalApplication);
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

  DateTime _nextDeliveryDate(List<String> deliveryDays) {
    return getNextDeliveryDateFromDays(deliveryDays);
  }

  List<DateTime> _nextDeliveryDates(List<String> deliveryDays, {int count = 4}) {
    const dayNames = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday'];
    final targetDays = deliveryDays.map((d) => dayNames.indexOf(d.toLowerCase())).where((i) => i >= 0).toList();
    final dates = <DateTime>[];
    var check = DateTime.now().add(const Duration(days: 1));
    while (dates.length < count) {
      if (targetDays.contains(check.weekday % 7)) dates.add(check);
      check = check.add(const Duration(days: 1));
    }
    return dates;
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatPostalInput(String input) {
    final cleaned = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final clipped = cleaned.length > 6 ? cleaned.substring(0, 6) : cleaned;
    if (clipped.length <= 3) return clipped;
    return '${clipped.substring(0, 3)} ${clipped.substring(3)}';
  }

  Widget _buildSection({
    required Color color,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: Colors.grey[900]));

  Widget _sublabel(String text) => Padding(
        padding: EdgeInsets.only(top: 2.h),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 14.sp, color: Colors.grey[500])),
      );

  Widget _smallLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700]));

  Widget _fieldLabel(String text) => Text(text,
      style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700]));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    Color? prefixColor,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 13.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey[400]),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 16.sp, color: prefixColor)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: selected ? activeColor : Colors.grey[300]!,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: selected ? activeColor : Colors.grey[600],
            )),
      ),
    );
  }

  List<Widget> _backyardOptions() {
    final options = [
      {
        'value': 'yes',
        'label': 'Yes — backyard drop-off',
        'desc': "We'll enter and leave at your water."
      },
      {
        'value': 'no',
        'label': 'No — front door only',
        'desc': "No backyard access needed."
      },
      {
        'value': 'onlyIfHome',
        'label': "Only if I'm home",
        'desc': ''
      },
    ];

    return options
        .map((opt) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: GestureDetector(
                onTap: () =>
                    _update(d.copyWith(backyardAccess: opt['value']!)),
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: d.backyardAccess == opt['value']
                        ? _lightBlue
                        : Colors.white,
                    border: Border.all(
                      color: d.backyardAccess == opt['value']
                          ? AppColors.primary
                          : Colors.grey[300]!,
                      width: d.backyardAccess == opt['value'] ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt['label']!,
                          style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[900])),
                      if (opt['desc']!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Text(opt['desc']!,
                              style: GoogleFonts.inter(
                                  fontSize: 14.sp, color: Colors.grey[500])),
                        ),
                    ],
                  ),
                ),
              ),
            ))
        .toList();
  }

  Widget _checkboxTile({
    required bool value,
    required String label,
    required Color color,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18.w,
            height: 18.h,
            child: Transform.scale(
              scale: 0.7,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: color,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.9))),
          ),
        ],
      ),
    );
  }

  Widget _citySuggestionDropdown({
    required List<String> cities,
    required void Function(String) onSelect,
    VoidCallback? onClose,
  }) {
    return Container(
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
                              fontSize: 14.sp, color: Colors.grey.shade800),
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

  Widget _streetSuggestionDropdown({
    required List<Map<String, dynamic>> suggestions,
    required void Function(Map<String, dynamic>) onSelect,
    VoidCallback? onClose,
  }) {
    return Container(
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
                            fontSize: 14.sp,
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
