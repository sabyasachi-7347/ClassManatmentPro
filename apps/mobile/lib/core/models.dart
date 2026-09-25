// Plain data classes for API responses. Keep in sync with apps/api DTOs.

typedef Json = Map<String, dynamic>;

List<String> _strings(dynamic v) => (v as List?)?.cast<String>() ?? const [];

enum Role { owner, admin, teacher, student, parent }

Role? roleFrom(String? s) => Role.values.where((r) => r.name == s).firstOrNull;

extension RoleX on Role? {
  bool get isStaff => this == Role.owner || this == Role.admin;
  bool get canTeach => isStaff || this == Role.teacher;
  bool get isLearner => this == Role.student || this == Role.parent;
}

class Me {
  Me({required this.uid, this.email, this.role, this.instituteName, this.name, this.studentIds = const []});
  factory Me.fromJson(Json j) => Me(
        uid: j['uid'] as String,
        email: j['email'] as String?,
        role: roleFrom(j['role'] as String?),
        instituteName: (j['institute'] as Json?)?['name'] as String?,
        name: (j['member'] as Json?)?['name'] as String?,
        studentIds: _strings(j['studentIds']),
      );
  final String uid;
  final String? email, instituteName, name;
  final Role? role;
  final List<String> studentIds;
  bool get hasInstitute => instituteName != null;
}

class Slot {
  Slot(this.day, this.start, this.end);
  factory Slot.fromJson(Json j) => Slot(j['day'] as int, j['start'] as String, j['end'] as String);
  final int day;
  final String start, end;
}

class Batch {
  Batch({required this.id, required this.name, required this.subject, this.room, this.schedule = const []});
  factory Batch.fromJson(Json j) => Batch(
        id: j['id'] as String,
        name: j['name'] as String,
        subject: j['subject'] as String? ?? '',
        room: j['room'] as String?,
        schedule: ((j['schedule'] as List?) ?? []).map((s) => Slot.fromJson(s as Json)).toList(),
      );
  final String id, name, subject;
  final String? room;
  final List<Slot> schedule;
}

class Student {
  Student({required this.id, required this.name, this.phone, this.batchIds = const []});
  factory Student.fromJson(Json j) => Student(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        batchIds: _strings(j['batchIds']),
      );
  final String id, name;
  final String? phone;
  final List<String> batchIds;
}

enum AttendanceStatus { present, absent, late, excused }

AttendanceStatus statusFrom(String? s) =>
    AttendanceStatus.values.where((v) => v.name == s).firstOrNull ?? AttendanceStatus.present;

class Fee {
  Fee({
    required this.id,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.studentName,
    this.period,
    this.overdue = false,
  });
  factory Fee.fromJson(Json j) => Fee(
        id: j['id'] as String,
        amount: (j['amount'] as num).toInt(),
        dueDate: j['dueDate'] as String,
        status: j['status'] as String,
        studentName: j['studentName'] as String?,
        period: j['period'] as String?,
        overdue: j['overdue'] as bool? ?? false,
      );
  final String id, dueDate, status;
  final String? studentName, period;
  final int amount;
  final bool overdue;
}

class Announcement {
  Announcement({required this.id, required this.title, required this.body, this.authorName, this.createdAt});
  factory Announcement.fromJson(Json j) => Announcement(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        authorName: j['authorName'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
  final String id, title, body;
  final String? authorName;
  final DateTime? createdAt;
}

class TodayClass {
  TodayClass.fromJson(Json j)
      : batchId = j['batchId'] as String,
        name = j['name'] as String? ?? '',
        subject = j['subject'] as String? ?? '',
        start = j['start'] as String,
        end = j['end'] as String,
        room = j['room'] as String?,
        attendanceMarked = j['attendanceMarked'] as bool? ?? false;
  final String batchId, name, subject, start, end;
  final String? room;
  final bool attendanceMarked;
}

class Dashboard {
  Dashboard.fromJson(Json j)
      : role = roleFrom(j['role'] as String?),
        batchCount = j['batchCount'] as int? ?? 0,
        todaysClasses = ((j['todaysClasses'] as List?) ?? [])
            .map((c) => TodayClass.fromJson(c as Json))
            .toList(),
        activeStudents = j['activeStudents'] as int?,
        attendanceRate = (j['attendanceToday'] as Json?)?['rate'] as num?,
        attendancePresent = (j['attendanceToday'] as Json?)?['present'] as int?,
        attendanceTotal = (j['attendanceToday'] as Json?)?['total'] as int?,
        feesDueAmount = (j['fees'] as Json?)?['dueAmount'] as int?,
        feesOverdue = (j['fees'] as Json?)?['overdueCount'] as int?,
        pendingAttendance = j['pendingAttendance'] as int?,
        students = ((j['students'] as List?) ?? []).cast<Json>(),
        dues = ((j['dues'] as List?) ?? []).map((f) => Fee.fromJson(f as Json)).toList();

  final Role? role;
  final int batchCount;
  final List<TodayClass> todaysClasses;
  final int? activeStudents, attendancePresent, attendanceTotal, feesDueAmount, feesOverdue, pendingAttendance;
  final num? attendanceRate;
  final List<Json> students;
  final List<Fee> dues;
}
