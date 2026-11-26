import 'package:flutter/material.dart';

import '../core/tokens.dart';
import 'primitives.dart';

class SwipeAction {
  final String label;
  final String glyph;
  final Color background;
  final VoidCallback onTap;

  const SwipeAction({
    required this.label,
    required this.glyph,
    required this.background,
    required this.onTap,
  });
}

/// A list row that reveals actions when dragged left, and snaps open or shut
/// on release. The parent's two most common actions live here rather than
/// behind a tap-through to a detail screen.
class SwipeRow extends StatefulWidget {
  final List<SwipeAction> actions;
  final Widget child;
  final double actionWidth;

  const SwipeRow({
    super.key,
    required this.actions,
    required this.child,
    this.actionWidth = 78,
  });

  @override
  State<SwipeRow> createState() => _SwipeRowState();
}

class _SwipeRowState extends State<SwipeRow> {
  double _x = 0;
  bool _dragging = false;

  double get _max => widget.actions.length * widget.actionWidth;

  void _close() => setState(() => _x = 0);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(R.md),
        boxShadow: Shadows.one(context.brightness),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: Row(
              children: [
                for (final a in widget.actions)
                  GestureDetector(
                    onTap: () {
                      tick();
                      a.onTap();
                      _close();
                    },
                    child: Container(
                      width: widget.actionWidth,
                      color: a.background,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(a.glyph,
                              style: AppType.body(17, color: Colors.white, height: 1)),
                          const SizedBox(height: 5),
                          Text(a.label,
                              style: AppType.body(11,
                                  weight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => setState(() => _dragging = true),
            onHorizontalDragUpdate: (d) {
              setState(() => _x = (_x + d.delta.dx).clamp(-_max, 0.0));
            },
            onHorizontalDragEnd: (d) {
              setState(() {
                _dragging = false;
                final flung = d.velocity.pixelsPerSecond.dx < -300;
                _x = (flung || _x < -_max / 2.4) ? -_max : 0;
              });
            },
            child: AnimatedContainer(
              duration: _dragging ? Duration.zero : Motion.base,
              curve: Motion.spring,
              transform: Matrix4.translationValues(_x, 0, 0),
              decoration: BoxDecoration(color: c.surface),
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
