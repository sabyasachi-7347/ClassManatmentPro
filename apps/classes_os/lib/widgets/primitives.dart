import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/tokens.dart';

/// Light haptic on any committing tap. Silently no-ops on web and desktop.
void tick() {
  HapticFeedback.selectionClick();
}

/// ---------------------------------------------------------------------------
/// Bento grid
///
/// Flutter has no CSS grid, so spans are resolved to pixel widths and laid out
/// with a Wrap. Four columns on a desk, two on a phone; a tile asking for more
/// columns than exist is clamped rather than overflowing.
/// ---------------------------------------------------------------------------
class BentoTile {
  final int span;
  final Widget child;
  const BentoTile({this.span = 1, required this.child});
}

class BentoGrid extends StatelessWidget {
  final List<BentoTile> tiles;
  final double gap;
  const BentoGrid({super.key, required this.tiles, this.gap = 12});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth < 620 ? 2 : 4;
        final unit = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tiles)
              SizedBox(
                width: _width(t.span.clamp(1, columns), unit, columns),
                child: t.child,
              ),
          ],
        );
      },
    );
  }

  double _width(int span, double unit, int columns) =>
      unit * span + gap * (span - 1);
}

/// ---------------------------------------------------------------------------
/// Surfaces
/// ---------------------------------------------------------------------------
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final VoidCallback? onTap;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 16),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final body = AnimatedContainer(
      duration: Motion.base,
      curve: Motion.ease,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(R.md),
        boxShadow: color == null ? Shadows.one(context.brightness) : null,
      ),
      child: child,
    );
    if (onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(R.md),
      child: body,
    );
  }
}

/// The gradient hero tile. One per screen at most — it marks the single number
/// that matters, and loses its force if everything is a hero.
class FeatureCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? radius;

  const FeatureCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(22, 20, 22, 20),
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(R.lg),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.accent, const Color(0xFF0B37D8), const Color(0xFF6C29E0)],
                stops: const [0, 0.55, 1],
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
          Positioned(
            right: -50,
            bottom: -70,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white.withOpacity(0.18), Colors.white.withOpacity(0)],
                    stops: const [0, 0.68],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Numerals
///
/// Every figure in the app animates up from zero on mount. It is the single
/// gesture that makes the dashboards feel alive rather than printed.
/// ---------------------------------------------------------------------------
class CountUp extends StatefulWidget {
  final num value;
  final TextStyle style;
  final String suffix;

  const CountUp({super.key, required this.value, required this.style, this.suffix = ''});

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: Motion.count)..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        final shown = (widget.value * t).round();
        return Text('${_grouped(shown)}${widget.suffix}', style: widget.style);
      },
    );
  }

  String _grouped(int n) {
    final s = n.toString();
    if (s.length < 4) return s;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

enum Trend { up, down, flat }

/// Label on top, big animated number, movement underneath. Used everywhere a
/// single figure needs to land.
class KpiTile extends StatelessWidget {
  final String label;
  final num value;
  final String suffix;
  final String? delta;
  final Trend trend;
  final double size;

  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.suffix = '',
    this.delta,
    this.trend = Trend.flat,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tc = switch (trend) {
      Trend.up => c.lime,
      Trend.down => c.hot,
      Trend.flat => c.text3,
    };
    final arrow = switch (trend) {
      Trend.up => '↑',
      Trend.down => '↓',
      Trend.flat => '·',
    };
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: AppType.label(c.text3)),
          const SizedBox(height: 8),
          CountUp(
            value: value,
            suffix: suffix,
            style: AppType.display(size, weight: FontWeight.w700, color: c.text),
          ),
          if (delta != null) ...[
            const SizedBox(height: 5),
            Text('$arrow $delta',
                style: AppType.body(11.5, weight: FontWeight.w600, color: tc)),
          ],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Small parts
/// ---------------------------------------------------------------------------
enum PillTone { accent, hot, lime, amber, neutral }

class Pill extends StatelessWidget {
  final String text;
  final PillTone tone;
  const Pill(this.text, {super.key, this.tone = PillTone.neutral});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (bg, fg) = switch (tone) {
      PillTone.accent => (c.accentSoft, c.accent),
      PillTone.hot => (c.hotSoft, c.hot),
      PillTone.lime => (c.limeSoft, c.lime),
      PillTone.amber => (c.amberSoft, c.amber),
      PillTone.neutral => (c.surface2, c.text2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text,
          style: AppType.body(11, weight: FontWeight.w600, color: fg, height: 1.2)),
    );
  }
}

enum AvatarTone { ink, accent, hot, lime }

class AvatarBadge extends StatelessWidget {
  final String name;
  final double size;
  final AvatarTone tone;
  final String? glyph;

  const AvatarBadge(this.name,
      {super.key, this.size = 34, this.tone = AvatarTone.ink, this.glyph});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final colors = switch (tone) {
      AvatarTone.ink => [const Color(0xFF2A3040), const Color(0xFF0A0C14)],
      AvatarTone.accent => [const Color(0xFF4A78FF), c.accent],
      AvatarTone.hot => [const Color(0xFFFF7E5F), c.hot],
      AvatarTone.lime => [const Color(0xFF25C68C), c.lime],
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Text(
        glyph ?? _initials(name),
        style: AppType.body(size * 0.34,
            weight: FontWeight.w600, color: Colors.white, height: 1),
      ),
    );
  }

  String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// A permission switch. Saves on tap — there is no save button anywhere in
/// this app, which is most of why it feels quick.
class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  const AppToggle(
      {super.key, required this.value, required this.onChanged, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      label: semanticLabel,
      toggled: value,
      child: GestureDetector(
        onTap: () {
          tick();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: Motion.base,
          width: 42,
          height: 24,
          decoration: BoxDecoration(
            color: value ? c.accent : c.line,
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: Motion.base,
            curve: Motion.spring,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.all(3),
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double value; // 0..100
  final Color? color;
  const ProgressBar(this.value, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return LayoutBuilder(
      builder: (context, box) => Container(
        height: 8,
        decoration: BoxDecoration(
          color: c.line2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (value / 100).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Motion.ease,
            builder: (context, t, _) => Container(
              width: box.maxWidth * t,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: color == null
                    ? LinearGradient(colors: [c.accent, const Color(0xFF6C8DFF)])
                    : null,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  const SectionLabel(this.text,
      {super.key, this.padding = const EdgeInsets.fromLTRB(2, 22, 2, 10)});

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(text.toUpperCase(), style: AppType.label(context.c.text3)),
      );
}

class PageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const PageTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppType.display(30, weight: FontWeight.w600, color: c.text)),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: AppType.body(13.5, color: c.text2)),
        ],
        const SizedBox(height: 22),
      ],
    );
  }
}

/// Card header: title on the left, anything you like on the right.
class PanelHeader extends StatelessWidget {
  final String title;
  final List<Widget> trailing;
  const PanelHeader(this.title, {super.key, this.trailing = const []});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: AppType.display(14, weight: FontWeight.w600, color: context.c.text)),
          ),
          for (final w in trailing) ...[const SizedBox(width: 6), w],
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Buttons
/// ---------------------------------------------------------------------------
enum BtnKind { plain, primary, dark, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final BtnKind kind;
  final bool small;
  final bool expand;
  final Color? overrideBg;
  final Color? overrideFg;

  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.kind = BtnKind.plain,
    this.small = false,
    this.expand = false,
    this.overrideBg,
    this.overrideFg,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dark = context.brightness == Brightness.dark;

    Color bg, fg;
    Border? border;
    List<BoxShadow>? shadow;

    switch (kind) {
      case BtnKind.primary:
        bg = c.accent;
        fg = Colors.white;
        shadow = [BoxShadow(color: c.accentGlow, blurRadius: 12, offset: const Offset(0, 3))];
      case BtnKind.dark:
        bg = dark ? Colors.white : c.ink;
        fg = dark ? c.ink : Colors.white;
      case BtnKind.ghost:
        bg = Colors.transparent;
        fg = c.accent;
      case BtnKind.plain:
        bg = c.surface;
        fg = c.text;
        border = Border.all(color: c.line);
    }

    final child = Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 11, vertical: 7)
          : const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: overrideBg ?? bg,
        border: border,
        borderRadius: BorderRadius.circular(R.sm),
        boxShadow: shadow,
      ),
      // Centre only when stretched: an alignment makes a Container take all
      // the width it is offered, which balloons the button inside a Wrap.
      alignment: expand ? Alignment.center : null,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppType.body(small ? 11.5 : 12.5,
            weight: FontWeight.w600, color: overrideFg ?? fg, height: 1.2),
      ),
    );

    final tappable = InkWell(
      onTap: onPressed == null
          ? null
          : () {
              tick();
              onPressed!();
            },
      borderRadius: BorderRadius.circular(R.sm),
      child: child,
    );

    return expand ? SizedBox(width: double.infinity, child: tappable) : tappable;
  }
}

/// Large call to action used on the entry screens.
class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final BtnKind kind;
  final Color? bg;
  final Color? fg;
  final Widget? leading;

  const BigButton(this.label,
      {super.key,
      required this.onPressed,
      this.kind = BtnKind.plain,
      this.bg,
      this.fg,
      this.leading});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isPrimary = kind == BtnKind.primary;
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: () {
          tick();
          onPressed();
        },
        borderRadius: BorderRadius.circular(R.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg ?? (isPrimary ? c.accent : c.surface),
            border: isPrimary || bg != null ? null : Border.all(color: c.line),
            borderRadius: BorderRadius.circular(R.md),
            boxShadow: isPrimary
                ? [BoxShadow(color: c.accentGlow, blurRadius: 14, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              Text(label,
                  style: AppType.body(14.5,
                      weight: FontWeight.w600,
                      color: fg ?? (isPrimary ? Colors.white : c.text))),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Segmented control — the child switcher, week/month, password/OTP.
/// ---------------------------------------------------------------------------
class Segmented extends StatelessWidget {
  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;

  const Segmented(
      {super.key, required this.options, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - 8) / options.length;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.base,
                curve: Motion.spring,
                left: w * index,
                top: 0,
                bottom: 0,
                width: w,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: Shadows.one(context.brightness),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < options.length; i++)
                    SizedBox(
                      width: w,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          tick();
                          onChanged(i);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            options[i],
                            textAlign: TextAlign.center,
                            style: AppType.body(12.5,
                                weight: i == index ? FontWeight.w600 : FontWeight.w400,
                                color: i == index ? c.text : c.text2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A capability chip — tap to grant or revoke a faculty module.
class ModuleChip extends StatelessWidget {
  final String label;
  final String glyph;
  final bool on;
  final VoidCallback onTap;

  const ModuleChip(
      {super.key,
      required this.label,
      required this.glyph,
      required this.on,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: () {
        tick();
        onTap();
      },
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.spring,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: on ? c.accentSoft : c.surface,
          border: Border.all(color: on ? c.accent : c.line),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(glyph, style: AppType.body(12, color: on ? c.accent : c.text2)),
            const SizedBox(width: 7),
            Text(label,
                style: AppType.body(12,
                    weight: on ? FontWeight.w600 : FontWeight.w400,
                    color: on ? c.accent : c.text)),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Skeleton — shown while a screen mounts so switching never flashes empty.
/// ---------------------------------------------------------------------------
class Skeleton extends StatefulWidget {
  final double height;
  const Skeleton({super.key, this.height = 96});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(R.md),
          gradient: LinearGradient(
            begin: Alignment(-1 - 2 * (1 - _ctrl.value), 0),
            end: Alignment(1 + 2 * _ctrl.value, 0),
            colors: [c.line2, c.line, c.line2],
          ),
        ),
      ),
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) => BentoGrid(
        tiles: [
          for (var i = 0; i < 6; i++)
            BentoTile(
              span: i % 3 == 0 ? 2 : 1,
              child: Skeleton(height: i % 3 == 0 ? 130 : 96),
            ),
        ],
      );
}

/// ---------------------------------------------------------------------------
/// Empty state
/// ---------------------------------------------------------------------------
class EmptyState extends StatelessWidget {
  final String title;
  final String body;
  const EmptyState({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          Text(title,
              style: AppType.display(17, weight: FontWeight.w600, color: c.text)),
          const SizedBox(height: 6),
          Text(body,
              textAlign: TextAlign.center, style: AppType.body(13, color: c.text2)),
        ],
      ),
    );
  }
}

/// A hairline divider that matches the one used inside every list.
class HairLine extends StatelessWidget {
  const HairLine({super.key});
  @override
  Widget build(BuildContext context) => Container(height: 1, color: context.c.line2);
}

/// Key/value row used in the institute cards.
class KeyValue extends StatelessWidget {
  final String label;
  final String value;
  final bool first;
  const KeyValue(this.label, this.value, {super.key, this.first = false});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.line2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppType.body(12.5, color: c.text2)),
          Text(value, style: AppType.body(12.5, weight: FontWeight.w600, color: c.text)),
        ],
      ),
    );
  }
}
