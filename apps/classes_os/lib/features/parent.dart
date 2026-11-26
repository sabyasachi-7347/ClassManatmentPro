import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/tokens.dart';
import '../data/mock_data.dart';
import '../widgets/charts.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import '../widgets/swipe_row.dart';

/// Whether the parent has acknowledged today's absence. Shared between the
/// home banner and the attendance list so confirming in one clears the other.
/// In the real app this is the AckState the API returns.
final ValueNotifier<bool> _acknowledged = ValueNotifier(false);

const _kids = ['Aarav', 'Sara'];

/// Parent — phone only. Read-only on their child, plus two requests.
///
/// The absence alert is the one screen in the app with a live state machine
/// behind it: a teacher marks the absence mid-lecture, FCM pushes it here, the
/// parent acknowledges, and faculty can see who has not.
class ParentScreen extends StatelessWidget {
  final String tab;
  final int childIndex;
  final ValueChanged<int> onChildChanged;

  const ParentScreen({
    super.key,
    required this.tab,
    required this.childIndex,
    required this.onChildChanged,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: _acknowledged,
        builder: (context, ack, _) => switch (tab) {
          'attendance' => _attendance(context, ack),
          'timetable' => const _Timetable(),
          _ => _home(context, ack),
        },
      );

  // ------------------------------------------------------------------ home --
  Widget _home(BuildContext context, bool ack) {
    final c = context.c;
    final kid = _kids[childIndex.clamp(0, _kids.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Segmented(
          options: _kids,
          index: childIndex,
          onChanged: (i) {
            HapticFeedback.selectionClick();
            onChildChanged(i);
          },
        ),
        const SizedBox(height: 13),
        AnimatedSize(
          duration: Motion.base,
          curve: Motion.ease,
          child: ack
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AbsenceBanner(
                    kid: kid,
                    onAck: () {
                      HapticFeedback.mediumImpact();
                      _acknowledged.value = true;
                      showToast(context, 'Acknowledged');
                    },
                    onCall: () => showToast(context, 'Calling the office'),
                  ),
                ),
        ),
        const BentoGrid(tiles: [
          BentoTile(
              child: KpiTile(label: 'Attendance', value: 94, suffix: '%', delta: '2 missed')),
          BentoTile(child: KpiTile(label: 'Batch rank', value: 4, delta: 'up 2', trend: Trend.up)),
        ]),
        const SizedBox(height: 11),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PanelHeader('Progress', trailing: [
                AppButton('Report', kind: BtnKind.ghost, small: true,
                    onPressed: () => showToast(context, 'Full report')),
              ]),
              LineChart(labels: Mock.months, series: [
                Series(name: kid, data: Mock.myScores, color: c.accent, filled: true),
                Series(name: 'Batch average', data: Mock.batchAverage, color: c.text3, dashed: true),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader('Recent tests'),
              for (final r in Mock.results.take(3)) ...[
                const HairLine(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.test, style: AppType.body(12.5, weight: FontWeight.w600, color: c.text)),
                        Text('${r.date} · rank ${r.rank}/${r.outOf}',
                            style: AppType.body(11, color: c.text2)),
                      ]),
                    ),
                    Text('${r.score}/${r.max}',
                        style: AppType.mono(14, weight: FontWeight.w600, color: c.text)),
                  ]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 11),
        Panel(
          color: c.accentSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Mock 04 · 12 August',
                  style: AppType.body(14, weight: FontWeight.w700, color: c.accent)),
              const SizedBox(height: 6),
              Text('PCM, 300 marks, 3 hours. Everything up to Rotational Dynamics.',
                  style: AppType.body(12.5, color: c.text2, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader('Parent meeting'),
              Text('Term review, Saturday 16 August 10:00–13:00, Kalyan West. 15-minute slots.',
                  style: AppType.body(12.5, color: c.text2, height: 1.5)),
              const SizedBox(height: 12),
              AppButton('Book a slot', kind: BtnKind.primary, small: true,
                  onPressed: () => showToast(context, 'Booked 10:30')),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ attendance --
  Widget _attendance(BuildContext context, bool ack) {
    final c = context.c;
    final missed = [
      ('Today 11:34', 'Moment of Inertia', 'JEE Adv B', ack),
      ('02 Aug 09:15', 'Electrostatics', 'HSC Physics', true),
      ('24 Jul 07:00', 'Laws of Motion', 'JEE Adv A', true),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PanelHeader('Attendance', trailing: [Pill('94% this term', tone: PillTone.lime)]),
              BarChart(data: Mock.attendanceByMonth, labels: Mock.attendanceMonths),
            ],
          ),
        ),
        const SectionLabel('Missed lectures'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Swipe a row left for quick actions',
              style: AppType.body(11.5, color: c.text3)),
        ),
        for (final m in missed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SwipeRow(
              actions: [
                SwipeAction(
                    label: 'Call',
                    glyph: '☎',
                    background: const Color(0xFF0A0C14),
                    onTap: () => showToast(context, 'Calling the office')),
                SwipeAction(
                    label: 'Reason',
                    glyph: '✎',
                    background: c.accent,
                    onTap: () => showToast(context, 'Reason sent')),
              ],
              child: Panel(
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.$2, style: AppType.body(13.5, weight: FontWeight.w600, color: c.text)),
                      const SizedBox(height: 3),
                      Text('${m.$3} · ${m.$1}', style: AppType.body(11.5, color: c.text2)),
                    ]),
                  ),
                  if (m.$4)
                    const Pill('Seen', tone: PillTone.lime)
                  else
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _acknowledged.value = true;
                        showToast(context, 'Acknowledged');
                      },
                      child: const Pill('Confirm', tone: PillTone.hot),
                    ),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}

class _AbsenceBanner extends StatelessWidget {
  final String kid;
  final VoidCallback onAck, onCall;
  const _AbsenceBanner({required this.kid, required this.onAck, required this.onCall});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
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
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text('Absent right now',
                style: AppType.body(14, weight: FontWeight.w700, color: Colors.white)),
          ]),
          const SizedBox(height: 6),
          Text(
              "$kid wasn't in Moment of Inertia with JEE Adv B, marked 11:34. "
              "Confirm you've seen this.",
              style: AppType.body(12.5, color: Colors.white.withOpacity(0.9), height: 1.5)),
          const SizedBox(height: 12),
          Wrap(spacing: 7, runSpacing: 7, children: [
            AppButton("I've seen this",
                small: true, overrideBg: Colors.white, overrideFg: c.hot, onPressed: onAck),
            AppButton('Call office',
                small: true,
                overrideBg: Colors.white.withOpacity(0.18),
                overrideFg: Colors.white,
                onPressed: onCall),
          ]),
        ],
      ),
    );
  }
}

class _Timetable extends StatefulWidget {
  const _Timetable();

  @override
  State<_Timetable> createState() => _TimetableState();
}

class _TimetableState extends State<_Timetable> {
  int _view = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Segmented(
          options: const ['Week', 'Month'],
          index: _view,
          onChanged: (i) {
            setState(() => _view = i);
            if (i == 1) showToast(context, 'Month view');
          },
        ),
        const SizedBox(height: 13),
        for (final d in const ['Monday 11', 'Tuesday 12', 'Wednesday 13'])
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PanelHeader(d),
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const HairLine(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 44,
                              child: Text(Mock.today[i].start,
                                  style: AppType.mono(11.5, color: c.text2))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(Mock.today[i].topic,
                                  style: AppType.body(12.5, weight: FontWeight.w600, color: c.text)),
                              Text(Mock.today[i].batch, style: AppType.body(11, color: c.text2)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
