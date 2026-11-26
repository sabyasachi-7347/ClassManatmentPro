import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/tokens.dart';
import '../data/models.dart';
import '../shell/nav_config.dart';
import '../widgets/primitives.dart';
import 'live_admin.dart';
import 'live_family.dart';
import 'live_models.dart';
import 'live_store.dart';
import 'live_teacher.dart';

/// Picks the live screen for a role and handles the first load and errors,
/// so the role screens only ever draw data that exists.
class LiveScreen extends StatelessWidget {
  final Role role;
  final String tab;
  final ValueChanged<String> onJump;
  final int childIndex;
  final ValueChanged<int> onChildChanged;

  const LiveScreen({
    super.key,
    required this.role,
    required this.tab,
    required this.onJump,
    required this.childIndex,
    required this.onChildChanged,
  });

  @override
  Widget build(BuildContext context) {
    final store = LiveScope.of(context);
    if (store.dashboard == null) {
      if (store.loading) return const Padding(padding: EdgeInsets.only(top: 4), child: SkeletonGrid());
      return LiveError(message: store.error ?? 'Nothing loaded yet.', onRetry: store.load);
    }
    return switch (role) {
      Role.teacher => LiveTeacherScreen(tab: tab),
      Role.student => LiveStudentScreen(tab: tab, onJump: onJump),
      Role.parent => LiveParentScreen(tab: tab, childIndex: childIndex, onChildChanged: onChildChanged),
      _ => LiveAdminScreen(tab: tab),
    };
  }
}

/// The phone header, in the signed-in person's own terms.
MobileHeader? liveHeader(LiveStore store, Role role, int childIndex) {
  final me = store.me;
  final inst = me.instituteName ?? '';
  switch (role) {
    case Role.teacher:
      final subjects = {for (final b in store.batches) if (b.subject.isNotEmpty) b.subject}.join(', ');
      final n = store.batches.length;
      return MobileHeader('Teacher', me.name,
          [if (subjects.isNotEmpty) subjects, '$n batch${n == 1 ? '' : 'es'}'].join(' · '));
    case Role.student:
      final kid = store.children.isEmpty ? null : store.children.first;
      return MobileHeader(kid?.grade.isNotEmpty == true ? kid!.grade : 'Student', kid?.name ?? me.name, inst);
    case Role.parent:
      final n = store.children.length;
      return MobileHeader('Parent', me.name, '$n child${n == 1 ? '' : 'ren'} · $inst');
    default:
      return null;
  }
}

class LiveError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const LiveError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Panel(
      color: c.hotSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Couldn't load", style: AppType.body(14, weight: FontWeight.w700, color: c.hot)),
          const SizedBox(height: 6),
          Text(message, style: AppType.body(12.5, color: c.text2, height: 1.5)),
          const SizedBox(height: 12),
          AppButton('Try again', kind: BtnKind.primary, small: true, onPressed: onRetry),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ helpers --

/// "Thursday 26 November"
String longDay(DateTime d) => DateFormat('EEEE d MMMM').format(d);

/// "05 Aug" from "2026-08-05"
String shortDate(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : DateFormat('dd MMM').format(d);
}

/// "6h45" / "45m"
String hoursLabel(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
}

int _minutesOf(String hhmm) {
  final p = hhmm.split(':');
  return p.length == 2 ? (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0) : 0;
}

/// Where a lecture is right now, by the clock.
LectureState lectureState(String start, String end, [DateTime? now]) {
  final t = now ?? DateTime.now();
  final m = t.hour * 60 + t.minute;
  if (m >= _minutesOf(end)) return LectureState.done;
  if (m >= _minutesOf(start)) return LectureState.live;
  return LectureState.upcoming;
}

/// The roll call and roster rows take the prototype's Student model.
Student asStudent(LStudent s) => Student(
      id: s.id,
      name: s.name,
      roll: s.grade.isNotEmpty ? s.grade : (s.phone.isNotEmpty ? s.phone : ''),
      standard: s.grade,
      batchIds: s.batchIds,
      attendance: 0,
      average: 0,
    );

/// The coming seven days of a set of batches, for week and timetable views.
List<(DateTime, List<(Slot, LBatch)>)> weekAhead(List<LBatch> batches, {int days = 7}) {
  final today = DateTime.now();
  return [
    for (var i = 0; i < days; i++)
      () {
        final d = DateTime(today.year, today.month, today.day + i);
        final dow = d.weekday % 7; // DateTime: Mon=1..Sun=7 → API: Sun=0
        final slots = [
          for (final b in batches)
            for (final s in b.schedule)
              if (s.day == dow) (s, b),
        ]..sort((a, b) => a.$1.start.compareTo(b.$1.start));
        return (d, slots);
      }(),
  ];
}

/// One day's panel in a week view.
class DayPanel extends StatelessWidget {
  final DateTime day;
  final List<(Slot, LBatch)> slots;
  final bool showSubjectFirst;
  const DayPanel({super.key, required this.day, required this.slots, this.showSubjectFirst = false});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PanelHeader(isToday ? 'Today · ${DateFormat('EEEE d').format(day)}' : DateFormat('EEEE d').format(day),
                trailing: [
                  Pill(slots.isEmpty ? 'Free' : '${slots.length} lecture${slots.length == 1 ? '' : 's'}',
                      tone: isToday ? PillTone.accent : PillTone.neutral),
                ]),
            if (slots.isEmpty)
              Text('No lectures', style: AppType.body(12, color: c.text3)),
            for (var i = 0; i < slots.length; i++) ...[
              if (i > 0) const HairLine(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 44, child: Text(slots[i].$1.start, style: AppType.mono(11.5, color: c.text2))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(showSubjectFirst && slots[i].$2.subject.isNotEmpty ? slots[i].$2.subject : slots[i].$2.name,
                            style: AppType.body(12.5, weight: FontWeight.w600, color: c.text)),
                        Text(
                            [
                              if (showSubjectFirst) slots[i].$2.name,
                              '${slots[i].$1.start}–${slots[i].$1.end}',
                              if (slots[i].$2.room.isNotEmpty) slots[i].$2.room,
                            ].join(' · '),
                            style: AppType.body(11, color: c.text2)),
                      ]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A batch's syllabus as a progress bar and chapter checklist.
class SyllabusPanel extends StatelessWidget {
  final LBatch batch;
  final Widget? action;
  const SyllabusPanel({super.key, required this.batch, this.action});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final pct = batch.syllabusPercent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PanelHeader(batch.name, trailing: [
              Text(pct == null ? '—' : '$pct%',
                  style: AppType.display(22, weight: FontWeight.w700, color: c.text)),
            ]),
            if (pct == null)
              Text('No syllabus set up for this batch yet.', style: AppType.body(12, color: c.text3))
            else ...[
              ProgressBar(pct.toDouble()),
              const SizedBox(height: 12),
              for (var i = 0; i < batch.syllabus.length; i++) ...[
                if (i > 0) const HairLine(),
                _chapterRow(c, batch.syllabus[i]),
              ],
            ],
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }

  Widget _chapterRow(AppColors c, Chapter ch) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: switch (ch.status) {
                ChapterStatus.done => c.accent,
                ChapterStatus.current => c.amberSoft,
                ChapterStatus.todo => c.line2,
              },
              border: ch.status == ChapterStatus.current ? Border.all(color: c.amber, width: 1.5) : null,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(ch.title,
                style: AppType.body(12.5,
                    weight: ch.status == ChapterStatus.current ? FontWeight.w600 : FontWeight.w400,
                    color: ch.status == ChapterStatus.todo ? c.text3 : c.text)),
          ),
          if (ch.status == ChapterStatus.current) const Pill('In class', tone: PillTone.amber),
        ]),
      );
}

/// Absence acknowledgement as a pill.
Widget absencePill(Absence a) => switch (a.state) {
      AbsenceState.acknowledged => Pill(
          a.ackAt == null ? 'Seen' : 'Seen ${DateFormat('HH:mm').format(a.ackAt!)}',
          tone: PillTone.lime),
      AbsenceState.waiting => const Pill('Waiting', tone: PillTone.amber),
      AbsenceState.silent => Pill('Silent ${a.hoursWaiting} hrs', tone: PillTone.hot),
    };
