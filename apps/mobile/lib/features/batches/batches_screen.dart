import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/os_widgets.dart';

const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

class BatchesScreen extends ConsumerWidget {
  const BatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(batchesProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(batchesProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
        children: [
          const ScreenHeader(eyebrow: 'Classes', title: 'Your batches'),
          ...batches.when(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (e, _) => [ErrorRetry(e, onRetry: () => ref.invalidate(batchesProvider))],
            data: (list) => [
              if (list.isEmpty) const EmptyState('No batches yet'),
              for (final b in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: OSCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(b.name, style: display(17, weight: FontWeight.w600))),
                        Pill(b.subject, tone: PillTone.acc),
                      ]),
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        for (final s in b.schedule) Pill('${_days[s.day]} ${s.start}–${s.end}'),
                        if (b.schedule.isEmpty)
                          Text('No schedule yet', style: TextStyle(color: context.os.txt3, fontSize: 12)),
                      ]),
                      if (b.room != null) ...[
                        const SizedBox(height: 8),
                        Text('Room ${b.room}', style: TextStyle(color: context.os.txt2, fontSize: 12)),
                      ],
                    ]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
