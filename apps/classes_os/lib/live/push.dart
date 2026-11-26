import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'config.dart';

/// Registers this device for push and reacts to incoming messages.
///
/// Skipped on web (it needs a service worker and VAPID key) and against the
/// emulators (there is no FCM emulator). Every failure is swallowed: push is
/// an enhancement, the app works without it.
class PushRegistrar {
  PushRegistrar(this.api, {required this.onMessage});

  final ApiClient api;

  /// Called for a message received in the foreground, or one tapped from the tray.
  final void Function(RemoteMessage message, {required bool tapped}) onMessage;

  final List<StreamSubscription<dynamic>> _subs = [];
  String? _token;

  static bool get supported => !kIsWeb && !AppConfig.useEmulators;

  Future<void> start() async {
    if (!supported) return;
    try {
      final fm = FirebaseMessaging.instance;
      final perm = await fm.requestPermission();
      if (perm.authorizationStatus == AuthorizationStatus.denied) return;

      _token = await fm.getToken();
      if (_token != null) await api.post<Json>('/me/devices', {'token': _token});
      _subs.add(fm.onTokenRefresh.listen((t) async {
        _token = t;
        await api.post<Json>('/me/devices', {'token': t});
      }));

      _subs.add(FirebaseMessaging.onMessage.listen((m) => onMessage(m, tapped: false)));
      _subs.add(FirebaseMessaging.onMessageOpenedApp.listen((m) => onMessage(m, tapped: true)));
      final initial = await fm.getInitialMessage();
      if (initial != null) onMessage(initial, tapped: true);
    } catch (e) {
      debugPrint('push registration failed: $e');
    }
  }

  /// Unregister before sign-out so the next person on this phone doesn't get
  /// the previous user's alerts.
  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    final t = _token;
    if (t == null) return;
    try {
      await api.delete<dynamic>('/me/devices/${Uri.encodeComponent(t)}');
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _token = null;
  }
}
