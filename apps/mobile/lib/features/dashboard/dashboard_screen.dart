import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/os_widgets.dart';
import '../attendance/attendance_screen.dart';
import '../home/home_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider).value;
    final dash = ref.watch(dashboardProvider);
    final first = (me?.name ?? me?.email ?? '').split(RegExp(r'[\s@]')).first;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dashboardProvider.future),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
        children: [
          ScreenHeader(
            eyebrow: me?.instituteName ?? 'Today',
            title: 'Hi, $first',
            sub: DateFormat('EEEE, d MMMM').format(DateTime.now()),
          ),
          dash.when(
            loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => ErrorRetry(e, onRetry: () => ref.invalidate(dashboardProvider)),
            data: (d) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ..._tiles(d),
              const SizedBox(height: 12),
              _TodayCard(d: d),
            ]),
          ),
        ],
      ),
    );
  }

  List<Widget> _tiles(Dashboard d) {
    Widget pair(Widget a, Widget b) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: a),
              const SizedBox(width: 12),
              Expanded(child: b),
            ]),
          ),
        );

    if (d.role.isStaff) {
      return [
        FeatureCard(
          label: 'Attendance today',
          value: d.attendanceRate == null ? '—' : '${d.attendanceRate}%',
          caption: '${d.attendancePresent ?? 0} of ${d.attendanceTotal ?? 0} marked present',
        ),
        pair(
          StatTile(label: 'Active students', value: '${d.activeStudents ?? 0}'),
          StatTile(label: 'Batches', value: '${d.batchCount}'),
        ),
        pair(
          StatTile(label: 'Fees due', value: money.format(d.feesDueAmount ?? 0)),
          StatTile(label: 'Overdue', value: '${d.feesOverdue ?? 0}', hot: (d.feesOverdue ?? 0) > 0),
        ),
      ];
    }
    if (d.role == Role.teacher) {
      return [
        FeatureCard(
          label: 'Classes today',
          value: '${d.todaysClasses.length}',
          caption: '${d.pendingAttendance ?? 0} still need attendance',
        ),
        pair(
          StatTile(label: 'My batches', value: '${d.batchCount}'),
          StatTile(label: 'Pending', value: '${d.pendingAttendance ?? 0}', hot: (d.pendingAttendance ?? 0) > 0),
        ),
      ];
    }
    final due = d.dues.fold<int>(0, (s, f) => s + f.amount);
    return [
      for (final s in d.students)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FeatureCard(
            label: '${s['name']} · attendance 30d',
            value: s['attendanceRate30d'] == null ? '—' : '${s['attendanceRate30d']}%',
          ),
        ),
      pair(
        StatTile(label: 'Fees due', value: money.format(due), hot: due > 0),
        StatTile(label: 'Batches', value: '${d.batchCount}'),
      ),
    ];
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.d});
  final Dashboard d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OSCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('Today’s classes', style: display(15, weight: FontWeight.w600)),
          const Spacer(),
          Pill('${d.todaysClasses.length}'),
        ]),
        if (d.todaysClasses.isEmpty) const EmptyState('No classes today', message: 'Enjoy the breather.'),
        for (final c in d.todaysClasses)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(children: [
              Text(c.start, style: mono(12, color: context.os.txt3, weight: FontWeight.w600)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text([c.subject, if (c.room != null) c.room].join(' · '),
                      style: TextStyle(fontSize: 12, color: context.os.txt2)),
                ]),
              ),
              if (d.role.canTeach)
                c.attendanceMarked
                    ? const Pill('Marked', tone: PillTone.lime)
                    : TextButton(
                        onPressed: () {
                          ref.read(attendanceBatchProvider.notifier).select(c.batchId);
                          ref.read(homeTabProvider.notifier).goTo('Attendance', d.role);
                        },
                        child: const Text('Take'),
                      ),
            ]),
          ),
      ]),
    );
  }
}
