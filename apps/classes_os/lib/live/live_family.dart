import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/tokens.dart';
import '../data/models.dart';
import '../features/student.dart' show leaderRow;
import '../widgets/charts.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import 'live_models.dart';
import 'live_screens.dart';
import 'live_store.dart';

// ------------------------------------------------------------ shared pieces --

/// Rank, attendance and the score history for one child.
class _ChildView {
  final LStudent child;
  final StudentAttendance? att;
  final List<Result> results;
  final TestDetail? latest;
  final List<TestSummary> tests;

  _ChildView(LiveStore s, this.child)
      : att = s.attendance[child.id],
        results = s.results[child.id] ?? const [],
        latest = s.latestTest[child.id],
        tests = s.tests;

  Result? get last => results.isEmpty ? null : results.first;

  /// Positive = moved up the leaderboard since the previous test.
  int? get rankDelta => results.length < 2 ? null : results[1].rank - results[0].rank;

  int? get rate => att?.rate?.round();

  /// Oldest → newest, at most 12, as percentages so totals line up.
  List<Result> get history => results.take(12).toList().reversed.toList();

  double batchAverageFor(Result r) {
    for (final t in tests) {
      if (t.id == r.testId) return t.averagePercent ?? r.percent;
    }
    return r.percent;
  }
}

Widget _scoresChart(BuildContext context, _ChildView v, String you) {
  final c = context.c;
  final h = v.history;
  if (h.length < 2) {
    return Text(
        h.isEmpty ? 'Scores appear here after the first test.' : 'The trend appears after a second test.',
        style: AppType.body(12, color: c.text3));
  }
  return LineChart(
    labels: [for (final r in h) shortDate(r.date)],
    series: [
      Series(name: you, data: [for (final r in h) r.percent], color: c.accent, filled: true),
      Series(name: 'Batch average', data: [for (final r in h) v.batchAverageFor(r)], color: c.text3, dashed: true),
    ],
  );
}

Widget _resultRow(BuildContext context, Result r, {bool big = false}) {
  final c = context.c;
  return Row(
    children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.title, style: AppType.body(big ? 13.5 : 12.5, weight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 3),
          Text('${shortDate(r.date)} · rank ${r.rank} of ${r.outOf}', style: AppType.body(11.5, color: c.text2)),
          if (r.note.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text('“${r.note}”', style: AppType.body(11.5, color: c.text2).copyWith(fontStyle: FontStyle.italic)),
          ],
        ]),
      ),
      Text.rich(TextSpan(children: [
        TextSpan(
            text: _fmt(r.score),
            style: big
                ? AppType.display(24, weight: FontWeight.w700, color: c.text)
                : AppType.mono(14, weight: FontWeight.w600, color: c.text)),
        TextSpan(text: '/${r.maxMarks}', style: AppType.body(12, color: c.text3)),
      ])),
    ],
  );
}

String _fmt(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);

Widget _leaderboard(BuildContext context, TestDetail? t, {String meLabel = 'You'}) {
  final c = context.c;
  return Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PanelHeader(t?.summary.title ?? 'Leaderboard',
            trailing: [if (t != null) Pill(shortDate(t.summary.date), tone: PillTone.accent)]),
        if (t == null || t.rows.isEmpty)
          Text('No marks published yet.', style: AppType.body(12, color: c.text3))
        else
          for (final r in t.rows.take(8))
            leaderRow(
              context,
              LeaderboardRow(rank: r.rank, name: r.name, score: r.score.round(), isMe: r.isMine),
              showMeAsYou: true,
              meLabel: meLabel,
            ),
      ],
    ),
  );
}

Widget _attendanceSummary(BuildContext context, StudentAttendance? att) {
  final c = context.c;
  final now = DateTime.now();
  final month = DateFormat('yyyy-MM').format(now);
  final thisMonth = (att?.sessions ?? const <Session>[]).where((s) => s.date.startsWith(month));
  final attended = thisMonth.where((s) => s.status == 'present' || s.status == 'late').length;
  final missed = thisMonth.where((s) => s.status == 'absent').length;
  Widget count(String v, String label, Color color) => Expanded(
        child: Column(children: [
          Text(v, style: AppType.display(28, weight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: AppType.body(11, color: c.text2)),
        ]),
      );
  return Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PanelHeader(DateFormat('MMMM').format(now)),
        Row(children: [
          count('$attended', 'Attended', c.lime),
          count('$missed', 'Missed', missed > 0 ? c.hot : c.text3),
          count(att?.rate == null ? '—' : '${att!.rate!.round()}%', 'Overall', c.text),
        ]),
      ],
    ),
  );
}

/// Monthly attendance rate for the last six months, for the bar chart.
(List<double>, List<String>) _monthlyRates(StudentAttendance? att) {
  final now = DateTime.now();
  final data = <double>[], labels = <String>[];
  for (var i = 5; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i);
    final key = DateFormat('yyyy-MM').format(m);
    final ss = (att?.sessions ?? const <Session>[]).where((s) => s.date.startsWith(key) && s.status != 'excused');
    final ok = ss.where((s) => s.status == 'present' || s.status == 'late').length;
    data.add(ss.isEmpty ? 0 : ok * 100 / ss.length);
    labels.add(DateFormat('MMM').format(m));
  }
  return (data, labels);
}

String _batchName(LiveStore s, String id) => s.batch(id)?.name ?? 'Class';

// ------------------------------------------------------------------ student --

class LiveStudentScreen extends StatelessWidget {
  final String tab;
  final ValueChanged<String> onJump;
  const LiveStudentScreen({super.key, required this.tab, required this.onJump});

  @override
  Widget build(BuildContext context) {
    final store = LiveScope.of(context);
    if (store.children.isEmpty) {
      return const EmptyState(
          title: 'No student record linked',
          body: 'Ask your institute to link your account to your student record.');
    }
    final v = _ChildView(store, store.children.first);
    return switch (tab) {
      'results' => _results(context, v),
      'syllabus' => _syllabus(context, store, v),
      'attendance' => _attendance(context, store, v),
      _ => _home(context, store, v),
    };
  }

  Widget _home(BuildContext context, LiveStore store, _ChildView v) {
    final c = context.c;
    final last = v.last;
    final delta = v.rankDelta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FeatureCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BATCH RANK', style: AppType.label(Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 8),
                    if (last == null)
                      Text('No tests yet', style: AppType.display(26, weight: FontWeight.w700, color: Colors.white))
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          CountUp(value: last.rank, style: AppType.display(44, weight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(width: 7),
                          Text('of ${last.outOf}', style: AppType.body(15, color: Colors.white.withOpacity(0.6))),
                        ],
                      ),
                    if (delta != null && delta != 0) ...[
                      const SizedBox(height: 7),
                      Text('${delta > 0 ? '↑' : '↓'} ${delta.abs()} since last test',
                          style: AppType.body(12, weight: FontWeight.w600, color: const Color(0xFF9DB6FF))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 18),
              ProgressRing(
                value: (v.rate ?? 0).toDouble(),
                size: 80,
                color: Colors.white,
                track: Colors.white.withOpacity(0.2),
                center: Text(v.rate == null ? '—' : '${v.rate}%',
                    style: AppType.mono(14, weight: FontWeight.w600, color: Colors.white.withOpacity(0.9))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            PanelHeader('Your scores',
                trailing: [AppButton('All', kind: BtnKind.ghost, small: true, onPressed: () => onJump('results'))]),
            _scoresChart(context, v, 'You'),
          ]),
        ),
        const SizedBox(height: 11),
        _leaderboard(context, v.latest),
        const SizedBox(height: 11),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const PanelHeader('Today'),
            if (store.dashboard!.today.isEmpty) Text('No lectures today.', style: AppType.body(12, color: c.text3)),
            for (final l in store.dashboard!.today) ...[
              const HairLine(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 44, child: Text(l.start, style: AppType.mono(11.5, color: c.text2))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.subject.isEmpty ? l.name : l.subject,
                          style: AppType.body(12.5, weight: FontWeight.w600, color: c.text)),
                      Text([l.name, if (l.room.isNotEmpty) l.room].join(' · '), style: AppType.body(11, color: c.text2)),
                    ]),
                  ),
                  if (lectureState(l.start, l.end) == LectureState.live) const Pill('Now', tone: PillTone.hot),
                ]),
              ),
            ],
          ]),
        ),
        if (last != null) ...[
          const SizedBox(height: 11),
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const PanelHeader('Latest result'),
              _resultRow(context, last, big: true),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _results(BuildContext context, _ChildView v) {
    final c = context.c;
    final recent = v.history.length > 6 ? v.history.sublist(v.history.length - 6) : v.history;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const PanelHeader('Marks by test'),
            if (recent.isEmpty)
              Text('No results yet.', style: AppType.body(12, color: c.text3))
            else ...[
              BarChart(data: [for (final r in recent) r.percent], labels: [for (final r in recent) shortDate(r.date)]),
              const SizedBox(height: 6),
              Text('As percentages, so different totals line up.', style: AppType.body(11.5, color: c.text3)),
            ],
          ]),
        ),
        for (final r in v.results) ...[const SizedBox(height: 11), Panel(child: _resultRow(context, r, big: true))],
      ],
    );
  }

  Widget _syllabus(BuildContext context, LiveStore store, _ChildView v) {
    final mine = store.batches.where((b) => v.child.batchIds.contains(b.id)).toList();
    if (mine.isEmpty) return const EmptyState(title: 'No batches yet', body: "You haven't been placed in a batch.");
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final b in mine) SyllabusPanel(batch: b)]);
  }

  Widget _attendance(BuildContext context, LiveStore store, _ChildView v) {
    final c = context.c;
    final missed = v.att?.missed ?? const <Session>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _attendanceSummary(context, v.att),
        const SectionLabel('Lectures you missed'),
        if (missed.isEmpty) Text('None — keep it up.', style: AppType.body(12.5, color: c.text3)),
        for (final m in missed)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Panel(
              child: Row(children: [
                const AvatarBadge('', size: 32, tone: AvatarTone.hot, glyph: '✕'),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_batchName(store, m.batchId), style: AppType.body(13, weight: FontWeight.w600, color: c.text)),
                    Text(shortDate(m.date), style: AppType.body(11.5, color: c.text2)),
                  ]),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------- parent --

class LiveParentScreen extends StatefulWidget {
  final String tab;
  final int childIndex;
  final ValueChanged<int> onChildChanged;
  const LiveParentScreen({super.key, required this.tab, required this.childIndex, required this.onChildChanged});

  @override
  State<LiveParentScreen> createState() => _LiveParentScreenState();
}

class _LiveParentScreenState extends State<LiveParentScreen> {
  String? _acking;

  @override
  Widget build(BuildContext context) {
    final store = LiveScope.of(context);
    final kids = store.children;
    if (kids.isEmpty) {
      return const EmptyState(
          title: 'No children linked',
          body: 'Ask your institute to link your account to your child’s record.');
    }
    final v = _ChildView(store, kids[widget.childIndex.clamp(0, kids.length - 1)]);
    final open = store.absences.where((a) => a.studentId == v.child.id && a.open).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (kids.length > 1) ...[
          Segmented(
            options: [for (final k in kids) k.firstName],
            index: widget.childIndex.clamp(0, kids.length - 1),
            onChanged: (i) {
              HapticFeedback.selectionClick();
              widget.onChildChanged(i);
            },
          ),
          const SizedBox(height: 13),
        ],
        ...switch (widget.tab) {
          'attendance' => _attendance(context, store, v),
          'timetable' => _timetable(store, v),
          _ => _home(context, store, v, open),
        },
      ],
    );
  }

  Future<void> _ack(LiveStore store, Absence a) async {
    if (_acking != null) return;
    HapticFeedback.mediumImpact();
    setState(() => _acking = a.id);
    try {
      await store.acknowledge(a.id);
      if (mounted) showToast(context, 'Acknowledged — the institute can see you’ve seen it');
    } catch (e) {
      if (mounted) showToast(context, '$e');
    } finally {
      if (mounted) setState(() => _acking = null);
    }
  }

  List<Widget> _home(BuildContext context, LiveStore store, _ChildView v, List<Absence> open) {
    final c = context.c;
    final last = v.last;
    final delta = v.rankDelta;
    return [
      for (final a in open.take(3))
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AbsenceBanner(
            absence: a,
            kid: v.child.firstName,
            busy: _acking == a.id,
            onAck: () => _ack(store, a),
          ),
        ),
      BentoGrid(tiles: [
        BentoTile(
          child: v.rate == null
              ? const KpiTile(label: 'Attendance', value: 0, delta: 'no classes yet')
              : KpiTile(
                  label: 'Attendance',
                  value: v.rate!,
                  suffix: '%',
                  delta: '${v.att?.missed.length ?? 0} missed',
                  trend: (v.rate ?? 0) >= 85 ? Trend.flat : Trend.down),
        ),
        BentoTile(
          child: last == null
              ? const KpiTile(label: 'Batch rank', value: 0, delta: 'no tests yet')
              : KpiTile(
                  label: 'Batch rank',
                  value: last.rank,
                  delta: delta == null || delta == 0 ? 'of ${last.outOf}' : '${delta > 0 ? 'up' : 'down'} ${delta.abs()}',
                  trend: delta == null || delta == 0 ? Trend.flat : (delta > 0 ? Trend.up : Trend.down)),
        ),
      ]),
      const SizedBox(height: 11),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PanelHeader('Progress'),
          _scoresChart(context, v, v.child.firstName),
        ]),
      ),
      const SizedBox(height: 11),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PanelHeader('Recent tests'),
          if (v.results.isEmpty) Text('No results yet.', style: AppType.body(12, color: c.text3)),
          for (final r in v.results.take(4)) ...[
            const HairLine(),
            Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: _resultRow(context, r)),
          ],
        ]),
      ),
      const SizedBox(height: 11),
      _leaderboard(context, v.latest, meLabel: v.child.firstName),
    ];
  }

  List<Widget> _attendance(BuildContext context, LiveStore store, _ChildView v) {
    final c = context.c;
    final (data, labels) = _monthlyRates(v.att);
    final absences = {for (final a in store.absences.where((a) => a.studentId == v.child.id)) '${a.batchId}_${a.date}': a};
    final missed = v.att?.missed ?? const <Session>[];
    return [
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PanelHeader('Attendance', trailing: [
            if (v.rate != null) Pill('${v.rate}% overall', tone: (v.rate ?? 0) >= 85 ? PillTone.lime : PillTone.amber),
          ]),
          BarChart(data: data, labels: labels),
        ]),
      ),
      const SectionLabel('Missed lectures'),
      if (missed.isEmpty) Text('No missed lectures.', style: AppType.body(12.5, color: c.text3)),
      for (final m in missed)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Panel(
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_batchName(store, m.batchId), style: AppType.body(13.5, weight: FontWeight.w600, color: c.text)),
                  const SizedBox(height: 3),
                  Text(shortDate(m.date), style: AppType.body(11.5, color: c.text2)),
                ]),
              ),
              if (absences['${m.batchId}_${m.date}'] case final a?)
                a.open
                    ? AppButton(_acking == a.id ? '…' : 'Confirm',
                        kind: BtnKind.primary, small: true, onPressed: () => _ack(store, a))
                    : absencePill(a),
            ]),
          ),
        ),
    ];
  }

  List<Widget> _timetable(LiveStore store, _ChildView v) {
    final mine = store.batches.where((b) => v.child.batchIds.contains(b.id)).toList();
    return [
      const SectionLabel('Next 7 days', padding: EdgeInsets.fromLTRB(4, 0, 4, 10)),
      for (final d in weekAhead(mine)) DayPanel(day: d.$1, slots: d.$2, showSubjectFirst: true),
    ];
  }
}

class _AbsenceBanner extends StatelessWidget {
  final Absence absence;
  final String kid;
  final bool busy;
  final VoidCallback onAck;
  const _AbsenceBanner({required this.absence, required this.kid, required this.busy, required this.onAck});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final a = absence;
    final today = a.date == isoDay(DateTime.now());
    final when = !today || a.markedAt == null ? '' : ', marked ${DateFormat('HH:mm').format(a.markedAt!)}';
    final what = [if (a.topic.isNotEmpty) a.topic, a.batchName].where((s) => s.isNotEmpty).join(' with ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(R.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.hot, const Color(0xFFE0392A)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(today ? 'Absent today' : 'Absent on ${shortDate(a.date)}',
                style: AppType.body(14, weight: FontWeight.w700, color: Colors.white)),
          ]),
          const SizedBox(height: 6),
          Text("$kid wasn't in ${what.isEmpty ? 'class' : what}$when. Confirm you've seen this.",
              style: AppType.body(12.5, color: Colors.white.withOpacity(0.9), height: 1.5)),
          const SizedBox(height: 12),
          AppButton(busy ? 'Sending…' : "I've seen this",
              small: true, overrideBg: Colors.white, overrideFg: c.hot, onPressed: onAck),
        ],
      ),
    );
  }
}
