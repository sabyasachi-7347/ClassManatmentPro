import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/no_institute_screen.dart';
import 'widgets/os_widgets.dart';

/// Re-evaluates router redirects whenever auth or /me changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
    ref.listen(meProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final me = ref.read(meProvider);
      final loc = state.matchedLocation;

      if (auth.isLoading) return loc == '/splash' ? null : '/splash';
      if (auth.value == null) return loc == '/login' ? null : '/login';
      if (me.isLoading && !me.hasValue) return loc == '/splash' ? null : '/splash';
      if (me.hasError) return loc == '/error' ? null : '/error';
      if (me.value?.hasInstitute != true) return loc == '/welcome' ? null : '/welcome';
      return const ['/login', '/splash', '/welcome', '/error'].contains(loc) ? '/' : null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeShell()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const NoInstituteScreen()),
      GoRoute(
        path: '/splash',
        builder: (_, _) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/error',
        builder: (_, _) => Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ErrorRetry(
              ref.watch(meProvider).error ?? 'Could not reach the server',
              onRetry: () => ref.invalidate(meProvider),
            ),
          ),
        ),
      ),
    ],
  );
});

class ClassesOsApp extends ConsumerWidget {
  const ClassesOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'CLASSES.OS',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
