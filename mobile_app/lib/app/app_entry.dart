import 'package:flutter/material.dart';

import '../features/onboarding/presentation/pages/landing_page.dart';
import '../shared/widgets/app_shell.dart';

/// Shows the landing page first; the main app opens after the user continues.
class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  void _openHome(BuildContext context) {
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LandingPage(onTrackBus: () => _openHome(context));
  }
}
