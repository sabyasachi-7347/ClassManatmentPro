import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (AppConfig.useEmulators) {
      await FirebaseAuth.instance.useAuthEmulator(AppConfig.localHost, 9099);
    }
  } catch (e) {
    // Without this, an init failure leaves the native splash up forever.
    runApp(_StartupError(e));
    return;
  }
  runApp(const ProviderScope(child: ClassesOsApp()));
}

class _StartupError extends StatelessWidget {
  const _StartupError(this.error);

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Startup failed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SelectableText('$error'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
