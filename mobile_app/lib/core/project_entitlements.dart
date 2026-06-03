import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../features/auth/data/commuter_auth_service.dart';

/// Commuter subscription state from Firestore (`commuters/{uid}`).
class ProjectEntitlements extends ChangeNotifier {
  ProjectEntitlements._();

  static final ProjectEntitlements instance = ProjectEntitlements._();

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _commuterSub;

  String _subscriptionStatus = 'free';
  String? _rejectReason;
  String? _displayName;
  String? _email;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  bool get isPro => _subscriptionStatus == 'pro';

  bool get isPending => _subscriptionStatus == 'pending';

  String get subscriptionStatus => _subscriptionStatus;

  String? get rejectReason => _rejectReason;

  String? get displayName => _displayName;

  String? get email => _email;

  bool get isSignedIn => CommuterAuthService.instance.currentUser != null;

  Future<void> initialize() async {
    if (_initialized) return;
    _authSub = CommuterAuthService.instance.authStateChanges.listen(_onAuthChanged);
    _onAuthChanged(CommuterAuthService.instance.currentUser);
    _initialized = true;
  }

  void _onAuthChanged(User? user) {
    _commuterSub?.cancel();
    _commuterSub = null;

    if (user == null) {
      _subscriptionStatus = 'free';
      _rejectReason = null;
      _displayName = null;
      _email = null;
      notifyListeners();
      return;
    }

    _email = user.email;
    _displayName = user.displayName;

    _commuterSub = FirebaseFirestore.instance
        .collection('commuters')
        .doc(user.uid)
        .snapshots()
        .listen(_onCommuterSnapshot, onError: (_) {
      notifyListeners();
    });
  }

  void _onCommuterSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists) {
      _subscriptionStatus = 'free';
      _rejectReason = null;
      notifyListeners();
      return;
    }

    final data = snap.data() ?? {};
    _subscriptionStatus = data['subscriptionStatus'] as String? ?? 'free';
    _rejectReason = data['rejectReason'] as String?;
    _displayName = data['displayName'] as String? ?? _displayName;
    _email = data['email'] as String? ?? _email;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final user = CommuterAuthService.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('commuters').doc(user.uid).get();
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _commuterSub?.cancel();
    super.dispose();
  }
}
