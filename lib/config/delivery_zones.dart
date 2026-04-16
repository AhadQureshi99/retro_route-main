import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ── Hub ──────────────────────────────────────────────────────────────────
const LatLng brockvilleHub = LatLng(44.5901, -75.6843);

// ── Zone Model ───────────────────────────────────────────────────────────
class DeliveryZone {
  final int id;
  final String name;
  final List<String> deliveryDays;
  final Color color;
  final List<String> cities;
  final List<CityMarker> cityMarkers;
  final List<LatLng> polygon;

  const DeliveryZone({
    required this.id,
    required this.name,
    required this.deliveryDays,
    required this.color,
    required this.cities,
    required this.cityMarkers,
    required this.polygon,
  });

  /// Primary delivery day (first in the list).
  String get deliveryDay => deliveryDays.first;

  /// Formatted string for display: "Monday & Thursday" or just "Wednesday".
  String get deliveryDaysLabel => deliveryDays.join(' & ');
}

class CityMarker {
  final String name;
  final LatLng position;
  const CityMarker({required this.name, required this.position});
}

// ── Zone Data ────────────────────────────────────────────────────────────
final List<DeliveryZone> deliveryZones = [
  DeliveryZone(
    id: 1,
    name: 'Zone 1',
    deliveryDays: ['Monday', 'Thursday'],
    color: const Color(0xFFef4444), // red
    cities: [
      'Aultsville', 'Avonmore', 'Baldwins Bridge', 'Berwick', 'Bonville',
      'Brinston', 'Brockville', 'Cardinal', 'Charleville', 'Chesterville',
      'Cornwall', 'Cornwall Island', "Dickinson's Landing", 'Dixons Corners',
      'Domville', 'Dunbar', 'Dundela', 'Elma', 'Elmas Corners', 'Finch',
      'Gallingertown', 'Glen Becker', 'Glen Small', 'Glen Stewart',
      'Groveton', 'Haddo', 'Hallville', 'Hanesville', 'Harrisons Corners',
      'Heckston', 'Hulbert', 'Hyndmans Ridge', 'Ingleside', 'Inkerman',
      'Irena', 'Iroquois', 'Johnstown', 'Kemptville', 'Long Sault',
      'Lunenburg', 'Mainsville', 'Maitland', 'Mariatown', 'Maynard',
      'McCarleys Corners', 'Millars Corners', 'Monkland', 'Morrisburg',
      'Mountain', 'Muttonville', 'Newington', 'North Mountain', 'Oak Valley',
      'Osnabruck Centre', 'Peltons Corner', 'Perkins Corners', 'Pittston',
      'Prescott', 'Riverside Heights', 'Roebuck', 'Rosedale Terrace',
      'Shanly', 'South Mountain', 'Sparkle City', 'Spencerville',
      'St Andrews West', 'Toyes Hill', 'Upper Canada Village', 'Van Camp',
      'Ventnor', 'Wales', 'Wexford', 'Williamsburg', 'Winchester',
      'Winchester Springs',
    ],
    cityMarkers: [
      CityMarker(name: 'Cornwall',    position: const LatLng(45.0218, -74.73)),
      CityMarker(name: 'Brockville',  position: const LatLng(44.5901, -75.6843)),
      CityMarker(name: 'Kemptville',  position: const LatLng(44.98,   -75.47)),
      CityMarker(name: 'Morrisburg',  position: const LatLng(44.9,    -75.19)),
    ],
    polygon: [
      LatLng(44.568734642, -75.70154954),
      LatLng(44.662457837, -75.576923384),
      LatLng(44.712251565, -75.505512251),
      LatLng(44.760052278, -75.443714155),
      LatLng(44.817555806, -75.340717329),
      LatLng(44.861375919, -75.283039106),
      LatLng(44.916833552, -75.141590132),
      LatLng(44.953775602, -75.05781938),
      LatLng(45.001376322, -74.956195845),
      LatLng(45.033411683, -74.821613325),
      LatLng(45.013998452, -74.730976118),
      LatLng(45.035352644, -74.659564985),
      LatLng(45.216541664, -74.825733198),
      LatLng(45.212671987, -74.914997114),
      LatLng(45.175896918, -75.020740522),
      LatLng(45.149752822, -75.12511064),
      LatLng(45.114875364, -75.276172651),
      LatLng(45.101306148, -75.405262007),
      LatLng(45.041175132, -75.686786665),
      LatLng(45.013998452, -75.69365312),
      LatLng(44.98292359, -75.618122114),
      LatLng(44.888624947, -75.589283003),
      LatLng(44.84093068, -75.596149458),
      LatLng(44.711275629, -75.611255659),
      LatLng(44.659161154, -75.755107889),
      LatLng(44.568734642, -75.70154954),
    ],
  ),
  DeliveryZone(
    id: 2,
    name: 'Zone 2',
    deliveryDays: ['Wednesday'],
    color: const Color(0xFF06b6d4), // cyan
    cities: [
      'Actons Corners', 'Addison', 'Algonquin', 'Andrewsville', 'Athens',
      'Bellamy', 'Bellamys', 'Bellamys Mill', 'Bells Crossing',
      'Beveridge Locks', 'Bishops Mills', 'Blanchards Hill',
      'Burritts Rapids', 'Carleys Corner', 'Crystal', 'East Oxford',
      'Eastons Corners', 'Elmgrove', 'Eloida', 'Frankville', 'Glen Elbe',
      'Glen Tay', 'Glenview', 'Greenbush', 'Jasper', 'Jellyby',
      'Judgeville', 'Kilmarnock', 'Lehighs Corners', 'Lombardy', 'Lyn',
      'Merrickville', 'Merrickville-Wolford', 'Motts Mills', 'New Dublin',
      'Newbliss', 'Newboyne', 'Newmanville', 'Nolans Corners',
      'North Augusta', 'Numogate', 'Oxford Mills', 'Oxford Station',
      'Perth', 'Plum Hollow', 'Port Elmsley', 'Rideau Ferry',
      'Rocksprings', 'Shanes', 'Smiths Falls', 'Snowdons Corners',
      'South Augusta', 'South Branch', 'Swan Crossing', 'Throoptown',
      'Tincap', 'Toledo', 'Wolford', 'Wolford Chapel',
    ],
    cityMarkers: [
      CityMarker(name: 'Smiths Falls',        position: const LatLng(44.9042, -76.0092)),
      CityMarker(name: 'Perth',               position: const LatLng(44.9,    -76.25)),
      CityMarker(name: 'Merrickville-Wolford', position: const LatLng(44.92,  -75.84)),
    ],
    polygon: [
      LatLng(44.568245468, -75.701206217),
      LatLng(44.659893766, -75.755451212),
      LatLng(44.716473201, -75.628722527),
      LatLng(44.888105053, -75.638542683),
      LatLng(44.967865646, -75.628765117),
      LatLng(44.994093059, -75.71390916),
      LatLng(44.911484707, -76.32227708),
      LatLng(44.837522434, -76.239879619),
      LatLng(44.606266515, -76.005046855),
      LatLng(44.568245468, -75.701206217),
    ],
  ),
  DeliveryZone(
    id: 3,
    name: 'Zone 3',
    deliveryDays: ['Tuesday', 'Friday'],
    color: const Color(0xFFeab308), // yellow
    cities: [
      'Amherstview', 'Ballycanoe', 'Barriefield', 'Bayridge', 'Browns Bay',
      'Butternut Bay', 'Caintown', 'Cataraqui', 'Cataraqui/Westbrook',
      'CFB Kingston', 'Cheeseborough', 'Collins Bay', 'Darlingside',
      'Ebenezer', 'Elizabethtown-Kitley', 'Emery', 'Escott', 'Frontenac',
      'Gananoque', 'Gananoque Junction', 'Glenburnie', "Gray's Beach",
      'Grenadier Village', 'Halsteads Bay', 'Hill Island', 'Howe Island',
      'Ivy Lea', 'Joyceville', 'Junetown', 'Kingston', 'Lansdowne',
      'Legge', 'Long Beach', 'Mallorytown', 'Mallorytown Landing',
      'Maple Grove', 'Marble Rock', 'McIntosh Mills', 'New Dublin Rd',
      'Pitts Ferry', 'Pittsburgh', 'Rapid Valley', 'Reddendale',
      'Rideau Heights', 'Rockfield', 'Rockport', 'Selton', 'Taylor',
      'Treasure Island', 'Trevelyan', 'Waterton', 'Westbrook',
      'Willowbank', 'Wilstead', 'Woodridge', 'Yonge Mills',
    ],
    cityMarkers: [
      CityMarker(name: 'Kingston',   position: const LatLng(44.2312, -76.486)),
      CityMarker(name: 'Gananoque', position: const LatLng(44.33,   -76.165)),
    ],
    polygon: [
      LatLng(44.564576528, -75.733135232),
      LatLng(44.366600988, -76.263225564),
      LatLng(44.268344837, -76.62302781),
      LatLng(44.213249527, -76.620281228),
      LatLng(44.199467638, -76.532390603),
      LatLng(44.211280883, -76.430767068),
      LatLng(44.228996309, -76.373088845),
      LatLng(44.278177856, -76.304424294),
      LatLng(44.315528323, -76.084697732),
      LatLng(44.384269622, -75.9061699),
      LatLng(44.433321187, -75.829265603),
      LatLng(44.446067857, -75.821025856),
      LatLng(44.545004938, -75.727642067),
      LatLng(44.564576528, -75.733135232),
    ],
  ),
];

// ── Ray-casting point-in-polygon ──────────────────────────────────────────
bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
  final double lat = point.latitude;
  final double lng = point.longitude;
  bool inside = false;
  int j = polygon.length - 1;
  for (int i = 0; i < polygon.length; j = i++) {
    final double yi = polygon[i].latitude;
    final double xi = polygon[i].longitude;
    final double yj = polygon[j].latitude;
    final double xj = polygon[j].longitude;
    final bool intersect =
        (yi > lat) != (yj > lat) &&
        lng < ((xj - xi) * (lat - yi) / (yj - yi) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

/// Returns the zone for [lat,lng] or null if outside all zones.
DeliveryZone? detectZone(double lat, double lng) {
  for (final zone in deliveryZones) {
    if (isPointInPolygon(LatLng(lat, lng), zone.polygon)) return zone;
  }
  return null;
}

/// Returns the zone whose cities list contains [cityName] (case-insensitive).
DeliveryZone? detectZoneByCity(String cityName) {
  if (cityName.trim().isEmpty) return null;
  final city = cityName.trim().toLowerCase();
  for (final zone in deliveryZones) {
    if (zone.cities.any((c) => c.toLowerCase() == city)) return zone;
  }
  // partial match
  for (final zone in deliveryZones) {
    if (zone.cities.any(
      (c) => c.toLowerCase().contains(city) || city.contains(c.toLowerCase()),
    )) return zone;
  }
  return null;
}

/// Computes the visual centroid of a polygon (for label placement).
LatLng polygonCenter(List<LatLng> polygon) {
  double latSum = 0, lngSum = 0;
  for (final p in polygon) {
    latSum += p.latitude;
    lngSum += p.longitude;
  }
  return LatLng(latSum / polygon.length, lngSum / polygon.length);
}

/// Returns the next calendar date on which [dayName] falls,
/// respecting 12 PM noon cutoff (day before delivery).
DateTime getNextDeliveryDate(String dayName) {
  const days = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday',
  ];
  final target = days.indexOf(dayName);
  if (target == -1) return DateTime.now();
  final now = DateTime.now();
  const cutoffHour = 12; // noon

  for (int i = 0; i <= 13; i++) {
    final candidate = DateTime(now.year, now.month, now.day + i);
    if (candidate.weekday % 7 != target) continue;
    // Cutoff is noon the day before this delivery day
    final cutoff = DateTime(candidate.year, candidate.month, candidate.day - 1, cutoffHour);
    if (now.isBefore(cutoff)) return candidate;
  }
  return DateTime.now();
}

/// Returns the soonest upcoming delivery date from a list of day names,
/// respecting 12 PM noon cutoff.
DateTime getNextDeliveryDateFromDays(List<String> dayNames) {
  if (dayNames.isEmpty) return DateTime.now();
  const days = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday',
  ];
  final targetDayNums = dayNames
      .map((d) => days.indexOf(d))
      .where((i) => i >= 0)
      .toList();
  if (targetDayNums.isEmpty) return DateTime.now();

  final now = DateTime.now();
  const cutoffHour = 12;

  for (int i = 0; i <= 13; i++) {
    final candidate = DateTime(now.year, now.month, now.day + i);
    if (!targetDayNums.contains(candidate.weekday % 7)) continue;
    final cutoff = DateTime(candidate.year, candidate.month, candidate.day - 1, cutoffHour);
    if (now.isBefore(cutoff)) return candidate;
  }
  return DateTime.now();
}

/// Returns the delivery date TWO weeks from now on [dayName] (the one after next).
DateTime getSecondDeliveryDate(String dayName) {
  final first = getNextDeliveryDate(dayName);
  return first.add(const Duration(days: 7));
}

/// Returns the second soonest delivery date from a list of day names,
/// respecting cutoff.
DateTime getSecondDeliveryDateFromDays(List<String> dayNames) {
  if (dayNames.isEmpty) return DateTime.now();
  const days = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday',
  ];
  final targetDayNums = dayNames
      .map((d) => days.indexOf(d))
      .where((i) => i >= 0)
      .toList();

  final now = DateTime.now();
  const cutoffHour = 12;
  final results = <DateTime>[];

  for (int i = 0; i <= 20; i++) {
    final candidate = DateTime(now.year, now.month, now.day + i);
    if (!targetDayNums.contains(candidate.weekday % 7)) continue;
    final cutoff = DateTime(candidate.year, candidate.month, candidate.day - 1, cutoffHour);
    if (now.isBefore(cutoff)) {
      results.add(candidate);
      if (results.length >= 2) return results[1];
    }
  }
  if (results.isNotEmpty) return results[0].add(const Duration(days: 7));
  return getSecondDeliveryDate(dayNames.first);
}

/// e.g. "Monday, March 9, 2026"
String formatDeliveryDate(DateTime date) {
  const weekdays = [
    '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  const months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${weekdays[date.weekday]}, ${months[date.month]} ${date.day}, ${date.year}';
}
