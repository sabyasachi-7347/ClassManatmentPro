import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/tokens.dart';
import '../data/models.dart';
import '../features/classes_admin.dart';
import '../features/entry_flow.dart';
import '../features/faculty.dart';
import '../features/parent.dart';
import '../features/student.dart';
import '../features/super_admin.dart';
import '../features/system_admin.dart';
import '../features/teacher.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import 'command_palette.dart';
import 'nav_config.dart';

/// The shell owns three things: which role is on screen, which tab inside it,
/// and whether we are drawing a desk or a phone. Everything else is a screen.
///
/// The role switcher in the top bar is a prototype affordance. In production a
/// user lands on their own role after the membership picker, and the switcher
/// only appears for the handful of people who genuinely hold two.
class AppShell extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const AppShell({super.key, required this.isDark, required this.onToggleTheme});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  Role _role = Role.classesAdmin;
  String _tab = 'overview';
  bool _forcePhone = false;
  bool _loading = false;
  int _child = 0; // which child a parent is looking at

  RoleConfig get _cfg => kRoles[_role]!;

  void _goto(Role role, String tab) {
    setState(() {
      _role = role;
      _tab = tab;
    });
    _flashSkeleton();
  }

  void _setRole(Role role) {
    setState(() {
      _role = role;
      _tab = kRoles[role]!.firstTab;
    });
    _flashSkeleton();
  }

  void _setTab(String tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    _flashSkeleton();
  }

  /// A brief shimmer on every navigation. Without it, switching a dense
  /// dashboard flashes an empty pane for one frame and reads as a stutter.
  void _flashSkeleton() {
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  /// Step through the bottom nav. Wired to horizontal flings on the body.
  void _step(int delta) {
    final tabs = _cfg.tabs;
    if (tabs.length < 2) return;
    final i = tabs.indexWhere((t) => t.key == _tab);
    final next = (i + delta).clamp(0, tabs.length - 1);
    if (next != i) {
      tick();
      _setTab(tabs[next].key);
    }
  }

  Widget _screen() {
    if (_loading && _role != Role.guest) {
      return const Padding(padding: EdgeInsets.only(top: 4), child: SkeletonGrid());
    }
    return switch (_role) {
      Role.guest => const EntryFlow(),
      Role.superAdmin => SuperAdminScreen(tab: _tab),
      Role.systemAdmin => SystemAdminScreen(tab: _tab),
      Role.classesAdmin => ClassesAdminScreen(tab: _tab),
      Role.faculty => FacultyScreen(tab: _tab),
      Role.teacher => TeacherScreen(tab: _tab),
      Role.student => StudentScreen(tab: _tab, onJump: _setTab),
      Role.parent => ParentScreen(
          tab: _tab,
          childIndex: _child,
          onChildChanged: (i) => setState(() => _child = i),
        ),
    };
  }

  List<QuickAction> get _quickActions => switch (_role) {
        Role.teacher => [
            QuickAction(
                glyph: '✓',
                title: 'Roll call',
                subtitle: 'Live lecture',
                onTap: () => showRollCall(context, batch: 'JEE Adv 2027 — B')),
            QuickAction(
                glyph: '▦',
                title: 'Log syllabus',
                subtitle: 'After class',
                onTap: () => showToast(context, 'Syllabus for the last lecture')),
            QuickAction(
                glyph: '◐',
                title: 'Mark away',
                subtitle: 'A day or a slot',
                onTap: () => _setTab('me')),
            QuickAction(
                glyph: '☎',
                title: 'Call office',
                subtitle: 'Front desk',
                onTap: () => showToast(context, 'Calling the front desk')),
          ],
        Role.student => [
            QuickAction(
                glyph: '▲',
                title: 'Results',
                subtitle: 'Latest marks',
                onTap: () => _setTab('results')),
            QuickAction(
                glyph: '▦',
                title: 'Syllabus',
                subtitle: "What's covered",
                onTap: () => _setTab('syllabus')),
            QuickAction(
                glyph: '✓',
                title: 'Attendance',
                subtitle: 'Your record',
                onTap: () => _setTab('attendance')),
            QuickAction(
                glyph: '☎',
                title: 'Ask a doubt',
                subtitle: 'Your teacher',
                onTap: () => showToast(context, 'Doubt sent to V. Raghavan')),
          ],
        Role.parent => [
            QuickAction(
                glyph: '☎',
                title: 'Request callback',
                subtitle: 'Office calls you',
                onTap: () => showToast(context, 'The office will call you back')),
            QuickAction(
                glyph: '◐',
                title: 'One-to-one',
                subtitle: 'Meet a teacher',
                onTap: () => showToast(context, 'Request sent to the office')),
            QuickAction(
                glyph: '✎',
                title: 'Send a reason',
                subtitle: 'For an absence',
                onTap: () => showToast(context, 'Reason sent')),
            QuickAction(
                glyph: '▲',
                title: 'Full report',
                subtitle: 'This term',
                onTap: () => showToast(context, 'Opening the term report')),
          ],
        _ => const [],
      };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final asDesk = _cfg.role.isDesk && wide && !_forcePhone;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _openPalette,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _openPalette,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              _TopBar(
                role: _role,
                isDark: widget.isDark,
                showDeviceToggle: _cfg.role.isDesk && wide,
                forcePhone: _forcePhone,
                onRole: _setRole,
                onToggleTheme: widget.onToggleTheme,
                onDevice: (phone) => setState(() => _forcePhone = phone),
                onPalette: wide ? _openPalette : null,
              ),
              Expanded(
                child: asDesk ? _desk() : _phone(wide),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPalette() => showCommandPalette(context, onPick: _goto);

  // ---------------------------------------------------------------- desk ----
  Widget _desk() {
    final c = context.c;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(right: BorderSide(color: c.line)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_cfg.scope,
                        style: AppType.display(17,
                            weight: FontWeight.w700, color: c.text)),
                    const SizedBox(height: 3),
                    Text(_role.label.toUpperCase(), style: AppType.label(c.accent)),
                  ],
                ),
              ),
              for (final t in _cfg.tabs) _railItem(t),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(30, 26, 30, 70),
            child: _screen(),
          ),
        ),
      ],
    );
  }

  Widget _railItem(NavItem t) {
    final c = context.c;
    final on = t.key == _tab;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(R.sm),
        onTap: () => _setTab(t.key),
        child: AnimatedContainer(
          duration: Motion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: on ? c.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(R.sm),
            boxShadow: on
                ? [BoxShadow(color: c.accentGlow, blurRadius: 14, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 17,
                child: Text(t.glyph,
                    textAlign: TextAlign.center,
                    style: AppType.body(13, color: on ? Colors.white : c.text2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(t.label,
                    style: AppType.body(13.5,
                        weight: on ? FontWeight.w600 : FontWeight.w400,
                        color: on ? Colors.white : c.text2)),
              ),
              if (t.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: on ? Colors.white.withOpacity(0.24) : c.hot,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(t.badge!,
                      style: AppType.body(10,
                          weight: FontWeight.w600, color: Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- phone ----
  Widget _phone(bool wide) {
    final c = context.c;
    final frame = Container(
      width: 414,
      constraints: BoxConstraints(
        maxHeight: wide ? 756 : double.infinity,
      ),
      decoration: BoxDecoration(
        color: c.canvas,
        borderRadius: wide ? BorderRadius.circular(30) : null,
        boxShadow: wide ? Shadows.three(context.brightness) : null,
      ),
      clipBehavior: wide ? Clip.antiAlias : Clip.none,
      child: _phoneBody(),
    );

    if (!wide) return SizedBox(width: double.infinity, child: _phoneBody());
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: frame,
      ),
    );
  }

  Widget _phoneBody() {
    final c = context.c;
    final header = _cfg.header;
    final hasNav = _cfg.tabs.isNotEmpty;
    final quick = _quickActions;

    return Stack(
      children: [
        Column(
          children: [
            if (header != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Text(header.eyebrow.toUpperCase(),
                          style: AppType.label(c.accent)),
                    ),
                    const SizedBox(height: 5),
                    Text(header.title,
                        style: AppType.display(25,
                            weight: FontWeight.w600, color: c.text)),
                    const SizedBox(height: 3),
                    Text(header.subtitle,
                        style: AppType.body(12.5, color: c.text2)),
                  ],
                ),
              ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  final v = d.velocity.pixelsPerSecond.dx;
                  if (v < -260) _step(1);
                  if (v > 260) _step(-1);
                },
                child: RefreshIndicator(
                  color: c.accent,
                  backgroundColor: c.surface,
                  onRefresh: () async {
                    await Future<void>.delayed(const Duration(milliseconds: 700));
                    if (mounted) showToast(context, 'Refreshed');
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(14, 12, 14, hasNav ? 104 : 24),
                    children: [_screen()],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (quick.isNotEmpty)
          Positioned(
            right: 18,
            bottom: hasNav ? 88 : 24,
            child: _Fab(onTap: () => showQuickActions(context, quick)),
          ),
        if (hasNav)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _BottomNav(
              tabs: _cfg.tabs,
              current: _tab,
              onTap: _setTab,
            ),
          ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Top bar
/// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  final Role role;
  final bool isDark;
  final bool showDeviceToggle;
  final bool forcePhone;
  final ValueChanged<Role> onRole;
  final VoidCallback onToggleTheme;
  final ValueChanged<bool> onDevice;
  final VoidCallback? onPalette;

  const _TopBar({
    required this.role,
    required this.isDark,
    required this.showDeviceToggle,
    required this.forcePhone,
    required this.onRole,
    required this.onToggleTheme,
    required this.onDevice,
    this.onPalette,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      color: c.ink,
      padding: EdgeInsets.fromLTRB(
          14, MediaQuery.paddingOf(context).top + 9, 14, 9),
      child: Row(
        children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: 'classes',
                  style: AppType.display(14,
                      weight: FontWeight.w800, color: Colors.white)),
              TextSpan(
                  text: '.',
                  style: AppType.display(14,
                      weight: FontWeight.w800, color: const Color(0xFF6C8DFF))),
              TextSpan(
                  text: 'os',
                  style: AppType.display(14,
                      weight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final r in kRoleOrder) ...[
                    _roleChip(context, r),
                    const SizedBox(width: 3),
                  ],
                ],
              ),
            ),
          ),
          if (onPalette != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onPalette,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('⌘K',
                        style: AppType.mono(11, color: Colors.white70)),
                  ),
                  const SizedBox(width: 7),
                  Text('jump to anything',
                      style:
                          AppType.body(11, color: Colors.white.withOpacity(0.42))),
                ],
              ),
            ),
          ],
          const SizedBox(width: 10),
          _iconButton(context, isDark ? '☀' : '☾', onToggleTheme),
          if (showDeviceToggle) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _deviceChip(context, 'Desktop', !forcePhone, () => onDevice(false)),
                  _deviceChip(context, 'Mobile', forcePhone, () => onDevice(true)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _roleChip(BuildContext context, Role r) {
    final on = r == role;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        tick();
        onRole(r);
      },
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          r.label,
          style: AppType.body(11.5,
              weight: on ? FontWeight.w600 : FontWeight.w400,
              color: on ? const Color(0xFF0A0C14) : Colors.white.withOpacity(0.62)),
        ),
      ),
    );
  }

  Widget _iconButton(BuildContext context, String glyph, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        tick();
        onTap();
      },
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(glyph, style: AppType.body(13, color: Colors.white)),
      ),
    );
  }

  Widget _deviceChip(BuildContext context, String label, bool on, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: AppType.body(11,
                weight: on ? FontWeight.w600 : FontWeight.w400,
                color: on ? const Color(0xFF0A0C14) : Colors.white.withOpacity(0.6))),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Bottom nav — a floating bar with a pill that springs between destinations.
/// ---------------------------------------------------------------------------
class _BottomNav extends StatelessWidget {
  final List<NavItem> tabs;
  final String current;
  final ValueChanged<String> onTap;

  const _BottomNav(
      {required this.tabs, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final index = tabs.indexWhere((t) => t.key == current).clamp(0, tabs.length - 1);

    return LayoutBuilder(
      builder: (context, box) {
        final slot = (box.maxWidth - 10) / tabs.length;
        return Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(20),
            boxShadow: Shadows.two(context.brightness),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.slow,
                curve: Motion.spring,
                left: slot * index,
                top: 0,
                bottom: 0,
                width: slot,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                          color: c.accentGlow,
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final t in tabs)
                    SizedBox(
                      width: slot,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          tick();
                          onTap(t.key);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                duration: Motion.base,
                                curve: Motion.spring,
                                scale: t.key == current ? 1.1 : 1,
                                child: Text(t.glyph,
                                    style: AppType.body(16,
                                        color: t.key == current
                                            ? Colors.white
                                            : c.text3,
                                        height: 1)),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.body(9.5,
                                    weight: t.key == current
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color:
                                        t.key == current ? Colors.white : c.text3),
                              ),
                            ],
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

class _Fab extends StatefulWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  State<_Fab> createState() => _FabState();
}

class _FabState extends State<_Fab> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        tick();
        widget.onTap();
      },
      child: AnimatedScale(
        duration: Motion.fast,
        curve: Motion.spring,
        scale: _down ? 0.9 : 1,
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.accent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: c.accentGlow.withOpacity(0.42),
                  blurRadius: 26,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Text('＋',
              style: AppType.body(25, color: Colors.white, height: 1)),
        ),
      ),
    );
  }
}
