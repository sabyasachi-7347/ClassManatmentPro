import '../data/models.dart';

class NavItem {
  final String key;
  final String label;
  final String glyph;
  final String? badge;

  const NavItem(this.key, this.label, this.glyph, {this.badge});
}

/// The header shown above a phone-first dashboard — who is signed in, in their
/// own terms rather than the system's.
class MobileHeader {
  final String eyebrow;
  final String title;
  final String subtitle;

  const MobileHeader(this.eyebrow, this.title, this.subtitle);
}

class RoleConfig {
  final Role role;
  final String scope;
  final List<NavItem> tabs;
  final MobileHeader? header;

  const RoleConfig({
    required this.role,
    required this.scope,
    required this.tabs,
    this.header,
  });

  String get firstTab => tabs.isEmpty ? '' : tabs.first.key;
}

const Map<Role, RoleConfig> kRoles = {
  Role.guest: RoleConfig(role: Role.guest, scope: 'Public', tabs: []),
  Role.superAdmin: RoleConfig(
    role: Role.superAdmin,
    scope: 'Platform',
    tabs: [
      NavItem('overview', 'Overview', '◈'),
      NavItem('admins', 'System admins', '◉'),
    ],
  ),
  Role.systemAdmin: RoleConfig(
    role: Role.systemAdmin,
    scope: '2 institutes',
    tabs: [
      NavItem('institutes', 'My institutes', '◈'),
      NavItem('leads', 'Callbacks', '☎', badge: '2'),
      NavItem('admins', 'Classes admins', '◉'),
    ],
  ),
  Role.classesAdmin: RoleConfig(
    role: Role.classesAdmin,
    scope: 'Sunrise Academy',
    tabs: [
      NavItem('overview', 'Overview', '◈'),
      NavItem('batches', 'Batches', '▦'),
      NavItem('mapping', 'Mapping', '⊞'),
      NavItem('people', 'People', '◉'),
      NavItem('tests', 'Tests & marks', '▲'),
    ],
  ),
  Role.faculty: RoleConfig(
    role: Role.faculty,
    scope: 'Sunrise Academy',
    tabs: [
      NavItem('desk', 'My desk', '◈'),
      NavItem('attendance', 'Attendance', '✓', badge: '2'),
      NavItem('timetable', 'Timetable', '▦'),
    ],
  ),
  Role.teacher: RoleConfig(
    role: Role.teacher,
    scope: 'Sunrise Academy',
    header: MobileHeader('Teacher', 'Vikram Raghavan', 'Physics · 3 batches'),
    tabs: [
      NavItem('today', 'Today', '◈'),
      NavItem('week', 'Week', '▦'),
      NavItem('me', 'Me', '◉'),
    ],
  ),
  Role.student: RoleConfig(
    role: Role.student,
    scope: 'Sunrise Academy',
    header: MobileHeader(
        'Std XII · JEE Adv A', 'Aarav Kulkarni', 'SA-2411 · Sunrise Academy'),
    tabs: [
      NavItem('home', 'Home', '◈'),
      NavItem('results', 'Results', '▲'),
      NavItem('syllabus', 'Syllabus', '▦'),
      NavItem('attendance', 'Attendance', '✓'),
    ],
  ),
  Role.parent: RoleConfig(
    role: Role.parent,
    scope: 'Sunrise Academy',
    header: MobileHeader(
        'Parent', 'Sanjay Kulkarni', '2 children · Sunrise Academy'),
    tabs: [
      NavItem('home', 'Home', '◈'),
      NavItem('attendance', 'Attendance', '✓'),
      NavItem('timetable', 'Timetable', '▦'),
    ],
  ),
};

/// Order of the role switcher in the top bar.
const List<Role> kRoleOrder = [
  Role.guest,
  Role.superAdmin,
  Role.systemAdmin,
  Role.classesAdmin,
  Role.faculty,
  Role.teacher,
  Role.student,
  Role.parent,
];

class Command {
  final String label;
  final String group;
  final Role role;
  final String tab;

  const Command(this.label, this.group, this.role, this.tab);
}

const List<Command> kCommands = [
  Command('Take roll call', 'Teacher', Role.teacher, 'today'),
  Command('Map students to batches', 'Classes admin', Role.classesAdmin, 'mapping'),
  Command('Enter marks', 'Classes admin', Role.classesAdmin, 'tests'),
  Command('Absence alerts', 'Faculty', Role.faculty, 'attendance'),
  Command('Publish the timetable', 'Faculty', Role.faculty, 'timetable'),
  Command('Callback requests', 'System admin', Role.systemAdmin, 'leads'),
  Command('Add a teacher', 'Classes admin', Role.classesAdmin, 'people'),
  Command('Platform statistics', 'Super admin', Role.superAdmin, 'overview'),
  Command('Batches', 'Classes admin', Role.classesAdmin, 'batches'),
  Command("A child's progress", 'Parent', Role.parent, 'home'),
  Command('My results', 'Student', Role.student, 'results'),
];
