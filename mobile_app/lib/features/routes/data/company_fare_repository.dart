import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import 'fare_fallback_data.dart';
import 'fare_models.dart';

/// Bachelor Express company document id in Firestore.
const kDefaultCompanyId = 'dnsc-express';

class CompanyFareRepository {
  CompanyFareRepository._();

  static final CompanyFareRepository instance = CompanyFareRepository._();

  Map<String, List<FareItem>>? _fareCache;
  List<RouteItem>? _routesCache;
  String? _companyName;
  bool _usingFallback = false;

  bool get usingFallback => _usingFallback;
  String? get companyName => _companyName;

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, List<FareItem>>> loadFareMatrix({
    String companyId = kDefaultCompanyId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _fareCache != null) {
      return _fareCache!;
    }

    final db = _db;
    if (db == null) {
      return _applyFallback();
    }

    try {
      final companySnap = await db.collection('companies').doc(companyId).get();
      if (companySnap.exists) {
        _companyName = companySnap.data()?['name'] as String?;
      }

      final faresSnap =
          await db.collection('companies').doc(companyId).collection('fares').get();

      if (faresSnap.docs.isEmpty) {
        return _applyFallback();
      }

      final matrix = <String, List<FareItem>>{};
      for (final doc in faresSnap.docs) {
        final data = doc.data();
        final origin = data['origin'] as String?;
        final destination = data['destination'] as String?;
        final amount = data['amount'];
        if (origin == null || destination == null || amount == null) continue;

        matrix.putIfAbsent(origin, () => []).add(
              FareItem(
                id: doc.id,
                destination: destination,
                fare: (amount is int) ? amount : (amount as num).round(),
              ),
            );
      }

      for (final origin in matrix.keys) {
        matrix[origin]!.sort((a, b) => a.destination.compareTo(b.destination));
      }

      _usingFallback = false;
      _fareCache = matrix;
      return matrix;
    } catch (e, st) {
      debugPrint('CompanyFareRepository.loadFareMatrix: $e\n$st');
      return _applyFallback();
    }
  }

  Future<List<RouteItem>> loadRoutes({
    String companyId = kDefaultCompanyId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _routesCache != null) {
      return _routesCache!;
    }

    final db = _db;
    if (db == null) {
      _routesCache = const [];
      return _routesCache!;
    }

    try {
      final routesSnap =
          await db.collection('companies').doc(companyId).collection('routes').get();

      final routes = routesSnap.docs
          .map((doc) {
            final data = doc.data();
            return RouteItem(
              id: doc.id,
              name: data['name'] as String? ?? '',
              origin: data['origin'] as String? ?? '',
              destination: data['destination'] as String? ?? '',
              status: data['status'] as String? ?? 'active',
            );
          })
          .where((r) => r.status == 'active')
          .toList();

      _routesCache = routes;
      return routes;
    } catch (e, st) {
      debugPrint('CompanyFareRepository.loadRoutes: $e\n$st');
      _routesCache = const [];
      return _routesCache!;
    }
  }

  /// Fare rows per origin; falls back to counting routes for that origin.
  int destinationCountFor(String location, Map<String, List<FareItem>> fareMatrix) {
    final fares = fareMatrix[location];
    if (fares != null && fares.isNotEmpty) return fares.length;

    final routes = _routesCache;
    if (routes == null || routes.isEmpty) return 0;
    return routes.where((r) => r.origin == location).length;
  }

  Map<String, List<FareItem>> _applyFallback() {
    _usingFallback = true;
    _companyName ??= 'Bachelor Express';
    _fareCache = Map<String, List<FareItem>>.from(fallbackFareData);
    return _fareCache!;
  }

  void clearCache() {
    _fareCache = null;
    _routesCache = null;
    _usingFallback = false;
  }

  /// Ensures every municipality in [AppConstants.locations] has a map entry.
  Map<String, List<FareItem>> normalizeForLocations(Map<String, List<FareItem>> matrix) {
    return {
      for (final location in AppConstants.locations)
        location: matrix[location] ?? const <FareItem>[],
    };
  }
}
