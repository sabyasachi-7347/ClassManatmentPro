import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Build-time configuration. Override with --dart-define, e.g.
///   flutter run --dart-define=API_URL=https://api.example.com/api/v1
///   flutter run --dart-define=USE_EMULATORS=true
class AppConfig {
  static const bool useEmulators = bool.fromEnvironment('USE_EMULATORS');
  static const String _apiUrl = String.fromEnvironment('API_URL');

  /// Android emulators reach the host machine at 10.0.2.2, not localhost.
  static String get localHost =>
      !kIsWeb && Platform.isAndroid ? '10.0.2.2' : 'localhost';

  static String get apiUrl =>
      _apiUrl.isNotEmpty ? _apiUrl : 'http://$localHost:3000/api/v1';
}
