import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../home/data/tracking_models.dart';
import 'alert_models.dart';

/// In-app alerts: Firestore (`commuter_alerts`) plus local session fallback.
class AlertsService extends ChangeNotifier {
  AlertsService._();

  static final AlertsService instance = AlertsService._();

  static const _collection = 'commuter_alerts';
  static const _localIdPrefix = 'local_';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _alertsSub;

  List<CommuterAlert> _remoteAlerts = const [];
  final List<CommuterAlert> _localAlerts = [];
  bool _initialized = false;
  bool _usingLocalFallbackOnly = false;
  String? _lastError;
  String? _lastTripDedupeKey;
  String? _lastTrafficDedupeKey;
  int _localIdCounter = 0;

  List<CommuterAlert> get alerts {
    final merged = [..._remoteAlerts, ..._localAlerts];
    merged.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return merged;
  }

  int get unreadCount => alerts.where((a) => !a.read).length;

  bool get isInitialized => _initialized;

  String? get lastError => _lastError;

  bool get usingLocalFallbackOnly => _usingLocalFallbackOnly;

  Future<void> initialize() async {
    if (_initialized) return;
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
    _onAuthChanged(_auth.currentUser);
    _initialized = true;
  }

  void _onAuthChanged(User? user) {
    _alertsSub?.cancel();
    _alertsSub = null;
    _lastTripDedupeKey = null;
    _lastTrafficDedupeKey = null;
    _lastError = null;
    _usingLocalFallbackOnly = false;

    if (user == null) {
      _remoteAlerts = const [];
      notifyListeners();
      return;
    }

    _listenRemoteAlerts(user.uid);
  }

  void _listenRemoteAlerts(String uid) {
    // Single-field query avoids requiring a composite index (userId + createdAt).
    _alertsSub = _db
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snap) {
        _lastError = null;
        _usingLocalFallbackOnly = false;
        _remoteAlerts = snap.docs
            .map((doc) => CommuterAlert.fromFirestore(doc.id, doc.data()))
            .toList()
          ..sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
        if (_remoteAlerts.length > 50) {
          _remoteAlerts = _remoteAlerts.take(50).toList();
        }
        notifyListeners();
      },
      onError: (Object e, StackTrace st) {
        _lastError = e.toString();
        _usingLocalFallbackOnly = _localAlerts.isNotEmpty;
        debugPrint('Alerts stream error: $e\n$st');
        notifyListeners();
      },
    );
  }

  Future<void> markRead(String alertId) async {
    if (alertId.startsWith(_localIdPrefix)) {
      final index = _localAlerts.indexWhere((a) => a.id == alertId);
      if (index >= 0) {
        final item = _localAlerts[index];
        _localAlerts[index] = CommuterAlert(
          id: item.id,
          type: item.type,
          title: item.title,
          body: item.body,
          read: true,
          createdAt: item.createdAt,
          routeFrom: item.routeFrom,
          routeTo: item.routeTo,
        );
        notifyListeners();
      }
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection(_collection).doc(alertId).update({'read': true});
    } catch (e) {
      debugPrint('markRead failed: $e');
    }
  }

  Future<void> markAllRead() async {
    for (var i = 0; i < _localAlerts.length; i++) {
      final item = _localAlerts[i];
      if (!item.read) {
        _localAlerts[i] = CommuterAlert(
          id: item.id,
          type: item.type,
          title: item.title,
          body: item.body,
          read: true,
          createdAt: item.createdAt,
          routeFrom: item.routeFrom,
          routeTo: item.routeTo,
        );
      }
    }

    final user = _auth.currentUser;
    if (user == null) {
      notifyListeners();
      return;
    }

    final unreadRemote = _remoteAlerts.where((a) => !a.read).toList();
    if (unreadRemote.isEmpty) {
      notifyListeners();
      return;
    }

    final batch = _db.batch();
    for (final alert in unreadRemote) {
      batch.update(_db.collection(_collection).doc(alert.id), {'read': true});
    }
    try {
      await batch.commit();
    } catch (e) {
      debugPrint('markAllRead failed: $e');
    }
    notifyListeners();
  }

  Future<bool> deleteAlert(String alertId) async {
    if (alertId.startsWith(_localIdPrefix)) {
      _localAlerts.removeWhere((a) => a.id == alertId);
      _usingLocalFallbackOnly = _remoteAlerts.isEmpty && _localAlerts.isNotEmpty;
      notifyListeners();
      return true;
    }

    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _db.collection(_collection).doc(alertId).delete();
      return true;
    } catch (e) {
      debugPrint('deleteAlert failed: $e');
      return false;
    }
  }

  Future<void> publishTripStatusChange({
    required String from,
    required String to,
    required ServiceStatus status,
    required int etaMinutes,
  }) async {
    final dedupeKey = 'trip:${from.trim()}|${to.trim()}|${status.name}';
    if (_lastTripDedupeKey == dedupeKey) return;
    _lastTripDedupeKey = dedupeKey;

    final (title, body) = switch (status) {
      ServiceStatus.onTime => (
          'Bus on time',
          'Your trip from $from to $to is on schedule. ETA about $etaMinutes min.',
        ),
      ServiceStatus.delayed => (
          'Trip delayed',
          'Expect a longer wait on $from → $to. Updated ETA about $etaMinutes min.',
        ),
      ServiceStatus.arriving => (
          'Bus arriving soon',
          'Your bus is nearing $to. ETA about $etaMinutes min.',
        ),
    };

    await _publish(
      type: AlertType.trip,
      title: title,
      body: body,
      routeFrom: from,
      routeTo: to,
    );
  }

  Future<void> publishTrafficAlert({
    required String from,
    required String to,
    required TrafficLevel level,
    required int etaMinutes,
  }) async {
    if (level == TrafficLevel.light) return;

    final dedupeKey = 'traffic:${from.trim()}|${to.trim()}|${level.name}';
    if (_lastTrafficDedupeKey == dedupeKey) return;
    _lastTrafficDedupeKey = dedupeKey;

    final extra = level == TrafficLevel.heavy ? 5 : 3;
    final title = level == TrafficLevel.heavy ? 'Heavy traffic' : 'Moderate traffic';
    final body =
        'Traffic on $from → $to may add about +$extra min. Updated ETA about $etaMinutes min.';

    await _publish(
      type: AlertType.traffic,
      title: title,
      body: body,
      routeFrom: from,
      routeTo: to,
    );
  }

  void resetTrackingDedupe() {
    _lastTripDedupeKey = null;
    _lastTrafficDedupeKey = null;
  }

  Future<void> _publish({
    required AlertType type,
    required String title,
    required String body,
    String? routeFrom,
    String? routeTo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _addLocalAlert(
        type: type,
        title: title,
        body: body,
        routeFrom: routeFrom,
        routeTo: routeTo,
      );
      return;
    }

    try {
      await _db.collection(_collection).add({
        'userId': user.uid,
        'type': alertTypeToString(type),
        'title': title,
        'body': body,
        'read': false,
        if (routeFrom != null) 'routeFrom': routeFrom,
        if (routeTo != null) 'routeTo': routeTo,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to create remote alert: $e');
      _addLocalAlert(
        type: type,
        title: title,
        body: body,
        routeFrom: routeFrom,
        routeTo: routeTo,
      );
    }
  }

  void _addLocalAlert({
    required AlertType type,
    required String title,
    required String body,
    String? routeFrom,
    String? routeTo,
  }) {
    _localIdCounter += 1;
    _localAlerts.insert(
      0,
      CommuterAlert(
        id: '$_localIdPrefix$_localIdCounter',
        type: type,
        title: title,
        body: body,
        read: false,
        createdAt: DateTime.now(),
        routeFrom: routeFrom,
        routeTo: routeTo,
      ),
    );
    _usingLocalFallbackOnly = _remoteAlerts.isEmpty;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _alertsSub?.cancel();
    super.dispose();
  }
}
