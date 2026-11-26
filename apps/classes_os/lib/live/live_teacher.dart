import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/tokens.dart';
import '../data/models.dart';
import '../features/teacher.dart' show RailItem;
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import 'live_models.dart';
import 'live_screens.dart';
import 'live_store.dart';

/// Teacher, live: today's rail with real roll calls, the coming week from the
/// batch schedules, and syllabus coverage plus today's absence alerts.
class LiveTeacherScreen extends StatefulWidget {
  final String tab;
  const LiveTeacherScreen({super.key, required this.tab});

  @override
  State<LiveTeacherScreen> createState() => _LiveTeacherScreenState();
}

class _LiveTeacherScreenState extends State<LiveTeacherScreen> {
  /// Batches whose coverage was logged this session — the button turns into a pill.
  final Set<String> _logged = {};
  String? _busy;

  LiveStore get _store => LiveScope.of(context);

  @override
  Widget build(BuildContext context) => switch (widget.tab) {
        'week' => _week(),
        'me' => _me(),
        _ => _today(),
      };

  // ----------------------------------------------------------------- today --
  Widget _today() {
    final c = context.c;
    final store = _store;
    final classes = store.dashboard!.today;
    final minutes = classes.fold<int>(0, (m, x) => m + Slot(0, x.start, x.end).minutes);
    final white60 = AppType.body(11, color: Colors.white.withOpacity(0.6));
    final pending = store.dashboard!.pendingAttendance ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FeatureCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: double.infinity),
              Text('TODAY', style: AppType.label(Colors.white.withOpacity(0.6))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 26,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  _stat(CountUp(value: classes.length, style: AppType.display(44, weight: FontWeight.w700, color: Colors.white)),
                      'lectures', white60),
                  _stat(CountUp(value: store.students.length, style: AppType.display(30, weight: FontWeight.w700, color: Colors.white)),
                      'students', white60),
                  _stat(Text(hoursLabel(minutes), style: AppType.display(30, weight: FontWeight.w700, color: Colors.white)),
                      'teaching', white60),
                ],
              ),
            ],
          ),
        ),
        if (pending > 0) ...[
          const SizedBox(height: 12),
          Panel(
            color: c.amberSoft,
            child: Text(
                '$pending roll call${pending == 1 ? '' : 's'} still to take today. '
                'Parents of absent students are alerted the moment you save.',
                style: AppType.body(12.5, color: c.text, height: 1.5)),
          ),
        ],
        SectionLabel(longDay(DateTime.now())),
        if (classes.isEmpty)
          const EmptyState(
              title: 'No lectures today',
              body: 'Your week is on the Week tab. Schedules are set by the institute office.')
        else
          for (var i = 0; i < classes.length; i++) _rail(classes[i], i == classes.length - 1),
      ],
    );
  }

  Widget _rail(TodayClass cls, bool last) {
    final store = _store;
    final state = lectureState(cls.start, cls.end);
    final att = store.todayAttendance[cls.batchId];
    final batch = store.batch(cls.batchId);
    final roster = store.rosterOf(cls.batchId);
    final canLog = batch != null && batch.syllabus.any((c) => c.status != ChapterStatus.done);

    final lecture = Lecture(
      id: cls.batchId,
      start: cls.start,
      end: cls.end,
      batch: cls.name,
      topic: [cls.subject, if (att != null && att.topic.isNotEmpty) att.topic].where((s) => s.isNotEmpty).join(' — '),
      room: cls.room.isEmpty ? '—' : cls.room,
      state: state,
      present: att?.present ?? 0,
      roster: att?.total ?? roster.length,
    );

    final actions = <Widget>[
      if (!cls.marked)
        AppButton(
          state == LectureState.upcoming ? 'Roll call' : 'Take roll call',
          kind: state == LectureState.upcoming ? BtnKind.plain : BtnKind.primary,
          small: true,
          onPressed: () => _rollCall(cls, roster, const {}),
        )
      else
        AppButton('Edit roll call', small: true, onPressed: () {
          final absent = {
            for (final e in (att?.records ?? const <String, String>{}).entries)
              if (e.value == 'absent') e.key,
          };
          _rollCall(cls, roster, absent);
        }),
      if (state != LectureState.upcoming && canLog && !_logged.contains(cls.batchId))
        AppButton(_busy == cls.batchId ? 'Saving…' : 'Log what you covered',
            kind: BtnKind.dark, small: true, onPressed: () => _log(cls.batchId)),
      if (_logged.contains(cls.batchId)) const Pill('Logged', tone: PillTone.lime),
    ];

    return RailItem(
      lecture: lecture,
      last: last,
      actions: actions,
      badge: cls.marked
          ? Pill('${att?.present ?? 0}/${att?.total ?? roster.length}', tone: PillTone.lime)
          : state == LectureState.live
              ? const Pill('Live', tone: PillTone.hot)
              : state == LectureState.done
                  ? const Pill('Not marked', tone: PillTone.amber)
                  : const SizedBox.shrink(),
    );
  }

  Future<void> _rollCall(TodayClass cls, List<LStudent> roster, Set<String> initialAbsent) {
    HapticFeedback.lightImpact();
    final store = _store;
    return showRollCall(
      context,
      batch: cls.name,
      roster: roster.map(asStudent).toList(),
      initialAbsent: initialAbsent,
      onSave: (absent) async {
        final opened = await store.markAttendance(cls.batchId, roster.map((s) => s.id), absent);
        if (absent.isEmpty) return 'All present — saved';
        // An alert is raised per newly absent student; parents with the app
        // installed get a push, the rest show as unacknowledged for staff.
        return opened > 0
            ? '${absent.length} absent · $opened absence alert${opened == 1 ? '' : 's'} raised'
            : '${absent.length} absent · saved';
      },
    );
  }

  Future<void> _log(String batchId) async {
    if (_busy != null) return;
    HapticFeedback.lightImpact();
    setState(() => _busy = batchId);
    try {
      final pct = await _store.logCoverage(batchId);
      if (!mounted) return;
      setState(() => _logged.add(batchId));
      showToast(context, pct == null ? 'Logged' : 'Coverage now $pct%');
    } catch (e) {
      if (mounted) showToast(context, '$e');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _stat(Widget n, String label, TextStyle style) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [n, const SizedBox(height: 4), Text(label, style: style)],
      );

  // ------------------------------------------------------------------ week --
  Widget _week() {
    final days = weekAhead(_store.batches);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Next 7 days', padding: EdgeInsets.fromLTRB(4, 0, 4, 10)),
        for (final d in days) DayPanel(day: d.$1, slots: d.$2),
      ],
    );
  }

  // -------------------------------------------------------------------- me --
  Widget _me() {
    final c = context.c;
    final store = _store;
    final open = store.absences.where((a) => a.open).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PanelHeader('Absences today', trailing: [
                if (open.isNotEmpty)
                  AppButton('Nudge ${open.length}', small: true, onPressed: () async {
                    try {
                      final n = await store.nudge(ids: open.map((a) => a.id).toList());
                      if (mounted) showToast(context, 'Reminded $n parent${n == 1 ? '' : 's'}');
                    } catch (e) {
                      if (mounted) showToast(context, '$e');
                    }
                  }),
              ]),
              if (store.absences.isEmpty)
                Text('No absences marked today.', style: AppType.body(12.5, color: c.text3)),
              for (var i = 0; i < store.absences.length; i++) ...[
                if (i > 0) const HairLine(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    AvatarBadge(store.absences[i].studentName,
                        size: 30, tone: store.absences[i].open ? AvatarTone.hot : AvatarTone.accent),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(store.absences[i].studentName,
                            style: AppType.body(13, weight: FontWeight.w600, color: c.text)),
                        Text(store.absences[i].batchName, style: AppType.body(11.5, color: c.text2)),
                      ]),
                    ),
                    absencePill(store.absences[i]),
                  ]),
                ),
              ],
            ],
          ),
        ),
        const SectionLabel('Syllabus'),
        if (store.batches.isEmpty)
          const EmptyState(title: 'No batches yet', body: 'The office assigns you to batches.'),
        for (final b in store.batches)
          SyllabusPanel(
            batch: b,
            action: b.syllabus.any((c) => c.status != ChapterStatus.done)
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton(_busy == b.id ? 'Saving…' : 'Mark current chapter done',
                        small: true, onPressed: () => _log(b.id)),
                  )
                : null,
          ),
        const SectionLabel('Account'),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            KeyValue('Name', store.me.name, first: true),
            KeyValue('Email', store.me.email),
            KeyValue('Institute', store.me.instituteName ?? '—'),
          ]),
        ),
      ],
    );
  }
}
