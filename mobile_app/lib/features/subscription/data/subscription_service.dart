import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;

import '../../../core/subscription_constants.dart';

class SubscriptionService {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> submitPayment({
    required String senderName,
    required int amount,
    required Uint8List proofBytes,
    String? proofNote,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Sign in to submit payment.');
    }

    if (amount != SubscriptionConstants.proMonthlyAmount) {
      throw Exception('Amount must be ₱${SubscriptionConstants.proMonthlyAmount}.');
    }

    final compressed = _compressProof(proofBytes);
    final base64Proof = base64Encode(compressed);

    if (base64Proof.length > SubscriptionConstants.maxProofBase64Length) {
      throw Exception('Image is too large. Please use a smaller screenshot.');
    }

    final commuterRef = _db.collection('commuters').doc(user.uid);
    final commuterSnap = await commuterRef.get();
    if (!commuterSnap.exists) {
      throw Exception('Commuter profile not found. Sign out and register again.');
    }

    final status = commuterSnap.data()?['subscriptionStatus'] as String? ?? 'free';
    if (status == 'pro') {
      throw Exception('Pro subscription is already active.');
    }
    if (status == 'pending') {
      throw Exception('A payment is already pending review.');
    }

    final paymentRef = _db.collection('payment_requests').doc();
    final batch = _db.batch();

    batch.set(paymentRef, {
      'userId': user.uid,
      'userEmail': user.email ?? commuterSnap.data()?['email'] ?? '',
      'senderName': senderName.trim(),
      'amount': amount,
      'plan': SubscriptionConstants.proMonthlyPlanId,
      'status': 'pending',
      'proofImageBase64': base64Proof,
      'proofNote': proofNote?.trim().isNotEmpty == true ? proofNote!.trim() : null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(commuterRef, {
      'subscriptionStatus': 'pending',
      'activePlan': SubscriptionConstants.proMonthlyPlanId,
      'pendingPaymentId': paymentRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final alertRef = _db.collection('commuter_alerts').doc();
    batch.set(alertRef, {
      'userId': user.uid,
      'type': 'payment_pending',
      'title': 'Payment submitted',
      'body':
          'Your Pro payment is pending super admin review. You will be notified here when it is approved.',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return paymentRef.id;
  }

  Uint8List _compressProof(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    const maxWidth = 1024;
    img.Image resized = decoded;
    if (decoded.width > maxWidth) {
      resized = img.copyResize(decoded, width: maxWidth);
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 72));
  }
}
