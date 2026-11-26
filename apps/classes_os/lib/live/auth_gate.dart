import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../data/models.dart';
import '../shell/app_shell.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import 'api_client.dart';
import 'config.dart';
import 'live_models.dart';
import 'live_store.dart';
import 'push.dart';

/// The app's role for an API role. Owner and admin share the classes-admin desk.
Role? appRoleFor(ApiRole r) => switch (r) {
      ApiRole.owner || ApiRole.admin => Role.classesAdmin,
      ApiRole.teacher => Role.teacher,
      ApiRole.student => Role.student,
      ApiRole.parent => Role.parent,
      ApiRole.none => null,
    };

/// Signed out → login. Signed in → load /me, then the shell for that one role.
class AuthGate extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  const AuthGate({super.key, required this.isDark, required this.onToggleTheme});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _auth = FirebaseAuth.instance;
  late final ApiClient _api = ApiClient(_auth);
  late final StreamSubscription<User?> _sub;

  User? _user;
  bool _resolving = true;
  String? _error;
  LiveStore? _store;
  PushRegistrar? _push;

  @override
  void initState() {
    super.initState();
    // userChanges, not idTokenChanges: a token refresh must not rebuild the app.
    _sub = _auth.userChanges().listen(_onUser);
  }

  Future<void> _onUser(User? user) async {
    if (user?.uid == _user?.uid && _store != null) return;
    _user = user;
    await _push?.stop();
    _push = null;
    _store?.dispose();
    _store = null;
    if (user == null) {
      setState(() => _resolving = false);
      return;
    }
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      final me = Me.fromJson(await _api.get<Json>('/me'));
      if (!mounted || _user?.uid != user.uid) return;
      if (me.hasInstitute) {
        final store = LiveStore(_api, me);
        _store = store;
        unawaited(store.load());
        _push = PushRegistrar(_api, onMessage: (m, {required tapped}) {
          store.load(quiet: true);
          final n = m.notification;
          if (!tapped && n != null && mounted) {
            showToast(context, n.title ?? 'New notification');
          }
        });
        unawaited(_push!.start());
      } else {
        _store = null;
        _error = me.role == ApiRole.none
            ? 'This account (${me.email}) isn\'t a member of any institute yet. '
                'Ask your institute to invite you, then sign in again.'
            : 'Your institute could not be loaded.';
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _resolving = false);
  }

  Future<void> _signOut() async {
    await _push?.stop();
    _push = null;
    await _auth.signOut();
  }

  @override
  void dispose() {
    _sub.cancel();
    _push?.stop();
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_resolving) return const _Splash();
    if (_user == null) return const LoginScreen();
    final store = _store;
    final role = store == null ? null : appRoleFor(store.me.role);
    if (store == null || role == null) {
      return _Problem(
        message: _error ?? 'Something went wrong.',
        onRetry: () => _onUser(_auth.currentUser),
        onSignOut: _signOut,
      );
    }
    return LiveScope(
      store: store,
      child: AppShell(
        isDark: widget.isDark,
        onToggleTheme: widget.onToggleTheme,
        liveRole: role,
        onSignOut: _signOut,
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('classes.os', style: AppType.display(26, weight: FontWeight.w700, color: c.text)),
          const SizedBox(height: 18),
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: c.accent),
          ),
        ]),
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;
  const _Problem({required this.message, required this.onRetry, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Panel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Can't open your workspace",
                        style: AppType.display(20, weight: FontWeight.w600, color: c.text)),
                    const SizedBox(height: 8),
                    Text(message, style: AppType.body(13, color: c.text2, height: 1.5)),
                    const SizedBox(height: 18),
                    BigButton('Try again', kind: BtnKind.primary, onPressed: onRetry),
                    const SizedBox(height: 8),
                    BigButton('Sign out', onPressed: onSignOut),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email.text.trim(), password: _password.text);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = switch (e.code) {
            'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Wrong email or password.',
            'too-many-requests' => 'Too many attempts. Wait a minute and try again.',
            'network-request-failed' => 'No connection to the sign-in server.',
            _ => e.message ?? 'Sign-in failed.',
          });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first, then tap "Forgot password".');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) showToast(context, 'Reset link sent to $email');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('classes.os', style: AppType.display(22, weight: FontWeight.w700, color: c.text)),
                    const SizedBox(height: 28),
                    Text('Welcome back', style: AppType.display(30, weight: FontWeight.w600, color: c.text)),
                    const SizedBox(height: 6),
                    Text('Sign in with the account your institute created for you.',
                        style: AppType.body(13.5, color: c.text2, height: 1.5)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(hintText: 'you@email.com'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _signIn(),
                      decoration: const InputDecoration(hintText: 'Password'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: AppType.body(12.5, color: c.hot, height: 1.4)),
                    ],
                    const SizedBox(height: 18),
                    BigButton(_busy ? 'Signing in…' : 'Sign in',
                        kind: BtnKind.primary, onPressed: _busy ? () {} : _signIn),
                    const SizedBox(height: 6),
                    TextButton(onPressed: _reset, child: const Text('Forgot password?')),
                    if (AppConfig.useEmulators) ...[
                      const SizedBox(height: 14),
                      Text('Local test build · API ${AppConfig.apiUrl}',
                          textAlign: TextAlign.center, style: AppType.mono(10.5, color: c.text3)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
