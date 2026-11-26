import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/tokens.dart';
import '../features/mapping_matrix.dart';
import '../widgets/app_table.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import 'live_models.dart';
import 'live_screens.dart';
import 'live_store.dart';

/// Owner/admin desk, live. Day-to-day running of the institute: today's
/// attendance and alerts, batches, enrolment, people, and tests.
///
/// Creating batches, students and invites is done on the web app, which has
/// the forms for it; this desk is for watching and the quick actions.
class LiveAdminScreen extends StatefulWidget {
  final String tab;
  const LiveAdminScreen({super.key, required this.tab});

  @override
  State<LiveAdminScreen> createState() => _LiveAdminScreenState();
}

class _LiveAdminScreenState extends State<LiveAdminScreen> {
  /// Unsaved enrolment changes from the matrix, keyed "studentId:batchId".
  final Map<String, bool> _pending = {};
  int _matrixVersion = 0;
  bool _saving = false;

  LiveStore get _store => LiveScope.of(context);

  @override
  Widget build(BuildContext context) => switch (widget.tab) {
        'batches' => _batches(),
        'mapping' => _mapping(),
        'people' => _people(),
        'tests' => _tests(),
        _ => _overview(),
      };

  String _teacherNames(LBatch b) {
    final names = [
      for (final id in b.teacherIds)
        for (final t in _store.teachers)
          if (t.id == id) t.name,
    ];
    return names.isEmpty ? 'Unassigned' : names.join(', ');
  }

  // -------------------------------------------------------------- overview --
  Widget _overview() {
    final c = context.c;
    final s = _store;
    final d = s.dashboard!;
    final open = s.absences.where((a) => a.open).toList();
    final silent = open.where((a) => a.state == AbsenceState.silent).length;
    final unmarked = d.today.where((x) => !x.marked && lectureState(x.start, x.end).index != 2).toList();
    final noTeacher = s.batches.where((b) => b.teacherIds.isEmpty).toList();

    final needs = <(String, String, bool, Widget?)>[
      if (open.isNotEmpty)
        (
          '${open.length} parent${open.length == 1 ? " hasn't" : "s haven't"} acknowledged an absence',
          silent > 0 ? '$silent silent for hours' : 'Alerts sent today',
          silent > 0,
          AppButton('Nudge', small: true, onPressed: () => _nudge(null)),
        ),
      if (unmarked.isNotEmpty)
        (
          '${unmarked.length} roll call${unmarked.length == 1 ? '' : 's'} not taken',
          unmarked.map((x) => '${x.name} ${x.start}').join(' · '),
          true,
          null,
        ),
      if ((d.feesOverdueCount ?? 0) > 0)
        (
          '${d.feesOverdueCount} overdue fee${d.feesOverdueCount == 1 ? '' : 's'}',
          '₹${NumberFormat.decimalPattern('en_IN').format(d.feesDueAmount ?? 0)} due in total',
          false,
          null,
        ),
      if (noTeacher.isNotEmpty)
        ('${noTeacher.length} batch${noTeacher.length == 1 ? '' : 'es'} without a teacher', noTeacher.map((b) => b.name).join(', '), false, null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle(s.me.instituteName ?? 'Institute',
            subtitle: '${longDay(DateTime.now())} · ${d.today.length} lecture${d.today.length == 1 ? '' : 's'} today'),
        BentoGrid(tiles: [
          BentoTile(
            span: 2,
            child: FeatureCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ATTENDANCE TODAY', style: AppType.label(Colors.white.withOpacity(0.6))),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    d.rateToday == null
                        ? Text('—', style: AppType.display(44, weight: FontWeight.w700, color: Colors.white))
                        : CountUp(
                            value: d.rateToday!,
                            suffix: '%',
                            style: AppType.display(44, weight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                            d.totalToday == null || d.totalToday == 0
                                ? 'No roll calls taken yet today'
                                : '${d.presentToday} of ${d.totalToday} in class\n'
                                    '${s.absences.length} absent, ${s.absences.where((a) => !a.open).length} acknowledged',
                            style: AppType.body(12.5, color: Colors.white.withOpacity(0.72), height: 1.45)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (d.rateToday ?? 0) / 100,
                      minHeight: 6,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          BentoTile(child: KpiTile(label: 'Students', value: d.activeStudents ?? s.students.length, delta: 'active')),
          BentoTile(child: KpiTile(label: 'Batches', value: s.batches.length, delta: '${s.teachers.length} teachers')),
          BentoTile(
            span: 2,
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PanelHeader('Syllabus coverage'),
                  if (s.batches.isEmpty) Text('No batches yet.', style: AppType.body(12, color: c.text3)),
                  for (final b in s.batches)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Text(b.name,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.body(12.5, weight: FontWeight.w500, color: c.text)),
                          ),
                          Text(b.syllabusPercent == null ? 'not set' : '${b.syllabusPercent}%',
                              style: AppType.mono(12.5, weight: FontWeight.w600, color: c.text2)),
                        ]),
                        const SizedBox(height: 5),
                        ProgressBar((b.syllabusPercent ?? 0).toDouble()),
                      ]),
                    ),
                ],
              ),
            ),
          ),
          BentoTile(
            span: 2,
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PanelHeader('Needs you', trailing: [
                    Pill('${needs.length}', tone: needs.isEmpty ? PillTone.lime : PillTone.hot),
                  ]),
                  if (needs.isEmpty) Text('All clear.', style: AppType.body(12.5, color: c.text3)),
                  for (var i = 0; i < needs.length; i++) ...[
                    if (i > 0) const HairLine(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: needs[i].$3 ? c.hot : c.amber, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(needs[i].$1, style: AppType.body(13, weight: FontWeight.w500, color: c.text, height: 1.35)),
                            const SizedBox(height: 2),
                            Text(needs[i].$2, style: AppType.body(11.5, color: c.text2)),
                          ]),
                        ),
                        if (needs[i].$4 != null) needs[i].$4!,
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ]),
        if (s.absences.isNotEmpty) ...[
          const SizedBox(height: 14),
          TablePanel(
            title: 'Absences today',
            trailing: [
              if (open.isNotEmpty) AppButton('Nudge silent', small: true, onPressed: () => _nudge(null)),
            ],
            columns: const [
              TableCol('Student', width: 200),
              TableCol('Batch', width: 170),
              TableCol('Marked', width: 90),
              TableCol('Parent', width: 150),
              TableCol('Acknowledgement', width: 150),
            ],
            rows: [
              for (final a in s.absences)
                [
                  TPerson(a.studentName, tone: a.open ? AvatarTone.hot : AvatarTone.accent),
                  TCell(a.batchName, muted: true),
                  TCell(a.markedAt == null ? '—' : DateFormat('HH:mm').format(a.markedAt!), mono: true, muted: true),
                  TCell(a.guardianName.isEmpty ? '—' : a.guardianName, muted: true),
                  Align(alignment: Alignment.centerLeft, child: absencePill(a)),
                ],
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _nudge(List<String>? ids) async {
    try {
      final n = await _store.nudge(ids: ids);
      if (mounted) showToast(context, n == 0 ? 'Nobody to remind' : 'Reminded $n parent${n == 1 ? '' : 's'}');
    } catch (e) {
      if (mounted) showToast(context, '$e');
    }
  }

  // --------------------------------------------------------------- batches --
  Widget _batches() {
    final s = _store;
    String sched(LBatch b) {
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      if (b.schedule.isEmpty) return '—';
      final byTime = <String, List<String>>{};
      for (final x in b.schedule) {
        byTime.putIfAbsent(x.start, () => []).add(days[x.day.clamp(0, 6)]);
      }
      return byTime.entries.map((e) => '${e.value.join('/')} · ${e.key}').join('; ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle('Batches', subtitle: '${s.batches.length} running · add or edit batches on the web app'),
        if (s.batches.isEmpty)
          const EmptyState(title: 'No batches yet', body: 'Create your first batch on the web app.')
        else
          TablePanel(
            title: 'All batches',
            columns: const [
              TableCol('Batch', width: 210),
              TableCol('Subject', width: 110),
              TableCol('Teacher', width: 170),
              TableCol('Schedule', width: 220),
              TableCol('Students', width: 90),
              TableCol('Syllabus', width: 90),
            ],
            rows: [
              for (final b in s.batches)
                [
                  TCell(b.name, strong: true),
                  TCell(b.subject, muted: true),
                  TCell(_teacherNames(b), muted: b.teacherIds.isNotEmpty),
                  TCell(sched(b), mono: true, muted: true),
                  TCell('${s.rosterOf(b.id).length}', mono: true),
                  TCell(b.syllabusPercent == null ? '—' : '${b.syllabusPercent}%', mono: true),
                ],
            ],
          ),
      ],
    );
  }

  // --------------------------------------------------------------- mapping --
  Widget _mapping() {
    final c = context.c;
    final s = _store;
    if (s.batches.isEmpty || s.students.isEmpty) {
      return const EmptyState(
          title: 'Nothing to map yet', body: 'Add batches and students on the web app, then enrol them here.');
    }
    final students = [...s.students]..sort((a, b) => a.name.compareTo(b.name));
    final initial = <String>{
      for (final st in students)
        for (var i = 0; i < s.batches.length; i++)
          if (st.batchIds.contains(s.batches[i].id)) '${st.id}:$i',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('Mapping', subtitle: 'Press and drag across cells — one gesture fills a row or a column'),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(R.md),
            boxShadow: Shadows.one(context.brightness),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Row(children: [
                  Expanded(
                    child: Text('Students × batches',
                        style: AppType.display(14, weight: FontWeight.w600, color: c.text)),
                  ),
                  if (_pending.isNotEmpty) ...[
                    AppButton('Discard', small: true, onPressed: () => setState(() {
                          _pending.clear();
                          _matrixVersion++;
                        })),
                    const SizedBox(width: 6),
                  ],
                  AppButton(
                    _saving
                        ? 'Saving…'
                        : _pending.isEmpty
                            ? 'No changes'
                            : 'Save ${_pending.length} change${_pending.length == 1 ? '' : 's'}',
                    kind: _pending.isEmpty ? BtnKind.plain : BtnKind.primary,
                    small: true,
                    onPressed: _pending.isEmpty || _saving ? null : _saveMapping,
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: MappingMatrix(
                  key: ValueKey('matrix-$_matrixVersion-${s.students.length}-${s.batches.length}'),
                  rows: [
                    for (final st in students)
                      MatrixRow(id: st.id, title: st.name, subtitle: st.grade.isEmpty ? st.phone : st.grade),
                  ],
                  columns: [for (final b in s.batches) b.name],
                  initial: initial,
                  onChanged: (rowId, col, value) {
                    final key = '$rowId:${s.batches[col].id}';
                    final original = initial.contains('$rowId:$col');
                    setState(() => value == original ? _pending.remove(key) : _pending[key] = value);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveMapping() async {
    setState(() => _saving = true);
    try {
      final n = _pending.length;
      await _store.saveEnrollments([
        for (final e in _pending.entries)
          (studentId: e.key.split(':')[0], batchId: e.key.split(':')[1], enrolled: e.value),
      ]);
      if (!mounted) return;
      setState(() {
        _pending.clear();
        _matrixVersion++;
      });
      showToast(context, 'Saved $n change${n == 1 ? '' : 's'}');
    } catch (e) {
      if (mounted) showToast(context, '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------------------------------------------------------- people --
  Widget _people() {
    final s = _store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('People', subtitle: 'Invite teachers, students and parents on the web app'),
        TablePanel(
          title: 'Teachers',
          columns: const [
            TableCol('Teacher', width: 210),
            TableCol('Email', width: 220),
            TableCol('Batches', width: 260),
          ],
          rows: [
            for (final t in s.teachers)
              [
                TPerson(t.name, tone: AvatarTone.accent),
                TCell(t.email, muted: true),
                TCell(
                    s.batches.where((b) => b.teacherIds.contains(t.id)).map((b) => b.name).join(', ').ifEmpty('—'),
                    muted: true),
              ],
          ],
        ),
        const SizedBox(height: 14),
        TablePanel(
          title: '${s.students.length} enrolled',
          columns: const [
            TableCol('Student', width: 210),
            TableCol('Grade', width: 90),
            TableCol('Guardian', width: 160),
            TableCol('Batches', width: 260),
          ],
          rows: [
            for (final st in [...s.students]..sort((a, b) => a.name.compareTo(b.name)))
              [
                TPerson(st.name),
                TCell(st.grade.ifEmpty('—'), muted: true),
                TCell(st.guardianName.ifEmpty('—'), muted: true),
                TCell(st.batchIds.map((id) => s.batch(id)?.name ?? '').where((n) => n.isNotEmpty).join(', ').ifEmpty('—'),
                    muted: true),
              ],
          ],
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- tests --
  Widget _tests() {
    final s = _store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('Tests & marks', subtitle: 'Create a test, then tap it to enter marks'),
        TablePanel(
          title: 'Tests',
          trailing: [
            AppButton('New test',
                kind: BtnKind.primary, small: true, onPressed: s.batches.isEmpty ? null : _newTest),
          ],
          columns: const [
            TableCol('Test', width: 230),
            TableCol('Batch', width: 180),
            TableCol('Date', width: 100),
            TableCol('Entered', width: 90),
            TableCol('Average', width: 100),
            TableCol('', width: 120),
          ],
          rows: [
            for (final t in s.tests)
              [
                TCell(t.title, strong: true),
                TCell(t.batchName, muted: true),
                TCell(shortDate(t.date), mono: true, muted: true),
                TCell('${t.entered}/${s.rosterOf(t.batchId).length}', mono: true),
                TCell(t.averagePercent == null ? '—' : '${t.averagePercent!.round()}%', mono: true),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton('Enter marks', small: true, onPressed: () => _marks(t)),
                ),
              ],
          ],
        ),
        if (s.tests.isEmpty) ...[
          const SizedBox(height: 12),
          const EmptyState(title: 'No tests yet', body: 'Create one with “New test”.'),
        ],
      ],
    );
  }

  Future<void> _newTest() async {
    final s = _store;
    final title = TextEditingController();
    final max = TextEditingController(text: '80');
    var batchId = s.batches.first.id;
    String? error;
    await showAppSheet<void>(
      context: context,
      title: 'New test',
      description: 'Dated today. Marks are entered after.',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: batchId,
              items: [for (final b in s.batches) DropdownMenuItem(value: b.id, child: Text(b.name))],
              onChanged: (v) => set(() => batchId = v ?? batchId),
            ),
            const SizedBox(height: 10),
            TextField(controller: title, decoration: const InputDecoration(hintText: 'Weekly Test 15 — Physics')),
            const SizedBox(height: 10),
            TextField(
              controller: max,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Out of (max marks)'),
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(error!, style: AppType.body(12.5, color: ctx.c.hot)),
            ],
            const SizedBox(height: 14),
            BigButton('Create test', kind: BtnKind.primary, onPressed: () async {
              final m = int.tryParse(max.text.trim());
              if (title.text.trim().isEmpty || m == null || m < 1) {
                set(() => error = 'Give the test a name and a whole-number total.');
                return;
              }
              try {
                await s.createTest(batchId, title.text.trim(), m);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showToast(context, 'Test created');
              } catch (e) {
                set(() => error = '$e');
              }
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    title.dispose();
    max.dispose();
  }

  Future<void> _marks(TestSummary t) async {
    final s = _store;
    final roster = s.rosterOf(t.batchId);
    TestDetail detail;
    try {
      detail = await s.testDetail(t.id);
    } catch (e) {
      if (mounted) showToast(context, '$e');
      return;
    }
    if (!mounted) return;
    final existing = {for (final r in detail.rows) if (r.studentId != null) r.studentId!: r.score};
    final ctrls = {
      for (final st in roster)
        st.id: TextEditingController(text: existing[st.id] == null ? '' : _fmt(existing[st.id]!)),
    };
    String? error;
    await showAppSheet<void>(
      context: context,
      title: t.title,
      description: '${t.batchName} · out of ${t.maxMarks}. Leave blank for absent.',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (roster.isEmpty) const EmptyState(title: 'No students', body: 'Nobody is enrolled in this batch.'),
            for (final st in roster)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  AvatarBadge(st.name, size: 30),
                  const SizedBox(width: 11),
                  Expanded(child: Text(st.name, style: AppType.body(13.5, weight: FontWeight.w500, color: ctx.c.text))),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: ctrls[st.id],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      style: AppType.mono(13.5, color: ctx.c.text),
                      decoration: const InputDecoration(
                          hintText: '—', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 10)),
                    ),
                  ),
                ]),
              ),
            if (error != null) Text(error!, style: AppType.body(12.5, color: ctx.c.hot)),
            const SizedBox(height: 10),
            BigButton('Save marks', kind: BtnKind.primary, onPressed: () async {
              final marks = <String, num?>{};
              for (final e in ctrls.entries) {
                final txt = e.value.text.trim();
                if (txt.isEmpty) {
                  if (existing.containsKey(e.key)) marks[e.key] = null;
                  continue;
                }
                final v = num.tryParse(txt);
                if (v == null || v < 0 || v > t.maxMarks) {
                  set(() => error = 'Marks must be between 0 and ${t.maxMarks}.');
                  return;
                }
                marks[e.key] = v;
              }
              try {
                await s.enterMarks(t.id, marks);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) showToast(context, 'Marks saved · ranks updated');
              } catch (e) {
                set(() => error = '$e');
              }
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    for (final c in ctrls.values) {
      c.dispose();
    }
  }
}

String _fmt(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
