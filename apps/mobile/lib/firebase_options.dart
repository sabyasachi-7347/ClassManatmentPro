// Placeholder. Generate the real file with the FlutterFire CLI:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=<your-firebase-project-id>
//
// That command overwrites this file with your project's Android/iOS options.
import 'package:firebase_core/firebase_core.dart';

import 'core/config.dart';

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
    throw UnsupportedError(
      'Firebase is not configured. Run `flutterfire configure` '
      '(see apps/mobile/README.md) or run with --dart-define=USE_EMULATORS=true.',
    );
  }
}
