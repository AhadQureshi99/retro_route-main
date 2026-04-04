import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/components/custom_textfield.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:retro_route/config/delivery_zones.dart';
import 'package:retro_route/model/address_model.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view_model/address_view_model/address_view_model.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  final Address? addressToEdit;
  const AddAddressScreen({super.key, this.addressToEdit});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyB_8gavyfzAIRyMl4eD18iGe_s27fjBSDo',
  );

  late TextEditingController _fullNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _pinCodeCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _phoneCtrl;

  // Zone detection
  DeliveryZone? _detectedZone;
  bool _cityTooShort = false;

  // City suggestions (from deliveryZones)
  List<String> _citySuggestions = [];
  Timer? _cityDebounce;

  // Address autocomplete
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;
  bool _isSelectingSuggestion = false;

  // Delivery location (from suggestion or map pin)
  double? _deliveryLat;
  double? _deliveryLon;

  // Current GPS location (fraud prevention)
  double? _currentLat;
  double? _currentLon;
  bool _fetchingLocation = false;
  Completer<void>? _locationCompleter;

  // Map picker
  bool _showMap = false;
  GoogleMapController? _mapController;
  LatLng _markerPos = const LatLng(44.5901, -75.6843); // Brockville hub default
  final _mapSearchCtrl = TextEditingController();
  bool _searchingMapLocation = false;
  List<Map<String, dynamic>> _mapSuggestions = [];
  Timer? _mapSearchDebounce;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AddAddress] $message');
    }
  }

  Future<void> _safeAnimateCamera(LatLng pos, {double zoom = 16}) async {
    final controller = _mapController;
    if (!mounted || controller == null) return;
    try {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(pos, zoom));
    } catch (e) {
      _log('Skipping animateCamera (map may be disposed): $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(text: widget.addressToEdit?.fullName ?? '');
    _addressCtrl = TextEditingController(text: widget.addressToEdit?.addressLine ?? '');
    _cityCtrl = TextEditingController(text: widget.addressToEdit?.city ?? '');
    _stateCtrl = TextEditingController(text: widget.addressToEdit?.state ?? '');
    _pinCodeCtrl = TextEditingController(
      text: _formatPostalInput(widget.addressToEdit?.pinCode ?? ''),
    );
    _countryCtrl = TextEditingController(text: 'Canada');
    _phoneCtrl = TextEditingController(text: widget.addressToEdit?.mobile ?? '');

    // Pre-detect zone if editing
    if (widget.addressToEdit?.city != null) {
      _detectedZone = detectZoneByCity(widget.addressToEdit!.city!);
    }

    // Pre-load delivery location if editing
    final existingDelivery = widget.addressToEdit?.deliveryLoc;
    if (existingDelivery != null) {
      _deliveryLat = existingDelivery['lat'];
      _deliveryLon = existingDelivery['lon'];
      if (_deliveryLat != null && _deliveryLon != null) {
        _markerPos = LatLng(_deliveryLat!, _deliveryLon!);
      }
    }

    // Eagerly grab current GPS for fraud prevention
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCurrentLocation());
  }

  Future<void> _fetchCurrentLocation() async {
    if (_fetchingLocation) return; // already running
    _locationCompleter = Completer<void>();
    setState(() => _fetchingLocation = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Location permission denied. Please enable it in Settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: Geolocator.openAppSettings,
              ),
            ),
          );
        }
        return;
      }
      if (perm == LocationPermission.denied) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() {
        _currentLat = pos.latitude;
        _currentLon = pos.longitude;
      });
    } catch (_) {
    } finally {
      _locationCompleter?.complete();
      _locationCompleter = null;
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cityDebounce?.cancel();
    _mapSearchDebounce?.cancel();
    _mapController?.dispose();
    _mapController = null;
    _mapSearchCtrl.dispose();
    _fullNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pinCodeCtrl.dispose();
    _countryCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onCityChanged(String value) {
    // Zone detection
    setState(() {
      if (value.trim().length >= 3) {
        _detectedZone = detectZoneByCity(value.trim());
        _cityTooShort = false;
      } else {
        _detectedZone = null;
        _cityTooShort = value.trim().isNotEmpty;
      }
    });

    // City suggestions dropdown
    _cityDebounce?.cancel();
    final text = value.trim().toLowerCase();
    if (text.isEmpty) {
      if (_citySuggestions.isNotEmpty) setState(() => _citySuggestions = []);
      return;
    }
    _cityDebounce = Timer(const Duration(milliseconds: 250), () {
      final matches = deliveryZones
          .expand((z) => z.cities)
          .where((c) => c.toLowerCase().contains(text))
          .toList();
      final isExact =
          matches.length == 1 && matches.first.toLowerCase() == text;
      if (mounted) setState(() => _citySuggestions = isExact ? [] : matches);
    });
  }

  // ── Address line autocomplete ──────────────────────────────────────────
  void _onAddressLineChanged(String value) {
    if (_isSelectingSuggestion) {
      _log('Ignoring onAddressLineChanged while selecting suggestion');
      return;
    }
    _debounce?.cancel();
    _log('Address line changed: "${value.trim()}"');
    if (value.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      _log('Input shorter than 3 chars, suggestions cleared');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _log('Debounce fired, fetching suggestions for "$value"');
      _fetchSuggestions(value.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      _log('Autocomplete request started for "$query"');
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&types=address'
        '&components=country:ca'
        '&language=en'
        '&key=$_googleMapsApiKey',
      );
      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 6));
      _log('Autocomplete HTTP status: ${res.statusCode}');
      if (res.statusCode != 200) {
        _log('Autocomplete failed with non-200 response');
        return;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';
      final err = body['error_message'] as String? ?? '';
      final predictions = (body['predictions'] as List?) ?? const [];
      _log('Autocomplete API status: $status, predictions: ${predictions.length}${err.isNotEmpty ? ', error: $err' : ''}');
      List<Map<String, dynamic>> nextSuggestions = [];

      if (status == 'OK') {
        nextSuggestions = predictions.map<Map<String, dynamic>>((item) {
          final prediction = (item as Map).cast<String, dynamic>();
          final structured =
              (prediction['structured_formatting'] as Map?)?.cast<String, dynamic>() ??
                  {};
          final mainText = (structured['main_text'] as String?) ?? '';
          final secondaryText = (structured['secondary_text'] as String?) ?? '';
          final label = secondaryText.isNotEmpty
              ? '$mainText, $secondaryText'
              : (prediction['description'] as String? ?? '');
          return {
            'placeId': prediction['place_id'] as String? ?? '',
            'display': prediction['description'] as String? ?? '',
            'label': label,
          };
        }).toList();
      }

      // Fallback: If Places is blocked/empty, use Geocoding API results.
      if (nextSuggestions.isEmpty) {
        _log('Autocomplete empty/non-OK, trying geocode fallback for "$query"');
        nextSuggestions = await _fetchGeocodeSuggestions(query, limit: 6);
        _log('Geocode fallback returned ${nextSuggestions.length} suggestions');
      }

      if (!mounted) return;
      setState(() {
        _suggestions = nextSuggestions;
        _showSuggestions = _suggestions.isNotEmpty;
      });
      _log('Suggestion panel updated. show=$_showSuggestions, count=${_suggestions.length}');
      if (_suggestions.isEmpty) {
        _log('No suggestions found for "$query"');
      }
    } catch (e, st) {
      _log('Autocomplete exception: $e');
      _log('$st');
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> s) async {
    _isSelectingSuggestion = true;
    FocusScope.of(context).unfocus();
    if (mounted) {
      setState(() {
        _showSuggestions = false;
      });
    }

    final placeId = s['placeId'] as String? ?? '';
    _log('Suggestion selected. placeId=${placeId.isNotEmpty}, label=${s['label']}');
    try {
      final tappedLabel = s['label'] as String? ?? '';
      if (tappedLabel.isNotEmpty && _addressCtrl.text.trim() != tappedLabel) {
        _addressCtrl.text = tappedLabel;
      }

      if (placeId.isNotEmpty) {
        await _fillAddressFromPlaceId(placeId);
      } else {
        final lat = (s['lat'] as num?)?.toDouble();
        final lon = (s['lon'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          final pos = LatLng(lat, lon);
          setState(() {
            _markerPos = pos;
            _deliveryLat = lat;
            _deliveryLon = lon;
          });
          await _safeAnimateCamera(pos);
          await _reverseGeocodeMarker(pos);
        }
      }
    } finally {
      _isSelectingSuggestion = false;
    }
  }

  // ── Map pin ────────────────────────────────────────────────────────────
  void _onMapTap(LatLng pos) => _updateMarker(pos);
  void _onMarkerDragEnd(LatLng pos) => _updateMarker(pos);

  void _onMapSearchChanged(String value) {
    _mapSearchDebounce?.cancel();
    if (value.trim().length < 3) {
      if (_mapSuggestions.isNotEmpty) setState(() => _mapSuggestions = []);
      return;
    }
    _mapSearchDebounce = Timer(const Duration(milliseconds: 450), () {
      _fetchMapSuggestions(value.trim());
    });
  }

  String _formatPostalInput(String input) {
    final cleaned = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final clipped = cleaned.length > 6 ? cleaned.substring(0, 6) : cleaned;
    if (clipped.length <= 3) return clipped;
    return '${clipped.substring(0, 3)} ${clipped.substring(3)}';
  }

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

  Future<void> _fetchMapSuggestions(String query) async {
    setState(() => _searchingMapLocation = true);
    try {
      _log('Map autocomplete request started for "$query"');
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(query)}'
        '&types=address'
        '&components=country:ca'
        '&language=en'
        '&key=$_googleMapsApiKey',
      );
      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 6));
        _log('Map autocomplete HTTP status: ${res.statusCode}');
        if (res.statusCode != 200 || !mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';
        final err = body['error_message'] as String? ?? '';
      final predictions = (body['predictions'] as List?) ?? const [];
        _log('Map autocomplete API status: $status, predictions: ${predictions.length}${err.isNotEmpty ? ', error: $err' : ''}');
      List<Map<String, dynamic>> nextSuggestions = [];

      if (status == 'OK') {
        nextSuggestions = predictions.map<Map<String, dynamic>>((item) {
          final prediction = (item as Map).cast<String, dynamic>();
          final structured =
              (prediction['structured_formatting'] as Map?)?.cast<String, dynamic>() ??
                  {};
          final mainText = (structured['main_text'] as String?) ?? '';
          final secondaryText = (structured['secondary_text'] as String?) ?? '';
          final label = secondaryText.isNotEmpty
              ? '$mainText, $secondaryText'
              : (prediction['description'] as String? ?? '');
          return {
            'placeId': prediction['place_id'] as String? ?? '',
            'label': label,
            'display': prediction['description'] as String? ?? '',
          };
        }).toList();
      }

      if (nextSuggestions.isEmpty) {
        _log('Map autocomplete empty/non-OK, trying geocode fallback for "$query"');
        nextSuggestions = await _fetchGeocodeSuggestions(query, limit: 6);
      }

      setState(() {
        _mapSuggestions = nextSuggestions;
      });
      _log('Map suggestion list updated. count=${_mapSuggestions.length}');
    } catch (e, st) {
      _log('Map autocomplete exception: $e');
      _log('$st');
    } finally {
      if (mounted) setState(() => _searchingMapLocation = false);
    }
  }

  Future<void> _selectMapSuggestion(Map<String, dynamic> s) async {
    final placeId = s['placeId'] as String? ?? '';
    _log('Map suggestion selected. placeId=${placeId.isNotEmpty}, label=${s['label']}');
    double lat = 0.0;
    double lon = 0.0;

    if (placeId.isNotEmpty) {
      final detail = await _fetchPlaceDetails(placeId);
      if (detail == null || !mounted) return;
      final location =
          ((detail['geometry'] as Map?)?['location'] as Map?)?.cast<String, dynamic>() ??
              {};
      lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
      lon = (location['lng'] as num?)?.toDouble() ?? 0.0;
      _applyPlaceDetails(detail);
    } else {
      lat = (s['lat'] as num?)?.toDouble() ?? 0.0;
      lon = (s['lon'] as num?)?.toDouble() ?? 0.0;
      if (lat == 0.0 && lon == 0.0) return;
      await _reverseGeocodeMarker(LatLng(lat, lon));
    }

    final label = s['label'] as String? ?? '';
    final pos = LatLng(lat, lon);
    _mapSearchCtrl.text = label;
    setState(() {
      _mapSuggestions = [];
      _markerPos = pos;
      _deliveryLat = lat;
      _deliveryLon = lon;
    });
    await _safeAnimateCamera(pos);
    FocusScope.of(context).unfocus();
  }

  Future<List<Map<String, dynamic>>> _fetchGeocodeSuggestions(
    String query, {
    int limit = 6,
  }) async {
    try {
      _log('Geocode fallback request started for "$query"');
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(query)}'
        '&components=country:CA'
        '&language=en'
        '&key=$_googleMapsApiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      _log('Geocode fallback HTTP status: ${res.statusCode}');
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';
      final err = body['error_message'] as String? ?? '';
      _log('Geocode fallback API status: $status${err.isNotEmpty ? ', error: $err' : ''}');
      if (status != 'OK') return const [];

      final results = (body['results'] as List?) ?? const [];
      _log('Geocode fallback results: ${results.length}');
      return results.take(limit).map<Map<String, dynamic>>((item) {
        final map = (item as Map).cast<String, dynamic>();
        final formatted = map['formatted_address'] as String? ?? '';
        final placeId = map['place_id'] as String? ?? '';
        final geometry = (map['geometry'] as Map?)?.cast<String, dynamic>() ?? {};
        final location = (geometry['location'] as Map?)?.cast<String, dynamic>() ?? {};
        final lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
        final lon = (location['lng'] as num?)?.toDouble() ?? 0.0;
        return {
          'placeId': placeId,
          'label': formatted,
          'display': formatted,
          'lat': lat,
          'lon': lon,
        };
      }).toList();
    } catch (e, st) {
      _log('Geocode fallback exception: $e');
      _log('$st');
      return const [];
    }
  }

  Future<void> _searchMapLocation(String query) async {
    if (_mapSuggestions.isNotEmpty) {
      _selectMapSuggestion(_mapSuggestions.first);
      return;
    }
    if (query.trim().isEmpty) return;
    setState(() => _searchingMapLocation = true);
    try {
      _log('Manual map search started for "$query"');
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(query.trim())}'
        '&components=country:CA'
        '&language=en'
        '&key=$_googleMapsApiKey',
      );
      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200 || !mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';
      final err = body['error_message'] as String? ?? '';
      final results = (body['results'] as List?) ?? const [];
      _log('Manual map search status: $status, results: ${results.length}${err.isNotEmpty ? ', error: $err' : ''}');
      if ((status != 'OK' && status != 'ZERO_RESULTS') || results.isEmpty) {
        CustomToast.error(msg: 'Location not found');
        return;
      }
      final first = (results.first as Map).cast<String, dynamic>();
      final geometry = (first['geometry'] as Map?)?.cast<String, dynamic>() ?? {};
      final location = (geometry['location'] as Map?)?.cast<String, dynamic>() ?? {};
      final lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
      final lon = (location['lng'] as num?)?.toDouble() ?? 0.0;
      final pos = LatLng(lat, lon);
      setState(() {
        _markerPos = pos;
        _deliveryLat = lat;
        _deliveryLon = lon;
      });
      await _safeAnimateCamera(pos);
      _applyGeocodeResult(first);
      FocusScope.of(context).unfocus();
    } catch (e, st) {
      _log('Manual map search exception: $e');
      _log('$st');
      CustomToast.error(msg: 'Search failed. Please try again.');
    } finally {
      if (mounted) setState(() => _searchingMapLocation = false);
    }
  }

  void _updateMarker(LatLng pos) {
    setState(() {
      _markerPos = pos;
      _deliveryLat = pos.latitude;
      _deliveryLon = pos.longitude;
    });
    // Reverse geocode to fill fields
    _reverseGeocodeMarker(pos);
  }

  Future<void> _reverseGeocodeMarker(LatLng pos) async {
    try {
      _log('Reverse geocode for marker: ${pos.latitude}, ${pos.longitude}');
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}'
        '&language=en'
        '&key=$_googleMapsApiKey',
      );
      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200 || !mounted) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';
      final err = body['error_message'] as String? ?? '';
      final results = (body['results'] as List?) ?? const [];
      _log('Reverse geocode status: $status, results: ${results.length}${err.isNotEmpty ? ', error: $err' : ''}');
      if ((status != 'OK' && status != 'ZERO_RESULTS') || results.isEmpty) {
        return;
      }
      final first = (results.first as Map).cast<String, dynamic>();
      _applyGeocodeResult(first);
    } catch (e, st) {
      _log('Reverse geocode exception: $e');
      _log('$st');
    }
  }

  Future<Map<String, dynamic>?> _fetchPlaceDetails(String placeId) async {
    try {
      _log('Place details request for placeId: $placeId');
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${Uri.encodeComponent(placeId)}'
        '&fields=geometry,address_components,formatted_address'
        '&language=en'
        '&key=$_googleMapsApiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      _log('Place details HTTP status: ${res.statusCode}');
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final status = body['status'] as String? ?? '';
      final err = body['error_message'] as String? ?? '';
      _log('Place details status: $status${err.isNotEmpty ? ', error: $err' : ''}');
      if (status != 'OK') return null;
      final result = (body['result'] as Map?)?.cast<String, dynamic>();
      return result;
    } catch (e, st) {
      _log('Place details exception: $e');
      _log('$st');
      return null;
    }
  }

  Future<void> _fillAddressFromPlaceId(String placeId) async {
    // 1) Always try geocode(place_id) first so fields refresh deterministically.
    final geocode = await _fetchGeocodeByPlaceId(placeId);
    if (geocode != null && mounted) {
      final geometry = (geocode['geometry'] as Map?)?.cast<String, dynamic>() ?? {};
      final location = (geometry['location'] as Map?)?.cast<String, dynamic>() ?? {};
      final lat = (location['lat'] as num?)?.toDouble() ?? 0.0;
      final lon = (location['lng'] as num?)?.toDouble() ?? 0.0;
      setState(() {
        _deliveryLat = lat;
        _deliveryLon = lon;
        _markerPos = LatLng(lat, lon);
      });
      await _safeAnimateCamera(_markerPos);
      _applyGeocodeResult(geocode);
    }

    // 2) Then try place details and enrich/override with richer components if available.
    final detail = await _fetchPlaceDetails(placeId);
    if (detail == null || !mounted) return;
    final location =
        ((detail['geometry'] as Map?)?['location'] as Map?)?.cast<String, dynamic>() ??
            {};
    final lat = (location['lat'] as num?)?.toDouble() ?? _deliveryLat ?? 0.0;
    final lon = (location['lng'] as num?)?.toDouble() ?? _deliveryLon ?? 0.0;
    setState(() {
      _deliveryLat = lat;
      _deliveryLon = lon;
      _markerPos = LatLng(lat, lon);
    });
    await _safeAnimateCamera(_markerPos);
    _applyPlaceDetails(detail);
  }

  Future<Map<String, dynamic>?> _fetchGeocodeByPlaceId(String placeId) async {
    try {
      _log('Geocode by placeId request: $placeId');
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
      final err = body['error_message'] as String? ?? '';
      final results = (body['results'] as List?) ?? const [];
      _log('Geocode by placeId status: $status, results: ${results.length}${err.isNotEmpty ? ', error: $err' : ''}');
      if (status != 'OK' || results.isEmpty) return null;
      return (results.first as Map).cast<String, dynamic>();
    } catch (e, st) {
      _log('Geocode by placeId exception: $e');
      _log('$st');
      return null;
    }
  }

  void _applyPlaceDetails(Map<String, dynamic> detail) {
    final components =
        (detail['address_components'] as List?)?.whereType<Map>().toList() ??
            const [];
    final parsed = _parseAddressComponents(components);
    final formattedAddress = detail['formatted_address'] as String? ?? '';

    final street = parsed['street'] as String;
    final city = parsed['city'] as String;
    final province = parsed['provinceShort'] as String;
    final postalCode = parsed['postalCode'] as String;
    final country = parsed['country'] as String;
    _log('Apply place details -> city=$city, province=$province, postal=$postalCode, country=$country');

    setState(() {
      if (street.isNotEmpty) {
        _addressCtrl.text = street;
      } else if (formattedAddress.isNotEmpty) {
        _addressCtrl.text = formattedAddress;
      }

      if (city.isNotEmpty) {
        _cityCtrl.text = city;
        _onCityChanged(city);
      }

      if (postalCode.isNotEmpty) {
        _pinCodeCtrl.text = _formatPostalInput(postalCode);
      }

      if (province.isNotEmpty) {
        _stateCtrl.text = province;
      }

      if (country.isNotEmpty) {
        _countryCtrl.text = country;
      }
    });
  }

  void _applyGeocodeResult(Map<String, dynamic> result) {
    final components =
        (result['address_components'] as List?)?.whereType<Map>().toList() ??
            const [];
    final parsed = _parseAddressComponents(components);
    final formattedAddress = result['formatted_address'] as String? ?? '';

    final street = parsed['street'] as String;
    final city = parsed['city'] as String;
    final province = parsed['provinceShort'] as String;
    final postalCode = parsed['postalCode'] as String;
    final country = parsed['country'] as String;
    _log('Apply geocode -> city=$city, province=$province, postal=$postalCode, country=$country');

    setState(() {
      if (street.isNotEmpty) {
        _addressCtrl.text = street;
      } else if (formattedAddress.isNotEmpty) {
        _addressCtrl.text = formattedAddress;
      }

      if (city.isNotEmpty) {
        _cityCtrl.text = city;
        _onCityChanged(city);
      }

      if (postalCode.isNotEmpty) {
        _pinCodeCtrl.text = _formatPostalInput(postalCode);
      }

      if (province.isNotEmpty) {
        _stateCtrl.text = province;
      }

      if (country.isNotEmpty) {
        _countryCtrl.text = country;
      }
    });
  }

  Map<String, String> _parseAddressComponents(List<Map> components) {
    String streetNumber = '';
    String route = '';
    String city = '';
    String provinceShort = '';
    String postalCode = '';
    String postalCodeSuffix = '';
    String country = '';

    for (final c in components) {
      final map = c.cast<String, dynamic>();
      final types = (map['types'] as List?)?.whereType<String>().toList() ??
          const <String>[];
      final longName = (map['long_name'] as String?) ?? '';
      final shortName = (map['short_name'] as String?) ?? '';

      if (types.contains('street_number')) {
        streetNumber = longName;
      } else if (types.contains('route')) {
        route = longName;
      } else if (types.contains('locality')) {
        city = longName;
      } else if (types.contains('sublocality') && city.isEmpty) {
        city = longName;
      } else if (types.contains('sublocality_level_1') && city.isEmpty) {
        city = longName;
      } else if (types.contains('postal_town') && city.isEmpty) {
        city = longName;
      } else if (types.contains('administrative_area_level_3') && city.isEmpty) {
        city = longName;
      } else if (types.contains('administrative_area_level_2') && city.isEmpty) {
        city = longName;
      } else if (types.contains('administrative_area_level_1')) {
        provinceShort = shortName.toUpperCase();
      } else if (types.contains('postal_code')) {
        postalCode = longName;
      } else if (types.contains('postal_code_suffix')) {
        postalCodeSuffix = longName;
      } else if (types.contains('country')) {
        country = longName;
      }
    }

    final postal = postalCodeSuffix.isNotEmpty
        ? '$postalCode-$postalCodeSuffix'
        : postalCode;

    final street = [streetNumber, route].where((p) => p.trim().isNotEmpty).join(' ').trim();
    return {
      'street': street,
      'city': city,
      'provinceShort': provinceShort,
      'postalCode': postal,
      'country': country,
    };
  }

  // ── Submit ─────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final token = ref.read(authNotifierProvider).value?.data?.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    // If background GPS fetch is still running, wait for it (up to 6 s)
    if (_fetchingLocation && _locationCompleter != null) {
      await _locationCompleter!.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () {},
      );
    }

    // Use already-fetched current location; refresh if still missing
    Map<String, double>? currentLoc;
    if (_currentLat != null && _currentLon != null) {
      currentLoc = {'lat': _currentLat!, 'lon': _currentLon!};
    } else {
      try {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 8));
          currentLoc = {'lat': pos.latitude, 'lon': pos.longitude};
          setState(() {
            _currentLat = pos.latitude;
            _currentLon = pos.longitude;
          });
        }
      } catch (_) {}
    }

    final deliveryLoc = (_deliveryLat != null && _deliveryLon != null)
        ? {'lat': _deliveryLat!, 'lon': _deliveryLon!}
        : null;

    final notifier = ref.read(addressProvider.notifier);

    final success = widget.addressToEdit == null
        ? await notifier.addAddress(
            token: token,
            fullName: _fullNameCtrl.text.trim(),
            addressLine: _addressCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            statess: _stateCtrl.text.trim(),
            country: _countryCtrl.text.trim(),
            postalCode: _pinCodeCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            currentLoc: currentLoc,
            deliveryLoc: deliveryLoc,
          )
        : await notifier.updateAddress(
            token: token,
            addressId: widget.addressToEdit!.safeId,
            fullName: _fullNameCtrl.text.trim(),
            addressLine: _addressCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            statess: _stateCtrl.text.trim(),
            country: _countryCtrl.text.trim(),
            postalCode: _pinCodeCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            currentLoc: currentLoc,
            deliveryLoc: deliveryLoc,
          );

    if (success && mounted) {
      CustomToast.success(
        msg: widget.addressToEdit == null
            ? "Address added successfully"
            : "Address updated",
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: customText(
          text: widget.addressToEdit == null
              ? "Add New Address"
              : "Edit Address",
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        backgroundColor: AppColors.primary,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          if (_citySuggestions.isNotEmpty) {
            setState(() => _citySuggestions = []);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Delivery Location Map ───────────────────────────
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pin_drop_outlined,
                              color: AppColors.black, size: 20.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: customText(
                              text: 'Pin Delivery Location',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _showMap = !_showMap),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(60.w, 30.h),
                            ),
                            child: Text(
                              _showMap ? 'Hide' : 'Show Map',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.btnColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Tap the map or drag the pin to set your exact delivery spot.',
                        style: GoogleFonts.inter(
                            fontSize: 14.sp, color: Colors.grey.shade900),
                      ),
                      // "Use my current location" shortcut
                      if (_currentLat != null)
                        Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: GestureDetector(
                            onTap: () {
                              final pos = LatLng(_currentLat!, _currentLon!);
                              setState(() {
                                _markerPos = pos;
                                _deliveryLat = _currentLat;
                                _deliveryLon = _currentLon;
                                _showMap = true;
                                _suggestions = [];
                                _showSuggestions = false;
                              });
                              _safeAnimateCamera(pos);
                              _reverseGeocodeMarker(pos);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.my_location,
                                    size: 14.sp, color: AppColors.primary),
                                SizedBox(width: 4.w),
                                Text(
                                  'Use my current location',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_fetchingLocation)
                        Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12.sp,
                                height: 12.sp,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: AppColors.primary),
                              ),
                              SizedBox(width: 6.w),
                              Text('Getting your location…',
                                  style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      color: Colors.grey.shade900)),
                            ],
                          ),
                        ),
                      if (_showMap) ...[
                        verticalSpacer(height: 10.h),
                        // ── Map location search bar ──
                        TextField(
                          controller: _mapSearchCtrl,
                          textInputAction: TextInputAction.search,
                          onChanged: _onMapSearchChanged,
                          onSubmitted: _searchMapLocation,
                          decoration: InputDecoration(
                            hintText: 'Search location on map…',
                            hintStyle: GoogleFonts.inter(
                                fontSize: 14.sp, color: Colors.grey.shade900),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: AppColors.primary, size: 20.sp),
                            suffixIcon: _searchingMapLocation
                                ? Padding(
                                    padding: EdgeInsets.all(12.w),
                                    child: SizedBox(
                                      width: 16.sp,
                                      height: 16.sp,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary),
                                    ),
                                  )
                                : _mapSearchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.close_rounded,
                                            size: 18.sp,
                                            color: Colors.grey.shade500),
                                        onPressed: () => setState(() {
                                          _mapSearchCtrl.clear();
                                          _mapSuggestions = [];
                                        }),
                                      )
                                    : null,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12.h, horizontal: 16.w),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                        // ── Suggestions dropdown ──
                        if (_mapSuggestions.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 3)),
                              ],
                            ),
                            child: Column(
                              children: _mapSuggestions.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final s = entry.value;
                                final label = s['label'] as String? ?? '';
                                final display = s['display'] as String? ?? '';
                                final isLast = idx == _mapSuggestions.length - 1;
                                return Column(
                                  children: [
                                    InkWell(
                                      onTap: () => _selectMapSuggestion(s),
                                      borderRadius: BorderRadius.circular(10.r),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.w, vertical: 10.h),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(top: 2.h),
                                              child: Icon(
                                                  Icons.location_on_outlined,
                                                  size: 16.sp,
                                                  color: AppColors.primary),
                                            ),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    label.isNotEmpty
                                                        ? label
                                                        : display,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  if (display.isNotEmpty)
                                                    Text(
                                                      display,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11.sp,
                                                        color: Colors
                                                            .grey.shade500,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (!isLast)
                                      Divider(
                                          height: 1,
                                          color: Colors.grey.shade100,
                                          indent: 36.w),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        verticalSpacer(height: 8.h),
                        if (_deliveryLat != null)
                          Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    size: 14.sp, color: Colors.green.shade600),
                                SizedBox(width: 4.w),
                                Text(
                                  'Pinned: ${_deliveryLat!.toStringAsFixed(5)}, ${_deliveryLon!.toStringAsFixed(5)}',
                                  style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                verticalSpacer(height: 16.h),

                // Current location status chip
                Row(
                  children: [
                    Icon(
                      _fetchingLocation
                          ? Icons.gps_not_fixed
                          : _currentLat != null
                              ? Icons.gps_fixed
                              : Icons.gps_off,
                      size: 18.sp,
                      color: _fetchingLocation
                          ? Colors.orange
                          : _currentLat != null
                              ? Colors.green.shade600
                              : Colors.grey,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      _fetchingLocation
                          ? 'Acquiring your location…'
                          : _currentLat != null
                              ? 'Current location captured'
                              : 'Current location unavailable',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: _fetchingLocation
                            ? Colors.orange
                            : _currentLat != null
                                ? Colors.green.shade900
                                : Colors.grey,
                      ),
                    ),
                    if (_fetchingLocation) ...
                      [
                        SizedBox(width: 8.w),
                        SizedBox(
                          width: 10.w,
                          height: 10.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                  ],
                ),
                verticalSpacer(height: 12),

                // 1. Full Name
                customText(
                  text: "Full Name",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                verticalSpacer(height: 8),
                CustomTextField(
                  controller: _fullNameCtrl,
                
                  hintText: "",
                  validator: (v) =>
                      v!.trim().isEmpty ? "Full name is required" : null,
                  width: 1.sw,
                     hintFontSize: 16.sp,
                ),
                verticalSpacer(height: 12),

                // Mobile Number (right after Full Name)
                customText(
                  text: "Mobile Number",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                verticalSpacer(height: 8),
                CustomTextField(
                  controller: _phoneCtrl,
                  hintText: "",
                  keyboardType: TextInputType.phone,
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
                  validator: (v) =>
                      v!.trim().isEmpty ? "Mobile number is required" : null,
                  width: 1.sw,
                     hintFontSize: 16.sp,
                ),
                verticalSpacer(height: 12),

                // 2. Address Line with autocomplete
                customText(
                  text: "Address Line",
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                verticalSpacer(height: 8),
                CustomTextField(
                  controller: _addressCtrl,
                  hintText: "Start typing to search…",
                  maxLines: 3,
                  onChanged: _onAddressLineChanged,
                  validator: (v) =>
                      v!.trim().isEmpty ? "Address is required" : null,
                  width: 1.sw,
                  hintFontSize: 16.sp,
                ),
                // Suggestions list
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Close suggestions header
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showSuggestions = false;
                              _suggestions = [];
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Close',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(Icons.close_rounded, size: 16.sp, color: Colors.grey.shade600),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey.shade200),
                        ..._suggestions.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final s = entry.value;
                        // Primary line: structured label (street, city, province, postcode)
                        final label = s['label'] as String? ?? '';
                        // Secondary: full display_name for extra context
                        final display = s['display'] as String? ?? '';
                        final isLast = idx == _suggestions.length - 1;
                        return Column(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                _log('Address suggestion tapped: ${label.isNotEmpty ? label : display}');
                                _selectSuggestion(s);
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 10.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(top: 2.h),
                                      child: Icon(Icons.location_on_outlined,
                                          size: 16.sp, color: AppColors.primary),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            label.isNotEmpty ? label : display,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (display.isNotEmpty)
                                            Text(
                                              display,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                  height: 1,
                                  color: Colors.grey.shade100,
                                  indent: 36.w),
                          ],
                        );
                      }).toList(),
                      ],
                    ),
                  ),
                // Delivery pin indicator
                if (_deliveryLat != null)
                  Padding(
                    padding: EdgeInsets.only(top: 6.h),
                    child: Row(
                      children: [
                        Icon(Icons.pin_drop, size: 18.sp, color: Colors.green.shade600),
                        SizedBox(width: 4.w),
                        Text(
                          'Delivery pin: ${_deliveryLat!.toStringAsFixed(4)}, ${_deliveryLon!.toStringAsFixed(4)}',
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                verticalSpacer(height: 12),

                // 3. City + State/Province (side by side)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          customText(
                            text: "City",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          verticalSpacer(height: 8.h),
                          CustomTextField(
                            controller: _cityCtrl,
                            hintText: "",
                            onChanged: _onCityChanged,
                            validator: (v) =>
                                v!.trim().isEmpty ? "City is required" : null,
                            width: double.infinity,
                               hintFontSize: 16.sp,
                        
                          ),
                          if (_citySuggestions.isNotEmpty) ...
                            [
                              SizedBox(height: 4.h),
                              _buildCitySuggestionDropdown(),
                            ],
                        ],
                      ),
                    ),
                    horizontalSpacer(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          customText(
                            text: "State/Province",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          verticalSpacer(height: 8.h),
                          CustomTextField(
                            controller: _stateCtrl,
                            hintText: "",
                            validator: (v) =>
                                v!.trim().isEmpty ? "State is required" : null,
                            width: double.infinity,
                            hintFontSize: 16.sp,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Zone badge below city
                verticalSpacer(height: 8.h),
                _buildZoneBadge(),

                verticalSpacer(height: 20.h),

                // 4. Postal Code
                customText(
                  text: "Postal Code",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                verticalSpacer(height: 8.h),
                CustomTextField(
                  controller: _pinCodeCtrl,
                  hintText: "",
                     hintFontSize: 16.sp,
                  onChanged: (v) {
                    final formatted = _formatPostalInput(v);
                    if (_pinCodeCtrl.text != formatted) {
                      _pinCodeCtrl.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  },
                  validator: (v) =>
                      v!.trim().isEmpty ? "Postal code is required" : null,
                  width: 1.sw,
                ),
                verticalSpacer(height: 20.h),

                // 5. Country
                customText(
                  text: "Country",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                verticalSpacer(height: 8.h),
                CustomTextField(
                  controller: _countryCtrl,
                  enAbleTextField: false,
                  hintText: "",
                     hintFontSize: 16.sp,
                  validator: (v) =>
                      v!.trim().isEmpty ? "Country is required" : null,
                  width: 1.sw,
                ),
                verticalSpacer(height: 32.h),

              
                // verticalSpacer(height: 12.h),

                // Submit button
                customButton(
                  context: context,
                  text: widget.addressToEdit == null
                      ? "Save Address"
                      : "Update Address",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontColor: Colors.white,
                  bgColor: AppColors.btnColor,
                  height: 58.h,
                  width: double.infinity,
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                  borderColor: AppColors.btnColor,
                  borderRadius: 16.r,
                  isCircular: false,
                ),
                verticalSpacer(height: 20.h),
                SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 48.h),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildZoneBadge() {
    if (_cityTooShort) return const SizedBox.shrink();

    if (_detectedZone != null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: _detectedZone!.color.withOpacity(0.08),
          border: Border.all(color: _detectedZone!.color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_shipping, size: 14.sp, color: _detectedZone!.color),
            SizedBox(width: 6.w),
            Text(
              '${_detectedZone!.name}  —  Delivery: ${_detectedZone!.deliveryDaysLabel}',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: _detectedZone!.color,
              ),
            ),
          ],
        ),
      );
    }

    if (_cityCtrl.text.trim().length >= 3) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          border: Border.all(color: Colors.amber[300]!),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 14.sp, color: Colors.amber[700]),
            SizedBox(width: 6.w),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber[800],
                  ),
                  children: [
                    const TextSpan(text: 'Your city is not in the delivery zone. We are working on it, but for now, please visit '),
                    TextSpan(
                      text: 'www.retrorouteco.com/home',
                      style: const TextStyle(
                        color: Color(0xFFE8751A),
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {
                        launchUrl(Uri.parse('https://www.retrorouteco.com/home'), mode: LaunchMode.externalApplication);
                      },
                    ),
                    const TextSpan(text: ' to place an order, and we will ship it to you.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCitySuggestionDropdown() {
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
            ..._citySuggestions.map((city) {
              return InkWell(
                onTap: () {
                  _cityCtrl.text = city;
                  _cityCtrl.selection =
                      TextSelection.collapsed(offset: city.length);
                  _onCityChanged(city);
                  setState(() => _citySuggestions = []);
                },
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 18.sp, color: AppColors.primary),
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
            InkWell(
              onTap: () => setState(() => _citySuggestions = []),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, size: 16.sp, color: Colors.grey.shade500),
                    SizedBox(width: 4.w),
                    Text(
                      "Close",
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
