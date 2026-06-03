import 'package:flutter/material.dart';

import '../../../core/project_entitlements.dart';
import '../../auth/presentation/pages/commuter_login_page.dart';
import 'pages/subscription_payment_page.dart';

Future<void> startProActivationFlow(BuildContext context) async {
  final entitlements = ProjectEntitlements.instance;

  if (entitlements.isPro) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pro plan is already active.')),
    );
    return;
  }

  if (entitlements.isPending) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment pending'),
        content: const Text(
          'Your payment is waiting for super admin approval. You will get Pro features once it is approved.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
    return;
  }

  if (!entitlements.isSignedIn) {
    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const CommuterLoginPage()),
    );
    if (!context.mounted) return;
    if (signedIn != true && !ProjectEntitlements.instance.isSignedIn) return;
    // After sign-in or registration, stay on Plans — user can tap Activate again to pay.
    return;
  }

  await _openPayment(context);
}

Future<void> _openPayment(BuildContext context) async {
  if (ProjectEntitlements.instance.isPro || ProjectEntitlements.instance.isPending) {
    return;
  }
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const SubscriptionPaymentPage()),
  );
}
