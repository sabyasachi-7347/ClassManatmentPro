import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../widgets/charts.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';

/// Student — phone only. Scoped to their own batch.
class StudentScreen extends StatelessWidget {
  final String tab;
  final void Function(String tab) onJump;

  const StudentScreen({super.key, required this.tab, required this.onJump});

  @override
  Widget build(BuildContext context) => switch (tab) {
        'results' => _results(context),
        'syllabus' => _syllabus(context),
        'attendance' => _attendance(context),
        _ => _home(context),
      };

  // ------------------------------------------------------------------ home --
  Widget _home(BuildContext context) {
    final c = context.c;
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        CountUp(
                            value: 4,
                            style: AppType.display(44, weight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(width: 7),
                        Text('of 38',
                            style: AppType.body(15, color: Colors.white.withOpacity(0.6))),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text('↑ 2 since last mock',
                        style: AppType.body(12, weight: FontWeight.w600, color: const Color(0xFF9DB6FF))),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              ProgressRing(
                value: 94,
                size: 80,
                color: Colors.white,
                track: Colors.white.withOpacity(0.2),
                center: Text('94%',
                    style: AppType.mono(14, weight: FontWeight.w600, color: Colors.white.withOpacity(0.9))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PanelHeader('Your scores', trailing: [
                AppButton('Details', kind: BtnKind.ghost, small: true,
                    onPressed: () => showToast(context, 'Full performance')),
              ]),
              LineChart(labels: Mock.months, series: [
                Series(name: 'You', data: Mock.myScores, color: c.accent, filled: true),
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
              const PanelHeader('Mock series 03', trailing: [Pill('Live', tone: PillTone.amber)]),
              for (final l in Mock.leaderboard) leaderRow(context, l, showMeAsYou: true),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader('Next up'),
              for (final l in Mock.today.skip(2).take(3)) ...[
                const HairLine(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: 44,
                          child: Text(l.start, style: AppType.mono(11.5, color: c.text2))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.topic,
                              style: AppType.body(12.5, weight: FontWeight.w600, color: c.text)),
                          Text(l.batch, style: AppType.body(11, color: c.text2)),
                        ]),
                      ),
                      if (l.state == LectureState.live) const Pill('Now', tone: PillTone.hot),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 11),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PanelHeader('Latest result', trailing: [
                AppButton('All', kind: BtnKind.ghost, small: true, onPressed: () => onJump('results')),
              ]),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  CountUp(value: 68, style: AppType.display(44, weight: FontWeight.w700, color: c.text)),
                  const SizedBox(width: 9),
                  Text('/ 80', style: AppType.body(15, color: c.text2)),
                  const Spacer(),
                  const Pill('Rank 4', tone: PillTone.lime),
                ],
              ),
              const SizedBox(height: 7),
              Text('Weekly Test 14 — Physics · 05 Aug', style: AppType.body(12.5, color: c.text2)),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- results --
  Widget _results(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader('Marks by test'),
              const BarChart(data: Mock.marksByTest, labels: Mock.testLabels),
              const SizedBox(height: 6),
              Text('As percentages, so different totals line up.',
                  style: AppType.body(11.5, color: c.text3)),
            ],
          ),
        ),
        for (final r in Mock.results) ...[
          const SizedBox(height: 11),
          Panel(
            child: Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.test, style: AppType.body(13.5, weight: FontWeight.w600, color: c.text)),
                    const SizedBox(height: 3),
                    Text('${r.date} · rank ${r.rank} of ${r.outOf}',
                        style: AppType.body(11.5, color: c.text2)),
                  ]),
                ),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: '${r.score}',
                      style: AppType.display(24, weight: FontWeight.w700, color: c.text)),
                  TextSpan(text: '/${r.max}', style: AppType.body(12, color: c.text3)),
                ])),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------- syllabus --
  Widget _syllabus(BuildContext context) {
    final c = context.c;
    const chapters = [
      ('Units & Measurements', _Ch.done),
      ('Kinematics', _Ch.done),
      ('Laws of Motion', _Ch.done),
      ('Rotational Dynamics', _Ch.now),
      ('Gravitation', _Ch.todo),
      ('Thermodynamics', _Ch.todo),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in Mock.batches.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PanelHeader(b.name, trailing: [
                    Text('${b.syllabus}%',
                        style: AppType.display(22, weight: FontWeight.w700, color: c.text)),
                  ]),
                  ProgressBar(b.syllabus.toDouble()),
                  const SizedBox(height: 14),
                  for (var i = 0; i < chapters.length; i++) ...[
                    if (i > 0) const HairLine(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(children: [
                        Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: switch (chapters[i].$2) {
                              _Ch.done => c.accent,
                              _Ch.now => c.amberSoft,
                              _Ch.todo => c.line2,
                            },
                            border: chapters[i].$2 == _Ch.now
                                ? Border.all(color: c.amber, width: 1.5)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(chapters[i].$1,
                              style: AppType.body(12.5,
                                  weight: chapters[i].$2 == _Ch.now ? FontWeight.w600 : FontWeight.w400,
                                  color: chapters[i].$2 == _Ch.todo ? c.text3 : c.text)),
                        ),
                        if (chapters[i].$2 == _Ch.now) const Pill('In class', tone: PillTone.amber),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------ attendance --
  Widget _attendance(BuildContext context) {
    final c = context.c;
    Widget count(String v, String label, Color color) => Expanded(
          child: Column(children: [
            Text(v, style: AppType.display(28, weight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(label, style: AppType.body(11, color: c.text2)),
          ]),
        );
    const missed = [
      ('02 Aug', 'Electrostatics — Gauss Law', 'HSC Physics'),
      ('24 Jul', 'Laws of Motion — Friction', 'JEE Adv A'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader('This month'),
              Row(children: [
                count('17', 'Attended', c.lime),
                count('2', 'Missed', c.hot),
                count('94%', 'Overall', c.text),
              ]),
            ],
          ),
        ),
        const SectionLabel('Lectures you missed'),
        for (final m in missed)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Panel(
              child: Row(children: [
                const AvatarBadge('', size: 32, tone: AvatarTone.hot, glyph: '✕'),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.$2, style: AppType.body(13, weight: FontWeight.w600, color: c.text)),
                    Text('${m.$3} · ${m.$1}', style: AppType.body(11.5, color: c.text2)),
                  ]),
                ),
                const Pill('Parent seen', tone: PillTone.lime),
              ]),
            ),
          ),
      ],
    );
  }
}

enum _Ch { done, now, todo }

/// A leaderboard row. Shared with the faculty desk.
Widget leaderRow(BuildContext context, LeaderboardRow l, {bool showMeAsYou = false}) {
  final c = context.c;
  final me = showMeAsYou && l.isMe;
  return Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: me ? c.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(R.sm),
    ),
    child: Row(children: [
      SizedBox(
        width: 28,
        child: Text(l.rank.toString().padLeft(2, '0'),
            style: AppType.mono(12, weight: FontWeight.w600, color: me ? c.accent : c.text3)),
      ),
      if (!showMeAsYou) ...[
        AvatarBadge(l.name, size: 27),
        const SizedBox(width: 10),
      ],
      Expanded(
        child: Text(me ? 'You' : l.name,
            style: AppType.body(13, weight: me ? FontWeight.w700 : FontWeight.w500, color: me ? c.accent : c.text)),
      ),
      Text('${l.score}',
          style: AppType.mono(13, weight: FontWeight.w600, color: me ? c.accent : c.text)),
    ]),
  );
}
