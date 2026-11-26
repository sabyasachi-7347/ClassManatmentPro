import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../widgets/app_table.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';

class SystemAdminScreen extends StatefulWidget {
  final String tab;
  const SystemAdminScreen({super.key, required this.tab});

  @override
  State<SystemAdminScreen> createState() => _SystemAdminScreenState();
}

class _SystemAdminScreenState extends State<SystemAdminScreen> {
  late List<Lead> _leads = List.of(Mock.leads);

  /// A system admin only ever sees the institutes assigned to them.
  List<Institute> get _mine => Mock.institutes.take(2).toList();

  @override
  Widget build(BuildContext context) => switch (widget.tab) {
        'leads' => _leadsTab(),
        'admins' => _classesAdmins(),
        _ => _institutes(),
      };

  // ---------------------------------------------------------- institutes --
  Widget _institutes() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('My institutes',
            subtitle: 'Two assigned to you · fields save as you type'),
        BentoGrid(
          tiles: [
            for (final i in _mine)
              BentoTile(
                span: 2,
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          AvatarBadge(i.name, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(i.name,
                                    style: AppType.body(16,
                                        weight: FontWeight.w600, color: c.text)),
                                Text(i.city,
                                    style: AppType.body(12, color: c.text2)),
                              ],
                            ),
                          ),
                          Pill(i.status,
                              tone: i.isActive ? PillTone.lime : PillTone.amber),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _miniStat(context, 'Students', i.students.toString()),
                          const SizedBox(width: 24),
                          _miniStat(context, 'Batches', i.batches.toString()),
                          const SizedBox(width: 24),
                          _miniStat(
                              context, 'Brochure', i.isActive ? 'Up' : '—'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          AppButton('Edit profile',
                              small: true,
                              onPressed: () =>
                                  showToast(context, 'Editing ${i.name}')),
                          const SizedBox(width: 7),
                          AppButton('Brochure',
                              small: true,
                              onPressed: () => showToast(
                                  context, 'Opens the brochure upload')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            BentoTile(
              span: 4,
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PanelHeader('Profile — Sunrise Academy',
                        trailing: [Pill('Autosaves')]),
                    LayoutBuilder(
                      builder: (context, box) {
                        final two = box.maxWidth > 560;
                        final w = two ? (box.maxWidth - 12) / 2 : box.maxWidth;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                                width: w,
                                child: _field(context, 'Name', 'Sunrise Academy')),
                            SizedBox(
                                width: w,
                                child: _field(context, 'Area', 'Kalyan West')),
                            SizedBox(
                                width: w,
                                child: _field(
                                    context, 'Phone', '+91 251 220 4488',
                                    mono: true)),
                            SizedBox(
                                width: w,
                                child: _field(
                                    context, 'Brand colour', '#1B4DFF',
                                    mono: true)),
                            SizedBox(
                              width: box.maxWidth,
                              child: _field(context, 'Address',
                                  '2nd Floor, Shivam Plaza, Rambaug Lane 4, Kalyan West 421301'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
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

  Widget _field(BuildContext context, String label, String value,
      {bool mono = false}) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppType.body(11.5, weight: FontWeight.w600, color: c.text2)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          style: mono
              ? AppType.mono(13.5, color: c.text)
              : AppType.body(13.5, color: c.text),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- leads --
  Widget _leadsTab() {
    final waiting = _leads.where((l) => l.state == LeadState.fresh).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('Callbacks',
            subtitle: 'Phone verified by OTP before it reaches you'),
        BentoGrid(
          tiles: [
            BentoTile(
                child: KpiTile(
                    label: 'Waiting',
                    value: waiting,
                    delta: 'oldest 2 hrs',
                    trend: Trend.down)),
            const BentoTile(
                child: KpiTile(
                    label: 'Called today',
                    value: 6,
                    delta: 'up from 4',
                    trend: Trend.up)),
            const BentoTile(
                child: KpiTile(
                    label: 'Enrolled',
                    value: 3,
                    delta: 'this week',
                    trend: Trend.up)),
            const BentoTile(
                child: KpiTile(
                    label: 'Conversion',
                    value: 34,
                    suffix: '%',
                    delta: 'vs 28% last month',
                    trend: Trend.up)),
          ],
        ),
        const SizedBox(height: 14),
        TablePanel(
          title: '$waiting waiting',
          columns: const [
            TableCol('Person', width: 200),
            TableCol('Phone', width: 150),
            TableCol('Institute', width: 160),
            TableCol('From', width: 110),
            TableCol('Age', width: 80),
            TableCol('', width: 160),
          ],
          rows: [
            for (final l in _leads)
              [
                TPerson(l.name, tone: AvatarTone.hot),
                TCell(l.phone, mono: true, muted: true),
                TCell(l.institute, muted: true),
                Align(alignment: Alignment.centerLeft, child: Pill(l.source)),
                TCell(l.age, muted: true),
                _leadAction(l),
              ],
          ],
        ),
      ],
    );
  }

  Widget _leadAction(Lead l) {
    if (l.state == LeadState.fresh) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton('Call',
              kind: BtnKind.primary,
              small: true,
              onPressed: () => showToast(context, 'Dialling ${l.name}')),
          const SizedBox(width: 6),
          AppButton('Done', small: true, onPressed: () {
            setState(() {
              _leads = _leads
                  .map((x) => x.id == l.id ? x.copyWith(state: LeadState.called) : x)
                  .toList();
            });
            showToast(context, 'Marked ${l.name} as called');
          }),
        ],
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Pill(
        l.state == LeadState.enrolled ? 'Enrolled' : 'Called',
        tone: l.state == LeadState.enrolled ? PillTone.lime : PillTone.accent,
      ),
    );
  }

  // ------------------------------------------------------- classes admins --
  Widget _classesAdmins() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('Classes admins',
            subtitle:
                'One per institute. Deactivating frees the slot straight away.'),
        BentoGrid(
          tiles: [
            for (final i in _mine)
              BentoTile(
                span: 2,
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PanelHeader(i.name, trailing: const [Pill('1 of 1')]),
                      if (i.admin.startsWith('—'))
                        Column(
                          children: [
                            const EmptyState(
                              title: 'No classes admin yet',
                              body:
                                  'This institute cannot take enrolments until someone is in the chair.',
                            ),
                            AppButton('Name a classes admin',
                                kind: BtnKind.primary,
                                onPressed: () => showToast(
                                    context, 'Opens the classes admin form')),
                          ],
                        )
                      else ...[
                        Row(
                          children: [
                            AvatarBadge(i.admin.replaceAll('. ', ' '),
                                size: 42, tone: AvatarTone.accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(i.admin,
                                      style: AppType.body(14.5,
                                          weight: FontWeight.w600, color: c.text)),
                                  Text('since Mar 2025',
                                      style: AppType.mono(11.5, color: c.text2)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            AppButton('Reset password',
                                small: true,
                                onPressed: () =>
                                    showToast(context, 'Reset link sent')),
                            const SizedBox(width: 7),
                            AppButton('Deactivate',
                                small: true,
                                onPressed: () => showToast(context,
                                    'Slot freed — you can name a replacement')),
                          ],
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
}
