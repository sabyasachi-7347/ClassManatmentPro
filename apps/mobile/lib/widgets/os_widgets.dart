import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Small uppercase label (".lab" in the web design system).
class Lab extends StatelessWidget {
  const Lab(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: color ?? context.os.txt3,
        ),
      );
}

/// Bento tile with a hero numeral.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.sub, this.hot = false});
  final String label, value;
  final String? sub;
  final bool hot;
  @override
  Widget build(BuildContext context) => OSCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Lab(label),
            const SizedBox(height: 12),
            Text(value, style: display(32, color: hot ? OS.hot : null)),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(sub!, style: TextStyle(fontSize: 11.5, color: context.os.txt3, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      );
}

/// Gradient hero card (".feat").
class FeatureCard extends StatelessWidget {
  const FeatureCard({super.key, required this.label, required this.value, this.caption});
  final String label, value;
  final String? caption;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        decoration: BoxDecoration(
          gradient: OS.featGradient,
          borderRadius: BorderRadius.circular(OS.rLg),
          boxShadow: [BoxShadow(color: OS.acc.withValues(alpha: .25), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Lab(label, color: Colors.white.withValues(alpha: .65)),
            const SizedBox(height: 10),
            Text(value, style: display(46, color: Colors.white)),
            if (caption != null) ...[
              const SizedBox(height: 8),
              Text(caption!, style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 12.5)),
            ],
          ],
        ),
      );
}

class OSCard extends StatelessWidget {
  const OSCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: context.os.surf,
          borderRadius: BorderRadius.circular(OS.r),
          boxShadow: const [BoxShadow(color: Color(0x0A0A0C14), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: child,
      );
}

enum PillTone { acc, hot, lime, amb, neutral }

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.tone = PillTone.neutral});
  final String text;
  final PillTone tone;
  @override
  Widget build(BuildContext context) {
    final c = context.os;
    final (bg, fg) = switch (tone) {
      PillTone.acc => (c.accSoft, OS.acc),
      PillTone.hot => (c.hotSoft, OS.hot),
      PillTone.lime => (c.limeSoft, OS.lime),
      PillTone.amb => (c.ambSoft, OS.amb),
      PillTone.neutral => (c.surf2, c.txt2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.name, {super.key, this.color});
  final String name;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF1B1F2B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.title, {super.key, this.message});
  final String title;
  final String? message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(children: [
          Text(title, style: display(17, weight: FontWeight.w600)),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, textAlign: TextAlign.center, style: TextStyle(color: context.os.txt2, fontSize: 13)),
          ],
        ]),
      );
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry(this.error, {super.key, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$error', textAlign: TextAlign.center, style: const TextStyle(color: OS.hot)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ),
      );
}

/// Screen header with eyebrow + title (".phh").
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.eyebrow, required this.title, this.sub});
  final String eyebrow, title;
  final String? sub;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Lab(eyebrow, color: OS.acc),
          const SizedBox(height: 6),
          Text(title, style: display(26, weight: FontWeight.w600)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!, style: TextStyle(color: context.os.txt2, fontSize: 12.5)),
          ],
        ]),
      );
}
