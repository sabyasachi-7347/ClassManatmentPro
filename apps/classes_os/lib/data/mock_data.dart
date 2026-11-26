import 'models.dart';

/// Stand-in for the NestJS API. Every screen reads from here and nowhere else,
/// so replacing this file with a repository that calls the API is the only
/// change needed to go live.
class Mock {
  const Mock._();

  static const List<Institute> institutes = [
    Institute(
        id: 'i1',
        name: 'Sunrise Academy',
        city: 'Kalyan West',
        students: 412,
        batches: 14,
        admin: 'R. Deshmukh',
        status: 'Active'),
    Institute(
        id: 'i2',
        name: 'Pinnacle Classes',
        city: 'Dombivli East',
        students: 286,
        batches: 9,
        admin: 'S. Nair',
        status: 'Active'),
    Institute(
        id: 'i3',
        name: 'Vidya Bhavan',
        city: 'Thane',
        students: 531,
        batches: 18,
        admin: 'A. Kulkarni',
        status: 'Active'),
    Institute(
        id: 'i4',
        name: 'Concept Point',
        city: 'Ambernath',
        students: 97,
        batches: 4,
        admin: '— unassigned',
        status: 'Setup'),
  ];

  static const List<SystemAdminAccount> systemAdmins = [
    SystemAdminAccount(
        id: '1',
        name: 'Meera Iyer',
        email: 'meera@platform.in',
        institutes: ['Sunrise Academy', 'Concept Point'],
        active: true),
    SystemAdminAccount(
        id: '2',
        name: 'Rohit Bansal',
        email: 'rohit@platform.in',
        institutes: ['Pinnacle Classes'],
        active: true),
    SystemAdminAccount(
        id: '3',
        name: 'Farah Sheikh',
        email: 'farah@platform.in',
        institutes: ['Vidya Bhavan'],
        active: true),
    SystemAdminAccount(
        id: '4',
        name: 'Dev Rathore',
        email: 'dev@platform.in',
        institutes: [],
        active: false),
  ];

  static const List<Lead> leads = [
    Lead(
        id: '1',
        name: 'Anjali Prabhu',
        phone: '+91 98•••• 4412',
        institute: 'Sunrise Academy',
        source: 'Brochure',
        age: '14 min',
        state: LeadState.fresh),
    Lead(
        id: '2',
        name: 'Kabir Menon',
        phone: '+91 99•••• 8830',
        institute: 'Sunrise Academy',
        source: 'Signup',
        age: '2 hrs',
        state: LeadState.fresh),
    Lead(
        id: '3',
        name: 'Ritu Save',
        phone: '+91 70•••• 1276',
        institute: 'Concept Point',
        source: 'Brochure',
        age: '1 day',
        state: LeadState.called),
    Lead(
        id: '4',
        name: 'Imran Qureshi',
        phone: '+91 88•••• 5591',
        institute: 'Sunrise Academy',
        source: 'Demo',
        age: '2 days',
        state: LeadState.enrolled),
  ];

  static const List<Batch> batches = [
    Batch(
        id: 'b1',
        name: 'JEE Adv 2027 — A',
        stream: 'PCM',
        students: 38,
        teacher: 'V. Raghavan',
        slot: 'Mon/Wed/Fri · 07:00',
        syllabus: 62),
    Batch(
        id: 'b2',
        name: 'JEE Adv 2027 — B',
        stream: 'PCM',
        students: 34,
        teacher: 'V. Raghavan',
        slot: 'Tue/Thu/Sat · 07:00',
        syllabus: 58),
    Batch(
        id: 'b3',
        name: 'NEET 2027 — A',
        stream: 'PCB',
        students: 41,
        teacher: 'S. Pillai',
        slot: 'Mon–Fri · 16:30',
        syllabus: 71),
    Batch(
        id: 'b4',
        name: 'Std X — SSC Maths',
        stream: 'Maths',
        students: 29,
        teacher: 'P. Joshi',
        slot: 'Mon/Thu · 18:00',
        syllabus: 84),
    Batch(
        id: 'b5',
        name: 'Std XII — Physics',
        stream: 'Physics',
        students: 26,
        teacher: 'V. Raghavan',
        slot: 'Wed/Sat · 18:00',
        syllabus: 47),
    Batch(
        id: 'b6',
        name: 'Foundation VIII–X',
        stream: 'Science',
        students: 33,
        teacher: 'N. Fernandes',
        slot: 'Sat/Sun · 09:00',
        syllabus: 39),
  ];

  static const List<Teacher> teachers = [
    Teacher(
        id: 't1',
        name: 'Vikram Raghavan',
        subject: 'Physics',
        load: '18 hrs/wk',
        availability: 'Available',
        acceptedSchedule: true),
    Teacher(
        id: 't2',
        name: 'Sunita Pillai',
        subject: 'Biology',
        load: '14 hrs/wk',
        availability: 'Available',
        acceptedSchedule: true),
    Teacher(
        id: 't3',
        name: 'Prakash Joshi',
        subject: 'Mathematics',
        load: '11 hrs/wk',
        availability: 'Away 12–14',
        acceptedSchedule: false),
    Teacher(
        id: 't4',
        name: 'Neha Fernandes',
        subject: 'Chemistry',
        load: '9 hrs/wk',
        availability: 'Available',
        acceptedSchedule: false),
  ];

  static const List<Student> students = [
    Student(
        id: 's1',
        name: 'Aarav Kulkarni',
        roll: 'SA-2411',
        standard: 'XII',
        batchIds: ['b1', 'b5'],
        attendance: 94,
        average: 78),
    Student(
        id: 's2',
        name: 'Diya Shetty',
        roll: 'SA-2412',
        standard: 'XII',
        batchIds: ['b1'],
        attendance: 88,
        average: 84),
    Student(
        id: 's3',
        name: 'Rehan Kadri',
        roll: 'SA-2413',
        standard: 'XII',
        batchIds: ['b2', 'b5'],
        attendance: 71,
        average: 62),
    Student(
        id: 's4',
        name: 'Ishita Rane',
        roll: 'SA-2414',
        standard: 'XI',
        batchIds: ['b3'],
        attendance: 97,
        average: 91),
    Student(
        id: 's5',
        name: 'Om Bhagat',
        roll: 'SA-2415',
        standard: 'X',
        batchIds: ['b4', 'b6'],
        attendance: 83,
        average: 70),
    Student(
        id: 's6',
        name: 'Sara Fernandes',
        roll: 'SA-2416',
        standard: 'X',
        batchIds: ['b4'],
        attendance: 91,
        average: 76),
    Student(
        id: 's7',
        name: 'Yash Pawar',
        roll: 'SA-2417',
        standard: 'XI',
        batchIds: ['b3', 'b6'],
        attendance: 65,
        average: 55),
  ];

  static const List<Lecture> today = [
    Lecture(
        id: 'L1',
        start: '07:00',
        end: '08:30',
        batch: 'JEE Adv 2027 — A',
        topic: 'Rotational Dynamics — Torque',
        room: 'Hall 2',
        state: LectureState.done,
        present: 36,
        roster: 38),
    Lecture(
        id: 'L2',
        start: '09:15',
        end: '10:45',
        batch: 'Std XII — Physics',
        topic: 'Electrostatics — Gauss Law',
        room: 'Room 4',
        state: LectureState.done,
        present: 24,
        roster: 26),
    Lecture(
        id: 'L3',
        start: '11:30',
        end: '13:00',
        batch: 'JEE Adv 2027 — B',
        topic: 'Moment of Inertia',
        room: 'Hall 2',
        state: LectureState.live,
        present: 0,
        roster: 34),
    Lecture(
        id: 'L4',
        start: '16:30',
        end: '18:00',
        batch: 'NEET 2027 — A',
        topic: 'Neural Control',
        room: 'Hall 1',
        state: LectureState.upcoming,
        present: 0,
        roster: 41),
    Lecture(
        id: 'L5',
        start: '18:15',
        end: '19:30',
        batch: 'Foundation VIII–X',
        topic: 'Light — Refraction',
        room: 'Room 1',
        state: LectureState.upcoming,
        present: 0,
        roster: 33),
  ];

  static const List<TestResult> results = [
    TestResult(
        id: '1',
        test: 'Weekly Test 14 — Physics',
        date: '05 Aug',
        score: 68,
        max: 80,
        rank: 4,
        outOf: 38),
    TestResult(
        id: '2',
        test: 'Weekly Test 13 — Chemistry',
        date: '29 Jul',
        score: 61,
        max: 80,
        rank: 9,
        outOf: 38),
    TestResult(
        id: '3',
        test: 'Monthly Mock 03 — PCM',
        date: '22 Jul',
        score: 214,
        max: 300,
        rank: 6,
        outOf: 72),
    TestResult(
        id: '4',
        test: 'Weekly Test 12 — Maths',
        date: '15 Jul',
        score: 72,
        max: 80,
        rank: 2,
        outOf: 38),
  ];

  static const List<LeaderboardRow> leaderboard = [
    LeaderboardRow(rank: 1, name: 'Ishita R.', score: 276),
    LeaderboardRow(rank: 2, name: 'Diya S.', score: 268),
    LeaderboardRow(rank: 3, name: 'Kunal M.', score: 259),
    LeaderboardRow(rank: 4, name: 'Aarav K.', score: 251, isMe: true),
    LeaderboardRow(rank: 5, name: 'Tanvi B.', score: 244),
    LeaderboardRow(rank: 6, name: 'Rehan K.', score: 231),
  ];

  static const List<AbsenceAlert> absences = [
    AbsenceAlert(
        id: '1',
        student: 'Rehan Kadri',
        batch: 'JEE Adv B',
        lecture: 'Rotational Dynamics',
        markedAt: '11:34',
        parent: 'S. Kadri',
        state: AckState.acknowledged,
        ackAt: '11:41'),
    AbsenceAlert(
        id: '2',
        student: 'Yash Pawar',
        batch: 'NEET A',
        lecture: 'Neural Control',
        markedAt: '11:34',
        parent: 'M. Pawar',
        state: AckState.waiting),
    AbsenceAlert(
        id: '3',
        student: 'Om Bhagat',
        batch: 'Std X Maths',
        lecture: 'Quadratics',
        markedAt: 'Yest 18:05',
        parent: 'K. Bhagat',
        state: AckState.silent),
    AbsenceAlert(
        id: '4',
        student: 'Sara Fernandes',
        batch: 'Std X Maths',
        lecture: 'Quadratics',
        markedAt: 'Yest 18:05',
        parent: 'J. Fernandes',
        state: AckState.acknowledged,
        ackAt: '18:12'),
  ];

  static const List<FacultyModule> facultyModules = [
    FacultyModule(key: 'timetable', name: 'Timetable', glyph: '▦', enabled: true),
    FacultyModule(key: 'parents', name: 'Parents', glyph: '◐', enabled: true),
    FacultyModule(key: 'enrollment', name: 'Enrollment', glyph: '＋', enabled: true),
    FacultyModule(key: 'performance', name: 'Performance', glyph: '▲', enabled: true),
    FacultyModule(key: 'attendance', name: 'Attendance', glyph: '✓', enabled: true),
  ];

  static const List<ActionItem> needsYou = [
    ActionItem(
        title: "2 teachers haven't accepted next week",
        detail: 'P. Joshi, N. Fernandes',
        action: 'Remind',
        urgent: false),
    ActionItem(
        title: 'Physics is 18 points behind target',
        detail: '47% covered, 12 weeks left',
        action: 'Open',
        urgent: true),
    ActionItem(
        title: "1 parent hasn't acknowledged",
        detail: 'Om Bhagat · 18 hrs',
        action: 'Call',
        urgent: true),
    ActionItem(
        title: '38 papers awaiting marks',
        detail: 'Weekly Test 15',
        action: 'Enter',
        urgent: false),
  ];

  static const List<String> months = [
    'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb',
    'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug',
  ];

  static const List<double> myScores = [58, 64, 61, 70, 66, 74, 78, 76, 82, 79, 85, 84];
  static const List<double> batchAverage = [62, 63, 63, 65, 64, 67, 68, 69, 70, 70, 72, 71];
  static const List<double> enrolment = [42, 51, 38, 60, 55, 71, 64];
  static const List<String> enrolmentMonths = ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];
  static const List<double> marksByTest = [85, 76, 71, 90, 68, 82];
  static const List<String> testLabels = ['T10', 'T11', 'T12', 'T13', 'T14', 'T15'];
  static const List<double> attendanceByMonth = [96, 92, 88, 94, 91, 94];
  static const List<String> attendanceMonths = ['Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];

  static const List<String> weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const List<String> slots = ['07:00', '09:15', '11:30', '16:30', '18:15'];
}

/// "Aarav Kulkarni" -> "AK". Used by every avatar in the app.
String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((p) => p[0].toUpperCase()).join();
}
