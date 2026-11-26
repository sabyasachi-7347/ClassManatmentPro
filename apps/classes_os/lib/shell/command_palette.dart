import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/tokens.dart';
import '../data/models.dart';
import '../widgets/primitives.dart';
import 'nav_config.dart';

/// Cmd/Ctrl+K. Type two letters, press Enter, land on the screen — role and
/// tab in one move. On a desk this replaces nearly all sidebar hunting.
Future<void> showCommandPalette(
  BuildContext context, {
  required void Function(Role role, String tab) onPick,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Command palette',
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, _, __) => _Palette(onPick: onPick),
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0)
            .animate(CurvedAnimation(parent: anim, curve: Motion.spring)),
        child: child,
      ),
    ),
  );
}

class _Palette extends StatefulWidget {
  final void Function(Role role, String tab) onPick;
  const _Palette({required this.onPick});

  @override
  State<_Palette> createState() => _PaletteState();
}

class _PaletteState extends State<_Palette> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  int _selected = 0;

  List<Command> get _hits {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) return kCommands;
    return kCommands
        .where((c) => '${c.label} ${c.group}'.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _run(Command c) {
    Navigator.of(context).pop();
    widget.onPick(c.role, c.tab);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final hits = _hits;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _selected = (_selected + 1).clamp(0, (hits.length - 1).clamp(0, 99)));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _selected = (_selected - 1).clamp(0, 99));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter && hits.isNotEmpty) {
      _run(hits[_selected.clamp(0, hits.length - 1)]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hits = _hits;

    return Align(
      alignment: const Alignment(0, -0.62),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 580,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.92,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(R.lg),
            boxShadow: Shadows.three(context.brightness),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Focus(
                onKeyEvent: _onKey,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  onChanged: (_) => setState(() => _selected = 0),
                  style: AppType.body(16, color: c.text),
                  decoration: const InputDecoration(
                    hintText: 'Search actions, screens, people…',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(22, 19, 22, 19),
                  ),
                ),
              ),
              Container(height: 1, color: c.line2),
              if (hits.isEmpty)
                const EmptyState(
                  title: 'Nothing matches',
                  body: 'Try a batch name or a person',
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(7),
                    itemCount: hits.length,
                    itemBuilder: (context, i) {
                      final hit = hits[i];
                      final on = i == _selected;
                      return InkWell(
                        borderRadius: BorderRadius.circular(R.sm),
                        onTap: () => _run(hit),
                        onHover: (_) => setState(() => _selected = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: on ? c.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(R.sm),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 27,
                                height: 27,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: on
                                      ? Colors.white.withOpacity(0.2)
                                      : c.surface2,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text('→',
                                    style: AppType.body(12,
                                        color: on ? Colors.white : c.text2)),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Text(hit.label,
                                    style: AppType.body(13.5,
                                        color: on ? Colors.white : c.text)),
                              ),
                              Text(hit.group,
                                  style: AppType.body(10.5,
                                      color: on
                                          ? Colors.white.withOpacity(0.6)
                                          : c.text3)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
