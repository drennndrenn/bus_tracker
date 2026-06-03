import 'package:latlong2/latlong.dart';

class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

const locationLatLng = <String, GeoPoint>{
  'Tagum City': GeoPoint(lat: 7.4478, lng: 125.8078),
  'Panabo City': GeoPoint(lat: 7.3081, lng: 125.6842),
  'Carmen': GeoPoint(lat: 7.3602, lng: 125.7068),
  'Sto. Tomas': GeoPoint(lat: 7.5316, lng: 125.6132),
  'Kapalong': GeoPoint(lat: 7.5854, lng: 125.7071),
  'New Corella': GeoPoint(lat: 7.5847, lng: 125.8230),
  // Municipal hall area (~PhilAtlas / OSM); previous coords were near New Corella lat + wrong lng.
  'Asuncion': GeoPoint(lat: 7.5386, lng: 125.7515),
};

/// OSRM / simulated routes that must pass through intermediate named places.
/// Key: `"From|To"`.
const routeViaLocationNames = <String, List<String>>{
  'Panabo City|Sto. Tomas': ['Carmen'],
  'Sto. Tomas|Panabo City': ['Carmen'],
};

/// Ordered [from, …vias, to] using pins in [locationLatLng].
List<GeoPoint> routeChainGeoPoints(String fromLocation, String toLocation) {
  final from = locationLatLng[fromLocation];
  final to = locationLatLng[toLocation];
  if (from == null || to == null) return const [];

  final viaNames = routeViaLocationNames['$fromLocation|$toLocation'];
  final via = <GeoPoint>[];
  if (viaNames != null) {
    for (final n in viaNames) {
      final p = locationLatLng[n];
      if (p != null) via.add(p);
    }
  }
  return [from, ...via, to];
}

/// Ordered location names matching [routeChainGeoPoints] indices.
List<String> routeChainLocationNames(String fromLocation, String toLocation) {
  if (locationLatLng[fromLocation] == null || locationLatLng[toLocation] == null) {
    return const [];
  }
  final via = routeViaLocationNames['$fromLocation|$toLocation'] ?? const <String>[];
  return [fromLocation, ...via, toLocation];
}

/// Legs where we draw a straight line between pins (OSRM detours too far west here).
const straightLineRouteLegs = <String>{
  'Carmen|Sto. Tomas',
  'Sto. Tomas|Carmen',
};

/// Straight path in lat/lng for [steps] segments; `null` if this pair uses OSRM.
List<LatLng>? straightLegLatLngs(String fromName, String toName, {int steps = 48}) {
  if (!straightLineRouteLegs.contains('$fromName|$toName')) return null;
  final a = locationLatLng[fromName];
  final b = locationLatLng[toName];
  if (a == null || b == null) return null;
  return List.generate(steps + 1, (i) {
    final t = i / steps;
    return LatLng(
      a.lat + (b.lat - a.lat) * t,
      a.lng + (b.lng - a.lng) * t,
    );
  });
}

const roadSegments = <List<String>>[
  ['Tagum City', 'Sto. Tomas'],
  ['Tagum City', 'Panabo City'],
  ['Sto. Tomas', 'Carmen'],
  ['Sto. Tomas', 'Kapalong'],
  ['Kapalong', 'New Corella'],
  ['New Corella', 'Asuncion'],
  ['Panabo City', 'Carmen'],  
];
