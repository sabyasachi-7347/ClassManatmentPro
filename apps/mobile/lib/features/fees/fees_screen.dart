import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/os_widgets.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});
  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  String _status = 'due';

  Future<void> _recordPayment(Fee fee) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Record ${money.format(fee.amount)}', style: display(20, weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${fee.studentName} · ${fee.period ?? fee.dueDate}', style: TextStyle(color: ctx.os.txt2)),
          const SizedBox(height: 12),
          for (final m in const ['upi', 'cash', 'card', 'bank'])
            ListTile(
              title: Text(m.toUpperCase()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx, m),
            ),
        ]),
      ),
    );
    if (method == null) return;
    try {
      await ref.read(apiProvider).post('/fees/${fee.id}/pay', {'method': method});
      ref.invalidate(feesProvider);
      ref.invalidate(dashboardProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(meProvider).value?.role.isStaff ?? false;
    final fees = ref.watch(feesProvider(_status));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(feesProvider(_status).future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
        children: [
          const ScreenHeader(eyebrow: 'Fees', title: 'Invoices'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'due', label: Text('Due')),
              ButtonSegment(value: 'paid', label: Text('Paid')),
              ButtonSegment(value: '', label: Text('All')),
            ],
            selected: {_status},
            onSelectionChanged: (s) => setState(() => _status = s.first),
          ),
          const SizedBox(height: 14),
          ...fees.when(
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (e, _) => [ErrorRetry(e, onRetry: () => ref.invalidate(feesProvider(_status)))],
            data: (list) {
              final overdue = list.where((f) => f.overdue).toList();
              return [
                if (overdue.isNotEmpty) _OverdueBanner(overdue),
                if (list.isEmpty) const EmptyState('All clear', message: 'No invoices in this view.'),
                for (final f in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: OSCard(
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(f.studentName ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text('${f.period ?? ''}  ·  due ${f.dueDate}',
                                style: mono(11.5, color: context.os.txt2)),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(money.format(f.amount), style: display(20)),
                          const SizedBox(height: 4),
                          _statusPill(f),
                        ]),
                        if (staff && f.status == 'due')
                          IconButton(
                            tooltip: 'Record payment',
                            icon: const Icon(Icons.check_circle_outline_rounded, color: OS.acc),
                            onPressed: () => _recordPayment(f),
                          ),
                      ]),
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
    );
  }

  Widget _statusPill(Fee f) => switch (f.status) {
        'paid' => const Pill('Paid', tone: PillTone.lime),
        'waived' => const Pill('Waived'),
        _ => f.overdue ? const Pill('Overdue', tone: PillTone.hot) : const Pill('Due', tone: PillTone.amb),
      };
}

/// ".bnr" — hot gradient alert.
class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner(this.overdue);
  final List<Fee> overdue;
  @override
  Widget build(BuildContext context) {
    final total = overdue.fold<int>(0, (s, f) => s + f.amount);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [OS.hot, Color(0xFFE03A16)]),
        borderRadius: BorderRadius.circular(OS.r),
        boxShadow: [BoxShadow(color: OS.hot.withValues(alpha: .3), blurRadius: 22, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${overdue.length} overdue', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('${money.format(total)} is past its due date.',
            style: TextStyle(color: Colors.white.withValues(alpha: .92), fontSize: 12.5)),
      ]),
    );
  }
}
