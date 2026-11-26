import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import 'primitives.dart';

/// Floating confirmation. Everything that writes says so here and nowhere else.
void showToast(BuildContext context, String message) {
  final c = context.c;
  final dark = context.brightness == Brightness.dark;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 2300),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF6C8DFF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: AppType.body(13, color: dark ? c.ink : Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Standard sheet chrome: grab handle, title, optional description, scrolling
/// body, pinned footer. Every sheet in the app uses it so they behave alike.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  String? description,
  required Widget Function(BuildContext context) builder,
  Widget Function(BuildContext context)? footer,
}) {
  final c = context.c;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    barrierColor: Colors.black.withOpacity(0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(R.xl)),
    ),
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.84),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(title,
                        style: AppType.display(20,
                            weight: FontWeight.w600, color: c.text)),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 5),
                    Text(description,
                        style: AppType.body(12.5, color: c.text2, height: 1.5)),
                  ],
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: builder(sheetContext),
              ),
            ),
            if (footer != null)
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, 18 + media.padding.bottom),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line2)),
                ),
                child: footer(sheetContext),
              ),
          ],
        ),
      );
    },
  );
}

/// ---------------------------------------------------------------------------
/// Quick actions — the four things a role does most, one tap from anywhere.
/// ---------------------------------------------------------------------------
class QuickAction {
  final String glyph;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickAction({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

Future<void> showQuickActions(BuildContext context, List<QuickAction> actions) {
  return showAppSheet<void>(
    context: context,
    title: 'Quick actions',
    description: 'The four things you do most, one tap away.',
    builder: (sheetContext) {
      final c = sheetContext.c;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            for (final a in actions)
              InkWell(
                borderRadius: BorderRadius.circular(R.md),
                onTap: () {
                  tick();
                  Navigator.of(sheetContext).pop();
                  a.onTap();
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(R.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(a.glyph,
                            style: AppType.body(16, color: c.accent, height: 1)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(a.title,
                              style: AppType.body(13.5,
                                  weight: FontWeight.w600, color: c.text)),
                          Text(a.subtitle,
                              style: AppType.body(11, color: c.text2)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// ---------------------------------------------------------------------------
/// Roll call
///
/// The design decision that matters: everyone starts present. A teacher taps
/// only the students who are missing, so a 34-strong batch is two taps rather
/// than thirty-four. Saving fires the parent notifications.
/// ---------------------------------------------------------------------------
///
/// Pass [roster] and [onSave] to run a real roll call: [initialAbsent]
/// pre-fills a re-take, and [onSave] gets the absent ids and returns the toast
/// to show (or throws, and the sheet stays open with the error).
Future<void> showRollCall(
  BuildContext context, {
  required String batch,
  List<Student>? roster,
  Set<String> initialAbsent = const {},
  Future<String> Function(Set<String> absent)? onSave,
}) {
  final rows = roster ?? Mock.students.take(6).toList();
  final absent = <String>{...initialAbsent};
  var saving = false;
  String? error;
  // The footer lives outside the body's StatefulBuilder; this tells it the
  // absent count changed so the button label keeps up.
  final changed = ValueNotifier(0);

  return showAppSheet<void>(
    context: context,
    title: 'Roll call',
    description: "Everyone starts present. Tap only who's missing.",
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        final c = context.c;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  _tally(context, '${rows.length - absent.length}', 'Present', c.lime),
                  const SizedBox(width: 12),
                  _tally(context, '${absent.length}', 'Absent',
                      absent.isEmpty ? c.text3 : c.hot),
                  const SizedBox(width: 12),
                  _tally(context, '${rows.length}', 'Roster', c.text),
                ],
              ),
            ),
            if (rows.isEmpty)
              const EmptyState(
                  title: 'No students in this batch',
                  body: 'Enrol students on the Mapping screen first.'),
            for (final s in rows)
              _RosterRow(
                student: s,
                absent: absent.contains(s.id),
                onTap: () {
                  tick();
                  setSheetState(() {
                    absent.contains(s.id) ? absent.remove(s.id) : absent.add(s.id);
                  });
                  changed.value++;
                },
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    ),
    footer: (sheetContext) => ValueListenableBuilder<int>(
      valueListenable: changed,
      builder: (context, _, __) => StatefulBuilder(
      builder: (context, setFooter) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(error!, style: AppType.body(12.5, color: context.c.hot)),
            ),
          Row(
            children: [
              Expanded(
                child: BigButton('Cancel', onPressed: () => Navigator.of(sheetContext).pop()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BigButton(
                  saving
                      ? 'Saving…'
                      : absent.isEmpty
                          ? 'All present'
                          : 'Save · alert ${absent.length}',
                  kind: BtnKind.primary,
                  onPressed: () async {
                    if (saving || rows.isEmpty) return;
                    if (onSave == null) {
                      Navigator.of(sheetContext).pop();
                      showToast(
                        context,
                        absent.isEmpty
                            ? 'All present — saved'
                            : '${absent.length} absent · parents notified',
                      );
                      return;
                    }
                    setFooter(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      final msg = await onSave({...absent});
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                      if (context.mounted) showToast(context, msg);
                    } catch (e) {
                      setFooter(() {
                        saving = false;
                        error = '$e';
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    ),
  ).whenComplete(changed.dispose);
}

Widget _tally(BuildContext context, String value, String label, Color color) {
  final c = context.c;
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(R.md),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppType.display(26, weight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(), style: AppType.label(c.text3)),
        ],
      ),
    ),
  );
}

class _RosterRow extends StatelessWidget {
  final Student student;
  final bool absent;
  final VoidCallback onTap;

  const _RosterRow(
      {required this.student, required this.absent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.spring,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: absent ? c.hotSoft : c.surface,
          border: Border.all(color: absent ? c.hot : c.line, width: 1.5),
          borderRadius: BorderRadius.circular(R.md),
        ),
        child: Row(
          children: [
            AvatarBadge(student.name,
                size: 32, tone: absent ? AvatarTone.hot : AvatarTone.ink),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name,
                      style: AppType.body(13.5,
                          weight: FontWeight.w600, color: c.text)),
                  Text(student.roll, style: AppType.mono(11, color: c.text2)),
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: absent ? c.hot : c.limeSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                absent ? '✕' : '✓',
                style: AppType.body(13,
                    weight: FontWeight.w700,
                    color: absent ? Colors.white : c.lime,
                    height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
