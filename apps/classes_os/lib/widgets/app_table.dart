import 'package:flutter/material.dart';

import '../core/tokens.dart';
import 'primitives.dart';

class TableCol {
  final String label;
  final double width;
  const TableCol(this.label, {this.width = 120});
}

/// A plain table with fixed column widths and a single horizontal scroll when
/// it outgrows the pane. Material's DataTable brings furniture this design
/// does not want — no dividers between columns, no zebra striping, just rows
/// separated by a hairline.
class AppTable extends StatelessWidget {
  final List<TableCol> columns;
  final List<List<Widget>> rows;

  const AppTable({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final total = columns.fold<double>(0, (sum, col) => sum + col.width);

    return LayoutBuilder(
      builder: (context, box) {
        final table = SizedBox(
          width: total < box.maxWidth ? box.maxWidth : total,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                child: Row(
                  children: [
                    for (final col in columns)
                      SizedBox(
                        width: _w(col, total, box.maxWidth),
                        child: Text(col.label.toUpperCase(),
                            style: AppType.label(c.text3)),
                      ),
                  ],
                ),
              ),
              for (final row in rows)
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.line2)),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < columns.length; i++)
                        SizedBox(
                          width: _w(columns[i], total, box.maxWidth),
                          child: i < row.length ? row[i] : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );

        return total < box.maxWidth
            ? table
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: table,
              );
      },
    );
  }

  /// When there is room to spare, columns share it proportionally rather than
  /// leaving a gutter on the right.
  double _w(TableCol col, double total, double available) {
    const padding = 36.0;
    if (total >= available - padding) return col.width;
    return col.width * (available - padding) / total;
  }
}

/// A card that is nothing but a header and a table.
class TablePanel extends StatelessWidget {
  final String title;
  final List<Widget> trailing;
  final List<TableCol> columns;
  final List<List<Widget>> rows;

  const TablePanel({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
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
                  child: Text(title,
                      style: AppType.display(14,
                          weight: FontWeight.w600, color: c.text)),
                ),
                for (final w in trailing) ...[const SizedBox(width: 6), w],
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppTable(columns: columns, rows: rows),
        ],
      ),
    );
  }
}

/// Convenience cells, so screens read as content rather than as styling.
class TCell extends StatelessWidget {
  final String text;
  final bool strong;
  final bool mono;
  final bool muted;

  const TCell(this.text,
      {super.key, this.strong = false, this.mono = false, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = muted ? c.text2 : c.text;
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: mono
          ? AppType.mono(muted ? 11.5 : 12.5, color: color)
          : AppType.body(muted ? 11.5 : 13,
              weight: strong ? FontWeight.w600 : FontWeight.w400, color: color),
    );
  }
}

class TPerson extends StatelessWidget {
  final String name;
  final AvatarTone tone;
  final String? sub;

  const TPerson(this.name, {super.key, this.tone = AvatarTone.ink, this.sub});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        AvatarBadge(name, size: 32, tone: tone),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body(13, weight: FontWeight.w600, color: c.text)),
              if (sub != null)
                Text(sub!,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.body(11.5, color: c.text2)),
            ],
          ),
        ),
      ],
    );
  }
}
