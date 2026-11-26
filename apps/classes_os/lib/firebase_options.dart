// Firebase configuration.
//
// For a real project, generate the platform options with the FlutterFire CLI
// (it also writes android/app/google-services.json and the iOS plist):
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
//
// Until then the app can run against the local emulators (USE_EMULATORS=true),
// or in demo mode, which needs no Firebase at all.
import 'package:firebase_core/firebase_core.dart';

import 'live/config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (AppConfig.useEmulators) {
      // Any values work against the local emulators.
      return const FirebaseOptions(
        apiKey: 'demo-api-key',
        appId: '1:000000000000:android:0000000000000000',
        messagingSenderId: '000000000000',
        projectId: 'demo-classes-os',
      );
    }
    throw UnsupportedError('Firebase is not configured — run `flutterfire configure`.');
  }
}
