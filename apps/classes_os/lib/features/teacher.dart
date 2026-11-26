import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/tokens.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';

/// Session state that outlives a tab switch. Lives here rather than in the
/// shell because nothing outside the teacher screens reads it.
final ValueNotifier<bool> _scheduleAccepted = ValueNotifier(false);
final ValueNotifier<Set<String>> _logged = ValueNotifier(<String>{});

/// Teacher — phone only. Scoped to assigned batches.
///
/// The day rail is the signature piece: lectures run down a vertical spine,
/// the live one is ringed and pulsing, and a finished lecture turns into a
/// "log what you covered" prompt so the syllabus update happens where the
/// lecture was rather than in a separate menu.
class TeacherScreen extends StatefulWidget {
  final String tab;
  const TeacherScreen({super.key, required this.tab});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  int _week = 0;

  /// Availability for the coming week. true = available.
  final List<(String, String, bool)> _avail = [
    ('Mon 11 Aug', 'Available', true),
    ('Tue 12 Aug', 'Away — family', false),
    ('Wed 13 Aug', 'Away — family', false),
    ('Thu 14 Aug', 'Available', true),
    ('Fri 15 Aug', 'Available', true),
  ];

  @override
  Widget build(BuildContext context) => switch (widget.tab) {
        'week' => _weekView(),
        'me' => _me(),
        _ => _today(),
      };

  // ----------------------------------------------------------------- today --
  Widget _today() {
    final c = context.c;
    final white60 = AppType.body(11, color: Colors.white.withOpacity(0.6));
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
                  _stat(CountUp(value: 5, style: AppType.display(44, weight: FontWeight.w700, color: Colors.white)), 'lectures', white60),
                  _stat(CountUp(value: 172, style: AppType.display(30, weight: FontWeight.w700, color: Colors.white)), 'students', white60),
                  _stat(Text('6h45', style: AppType.display(30, weight: FontWeight.w700, color: Colors.white)), 'teaching', white60),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable: _scheduleAccepted,
          builder: (context, accepted, _) => AnimatedSize(
            duration: Motion.base,
            curve: Motion.ease,
            child: accepted
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Panel(
                      color: c.amberSoft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Next week's schedule",
                              style: AppType.body(14, weight: FontWeight.w700, color: c.amber)),
                          const SizedBox(height: 6),
                          Text('18 hours, 3 batches, week of 11 Aug.',
                              style: AppType.body(12.5, color: c.text2, height: 1.5)),
                          const SizedBox(height: 12),
                          Wrap(spacing: 7, runSpacing: 7, children: [
                            AppButton('Accept', kind: BtnKind.primary, small: true, onPressed: () {
                              HapticFeedback.lightImpact();
                              _scheduleAccepted.value = true;
                              showToast(context, 'Accepted');
                            }),
                            AppButton('Conflict', small: true,
                                onPressed: () => showToast(context, 'Raise a conflict')),
                          ]),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        const SectionLabel('Friday 8 August'),
        ValueListenableBuilder<Set<String>>(
          valueListenable: _logged,
          builder: (context, logged, _) => Column(
            children: [
              for (var i = 0; i < Mock.today.length; i++)
                RailItem(
                  lecture: Mock.today[i],
                  last: i == Mock.today.length - 1,
                  logged: logged.contains(Mock.today[i].id),
                  onRoll: () {
                    HapticFeedback.lightImpact();
                    showRollCall(context, batch: Mock.today[i].batch);
                  },
                  onSyllabus: () => showToast(context, 'Syllabus'),
                  onLog: () {
                    HapticFeedback.lightImpact();
                    _logged.value = {...logged, Mock.today[i].id};
                    showToast(context, 'Coverage now 64%');
                  },
                  onCant: () => showToast(context, 'Office and parents told'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(Widget n, String label, TextStyle style) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [n, const SizedBox(height: 4), Text(label, style: style)],
      );

  // ------------------------------------------------------------------ week --
  Widget _weekView() {
    final c = context.c;
    const days = ['Monday 11', 'Tuesday 12', 'Wednesday 13', 'Thursday 14'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Segmented(
          options: const ['This week', 'Next week'],
          index: _week,
          onChanged: (i) {
            setState(() => _week = i);
            if (i == 1) showToast(context, 'Week of 11 Aug');
          },
        ),
        const SizedBox(height: 14),
        for (var di = 0; di < days.length; di++)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PanelHeader(days[di], trailing: [
                    Pill(di == 2 ? '1 cancelled' : '${2 + di % 2} lectures',
                        tone: di == 2 ? PillTone.hot : PillTone.neutral),
                  ]),
                  for (var i = 0; i < 2 + di % 2; i++) ...[
                    if (i > 0) const HairLine(),
                    _timeRow(
                      Mock.today[i].start,
                      Mock.today[i].batch,
                      Mock.today[i].room,
                      c,
                      cancelled: di == 2 && i == 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------- me --
  Widget _me() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PanelHeader('Availability'),
              Text(
                  'Blocking a day warns the office before the timetable is built. '
                  'Blocking a scheduled lecture cancels it and tells parents.',
                  style: AppType.body(12.5, color: c.text2, height: 1.5)),
              const SizedBox(height: 8),
              for (var i = 0; i < _avail.length; i++) ...[
                if (i > 0) const HairLine(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_avail[i].$1,
                            style: AppType.body(13.5, weight: FontWeight.w600, color: c.text)),
                        Text(_avail[i].$2,
                            style: AppType.body(11.5, color: _avail[i].$3 ? c.text2 : c.amber)),
                      ]),
                    ),
                    AppToggle(
                      value: _avail[i].$3,
                      semanticLabel: 'Available ${_avail[i].$1}',
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _avail[i] = (_avail[i].$1, v ? 'Available' : 'Away', v));
                        showToast(context, v ? 'Marked available' : 'Marked away');
                      },
                    ),
                  ]),
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
              const PanelHeader('Syllabus'),
              for (final b in Mock.batches.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(b.name,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.body(12.5, weight: FontWeight.w500, color: c.text)),
                      ),
                      Text('${b.syllabus}%',
                          style: AppType.mono(12.5, weight: FontWeight.w600, color: c.text)),
                    ]),
                    const SizedBox(height: 5),
                    ProgressBar(b.syllabus.toDouble()),
                  ]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Time on the left, two lines on the right. Shared by week and timetable views.
Widget _timeRow(String time, String title, String sub, AppColors c, {bool cancelled = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 44, child: Text(time, style: AppType.mono(11.5, color: c.text2))),
          const SizedBox(width: 8),
          Expanded(
            child: Opacity(
              opacity: cancelled ? 0.45 : 1,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: AppType.body(12.5, weight: FontWeight.w600, color: c.text).copyWith(
                        decoration: cancelled ? TextDecoration.lineThrough : null)),
                Text(sub, style: AppType.body(11, color: c.text2)),
              ]),
            ),
          ),
        ],
      ),
    );

/// One stop on the day rail: time, a dot on the spine, and the lecture card.
class RailItem extends StatelessWidget {
  final Lecture lecture;
  final bool last;
  final bool logged;
  final VoidCallback? onRoll, onSyllabus, onLog, onCant;

  /// Replaces the built-in buttons when set (the live screens pass their own).
  final List<Widget>? actions;

  /// Replaces the present/roster pill on a finished lecture.
  final Widget? badge;

  const RailItem({
    super.key,
    required this.lecture,
    required this.last,
    this.logged = false,
    this.onRoll,
    this.onSyllabus,
    this.onLog,
    this.onCant,
    this.actions,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final l = lecture;
    final live = l.state == LectureState.live;
    final done = l.state == LectureState.done;

    final actions = this.actions ?? <Widget>[
      if (live) ...[
        AppButton('Take roll call', kind: BtnKind.primary, small: true, onPressed: onRoll),
        AppButton('Syllabus', small: true, onPressed: onSyllabus),
      ],
      if (done && !logged) AppButton('Log what you covered', kind: BtnKind.dark, small: true, onPressed: onLog),
      if (done && logged) const Pill('Logged', tone: PillTone.lime),
      if (l.state == LectureState.upcoming) AppButton("Can't take this", small: true, onPressed: onCant),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(l.start,
                  style: AppType.mono(11, weight: FontWeight.w600, color: live ? c.hot : c.text2)),
            ),
          ),
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 0,
                  bottom: last ? null : 0,
                  height: last ? 22 : null,
                  child: Container(width: 2, color: c.line),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 17),
                  child: live
                      ? const _PulseDot()
                      : Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done ? c.lime : c.surface,
                            border: done ? null : Border.all(color: c.text3, width: 2),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l.batch,
                                style: AppType.body(13.5, weight: FontWeight.w600, color: c.text)),
                            const SizedBox(height: 2),
                            Text(l.topic, style: AppType.body(12, color: c.text2)),
                            const SizedBox(height: 3),
                            Text('${l.start}–${l.end} · ${l.room}',
                                style: AppType.mono(11, color: c.text2)),
                          ]),
                        ),
                        if (badge != null)
                          badge!
                        else ...[
                          if (live) const Pill('Live', tone: PillTone.hot),
                          if (done) Pill('${l.present}/${l.roster}', tone: PillTone.lime),
                        ],
                      ],
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 11),
                      Wrap(spacing: 7, runSpacing: 7, children: actions),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hot = context.c.hot;
    return SizedBox(
      width: 12,
      height: 12,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1 + _ctrl.value * 1.4,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hot.withOpacity(0.35 * (1 - _ctrl.value)),
                ),
              ),
            ),
            Container(decoration: BoxDecoration(shape: BoxShape.circle, color: hot)),
          ],
        ),
      ),
    );
  }
}
