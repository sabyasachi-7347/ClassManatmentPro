import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../widgets/app_table.dart';
import '../widgets/charts.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';

class SuperAdminScreen extends StatefulWidget {
  final String tab;
  const SuperAdminScreen({super.key, required this.tab});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  late List<SystemAdminAccount> _admins = List.of(Mock.systemAdmins);

  void _toggle(SystemAdminAccount a, bool on) {
    setState(() {
      _admins = _admins
          .map((x) => x.id == a.id ? x.copyWith(active: on) : x)
          .toList();
    });
    showToast(context, '${a.name} ${on ? 'activated' : 'deactivated'}');
  }

  @override
  Widget build(BuildContext context) =>
      widget.tab == 'admins' ? _admins_() : _overview();

  // ------------------------------------------------------------- overview --
  Widget _overview() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('Platform', subtitle: '4 institutes · 1,326 students · live'),
        BentoGrid(
          tiles: [
            BentoTile(
              span: 2,
              child: FeatureCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('STUDENTS ENROLLED',
                        style: AppType.label(Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 10),
                    CountUp(
                      value: 1326,
                      style: AppType.display(44,
                          weight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text('↑ 64 this month across all institutes',
                        style: AppType.body(12.5,
                            color: Colors.white.withOpacity(0.72))),
                    const SizedBox(height: 16),
                    const MiniBars(data: Mock.enrolment),
                  ],
                ),
              ),
            ),
            const BentoTile(
                child: KpiTile(
                    label: 'Institutes', value: 4, delta: '1 in setup')),
            const BentoTile(
                child: KpiTile(
                    label: 'Open leads',
                    value: 27,
                    delta: '8 today',
                    trend: Trend.up)),
            BentoTile(
              span: 2,
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PanelHeader('System admins',
                        trailing: [Pill('${_admins.length} accounts')]),
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const HairLine(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            AvatarBadge(_admins[i].name,
                                size: 28, tone: AvatarTone.accent),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_admins[i].name,
                                      style: AppType.body(13,
                                          weight: FontWeight.w600, color: c.text)),
                                  Text(
                                      '${_admins[i].institutes.length} institutes',
                                      style:
                                          AppType.body(11, color: c.text2)),
                                ],
                              ),
                            ),
                            AppToggle(
                              value: _admins[i].active,
                              semanticLabel: 'Access for ${_admins[i].name}',
                              onChanged: (v) => _toggle(_admins[i], v),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                    const PanelHeader('By institute'),
                    for (final i in Mock.institutes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(i.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppType.body(12.5,
                                          weight: FontWeight.w500, color: c.text)),
                                ),
                                Text('${i.students}',
                                    style: AppType.mono(12.5,
                                        weight: FontWeight.w600, color: c.text)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ProgressBar(i.students / 531 * 100),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            BentoTile(
              span: 4,
              child: TablePanel(
                title: 'All institutes',
                trailing: [
                  AppButton('Add institute',
                      kind: BtnKind.primary,
                      small: true,
                      onPressed: () =>
                          showToast(context, 'Opens the new institute form')),
                ],
                columns: const [
                  TableCol('Institute', width: 220),
                  TableCol('Area', width: 130),
                  TableCol('Students', width: 90),
                  TableCol('Batches', width: 90),
                  TableCol('Classes admin', width: 150),
                  TableCol('Status', width: 100),
                ],
                rows: [
                  for (final i in Mock.institutes)
                    [
                      TPerson(i.name),
                      TCell(i.city, muted: true),
                      TCell('${i.students}', mono: true),
                      TCell('${i.batches}', mono: true),
                      TCell(i.admin, muted: true),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Pill(i.status,
                            tone: i.isActive ? PillTone.lime : PillTone.amber),
                      ),
                    ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------- admins --
  Widget _admins_() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('System admins',
            subtitle: 'Access toggles save the moment you tap them'),
        TablePanel(
          title: '${_admins.length} accounts',
          trailing: [
            AppButton('Add admin',
                kind: BtnKind.primary,
                small: true,
                onPressed: () => showToast(context, 'Opens the new admin form')),
          ],
          columns: const [
            TableCol('Name', width: 200),
            TableCol('Email', width: 190),
            TableCol('Institutes', width: 260),
            TableCol('Access', width: 90),
          ],
          rows: [
            for (final a in _admins)
              [
                TPerson(a.name, tone: AvatarTone.accent),
                TCell(a.email, mono: true, muted: true),
                a.institutes.isEmpty
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Pill('None', tone: PillTone.amber))
                    : Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          for (final n in a.institutes)
                            Pill(n, tone: PillTone.accent)
                        ],
                      ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppToggle(
                    value: a.active,
                    semanticLabel: 'Access for ${a.name}',
                    onChanged: (v) => _toggle(a, v),
                  ),
                ),
              ],
          ],
        ),
      ],
    );
  }
}
