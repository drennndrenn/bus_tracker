import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app_entry.dart';
import 'core/project_entitlements.dart';
import 'features/alerts/data/alerts_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await ProjectEntitlements.instance.initialize();
    await AlertsService.instance.initialize();
  } catch (e, st) {
    debugPrint('Firebase init failed (using offline fare fallback): $e\n$st');
    await ProjectEntitlements.instance.initialize();
    await AlertsService.instance.initialize();
  }
  runApp(const SmartBusTrackerApp());
}

class SmartBusTrackerApp extends StatelessWidget {
  const SmartBusTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProjectEntitlements.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Bus Tracking PH',
          theme: buildAppTheme(),
          home: const AppEntry(),
        );
      },
    );
  }
}
