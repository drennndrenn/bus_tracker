import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'location_map_data.dart';

class OsrmRouteService {
  const OsrmRouteService();

  Future<List<LatLng>> fetchRoute({
    required String fromLocation,
    required String toLocation,
  }) async {
    final from = locationLatLng[fromLocation];
    final to = locationLatLng[toLocation];
    if (from == null || to == null) return const [];

    final chain = routeChainGeoPoints(fromLocation, toLocation);
    final names = routeChainLocationNames(fromLocation, toLocation);
    if (chain.length < 2 || names.length != chain.length) return const [];

    if (chain.length == 2) {
      final leg = await _legPoints(names[0], chain[0], names[1], chain[1]);
      return _snapEndpoints(List<LatLng>.from(leg), chain[0], chain[1]);
    }

    final merged = <LatLng>[];
    for (var i = 0; i < chain.length - 1; i++) {
      var leg = await _legPoints(names[i], chain[i], names[i + 1], chain[i + 1]);
      if (leg.isEmpty) return const [];
      leg = _snapEndpoints(List<LatLng>.from(leg), chain[i], chain[i + 1]);
      if (merged.isNotEmpty) {
        merged.removeLast();
      }
      merged.addAll(leg);
    }
    return merged;
  }

  /// OSRM driving route, or a straight “presentation” leg when configured.
  Future<List<LatLng>> _legPoints(String nameA, GeoPoint a, String nameB, GeoPoint b) async {
    final straight = straightLegLatLngs(nameA, nameB);
    if (straight != null) {
      return straight;
    }
    return _fetchSingleLegOsrm(a, b);
  }

  Future<List<LatLng>> _fetchSingleLegOsrm(GeoPoint a, GeoPoint b) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${a.lng},${a.lat};${b.lng},${b.lat}'
      '?overview=full&geometries=geojson',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return const [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = body['routes'];
    if (routes is! List || routes.isEmpty) return const [];

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'];
    if (coordinates is! List) return const [];

    final points = <LatLng>[];
    for (final point in coordinates) {
      if (point is List && point.length >= 2) {
        final lng = (point[0] as num).toDouble();
        final lat = (point[1] as num).toDouble();
        points.add(LatLng(lat, lng));
      }
    }
    return points;
  }

  List<LatLng> _snapEndpoints(List<LatLng> points, GeoPoint a, GeoPoint b) {
    final exactStart = LatLng(a.lat, a.lng);
    final exactEnd = LatLng(b.lat, b.lng);
    if (points.isEmpty) {
      return [exactStart, exactEnd];
    }
    points[0] = exactStart;
    points[points.length - 1] = exactEnd;
    return points;
  }
}
