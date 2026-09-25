import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'api_client.dart';
import 'models.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);

/// Emits on sign-in/out and whenever the ID token (and so custom claims) changes.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).idTokenChanges(),
);

final apiProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(firebaseAuthProvider)));

final meProvider = FutureProvider<Me?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return Me.fromJson(await ref.watch(apiProvider).get<Json>('/me'));
});

String todayIso() => DateFormat('yyyy-MM-dd').format(DateTime.now());

final dashboardProvider = FutureProvider<Dashboard>((ref) async {
  final json = await ref.watch(apiProvider).get<Json>('/dashboard', query: {'date': todayIso()});
  return Dashboard.fromJson(json);
});

final batchesProvider = FutureProvider<List<Batch>>((ref) async {
  final list = await ref.watch(apiProvider).get<List<dynamic>>('/batches');
  return list.map((b) => Batch.fromJson(b as Json)).toList();
});

final feesProvider = FutureProvider.family<List<Fee>, String>((ref, status) async {
  final list = await ref.watch(apiProvider).get<List<dynamic>>(
    '/fees',
    query: status.isEmpty ? null : {'status': status},
  );
  return list.map((f) => Fee.fromJson(f as Json)).toList();
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final list = await ref.watch(apiProvider).get<List<dynamic>>('/announcements');
  return list.map((a) => Announcement.fromJson(a as Json)).toList();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
  void toggle(Brightness current) =>
      state = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

final money = NumberFormat.decimalPattern();
