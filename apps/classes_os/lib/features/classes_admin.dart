import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../data/mock_data.dart';
import '../widgets/app_table.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import 'mapping_matrix.dart';

class ClassesAdminScreen extends StatefulWidget {
  final String tab;
  const ClassesAdminScreen({super.key, required this.tab});

  @override
  State<ClassesAdminScreen> createState() => _ClassesAdminScreenState();
}

class _ClassesAdminScreenState extends State<ClassesAdminScreen> {
  final _search = TextEditingController();
  final _matrixKey = GlobalKey<MappingMatrixState>();

  /// Per-teacher capability grants: marks, syllabus, absence.
  final Map<String, Map<String, bool>> _perms = {
    't1': {'marks': true, 'syllabus': true, 'absence': true},
    't2': {'marks': false, 'syllabus': true, 'absence': true},
    't3': {'marks': false, 'syllabus': true, 'absence': false},
    't4': {'marks': true, 'syllabus': true, 'absence': true},
  };

  int _placements = 0;

  @override
  void initState() {
    super.initState();
    _placements =
        Mock.students.fold<int>(0, (sum, s) => sum + s.batchIds.length);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (widget.tab) {
        'batches' => _batches(),
        'mapping' => _mapping(),
        'people' => _people(),
        'tests' => _tests(),
        _ => _overview(),
      };

  // -------------------------------------------------------------- overview --
  Widget _overview() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('Sunrise Academy',
            subtitle: 'Friday 8 August · 5 lectures · ⌘K to jump anywhere'),
        BentoGrid(
          tiles: [
            BentoTile(
              span: 2,
              child: FeatureCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ATTENDANCE TODAY',
                        style: AppType.label(Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CountUp(
                          value: 91,
                          suffix: '%',
                          style: AppType.display(44,
                              weight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                                '398 of 412 in class\n14 absent, 12 acknowledged',
                                style: AppType.body(12.5,
                                    color: Colors.white.withOpacity(0.72),
                                    height: 1.45)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: 0.91,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const BentoTile(
                child: KpiTile(
                    label: 'Students',
                    value: 412,
                    delta: '12 this month',
                    trend: Trend.up)),
            const BentoTile(
                child: KpiTile(
                    label: 'Batches', value: 14, delta: 'all running')),
            BentoTile(
              span: 2,
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PanelHeader('Syllabus coverage',
                        trailing: [Pill('Target 65%')]),
                    for (final b in Mock.batches)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(b.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppType.body(12.5,
                                          weight: FontWeight.w500,
                                          color: c.text)),
                                ),
                                Text('${b.syllabus}%',
                                    style: AppType.mono(12.5,
                                        weight: FontWeight.w600,
                                        color: b.behindTarget ? c.hot : c.text2)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ProgressBar(b.syllabus.toDouble(),
                                color: b.behindTarget ? c.hot : null),
                          ],
                        ),
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
                    const PanelHeader('Needs you',
                        trailing: [Pill('4', tone: PillTone.hot)]),
                    for (var i = 0; i < Mock.needsYou.length; i++) ...[
                      if (i > 0) const HairLine(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Mock.needsYou[i].urgent ? c.hot : c.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(Mock.needsYou[i].title,
                                      style: AppType.body(13,
                                          weight: FontWeight.w500,
                                          color: c.text,
                                          height: 1.35)),
                                  const SizedBox(height: 2),
                                  Text(Mock.needsYou[i].detail,
                                      style:
                                          AppType.body(11.5, color: c.text2)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppButton(Mock.needsYou[i].action,
                                small: true,
                                onPressed: () => showToast(
                                    context, Mock.needsYou[i].action)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------- mapping --
  Widget _mapping() {
    final c = context.c;
    final q = _search.text.trim().toLowerCase();
    final rows = Mock.students
        .where((s) =>
            q.isEmpty ||
            s.name.toLowerCase().contains(q) ||
            s.roll.toLowerCase().contains(q))
        .map((s) => MatrixRow(
              id: s.id,
              title: s.name,
              subtitle: '${s.roll} · ${s.standard}',
            ))
        .toList();

    final initial = <String>{
      for (final s in Mock.students)
        for (var i = 0; i < Mock.batches.length; i++)
          if (s.batchIds.contains(Mock.batches[i].id)) '${s.id}:$i',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('Mapping',
            subtitle:
                'Press and drag across cells — one gesture fills a row or a column'),
        Container(
          margin: const EdgeInsets.only(bottom: 13),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(R.md),
          ),
          child: Row(
            children: [
              Text('⌕', style: AppType.body(15, color: c.text3)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: AppType.body(13.5, color: c.text),
                  decoration: const InputDecoration(
                    hintText: 'Filter by name or roll number',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (q.isNotEmpty)
                AppButton('Clear',
                    small: true,
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                    }),
            ],
          ),
        ),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Students × batches',
                          style: AppType.display(14,
                              weight: FontWeight.w600, color: c.text)),
                    ),
                    Pill('$_placements placements', tone: PillTone.accent),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: MappingMatrix(
                  key: _matrixKey,
                  rows: rows,
                  columns: [for (final b in Mock.batches) b.name],
                  initial: initial,
                  onChanged: (rowId, col, value) {
                    setState(() => _placements += value ? 1 : -1);
                  },
                ),
              ),
            ],
          ),
        ),
        const SectionLabel('Teachers × batches'),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(R.md),
            boxShadow: Shadows.one(context.brightness),
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.only(top: 8, bottom: 14),
          child: MappingMatrix(
            rows: [
              for (final t in Mock.teachers)
                MatrixRow(
                  id: t.id,
                  title: t.name,
                  subtitle: t.subject,
                  tone: AvatarTone.accent,
                ),
            ],
            columns: [for (final b in Mock.batches) b.name],
            initial: {
              for (var ti = 0; ti < Mock.teachers.length; ti++)
                for (var bi = 0; bi < Mock.batches.length; bi++)
                  if (Mock.batches[bi].teacher.split('. ').last ==
                      Mock.teachers[ti].name.split(' ').last)
                    '${Mock.teachers[ti].id}:$bi',
            },
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- batches --
  Widget _batches() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('Batches', subtitle: '14 running · 6 shown'),
        BentoGrid(
          tiles: [
            for (final b in Mock.batches)
              BentoTile(
                span: 2,
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PanelHeader(b.name, trailing: [Pill(b.stream)]),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stat(context, 'Students', '${b.students}'),
                          const SizedBox(width: 24),
                          _stat(context, 'Covered', '${b.syllabus}%'),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TEACHER', style: AppType.label(c.text3)),
                                const SizedBox(height: 6),
                                Text(b.teacher,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppType.body(13.5,
                                        weight: FontWeight.w600, color: c.text)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ProgressBar(b.syllabus.toDouble(),
                          color: b.behindTarget ? c.hot : null),
                      const SizedBox(height: 10),
                      Text(b.slot, style: AppType.mono(11.5, color: c.text2)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: AppType.label(c.text3)),
        const SizedBox(height: 6),
        Text(value,
            style: AppType.display(26, weight: FontWeight.w700, color: c.text)),
      ],
    );
  }

  // ---------------------------------------------------------------- people --
  Widget _people() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('People',
            subtitle: 'Permissions toggle inline — there is no save button'),
        TablePanel(
          title: 'Teachers',
          trailing: [
            AppButton('Add teacher',
                kind: BtnKind.primary,
                small: true,
                onPressed: () => showToast(context, 'Opens the add teacher form')),
          ],
          columns: const [
            TableCol('Teacher', width: 210),
            TableCol('Subject', width: 120),
            TableCol('Load', width: 100),
            TableCol('Availability', width: 130),
            TableCol('Marks', width: 80),
            TableCol('Syllabus', width: 90),
            TableCol('Absence', width: 90),
          ],
          rows: [
            for (final t in Mock.teachers)
              [
                TPerson(t.name, tone: AvatarTone.accent),
                TCell(t.subject, muted: true),
                TCell(t.load, mono: true, muted: true),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Pill(t.availability,
                      tone: t.isAvailable ? PillTone.lime : PillTone.amber),
                ),
                for (final k in ['marks', 'syllabus', 'absence'])
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppToggle(
                      value: _perms[t.id]![k]!,
                      semanticLabel: '$k permission for ${t.name}',
                      onChanged: (v) {
                        setState(() => _perms[t.id]![k] = v);
                        showToast(context,
                            '${t.name} · $k ${v ? 'granted' : 'revoked'}');
                      },
                    ),
                  ),
              ],
          ],
        ),
        const SectionLabel('Students'),
        TablePanel(
          title: '412 enrolled',
          trailing: [
            AppButton('Import CSV',
                small: true,
                onPressed: () => showToast(context, 'Opens the CSV importer')),
            AppButton('Add student',
                kind: BtnKind.primary,
                small: true,
                onPressed: () => showToast(context, 'Opens the add student form')),
          ],
          columns: const [
            TableCol('Student', width: 210),
            TableCol('Roll', width: 110),
            TableCol('Std', width: 70),
            TableCol('Batches', width: 90),
            TableCol('Attendance', width: 110),
            TableCol('Average', width: 90),
          ],
          rows: [
            for (final s in Mock.students)
              [
                TPerson(s.name),
                TCell(s.roll, mono: true, muted: true),
                TCell(s.standard, muted: true),
                TCell('${s.batchIds.length}', muted: true),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Pill('${s.attendance}%',
                      tone: s.attendance >= 85
                          ? PillTone.lime
                          : s.attendance >= 75
                              ? PillTone.amber
                              : PillTone.hot),
                ),
                TCell('${s.average}%', mono: true),
              ],
          ],
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- tests --
  Widget _tests() {
    final c = context.c;
    final nodes = List.generate(4, (_) => FocusNode());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('Tests and marks',
            subtitle:
                'Type a mark, press Enter, and the cursor drops to the next student'),
        TablePanel(
          title: 'Test series',
          trailing: [
            AppButton('Create test',
                kind: BtnKind.primary,
                small: true,
                onPressed: () => showToast(context, 'Opens the new test form')),
          ],
          columns: const [
            TableCol('Test', width: 240),
            TableCol('Batch', width: 150),
            TableCol('Date', width: 90),
            TableCol('Max', width: 70),
            TableCol('Entered', width: 90),
            TableCol('', width: 130),
          ],
          rows: [
            for (final t in const [
              ('Weekly Test 15 — Physics', 'JEE Adv A', '07 Aug', 80, 0, 38, false),
              ('Weekly Test 14 — Physics', 'JEE Adv A', '05 Aug', 80, 38, 38, true),
              ('Monthly Mock 04 — PCM', 'A + B', '12 Aug', 300, 0, 72, false),
              ('Unit Test — Biology', 'NEET A', '02 Aug', 50, 41, 41, true),
            ])
              [
                TCell(t.$1, strong: true),
                TCell(t.$2, muted: true),
                TCell(t.$3, mono: true, muted: true),
                TCell('${t.$4}', mono: true),
                TCell('${t.$5}/${t.$6}', mono: true, muted: true),
                t.$7
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Pill('Published', tone: PillTone.lime))
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: AppButton('Enter marks',
                            small: true,
                            onPressed: () =>
                                showToast(context, 'Opens the marks sheet')),
                      ),
              ],
          ],
        ),
        const SizedBox(height: 14),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Weekly Test 15 — Physics',
                          style: AppType.display(14,
                              weight: FontWeight.w600, color: c.text)),
                    ),
                    const Pill('Draft', tone: PillTone.amber),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              AppTable(
                columns: const [
                  TableCol('Roll', width: 110),
                  TableCol('Student', width: 200),
                  TableCol('Marks / 80', width: 130),
                  TableCol('Note for parent', width: 260),
                ],
                rows: [
                  for (var i = 0; i < 4; i++)
                    [
                      TCell(Mock.students[i].roll, mono: true, muted: true),
                      TCell(Mock.students[i].name, strong: true),
                      SizedBox(
                        width: 88,
                        child: TextField(
                          focusNode: nodes[i],
                          textInputAction: i < 3
                              ? TextInputAction.next
                              : TextInputAction.done,
                          keyboardType: TextInputType.number,
                          style: AppType.mono(13.5, color: c.text),
                          decoration: const InputDecoration(
                            hintText: '—',
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                          ),
                          onSubmitted: (_) {
                            if (i < 3) {
                              FocusScope.of(context).requestFocus(nodes[i + 1]);
                            } else {
                              showToast(context, 'Last student — saved');
                            }
                          },
                        ),
                      ),
                      TextField(
                        style: AppType.body(13, color: c.text),
                        decoration: const InputDecoration(
                          hintText: 'Optional',
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                        ),
                      ),
                    ],
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration:
                    BoxDecoration(border: Border(top: BorderSide(color: c.line2))),
                child: Row(
                  children: [
                    AppButton('Save draft',
                        onPressed: () => showToast(context, 'Draft saved')),
                    const SizedBox(width: 8),
                    AppButton('Publish results',
                        kind: BtnKind.dark,
                        onPressed: () => showToast(context,
                            'Published — 38 students and parents notified')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
