// Firebase config for Smart Bus Tracker (same project as admin_web).
// For Android/iOS builds, run `flutterfire configure` to register native apps.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String projectId = 'smart-bus-tracker-ddn';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDnF_PZ1itL3pfVz44K75sFSA8-Pp44prI',
    appId: '1:874405254050:web:9c2eef4bd3cbe6a581d8fb',
    messagingSenderId: '874405254050',
    projectId: projectId,
    authDomain: 'smart-bus-tracker-ddn.firebaseapp.com',
    storageBucket: 'smart-bus-tracker-ddn.firebasestorage.app',
  );

  /// Uses web app id until a dedicated Android app is registered in Firebase Console.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDnF_PZ1itL3pfVz44K75sFSA8-Pp44prI',
    appId: '1:874405254050:web:9c2eef4bd3cbe6a581d8fb',
    messagingSenderId: '874405254050',
    projectId: projectId,
    storageBucket: 'smart-bus-tracker-ddn.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDnF_PZ1itL3pfVz44K75sFSA8-Pp44prI',
    appId: '1:874405254050:web:9c2eef4bd3cbe6a581d8fb',
    messagingSenderId: '874405254050',
    projectId: projectId,
    storageBucket: 'smart-bus-tracker-ddn.firebasestorage.app',
    iosBundleId: 'com.example.smartBusTrackerMobile',
  );
}
