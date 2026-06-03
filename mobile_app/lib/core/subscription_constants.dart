/// Pro subscription pricing and GCash payment display (demo).
class SubscriptionConstants {
  SubscriptionConstants._();

  static const proMonthlyPlanId = 'pro_monthly';
  static const proMonthlyAmount = 99;
  static const gcashDisplayNumber = '0917 123 4567';
  static const gcashQrPayload = 'GCASH-DEMO-BUSTRACKER-99';

  /// Max base64 length sent to Firestore (~650 KB image).
  static const maxProofBase64Length = 900000;
}
