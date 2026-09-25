import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/os_widgets.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).value;
    final brightness = Theme.of(context).brightness;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
      children: [
        const ScreenHeader(eyebrow: 'Account', title: 'More'),
        OSCard(
          child: Row(children: [
            Avatar(me?.name ?? me?.email ?? '?', color: OS.acc),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(me?.name ?? me?.email ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${me?.instituteName ?? ''} · ${me?.role?.name ?? ''}',
                    style: TextStyle(color: context.os.txt2, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        OSCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            SwitchListTile(
              title: const Text('Dark mode'),
              value: brightness == Brightness.dark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(brightness),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Sign out'),
              onTap: () => ref.read(firebaseAuthProvider).signOut(),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Center(child: Text('API: ${AppConfig.apiUrl}', style: mono(10.5, color: context.os.txt3))),
      ],
    );
  }
}
