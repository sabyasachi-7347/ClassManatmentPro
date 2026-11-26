import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'firebase_options.dart';
import 'live/auth_gate.dart';
import 'live/config.dart';
import 'shell/app_shell.dart';

/// Two ways to run:
///
/// * Live (default when Firebase is configured): sign in, and the app opens
///   the one role your account holds, with real data from the API.
/// * Demo (`--dart-define=DEMO=true`, or when Firebase isn't configured yet):
///   mock data and a role switcher across all eight roles.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var live = false;
  if (!AppConfig.demo) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      if (AppConfig.useEmulators) {
        await FirebaseAuth.instance.useAuthEmulator(AppConfig.localHost, 9099);
      }
      live = true;
    } catch (e) {
      debugPrint('Firebase not configured, starting in demo mode: $e');
    }
  }
  runApp(ClassesOsApp(live: live));
}

class ClassesOsApp extends StatefulWidget {
  final bool live;
  const ClassesOsApp({super.key, this.live = false});

  @override
  State<ClassesOsApp> createState() => _ClassesOsAppState();
}

class _ClassesOsAppState extends State<ClassesOsApp> {
  ThemeMode _mode = ThemeMode.light;

  bool get _isDark => _mode == ThemeMode.dark;

  void _toggle() => setState(() => _mode = _isDark ? ThemeMode.light : ThemeMode.dark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'classes.os',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: _mode,
      home: widget.live
          ? AuthGate(isDark: _isDark, onToggleTheme: _toggle)
          : AppShell(isDark: _isDark, onToggleTheme: _toggle),
    );
  }
}
