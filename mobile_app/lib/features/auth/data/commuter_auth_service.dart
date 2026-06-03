import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommuterAuthService {
  CommuterAuthService._();

  static final CommuterAuthService instance = CommuterAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Account was not created.');
    }

    await user.updateDisplayName(displayName.trim());

    final commuterRef = _db.collection('commuters').doc(user.uid);
    final existing = await commuterRef.get();
    if (!existing.exists) {
      await commuterRef.set({
        'email': email.trim(),
        'displayName': displayName.trim(),
        'subscriptionStatus': 'free',
        'activePlan': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return credential;
  }

  Future<void> signOut() => _auth.signOut();
}
