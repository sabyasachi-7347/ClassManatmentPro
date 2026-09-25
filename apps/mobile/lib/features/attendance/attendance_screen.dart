import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../widgets/os_widgets.dart';

/// Selected batch for the attendance tab (null = first batch).
final attendanceBatchProvider = NotifierProvider<AttendanceBatch, String?>(AttendanceBatch.new);

class AttendanceBatch extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String id) => state = id;
}

typedef _RosterKey = ({String batchId, String date});

class _Roster {
  _Roster(this.students, this.existing);
  final List<Student> students;
  final Map<String, AttendanceStatus> existing;
  bool get alreadyMarked => existing.isNotEmpty;
}

final _rosterProvider = FutureProvider.family<_Roster, _RosterKey>((ref, key) async {
  final api = ref.watch(apiProvider);
  final results = await Future.wait([
    api.get<List<dynamic>>('/students', query: {'batchId': key.batchId}),
    api.get<List<dynamic>>('/attendance/batches/${key.batchId}', query: {'from': key.date, 'to': key.date}),
  ]);
  final students = results[0].map((s) => Student.fromJson(s as Json)).toList();
  final sessions = results[1];
  final records = sessions.isEmpty ? <String, dynamic>{} : (sessions.first as Json)['records'] as Json;
  return _Roster(students, records.map((k, v) => MapEntry(k, statusFrom(v as String?))));
});

const _next = {
  AttendanceStatus.present: AttendanceStatus.absent,
  AttendanceStatus.absent: AttendanceStatus.late,
  AttendanceStatus.late: AttendanceStatus.excused,
  AttendanceStatus.excused: AttendanceStatus.present,
};

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _date = DateTime.now();
  final Map<String, AttendanceStatus> _marks = {};
  _RosterKey? _loadedFor;
  bool _saving = false;

  String get _dateIso => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _save(String batchId) async {
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).put('/attendance/batches/$batchId/$_dateIso', {
        'records': [
          for (final e in _marks.entries) {'studentId': e.key, 'status': e.value.name},
        ],
      });
      ref.invalidate(dashboardProvider);
      ref.invalidate(_rosterProvider((batchId: batchId, date: _dateIso)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved')));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final batches = ref.watch(batchesProvider);
    return batches.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorRetry(e, onRetry: () => ref.invalidate(batchesProvider)),
      data: (list) {
        if (list.isEmpty) return const EmptyState('No batches assigned to you');
        final selected = ref.watch(attendanceBatchProvider) ?? list.first.id;
        final key = (batchId: selected, date: _dateIso);
        final roster = ref.watch(_rosterProvider(key));

        // Reset local marks whenever the batch/date changes and fresh data arrives.
        roster.whenData((r) {
          if (_loadedFor != key) {
            _loadedFor = key;
            _marks
              ..clear()
              ..addAll({for (final s in r.students) s.id: r.existing[s.id] ?? AttendanceStatus.present});
          }
        });

        int count(AttendanceStatus s) => _marks.values.where((m) => m == s).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
          children: [
            ScreenHeader(
              eyebrow: 'Attendance',
              title: DateFormat('EEE, d MMM').format(_date),
              sub: roster.value?.alreadyMarked == true
                  ? 'Already marked — saving will overwrite.'
                  : 'Everyone starts present. Tap to cycle status.',
            ),
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final b in list)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(b.name),
                      selected: b.id == selected,
                      onSelected: (_) => ref.read(attendanceBatchProvider.notifier).select(b.id),
                    ),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: const Text('Date'),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              _Count('Present', count(AttendanceStatus.present), OS.lime),
              _Count('Absent', count(AttendanceStatus.absent), OS.hot),
              _Count('Late', count(AttendanceStatus.late), OS.amb),
            ]),
            const SizedBox(height: 14),
            ...roster.when(
              loading: () => [const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))],
              error: (e, _) => [ErrorRetry(e, onRetry: () => ref.invalidate(_rosterProvider(key)))],
              data: (r) => [
                if (r.students.isEmpty) const EmptyState('No students in this batch'),
                for (final s in r.students)
                  _StudentRow(
                    student: s,
                    status: _marks[s.id] ?? AttendanceStatus.present,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _marks[s.id] = _next[_marks[s.id] ?? AttendanceStatus.present]!);
                    },
                  ),
                if (r.students.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : () => _save(selected),
                    child: Text(_saving ? 'Saving…' : 'Save attendance'),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: context.os.surf2, borderRadius: BorderRadius.circular(OS.r)),
          child: Column(children: [
            Text('$value', style: display(24, color: color)),
            const SizedBox(height: 4),
            Lab(label),
          ]),
        ),
      );
}

/// ".prs" row — red border + fill when absent.
class _StudentRow extends StatelessWidget {
  const _StudentRow({required this.student, required this.status, required this.onTap});
  final Student student;
  final AttendanceStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.os;
    final absent = status == AttendanceStatus.absent;
    final (tone, mark) = switch (status) {
      AttendanceStatus.present => (PillTone.lime, '✓'),
      AttendanceStatus.absent => (PillTone.hot, '✕'),
      AttendanceStatus.late => (PillTone.amb, 'L'),
      AttendanceStatus.excused => (PillTone.neutral, 'E'),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: absent ? c.hotSoft : c.surf,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OS.r),
          side: BorderSide(color: absent ? OS.hot : c.line, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(OS.r),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(children: [
              Avatar(student.name),
              const SizedBox(width: 13),
              Expanded(child: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w500))),
              Pill(status.name, tone: tone),
              const SizedBox(width: 10),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: absent ? OS.hot : c.limeSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(mark,
                    style: TextStyle(fontWeight: FontWeight.w700, color: absent ? Colors.white : OS.lime)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
