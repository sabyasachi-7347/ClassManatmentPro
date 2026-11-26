import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../widgets/primitives.dart';

class MatrixRow {
  final String id;
  final String title;
  final String subtitle;
  final AvatarTone tone;

  const MatrixRow({
    required this.id,
    required this.title,
    required this.subtitle,
    this.tone = AvatarTone.ink,
  });
}

/// The mapping matrix.
///
/// The point of this screen is the drag: press on a cell and sweep, and every
/// cell the pointer crosses takes the value the first one got. Enrolling a
/// whole batch is one gesture rather than thirty taps, and un-enrolling works
/// the same way because the first cell decides the direction.
///
/// Cells are located by arithmetic on the pointer position rather than by hit
/// testing, which is why the grid uses fixed metrics.
class MappingMatrix extends StatefulWidget {
  final List<MatrixRow> rows;
  final List<String> columns;
  final Set<String> initial; // "rowId:columnIndex"
  final void Function(String rowId, int column, bool value)? onChanged;

  const MappingMatrix({
    super.key,
    required this.rows,
    required this.columns,
    required this.initial,
    this.onChanged,
  });

  @override
  State<MappingMatrix> createState() => MappingMatrixState();
}

class MappingMatrixState extends State<MappingMatrix> {
  static const double _cell = 44;
  static const double _row = 42;
  static const double _head = 112;
  static const double _nameCol = 190;

  late final Set<String> _on = Set.of(widget.initial);

  /// The value being painted for the duration of one drag. Null between drags.
  bool? _brush;
  String? _lastKey;

  int get count => _on.length;

  String _key(String rowId, int col) => '$rowId:$col';

  void _apply(int rowIndex, int col, bool value) {
    if (rowIndex < 0 || rowIndex >= widget.rows.length) return;
    if (col < 0 || col >= widget.columns.length) return;
    final k = _key(widget.rows[rowIndex].id, col);
    if (_lastKey == k && _brush != null) return;
    _lastKey = k;
    setState(() => value ? _on.add(k) : _on.remove(k));
    widget.onChanged?.call(widget.rows[rowIndex].id, col, value);
  }

  void _pointer(Offset local, {required bool isDown}) {
    final col = (local.dx / _cell).floor();
    final rowIndex = (local.dy / _row).floor();
    if (col < 0 || rowIndex < 0) return;
    if (col >= widget.columns.length || rowIndex >= widget.rows.length) return;

    if (isDown) {
      final current = _on.contains(_key(widget.rows[rowIndex].id, col));
      _brush = !current;
      _lastKey = null;
      tick();
    }
    if (_brush == null) return;
    _apply(rowIndex, col, _brush!);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Listener(
      onPointerUp: (_) {
        _brush = null;
        _lastKey = null;
      },
      onPointerCancel: (_) {
        _brush = null;
        _lastKey = null;
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Frozen first column: who the row is.
          SizedBox(
            width: _nameCol,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: _head,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 18, bottom: 10),
                      child: Text('STUDENT', style: AppType.label(c.text3)),
                    ),
                  ),
                ),
                for (final r in widget.rows)
                  SizedBox(
                    height: _row,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 18, right: 12),
                      child: Row(
                        children: [
                          AvatarBadge(r.title, size: 28, tone: r.tone),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppType.body(12.5,
                                        weight: FontWeight.w600, color: c.text)),
                                Text(r.subtitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppType.mono(10.5, color: c.text3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: widget.columns.length * _cell,
                child: Column(
                  children: [
                    // Column labels, turned on their side so a six-batch grid
                    // fits a laptop without truncating any names.
                    SizedBox(
                      height: _head,
                      child: Row(
                        children: [
                          for (final label in widget.columns)
                            SizedBox(
                              width: _cell,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppType.body(11, color: c.text2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) =>
                          _pointer(e.localPosition, isDown: true),
                      onPointerMove: (e) =>
                          _pointer(e.localPosition, isDown: false),
                      child: SizedBox(
                        height: widget.rows.length * _row,
                        child: Column(
                          children: [
                            for (final r in widget.rows)
                              SizedBox(
                                height: _row,
                                child: Row(
                                  children: [
                                    for (var col = 0;
                                        col < widget.columns.length;
                                        col++)
                                      _Cell(
                                        on: _on.contains(_key(r.id, col)),
                                        size: _cell,
                                        semantics:
                                            '${r.title} in ${widget.columns[col]}',
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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

class _Cell extends StatelessWidget {
  final bool on;
  final double size;
  final String semantics;

  const _Cell({required this.on, required this.size, required this.semantics});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      label: semantics,
      checked: on,
      child: SizedBox(
        width: size,
        child: Center(
          child: AnimatedContainer(
            duration: Motion.fast,
            curve: Motion.spring,
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              color: on ? c.accent : Colors.transparent,
              border: Border.all(
                color: on ? c.accent : c.line,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(7),
              boxShadow: on
                  ? [
                      BoxShadow(
                          color: c.accentGlow,
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ]
                  : null,
            ),
            child: on
                ? Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
