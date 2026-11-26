import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/tokens.dart';

/// Charts are hand-painted rather than pulled from a package. It keeps the
/// dependency list at one, and more importantly lets the line, the fill and the
/// end-point dot animate in together on the same curve as the rest of the app.

class Series {
  final String name;
  final List<double> data;
  final Color color;
  final bool dashed;
  final bool filled;

  const Series({
    required this.name,
    required this.data,
    required this.color,
    this.dashed = false,
    this.filled = false,
  });
}

class LineChart extends StatefulWidget {
  final List<Series> series;
  final List<String> labels;
  final double height;

  const LineChart(
      {super.key, required this.series, required this.labels, this.height = 150});

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => CustomPaint(
              painter: _LinePainter(
                series: widget.series,
                labels: widget.labels,
                grid: c.line2,
                labelColor: c.text3,
                surface: c.surface,
                progress: Curves.easeOutCubic.transform(_ctrl.value),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final s in widget.series)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: s.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(s.name, style: AppType.body(11, color: c.text2)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<Series> series;
  final List<String> labels;
  final Color grid;
  final Color labelColor;
  final Color surface;
  final double progress;

  _LinePainter({
    required this.series,
    required this.labels,
    required this.grid,
    required this.labelColor,
    required this.surface,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 26.0, padR = 10.0, padT = 14.0, padB = 22.0;
    final all = series.expand((s) => s.data).toList();
    if (all.isEmpty) return;

    final minV = all.reduce(math.min) - 6;
    final maxV = all.reduce(math.max) + 6;
    final chartW = size.width - padL - padR;
    final chartH = size.height - padT - padB;

    double dx(int i, int n) => padL + (n <= 1 ? 0 : i * chartW / (n - 1));
    double dy(double v) => padT + (1 - (v - minV) / (maxV - minV)) * chartH;

    // Gridlines
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final v in [minV + 6, (minV + maxV) / 2, maxV - 6]) {
      canvas.drawLine(Offset(padL, dy(v)), Offset(size.width - padR, dy(v)), gridPaint);
    }

    // X labels, every third tick so they never collide on a phone
    for (var i = 0; i < labels.length; i += 3) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: AppType.mono(9, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(dx(i, labels.length) - tp.width / 2, size.height - padB + 8),
      );
    }

    for (final s in series) {
      if (s.data.isEmpty) continue;
      final n = s.data.length;
      // Reveal the line left to right.
      final visible = (n * progress).ceil().clamp(1, n);

      final path = Path();
      for (var i = 0; i < visible; i++) {
        final p = Offset(dx(i, n), dy(s.data[i]));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }

      if (s.filled && visible > 1) {
        final fill = Path.from(path)
          ..lineTo(dx(visible - 1, n), dy(minV))
          ..lineTo(dx(0, n), dy(minV))
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [s.color.withOpacity(0.22), s.color.withOpacity(0)],
            ).createShader(Rect.fromLTWH(0, padT, size.width, chartH)),
        );
      }

      final stroke = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.dashed ? 1.6 : 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(s.dashed ? _dash(path, 3, 4) : path, stroke);

      // Solid series get a dot on the most recent reading.
      if (!s.dashed && visible > 0) {
        final last = Offset(dx(visible - 1, n), dy(s.data[visible - 1]));
        canvas.drawCircle(last, 4.5, Paint()..color = s.color);
        canvas.drawCircle(
          last,
          4.5,
          Paint()
            ..color = surface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }
  }

  Path _dash(Path source, double on, double off) {
    final out = Path();
    for (final metric in source.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = math.min(d + on, metric.length);
        out.addPath(metric.extractPath(d, next), Offset.zero);
        d = next + off;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.progress != progress || old.series != series || old.grid != grid;
}

/// Bars. The most recent bar is full strength, the rest recede — so "now" reads
/// first without needing a label to say so.
class BarChart extends StatefulWidget {
  final List<double> data;
  final List<String> labels;
  final double height;
  final Color? color;

  const BarChart(
      {super.key,
      required this.data,
      required this.labels,
      this.height = 128,
      this.color});

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _BarPainter(
            data: widget.data,
            labels: widget.labels,
            color: widget.color ?? c.accent,
            labelColor: c.text3,
            progress: Curves.easeOutCubic.transform(_ctrl.value),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final Color color;
  final Color labelColor;
  final double progress;

  _BarPainter({
    required this.data,
    required this.labels,
    required this.color,
    required this.labelColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const padL = 24.0, padR = 6.0, padT = 10.0, padB = 22.0;
    final maxV = data.reduce(math.max) * 1.12;
    final chartH = size.height - padT - padB;
    final slot = (size.width - padL - padR) / data.length;

    for (var i = 0; i < data.length; i++) {
      final h = (data[i] / maxV) * chartH * progress;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(padL + i * slot + slot * 0.22, size.height - padB - h,
            slot * 0.56, h),
        const Radius.circular(5),
      );
      canvas.drawRect(
        rect.outerRect,
        Paint()..color = Colors.transparent,
      );
      canvas.drawRRect(
        rect,
        Paint()..color = color.withOpacity(i == data.length - 1 ? 1 : 0.32),
      );
    }

    for (var i = 0; i < labels.length && i < data.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: AppType.mono(9, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(padL + i * slot + slot / 2 - tp.width / 2, size.height - padB + 8),
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.progress != progress || old.data != data || old.color != color;
}

/// The attendance ring. Sweeps up on mount like every other figure.
class ProgressRing extends StatelessWidget {
  final double value; // 0..100
  final double size;
  final double stroke;
  final Color? color;
  final Color? track;
  final Widget? center;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 76,
    this.stroke = 8,
    this.color,
    this.track,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (value / 100).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(
                progress: t,
                color: color ?? c.accent,
                track: track ?? c.line2,
                stroke: stroke,
              ),
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// Tiny inline bars used inside the gradient hero, where a full chart would be
/// too much furniture.
class MiniBars extends StatelessWidget {
  final List<double> data;
  final Color color;
  final Color dim;
  final double height;

  const MiniBars({
    super.key,
    required this.data,
    this.color = Colors.white,
    this.dim = const Color(0x4DFFFFFF),
    this.height = 42,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = data.reduce(math.max);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < data.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: data[i] / maxV),
                duration: Duration(milliseconds: 600 + i * 70),
                curve: Motion.ease,
                builder: (context, t, _) => Container(
                  height: height * t,
                  decoration: BoxDecoration(
                    color: i == data.length - 1 ? color : dim,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
