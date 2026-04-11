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
import 'package:retro_route/utils/app_toast.dart';

const _dropOffOptions = [
  'Beside the pool',
  'Beside the hot tub',
  'Inside shed',
  'Front door / porch',
  'By the gate',
  'Other',
];

const _backyardOptions = [
  {
    'value': 'yes',
    'label': 'Yes — backyard drop-off',
    'desc': "We'll enter and leave at your water.",
  },
  {
    'value': 'no',
    'label': 'No — front door only',
    'desc': 'No backyard access needed.',
  },
  {'value': 'onlyIfHome', 'label': "Only if I'm home", 'desc': ''},
];

const _gateAccess = [
  {'value': 'noGate', 'label': 'No gate'},
  {'value': 'unlocked', 'label': 'Gate is unlocked'},
  {'value': 'codeLock', 'label': 'Gate has a code/lock'},
];

const _gateLocations = ['Left side', 'Right side', 'Back', 'Other'];

const _contactOptions = [
  {'value': 'emailNotification', 'label': 'Email/App notification'},
  {'value': 'callMe', 'label': 'Call me'},
];

class DeliverySafetySection extends StatefulWidget {
  final DeliverySafety data;
  final ValueChanged<DeliverySafety> onChange;

  const DeliverySafetySection({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<DeliverySafetySection> createState() => DeliverySafetySectionState();
}

class DeliverySafetySectionState extends State<DeliverySafetySection> {
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB_8gavyfzAIRyMl4eD18iGe_s27fjBSDo',
  );
  static const Color _primaryLight = Color(0xFFF0FDFA);
  static const Color _primaryBorder = Color(0xFFBAE6FD);
  static const Color _primaryDark = AppColors.primary;
  static const Color _primarySoftText = Color(0xE6FFFFFF);

  late TextEditingController _streetCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _postalCtrl;
  late TextEditingController _dropOffDetailsCtrl;
  late TextEditingController _dogNotesCtrl;
  late TextEditingController _gateCodeCtrl;
  late TextEditingController _gateLocationOtherCtrl;
  bool _isLoadingLocation = false;
  bool _isSelectingStreetSuggestion = false;
  List<String> _citySuggestions = [];
  List<Map<String, dynamic>> _streetSuggestions = [];
  Timer? _cityDebounce;
  Timer? _streetDebounce;
  DeliveryZone? _detectedZone;
  DateTime? _selectedDeliveryDate;
  bool _showDateOptions = false;
  double? _selectedLat;
  double? _selectedLon;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    String streetVal = widget.data.street;
    String cityVal = widget.data.city;
    String postalVal = widget.data.postalCode;

    // If individual fields are empty but combined address exists, parse it
    if (streetVal.isEmpty &&
        cityVal.isEmpty &&
        postalVal.isEmpty &&
        widget.data.address.isNotEmpty) {
      final parts = widget.data.address.split(', ');
      if (parts.length >= 3) {
        streetVal = parts[0];
        cityVal = parts[1];
        postalVal = parts.sublist(2).join(', ');
      } else if (parts.length == 2) {
        streetVal = parts[0];
        cityVal = parts[1];
      } else {
        streetVal = widget.data.address;
      }
    }

    _streetCtrl = TextEditingController(text: streetVal);
    _cityCtrl = TextEditingController(text: cityVal);
    _postalCtrl = TextEditingController(text: postalVal);
    _dropOffDetailsCtrl = TextEditingController(
      text: widget.data.dropOffDetails,
    );
    _dogNotesCtrl = TextEditingController(text: widget.data.dogSafety.dogNotes);
    _gateCodeCtrl = TextEditingController(text: widget.data.gateEntry.gateCode);
    _gateLocationOtherCtrl = TextEditingController(text: widget.data.gateEntry.gateLocationOther);

    if (cityVal.trim().isNotEmpty) {
      _detectedZone = detectZoneByCity(cityVal);
    }
  }

  @override
  void dispose() {
    _cityDebounce?.cancel();
    _streetDebounce?.cancel();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _dropOffDetailsCtrl.dispose();
    _dogNotesCtrl.dispose();
    _gateCodeCtrl.dispose();
    _gateLocationOtherCtrl.dispose();
    super.dispose();
  }

  void _update(DeliverySafety Function(DeliverySafety) updater) {
    if (_validationError != null) {
      setState(() => _validationError = null);
    }
    widget.onChange(updater(widget.data));
  }

  Future<void> _useMyLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled. Please enable them.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Location permission denied. Please enter your address manually.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission permanently denied. Please enter your address manually.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _selectedLat = position.latitude;
      _selectedLon = position.longitude;

      final geo = await _reverseGeocode(position.latitude, position.longitude);
      final street = geo['street'] ?? '';
      final city = geo['city'] ?? '';
      final postal = geo['postal'] ?? '';

      _streetCtrl.text = street;
      _cityCtrl.text = city;
      _postalCtrl.text = postal;

      final zone = city.isNotEmpty ? detectZoneByCity(city) : null;
      setState(() {
        _streetSuggestions = [];
        _detectedZone = zone;
        _selectedDeliveryDate = null;
        _showDateOptions = false;
      });

      final parts = [street, city, postal].where((p) => p.isNotEmpty).toList();
      final fullAddress = parts.join(', ');
      _update(
        (s) => s.copyWith(
          street: street,
          city: city,
          postalCode: postal,
          address: fullAddress,
        ),
      );
    } catch (e) {
      _showSnack('Unable to get your location. Please enter your address manually.');
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
          final types =
              (map['types'] as List?)?.whereType<String>().toList() ??
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

        final street =
            [streetNumber, route].where((p) => p.trim().isNotEmpty).join(' ').trim();
        if (postalSuffix.isNotEmpty) {
          postal = '$postal-$postalSuffix';
        }
        return {'street': street, 'city': city, 'postal': postal};
      }
    } catch (_) {}
    return {};
  }

  void _showSnack(String message) {
    CustomToast.error(msg: message);
  }

  /// Called by the parent just before navigating to step 2.
  /// Reads all text controller values into [current] and returns the updated copy.
  DeliverySafety flushToData(DeliverySafety current) {
    final parts = [
      _streetCtrl.text,
      _cityCtrl.text,
      _postalCtrl.text,
    ].where((p) => p.trim().isNotEmpty).toList();
    return current.copyWith(
      street: _streetCtrl.text,
      city: _cityCtrl.text,
      postalCode: _postalCtrl.text,
      address: parts.join(', '),
      dropOffDetails: _dropOffDetailsCtrl.text,
      dogSafety: current.dogSafety.copyWith(dogNotes: _dogNotesCtrl.text),
      gateEntry: current.gateEntry.copyWith(
        gateCode: _gateCodeCtrl.text,
        gateLocationOther: _gateLocationOtherCtrl.text,
      ),
    );
  }

  /// Validates required step-1 fields and selections.
  /// Returns true only when the section is complete.
  bool validateSelection() {
    final data = flushToData(widget.data);
    widget.onChange(data);

    // Address validation skipped — collected later, not during onboarding
    if (data.dropOffSpot.trim().isEmpty) {
      setState(() => _validationError = 'dropoff');
      _showSnack('Please select a drop-off spot.');
      return false;
    }
    if (data.backyardAccess.trim().isEmpty) {
      setState(() => _validationError = 'backyard');
      _showSnack('Please choose backyard access preference.');
      return false;
    }

    if (data.backyardAccess == 'yes') {
      if (!data.backyardPermission) {
        setState(() => _validationError = 'backyard');
        _showSnack('Please confirm backyard entry permission.');
        return false;
      }
      if (data.gateEntry.accessMethod.trim().isEmpty) {
        setState(() => _validationError = 'gate');
        _showSnack('Please select how we get in.');
        return false;
      }
      if (data.gateEntry.gateLocation.trim().isEmpty) {
        setState(() => _validationError = 'gate');
        _showSnack('Please select gate location.');
        return false;
      }
    }

    if (data.dogSafety.hasDogs && data.dogSafety.dogsContained.trim().isEmpty) {
      setState(() => _validationError = 'dog');
      _showSnack('Please tell us if dogs will be contained during delivery.');
      return false;
    }

    if (data.dogSafety.hasDogs &&
        data.dogSafety.dogsContained == 'yes' &&
        !data.dogSafety.petsSecuredConfirm) {
      setState(() => _validationError = 'dog');
      _showSnack('Please confirm pets will be secured during the delivery window.');
      return false;
    }

    if (data.contactPreference.trim().isEmpty) {
      setState(() => _validationError = 'contact');
      _showSnack('Please select your contact preference.');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Column(
      children: [
        // ── Header ───────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              Container(
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Delivery & safety",
                          style: GoogleFonts.inter(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "We'll only enter backyards when it's safe. This keeps everyone protected.",
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            color: _primarySoftText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.shield_rounded,
                    size: 42.sp,
                    color: const Color(0xFFfbbf24).withOpacity(0.8),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Address section hidden during signup ──
        // (Address is collected later, not during onboarding)

        // ── Drop-off spot ────────────────────────────
        _card(
          bgColor: const Color(0xFFFFF7ED),
          borderColor: _validationError == 'dropoff' ? Colors.red : const Color(0xFFFED7AA),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Drop-off spot"),
              Text(
                "Choose a clear place so we can be in and out fast.",
                style: _caption,
              ),
              SizedBox(height: 6.h),
              Text("Where should we leave your order?", style: _label),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: _dropOffOptions.map((opt) {
                  return _pillButton(
                    opt,
                    selected: d.dropOffSpot == opt,
                    onTap: () => _update((s) => s.copyWith(dropOffSpot: opt)),
                  );
                }).toList(),
              ),
              SizedBox(height: 10.h),
              _textField(
                controller: _dropOffDetailsCtrl,
                hint: "Drop-off details (optional) — e.g., right side of deck",
                onChanged: (v) => _update((s) => s.copyWith(dropOffDetails: v)),
              ),
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // ── Backyard access ──────────────────────────
        _card(
          bgColor: Colors.grey.shade50,
          borderColor: _validationError == 'backyard' ? Colors.red : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Backyard access"),
              Text(
                "We only enter backyards with permission and safe conditions.",
                style: _caption,
              ),
              SizedBox(height: 6.h),
              Text("Can we enter your backyard for delivery?", style: _label),
              SizedBox(height: 8.h),
              ..._backyardOptions.map((opt) {
                final selected = d.backyardAccess == opt['value'];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: GestureDetector(
                    onTap: () => _update(
                      (s) => s.copyWith(backyardAccess: opt['value'] as String),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: selected
                            ? _primaryLight
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['label'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          if ((opt['desc'] as String).isNotEmpty)
                            Text(
                              opt['desc'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (d.backyardAccess == 'yes') ...[
                SizedBox(height: 12.h),
                _infoBox(
                  icon: Icons.info_outline,
                  text:
                      "Backyard access is required for water testing. We'll need to reach your pool or hot tub to collect a water sample.",
                  color: AppColors.primary,
                  bgColor: _primaryLight,
                ),
                SizedBox(height: 10.h),
                _checkboxTile(
                  value: d.backyardPermission,
                  label:
                      "I give permission to enter my backyard during the delivery window.",
                  color: AppColors.primary,
                  bgColor: _primaryLight,
                  onChanged: (v) =>
                      _update((s) => s.copyWith(backyardPermission: v)),
                ),
              ],
              if (d.backyardAccess == 'no') ...[
                SizedBox(height: 12.h),
                _infoBox(
                  icon: Icons.warning_amber_rounded,
                  text:
                      "Without backyard access, we won't be able to test your water. Deliveries will be left at your front door only.",
                  color: Colors.orange[700]!,
                  bgColor: Colors.orange[50]!,
                  borderColor: Colors.orange[200],
                ),
              ],
              if (d.backyardAccess == 'onlyIfHome') ...[
                SizedBox(height: 12.h),
                _infoBox(
                  icon: Icons.info_outline,
                  text:
                      "We'll only enter your backyard and perform water testing when you're home. If you're not available, we'll leave your order at the front door.",
                  color: Colors.blue[700]!,
                  bgColor: Colors.blue[50]!,
                  borderColor: Colors.blue[200],
                ),
              ],
            ],
          ),
        ),

        // ── Gate & entry details ─────────────────────
        if (d.backyardAccess == 'yes') ...[
          SizedBox(height: 14.h),
          _card(
            bgColor: _primaryLight,
            borderColor: _validationError == 'gate' ? Colors.red : _primaryBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("Gate & entry details"),
                Text(
                  "Shown only when backyard drop-off is selected.",
                  style: _caption,
                ),
                SizedBox(height: 6.h),
                Text("How do we get in?", style: _label),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: _gateAccess.map((opt) {
                    return _pillButton(
                      opt['label'] as String,
                      selected: d.gateEntry.accessMethod == opt['value'],
                      onTap: () => _update(
                        (s) => s.copyWith(
                          gateEntry: s.gateEntry.copyWith(
                            accessMethod: opt['value'] as String,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (d.gateEntry.accessMethod != 'noGate') ...[
                if (d.gateEntry.accessMethod == 'codeLock') ...[
                  SizedBox(height: 10.h),
                  _textField(
                    controller: _gateCodeCtrl,
                    hint: "Gate code / lock combo",
                    onChanged: (v) => _update(
                      (s) => s.copyWith(
                        gateEntry: s.gateEntry.copyWith(gateCode: v),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 12.h),
                Text("Gate location", style: _label),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: _gateLocations.map((loc) {
                    final val = loc.toLowerCase().replaceAll(' side', '');
                    return _pillButton(
                      loc,
                      selected: d.gateEntry.gateLocation == val,
                      onTap: () => _update(
                        (s) => s.copyWith(
                          gateEntry: s.gateEntry.copyWith(gateLocation: val),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (d.gateEntry.gateLocation == 'other') ...[
                  SizedBox(height: 10.h),
                  _textField(
                    controller: _gateLocationOtherCtrl,
                    hint: "Describe gate location",
                    onChanged: (v) => _update(
                      (s) => s.copyWith(
                        gateEntry: s.gateEntry.copyWith(gateLocationOther: v),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _primaryBorder,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        "Please re-latch gate behind you",
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                ], // end noGate check
              ],
            ),
          ),
        ],

        SizedBox(height: 14.h),

        // ── Dog safety ───────────────────────────────
        _card(
          bgColor: const Color(0xFFFFF7ED),
          borderColor: _validationError == 'dog' ? Colors.red : const Color(0xFFFED7AA),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Dog safety (required)"),
              Text(
                "This step protects your delivery and our driver.",
                style: _caption,
              ),
              SizedBox(height: 6.h),
              Text(
                "Are there dogs that could access the yard during delivery?",
                style: _label,
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _pillButton(
                    "No",
                    selected:
                        d.dogSafety.hasDogs == false &&
                            d.dogSafety.dogsContained.isNotEmpty ||
                        d.backyardAccess.isNotEmpty && !d.dogSafety.hasDogs,
                    onTap: () => _update(
                      (s) => s.copyWith(
                        dogSafety: s.dogSafety.copyWith(hasDogs: false),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _pillButton(
                    "Yes",
                    selected: d.dogSafety.hasDogs,
                    selectedColor: const Color(0xFFFED7AA),
                    selectedTextColor: const Color(0xFFC2410C),
                    onTap: () => _update(
                      (s) => s.copyWith(
                        dogSafety: s.dogSafety.copyWith(hasDogs: true),
                      ),
                    ),
                  ),
                ],
              ),
              if (d.dogSafety.hasDogs) ...[
                SizedBox(height: 12.h),
                Text(
                  "During your delivery window, will the dog be inside or securely contained?",
                  style: _label,
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    _pillButton(
                      "Yes (guaranteed)",
                      selected: d.dogSafety.dogsContained == 'yes',
                      selectedColor: _primaryLight,
                      selectedTextColor: AppColors.primary,
                      onTap: () => _update(
                        (s) => s.copyWith(
                          dogSafety: s.dogSafety.copyWith(dogsContained: 'yes'),
                        ),
                      ),
                    ),
                    _pillButton(
                      "No",
                      selected: d.dogSafety.dogsContained == 'no',
                      onTap: () => _update(
                        (s) => s.copyWith(
                          dogSafety: s.dogSafety.copyWith(dogsContained: 'no'),
                        ),
                      ),
                    ),
                    _pillButton(
                      "Not sure",
                      selected: d.dogSafety.dogsContained == 'notSure',
                      onTap: () => _update(
                        (s) => s.copyWith(
                          dogSafety: s.dogSafety.copyWith(
                            dogsContained: 'notSure',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (d.dogSafety.dogsContained == 'no' ||
                    d.dogSafety.dogsContained == 'notSure') ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safety Warning',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB91C1C),
                          ),
                        ),
                        SizedBox(height: 2.h),
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
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Safety rule",
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "If a dog is loose when we arrive, we'll switch to front-door drop-off or reschedule.",
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text("Dog notes (optional)", style: _label),
                  SizedBox(height: 6.h),
                  _textField(
                    controller: _dogNotesCtrl,
                    hint: "e.g., please keep gate closed behind you",
                    onChanged: (v) => _update(
                      (s) => s.copyWith(
                        dogSafety: s.dogSafety.copyWith(dogNotes: v),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _checkboxTile(
                    value: d.dogSafety.petsSecuredConfirm,
                    label:
                        "I confirm pets will be secured during the delivery window.",
                    color: const Color(0xFFea580c),
                    bgColor: const Color(0xFFFFEDD5),
                    onChanged: (v) => _update(
                      (s) => s.copyWith(
                        dogSafety: s.dogSafety.copyWith(petsSecuredConfirm: v),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),

        SizedBox(height: 14.h),

        // ── Contact & proof ──────────────────────────
        _card(
          borderColor: _validationError == 'contact' ? Colors.red : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Contact & proof"),
              Text(
                "If there's an issue, we'll handle it quickly.",
                style: _caption,
              ),
              SizedBox(height: 6.h),
              Text(
                "If we have a quick question at your stop...",
                style: _label,
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: _contactOptions.map((opt) {
                  return _pillButton(
                    opt['label'] as String,
                    selected: d.contactPreference == opt['value'],
                    onTap: () => _update(
                      (s) =>
                          s.copyWith(contactPreference: opt['value'] as String),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 12.h),
              _infoBox(
                icon: Icons.info_outline,
                text:
                    "You'll be notified when the driver is on the way to your address.",
                color: AppColors.primary,
                bgColor: _primaryLight,
                borderColor: _primaryBorder,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────

  TextStyle get _caption =>
      GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500);
  TextStyle get _label => GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: Colors.grey.shade700,
  );

  Widget _card({required Widget child, Color? bgColor, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor ?? Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade900,
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    IconData? prefix,
    Color? prefixColor,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(fontSize: 13.sp),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14.sp,
          color: Colors.grey.shade400,
        ),
     
        
        prefixIcon: prefix != null
            ? Icon(prefix, size: 22.sp, color: prefixColor ?? Colors.grey)
            : null,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _pillButton(
    String label, {
    bool selected = false,
    VoidCallback? onTap,
    IconData? icon,
    Color? selectedColor,
    Color? selectedTextColor,
  }) {
    final bg = selected
      ? (selectedColor ?? _primaryLight)
        : Colors.white;
    final border = selected
      ? (selectedTextColor ?? AppColors.primary)
        : Colors.grey.shade300;
    final textColor = selected
      ? (selectedTextColor ?? _primaryDark)
        : Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14.sp, color: textColor),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkboxTile({
    required bool value,
    required String label,
    required Color color,
    required Color bgColor,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 18.w,
              height: 18.w,
              child: Transform.scale(
                scale: 0.7,
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(fontSize: 11.sp, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCityChanged(String value) {
    _cityDebounce?.cancel();
    final text = value.trim().toLowerCase();
    if (text.isEmpty) {
      if (_citySuggestions.isNotEmpty || _detectedZone != null) {
        setState(() {
          _citySuggestions = [];
          _detectedZone = null;
          _selectedDeliveryDate = null;
          _showDateOptions = false;
        });
      }
      return;
    }
    _cityDebounce = Timer(const Duration(milliseconds: 250), () {
      final zone = detectZoneByCity(value.trim());
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
          if (zone == null) {
            _selectedDeliveryDate = null;
            _showDateOptions = false;
          }
        });
      }
    });
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
        final types =
            (map['types'] as List?)?.whereType<String>().toList() ??
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

      _update(
        (s) => s.copyWith(
          street: _streetCtrl.text,
          city: city,
          postalCode: _postalCtrl.text,
          address: parts.join(', '),
        ),
      );
    } finally {
      _isSelectingStreetSuggestion = false;
    }
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
                      Icon(
                        Icons.location_on_rounded,
                        size: 16.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          city,
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

  // ── Zone card with date picker ──────────────────────────────────────
  Widget _detectedZoneCard() {
    final zone = _detectedZone;
    if (zone == null) return const SizedBox.shrink();
    final cityText = _cityCtrl.text.trim();
    final selected =
        _selectedDeliveryDate ?? _nextDeliveryDate(zone.deliveryDays);
    final options = _nextDeliveryDates(zone.deliveryDays, count: 4);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: Colors.white,
                size: 16.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Your milk run: Every ${zone.deliveryDaysLabel}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
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
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Delivery Day: ${_formatDate(selected)}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: _primarySoftText,
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
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (_selectedDeliveryDate != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'Selected: ${_formatDate(_selectedDeliveryDate!)}',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: const Color(0xFFFDE68A),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _showDateOptions = !_showDateOptions),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 12.sp,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _showDateOptions ? 'Close' : 'Pick Date',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 6.h,
                          ),
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
                              fontSize: 10.sp,
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
          if (_selectedDeliveryDate != null) ...[
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: () => setState(() {
                _selectedDeliveryDate = null;
              }),
              child: Text(
                'Proceed with earliest date',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
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
            style: GoogleFonts.inter(fontSize: 10.sp, color: _primarySoftText),
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
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatPostalInput(String input) {
    final cleaned = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final clipped = cleaned.length > 6 ? cleaned.substring(0, 6) : cleaned;
    if (clipped.length <= 3) return clipped;
    return '${clipped.substring(0, 3)} ${clipped.substring(3)}';
  }

  Widget _infoBox({
    required IconData icon,
    required String text,
    required Color color,
    required Color bgColor,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bgColor,
        border: borderColor != null ? Border.all(color: borderColor) : null,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 11.sp, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelDropdown(DeliverySafety d) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: d.addressLabel.isEmpty ? 'Home' : d.addressLabel,
          isDense: true,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.grey.shade700,
          ),
          items: [
            'Home',
            'Work',
            'Other',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) =>
              _update((s) => s.copyWith(addressLabel: v ?? 'Home')),
        ),
      ),
    );
  }
}
