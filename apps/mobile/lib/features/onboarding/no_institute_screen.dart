import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';

/// Signed in but not a member of any institute. Institutes are created on the web app;
/// members are invited by an admin.
class NoInstituteScreen extends ConsumerWidget {
  const NoInstituteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Almost there', style: display(28, weight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(
                '${auth.currentUser?.email} isn’t linked to an institute yet. '
                'Ask your institute admin to invite you, then tap refresh.',
                style: TextStyle(color: context.os.txt2, height: 1.5),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  await auth.currentUser?.getIdToken(true);
                  ref.invalidate(meProvider);
                },
                child: const Text('Refresh'),
              ),
              TextButton(onPressed: auth.signOut, child: const Text('Sign out')),
            ],
          ),
        ),
      ),
    );
  }
}
