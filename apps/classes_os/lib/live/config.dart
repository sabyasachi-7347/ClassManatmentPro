import 'package:flutter/foundation.dart';

/// Build-time configuration, set with --dart-define:
///
///   DEMO=true            prototype mode: mock data and the role switcher
///   USE_EMULATORS=true   local Firebase emulators + API on this machine
///   API_URL=https://…    the deployed NestJS API (…/api/v1)
///   EMULATOR_HOST=…      host running the emulators/API when testing on a
///                        real phone (your computer's LAN IP)
class AppConfig {
  const AppConfig._();

  static const bool demo = bool.fromEnvironment('DEMO');
  static const bool useEmulators = bool.fromEnvironment('USE_EMULATORS');
  static const String _apiUrl = String.fromEnvironment('API_URL');
  static const String _emulatorHost = String.fromEnvironment('EMULATOR_HOST');

  /// Android emulators reach the host machine at 10.0.2.2, not localhost.
  static String get localHost {
    if (_emulatorHost.isNotEmpty) return _emulatorHost;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
    return 'localhost';
  }

  static String get apiUrl => _apiUrl.isNotEmpty ? _apiUrl : 'http://$localHost:3000/api/v1';
}
