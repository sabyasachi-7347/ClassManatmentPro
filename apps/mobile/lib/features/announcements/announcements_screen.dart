import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/os_widgets.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  Future<void> _compose(BuildContext context, WidgetRef ref) async {
    final title = TextEditingController();
    final body = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('New announcement', style: display(20, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(controller: body, maxLines: 4, decoration: const InputDecoration(labelText: 'Message')),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Post')),
        ]),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(apiProvider).post('/announcements', {'title': title.text, 'body': body.text});
      ref.invalidate(announcementsProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPost = ref.watch(meProvider).value?.role.canTeach ?? false;
    final list = ref.watch(announcementsProvider);
    return Stack(children: [
      RefreshIndicator(
        onRefresh: () => ref.refresh(announcementsProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
          children: [
            const ScreenHeader(eyebrow: 'Notices', title: 'Announcements'),
            ...list.when(
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (e, _) => [ErrorRetry(e, onRetry: () => ref.invalidate(announcementsProvider))],
              data: (items) => [
                if (items.isEmpty) const EmptyState('No announcements yet'),
                for (final a in items) _AnnouncementCard(a),
              ],
            ),
          ],
        ),
      ),
      if (canPost)
        Positioned(
          right: 18,
          bottom: 88,
          child: FloatingActionButton(
            backgroundColor: OS.acc,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _compose(context, ref),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
    ]);
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard(this.a);
  final Announcement a;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: OSCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(a.title, style: display(16, weight: FontWeight.w600))),
              if (a.createdAt != null)
                Text(DateFormat('d MMM').format(a.createdAt!.toLocal()),
                    style: TextStyle(fontSize: 11.5, color: context.os.txt3)),
            ]),
            const SizedBox(height: 8),
            Text(a.body, style: const TextStyle(height: 1.45)),
            if (a.authorName != null) ...[
              const SizedBox(height: 8),
              Text('— ${a.authorName}', style: TextStyle(fontSize: 12, color: context.os.txt2)),
            ],
          ]),
        ),
      );
}
