import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/tokens.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../widgets/app_table.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import 'student.dart' show leaderRow;

/// Which modules this faculty member holds. The classes admin grants these in
/// the real app; here the chips on the desk toggle them so every combination
/// can be seen. Kept outside the widget so it survives tab switches.
final ValueNotifier<List<FacultyModule>> _modules =
    ValueNotifier(List.of(Mock.facultyModules));

/// Faculty — non-teaching staff, one institute.
///
/// Capabilities are granted module by module rather than by a fixed sub-role,
/// so a timetable-only person and an attendance-only person see completely
/// different desks. The dashboard is assembled from whichever modules are on.
class FacultyScreen extends StatelessWidget {
  final String tab;
  const FacultyScreen({super.key, required this.tab});

  @override
  Widget build(BuildContext context) => switch (tab) {
        'attendance' => _attendance(context),
        'timetable' => _timetable(context),
        _ => ValueListenableBuilder<List<FacultyModule>>(
            valueListenable: _modules,
            builder: (context, mods, _) => _desk(context, mods),
          ),
      };

  // ------------------------------------------------------------------ desk --
  Widget _desk(BuildContext context, List<FacultyModule> mods) {
    final c = context.c;
    bool on(String k) => mods.any((m) => m.key == k && m.enabled);
    final onCount = mods.where((m) => m.enabled).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle('Afternoon, Priya',
            subtitle: 'Sunrise Academy · $onCount of ${mods.length} modules'),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final m in mods)
              ModuleChip(
                label: m.name,
                glyph: m.glyph,
                on: m.enabled,
                onTap: () {
                  HapticFeedback.selectionClick();
                  _modules.value = [
                    for (final x in mods) x.key == m.key ? x.copyWith(enabled: !x.enabled) : x,
                  ];
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Toggle a module to see the desk change. The classes admin sets this in the real app.',
            style: AppType.body(11.5, color: c.text3)),
        const SizedBox(height: 20),
        BentoGrid(tiles: [
          BentoTile(
            span: 2,
            child: FeatureCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ABSENT TODAY', style: AppType.label(Colors.white.withOpacity(0.6))),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CountUp(
                          value: 14,
                          style: AppType.display(44, weight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('12 parents acknowledged\n2 still silent',
                              style: AppType.body(12.5,
                                  color: Colors.white.withOpacity(0.72), height: 1.45)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppButton('Nudge the silent two',
                      small: true,
                      overrideBg: Colors.white,
                      overrideFg: c.accent,
                      onPressed: () => showToast(context, 'Nudged 2 parents')),
                ],
              ),
            ),
          ),
          const BentoTile(
              child: KpiTile(label: 'Papers to correct', value: 38, delta: 'Weekly Test 15')),
          const BentoTile(
              child: KpiTile(label: 'Meeting requests', value: 3, delta: '2 new', trend: Trend.up)),
          if (on('attendance')) BentoTile(span: 2, child: _absenceCard(context)),
          if (on('performance')) BentoTile(span: 2, child: _leaderboardCard(context)),
          if (on('parents')) BentoTile(span: 2, child: _meetingsCard(context)),
          if (on('timetable')) BentoTile(span: 2, child: _acceptanceCard(context)),
        ]),
        if (onCount == 0) ...[
          const SizedBox(height: 12),
          const EmptyState(
              title: 'No modules on',
              body: 'Turn a module on above to put its work on your desk.'),
        ],
      ],
    );
  }

  Widget _absenceCard(BuildContext context) {
    final c = context.c;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PanelHeader('Absence alerts', trailing: [Pill('1 silent', tone: PillTone.hot)]),
          for (var i = 0; i < Mock.absences.length; i++) ...[
            if (i > 0) const HairLine(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                AvatarBadge(Mock.absences[i].student,
                    size: 30,
                    tone: Mock.absences[i].state == AckState.acknowledged
                        ? AvatarTone.accent
                        : AvatarTone.hot),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Mock.absences[i].student,
                        style: AppType.body(13, weight: FontWeight.w600, color: c.text)),
                    Text('${Mock.absences[i].batch} · ${Mock.absences[i].markedAt}',
                        style: AppType.body(11.5, color: c.text2)),
                  ]),
                ),
                switch (Mock.absences[i].state) {
                  AckState.acknowledged =>
                    Pill('Seen ${Mock.absences[i].ackAt ?? ''}', tone: PillTone.lime),
                  AckState.waiting => const Pill('Waiting', tone: PillTone.amber),
                  AckState.silent => AppButton('Call',
                      kind: BtnKind.primary,
                      small: true,
                      onPressed: () => showToast(context, 'Dialling ${Mock.absences[i].parent}')),
                },
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _leaderboardCard(BuildContext context) => Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PanelHeader('Leaderboard', trailing: [
              AppButton('Broadcast',
                  small: true, onPressed: () => showToast(context, 'Published to 38 students')),
            ]),
            for (final l in Mock.leaderboard) leaderRow(context, l),
          ],
        ),
      );

  Widget _meetingsCard(BuildContext context) {
    final c = context.c;
    const reqs = [
      ('S. Kadri', 'Rehan', 'Falling test scores', true),
      ('M. Pawar', 'Yash', 'Attendance', true),
      ('K. Bhagat', 'Om', 'Progress review', false),
    ];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PanelHeader('Meeting requests'),
          for (var i = 0; i < reqs.length; i++) ...[
            if (i > 0) const HairLine(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: reqs[i].$1,
                          style: AppType.body(13, weight: FontWeight.w600, color: c.text)),
                      TextSpan(
                          text: " · ${reqs[i].$2}'s parent",
                          style: AppType.body(13, color: c.text2)),
                    ])),
                    const SizedBox(height: 2),
                    Text(reqs[i].$3, style: AppType.body(11.5, color: c.text2)),
                  ]),
                ),
                if (reqs[i].$4)
                  AppButton('Offer slot',
                      kind: BtnKind.primary,
                      small: true,
                      onPressed: () => showToast(context, 'Offered Sat 10:30'))
                else
                  const Pill('Offered', tone: PillTone.accent),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _acceptanceCard(BuildContext context) {
    final c = context.c;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PanelHeader('Schedule acceptance',
              trailing: [Pill('Week of 11 Aug', tone: PillTone.amber)]),
          for (var i = 0; i < Mock.teachers.length; i++) ...[
            if (i > 0) const HairLine(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                AvatarBadge(Mock.teachers[i].name, size: 30, tone: AvatarTone.accent),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Mock.teachers[i].name,
                        style: AppType.body(13, weight: FontWeight.w600, color: c.text)),
                    Text(Mock.teachers[i].load, style: AppType.body(11.5, color: c.text2)),
                  ]),
                ),
                if (Mock.teachers[i].acceptedSchedule)
                  const Pill('Accepted', tone: PillTone.lime)
                else
                  AppButton('Nudge',
                      small: true,
                      onPressed: () => showToast(context, 'Nudged ${Mock.teachers[i].name}')),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------ attendance --
  Widget _attendance(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageTitle('Attendance', subtitle: 'Friday 8 August · compiled from class'),
        const BentoGrid(tiles: [
          BentoTile(child: KpiTile(label: 'Present', value: 398, delta: 'of 412')),
          BentoTile(
              child: KpiTile(
                  label: 'Absent', value: 14, delta: '3 more than usual', trend: Trend.down)),
          BentoTile(
              child: KpiTile(label: 'Acknowledged', value: 12, delta: 'of 14', trend: Trend.up)),
          BentoTile(child: KpiTile(label: 'Teachers in', value: 9, delta: 'all signed')),
        ]),
        const SizedBox(height: 14),
        TablePanel(
          title: 'Absences',
          trailing: [
            AppButton('Nudge silent', small: true, onPressed: () => showToast(context, 'Nudged 2')),
            AppButton('Export',
                kind: BtnKind.primary, small: true, onPressed: () => showToast(context, 'Exported')),
          ],
          columns: const [
            TableCol('Student', width: 200),
            TableCol('Batch', width: 120),
            TableCol('Lecture', width: 170),
            TableCol('Marked', width: 100),
            TableCol('Parent', width: 120),
            TableCol('Acknowledgement', width: 150),
          ],
          rows: [
            for (final a in Mock.absences)
              [
                TPerson(a.student, tone: AvatarTone.hot),
                TCell(a.batch, muted: true),
                TCell(a.lecture, muted: true),
                TCell(a.markedAt, mono: true, muted: true),
                TCell(a.parent, muted: true),
                Align(
                  alignment: Alignment.centerLeft,
                  child: switch (a.state) {
                    AckState.acknowledged => Pill('Seen ${a.ackAt ?? ''}', tone: PillTone.lime),
                    AckState.waiting => const Pill('Waiting', tone: PillTone.amber),
                    AckState.silent => const Pill('Silent 18 hrs', tone: PillTone.hot),
                  },
                ),
              ],
          ],
        ),
        const SectionLabel('Cancellations'),
        Panel(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Std XII — Physics · Wed 13 Aug 18:00',
                      style: AppType.body(14, weight: FontWeight.w600, color: c.text)),
                  const SizedBox(height: 3),
                  Text('V. Raghavan is away. 26 students affected, parents not told.',
                      style: AppType.body(12, color: c.text2)),
                ]),
              ),
              AppButton('Notify parents',
                  kind: BtnKind.primary,
                  small: true,
                  onPressed: () => showToast(context, '26 parents notified')),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- timetable --
  Widget _timetable(BuildContext context) {
    final c = context.c;
    const cellW = 112.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('Timetable', subtitle: 'Week of 11 August · tap an empty slot to fill it'),
        Panel(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PanelHeader('Weekly grid', trailing: [
                AppButton('Copy last week',
                    small: true, onPressed: () => showToast(context, 'Copied last week')),
                AppButton('Publish',
                    kind: BtnKind.primary,
                    small: true,
                    onPressed: () => showToast(context, 'Sent to 9 teachers')),
              ]),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const SizedBox(width: 52),
                      for (final d in Mock.weekDays)
                        SizedBox(
                          width: cellW + 8,
                          child: Center(
                            child: Text(d,
                                style: AppType.body(11, weight: FontWeight.w600, color: c.text2)),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 6),
                    for (var ri = 0; ri < Mock.slots.length; ri++)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 52,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(Mock.slots[ri], style: AppType.mono(11, color: c.text2)),
                            ),
                          ),
                          for (var ci = 0; ci < Mock.weekDays.length; ci++)
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: SizedBox(
                                width: cellW,
                                height: 54,
                                child: _slot(context, ri, ci),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _slot(BuildContext context, int ri, int ci) {
    final c = context.c;
    final has = (ri + ci) % 3 != 1;
    final b = Mock.batches[(ri + ci) % Mock.batches.length];
    if (has) {
      return Material(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showToast(context, '${b.name} · ${Mock.slots[ri]}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(b.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.body(11, weight: FontWeight.w600, color: c.accent, height: 1.25)),
                const SizedBox(height: 2),
                Text(b.teacher,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.body(10, color: c.text2)),
              ],
            ),
          ),
        ),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showToast(context, 'Add lecture'),
      child: CustomPaint(
        painter: _DashedBorder(c.line),
        child: Center(child: Text('+', style: AppType.body(16, color: c.text3))),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  final Color color;
  _DashedBorder(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(14)).deflate(0.75));
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
