import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../announcements/announcements_screen.dart';
import '../attendance/attendance_screen.dart';
import '../batches/batches_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../fees/fees_screen.dart';
import '../more/more_screen.dart';

class _Tab {
  const _Tab(this.label, this.icon, this.screen);
  final String label;
  final IconData icon;
  final Widget screen;
}

List<_Tab> _tabsFor(Role? role) => [
      const _Tab('Home', Icons.dashboard_rounded, DashboardScreen()),
      if (role.canTeach) const _Tab('Attendance', Icons.fact_check_rounded, AttendanceScreen()),
      if (role == Role.teacher || role.isLearner) const _Tab('Classes', Icons.grid_view_rounded, BatchesScreen()),
      if (role.isStaff || role.isLearner) const _Tab('Fees', Icons.payments_rounded, FeesScreen()),
      const _Tab('Notices', Icons.campaign_rounded, AnnouncementsScreen()),
      const _Tab('More', Icons.more_horiz_rounded, MoreScreen()),
    ];

/// Lets child screens switch tabs (e.g. "Take attendance" on the dashboard).
final homeTabProvider = NotifierProvider<HomeTab, int>(HomeTab.new);

class HomeTab extends Notifier<int> {
  @override
  int build() => 0;
  void go(int i) => state = i;
  void goTo(String label, Role? role) {
    final i = _tabsFor(role).indexWhere((t) => t.label == label);
    if (i >= 0) state = i;
  }
}

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(meProvider).value?.role;
    final tabs = _tabsFor(role);
    final index = ref.watch(homeTabProvider).clamp(0, tabs.length - 1);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: index, children: [for (final t in tabs) t.screen]),
      ),
      extendBody: true,
      bottomNavigationBar: _PillNav(
        tabs: tabs,
        index: index,
        onTap: (i) => ref.read(homeTabProvider.notifier).go(i),
      ),
    );
  }
}

/// Floating bottom nav with a spring-animated selection pill (".pn" in the web prototype).
class _PillNav extends StatelessWidget {
  const _PillNav({required this.tabs, required this.index, required this.onTap});
  final List<_Tab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.os;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        height: 62,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: c.surf,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.line),
          boxShadow: const [BoxShadow(color: Color(0x1A0A0C14), blurRadius: 32, offset: Offset(0, 12))],
        ),
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth / tabs.length;
          return Stack(children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 380),
              curve: const Cubic(.34, 1.56, .64, 1),
              left: w * index,
              top: 0,
              bottom: 0,
              width: w,
              child: Container(
                decoration: BoxDecoration(
                  color: OS.acc,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: OS.acc.withValues(alpha: .3), blurRadius: 14, offset: const Offset(0, 4))],
                ),
              ),
            ),
            Row(children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: InkResponse(
                    onTap: () => onTap(i),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      AnimatedScale(
                        scale: i == index ? 1.1 : 1,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(tabs[i].icon, size: 20, color: i == index ? Colors.white : c.txt3),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: i == index ? Colors.white : c.txt3,
                          fontWeight: i == index ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ]),
                  ),
                ),
            ]),
          ]);
        }),
      ),
    );
  }
}
