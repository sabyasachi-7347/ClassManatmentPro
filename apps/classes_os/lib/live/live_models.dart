/// Shapes returned by the NestJS API. Parsing is forgiving: a missing field
/// becomes a sensible default rather than a crash, because a half-filled
/// institute (no syllabus yet, no tests yet) is the normal state on day one.
library;

import 'api_client.dart';

String _s(Object? v, [String d = '']) => v == null ? d : v.toString();
int _i(Object? v, [int d = 0]) => v is num ? v.toInt() : int.tryParse('$v') ?? d;
double? _dn(Object? v) => v is num ? v.toDouble() : double.tryParse('$v');
List<String> _ls(Object? v) => v is List ? v.map((e) => e.toString()).toList() : const [];
List<Json> _lj(Object? v) => v is List ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() : const [];

/// The API's roles. Owner and admin both land on the classes-admin desk.
enum ApiRole { owner, admin, teacher, student, parent, none }

ApiRole _role(Object? v) => switch (v) {
      'owner' => ApiRole.owner,
      'admin' => ApiRole.admin,
      'teacher' => ApiRole.teacher,
      'student' => ApiRole.student,
      'parent' => ApiRole.parent,
      _ => ApiRole.none,
    };

class Me {
  final String uid;
  final String email;
  final ApiRole role;
  final List<String> studentIds;
  final String? instituteName;
  final String? instituteCity;
  final String name;

  const Me({
    required this.uid,
    required this.email,
    required this.role,
    required this.studentIds,
    required this.instituteName,
    required this.instituteCity,
    required this.name,
  });

  bool get hasInstitute => instituteName != null && role != ApiRole.none;
  bool get isStaff => role == ApiRole.owner || role == ApiRole.admin;

  factory Me.fromJson(Json j) {
    final inst = j['institute'] is Map ? (j['institute'] as Map).cast<String, dynamic>() : null;
    final member = j['member'] is Map ? (j['member'] as Map).cast<String, dynamic>() : null;
    final email = _s(j['email']);
    return Me(
      uid: _s(j['uid']),
      email: email,
      role: _role(j['role']),
      studentIds: _ls(j['studentIds']),
      instituteName: inst?['name']?.toString(),
      instituteCity: inst?['city']?.toString(),
      name: _s(member?['name'], email.split('@').first),
    );
  }
}

class Slot {
  final int day; // 0 = Sunday
  final String start;
  final String end;
  const Slot(this.day, this.start, this.end);

  factory Slot.fromJson(Json j) => Slot(_i(j['day']), _s(j['start']), _s(j['end']));

  /// Duration in minutes, for "teaching hours".
  int get minutes {
    int m(String t) {
      final p = t.split(':');
      return p.length == 2 ? _i(p[0]) * 60 + _i(p[1]) : 0;
    }

    return (m(end) - m(start)).clamp(0, 24 * 60);
  }
}

enum ChapterStatus { todo, current, done }

class Chapter {
  final String title;
  final ChapterStatus status;
  const Chapter(this.title, this.status);

  factory Chapter.fromJson(Json j) => Chapter(
        _s(j['title']),
        switch (j['status']) {
          'done' => ChapterStatus.done,
          'current' => ChapterStatus.current,
          _ => ChapterStatus.todo,
        },
      );

  Json toJson() => {'title': title, 'status': status.name};
}

class LBatch {
  final String id;
  final String name;
  final String subject;
  final String room;
  final List<Slot> schedule;
  final List<String> teacherIds;
  final List<Chapter> syllabus;

  const LBatch({
    required this.id,
    required this.name,
    required this.subject,
    required this.room,
    required this.schedule,
    required this.teacherIds,
    required this.syllabus,
  });

  factory LBatch.fromJson(Json j) => LBatch(
        id: _s(j['id']),
        name: _s(j['name'], 'Batch'),
        subject: _s(j['subject']),
        room: _s(j['room']),
        schedule: _lj(j['schedule']).map(Slot.fromJson).toList(),
        teacherIds: _ls(j['teacherIds']),
        syllabus: _lj(j['syllabus']).map(Chapter.fromJson).toList(),
      );

  /// Share of chapters finished; null when no syllabus has been set up.
  int? get syllabusPercent {
    if (syllabus.isEmpty) return null;
    final done = syllabus.where((c) => c.status == ChapterStatus.done).length;
    return (done * 100 / syllabus.length).round();
  }
}

class LStudent {
  final String id;
  final String name;
  final String grade;
  final String phone;
  final String guardianName;
  final List<String> batchIds;

  const LStudent({
    required this.id,
    required this.name,
    required this.grade,
    required this.phone,
    required this.guardianName,
    required this.batchIds,
  });

  factory LStudent.fromJson(Json j) => LStudent(
        id: _s(j['id']),
        name: _s(j['name'], 'Student'),
        grade: _s(j['grade']),
        phone: _s(j['phone']),
        guardianName: _s(j['guardianName']),
        batchIds: _ls(j['batchIds']),
      );

  String get firstName => name.split(' ').first;
}

class TodayClass {
  final String batchId;
  final String name;
  final String subject;
  final String room;
  final String start;
  final String end;
  final bool marked;

  const TodayClass({
    required this.batchId,
    required this.name,
    required this.subject,
    required this.room,
    required this.start,
    required this.end,
    required this.marked,
  });

  factory TodayClass.fromJson(Json j) => TodayClass(
        batchId: _s(j['batchId']),
        name: _s(j['name'], 'Class'),
        subject: _s(j['subject']),
        room: _s(j['room']),
        start: _s(j['start']),
        end: _s(j['end']),
        marked: j['attendanceMarked'] == true,
      );
}

class Dashboard {
  final String date;
  final List<TodayClass> today;
  final int batchCount;
  final int? activeStudents;
  final int? presentToday;
  final int? totalToday;
  final int? rateToday;
  final int? feesDueCount;
  final int? feesDueAmount;
  final int? feesOverdueCount;
  final int? pendingAttendance;

  const Dashboard({
    required this.date,
    required this.today,
    required this.batchCount,
    this.activeStudents,
    this.presentToday,
    this.totalToday,
    this.rateToday,
    this.feesDueCount,
    this.feesDueAmount,
    this.feesOverdueCount,
    this.pendingAttendance,
  });

  factory Dashboard.fromJson(Json j) {
    final att = j['attendanceToday'] is Map ? (j['attendanceToday'] as Map) : const {};
    final fees = j['fees'] is Map ? (j['fees'] as Map) : const {};
    return Dashboard(
      date: _s(j['date']),
      today: _lj(j['todaysClasses']).map(TodayClass.fromJson).toList(),
      batchCount: _i(j['batchCount']),
      activeStudents: j['activeStudents'] == null ? null : _i(j['activeStudents']),
      presentToday: att['present'] == null ? null : _i(att['present']),
      totalToday: att['total'] == null ? null : _i(att['total']),
      rateToday: att['rate'] == null ? null : _i(att['rate']),
      feesDueCount: fees['dueCount'] == null ? null : _i(fees['dueCount']),
      feesDueAmount: fees['dueAmount'] == null ? null : _i(fees['dueAmount']),
      feesOverdueCount: fees['overdueCount'] == null ? null : _i(fees['overdueCount']),
      pendingAttendance: j['pendingAttendance'] == null ? null : _i(j['pendingAttendance']),
    );
  }
}

enum AbsenceState { waiting, acknowledged, silent }

class Absence {
  final String id;
  final String batchId;
  final String batchName;
  final String date;
  final String topic;
  final String studentId;
  final String studentName;
  final String guardianName;
  final String guardianPhone;
  final AbsenceState state;
  final DateTime? markedAt;
  final DateTime? ackAt;
  final int hoursWaiting;

  const Absence({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.date,
    required this.topic,
    required this.studentId,
    required this.studentName,
    required this.guardianName,
    required this.guardianPhone,
    required this.state,
    required this.markedAt,
    required this.ackAt,
    required this.hoursWaiting,
  });

  factory Absence.fromJson(Json j) => Absence(
        id: _s(j['id']),
        batchId: _s(j['batchId']),
        batchName: _s(j['batchName']),
        date: _s(j['date']),
        topic: _s(j['topic']),
        studentId: _s(j['studentId']),
        studentName: _s(j['studentName'], 'Student'),
        guardianName: _s(j['guardianName']),
        guardianPhone: _s(j['guardianPhone']),
        state: switch (j['state']) {
          'acknowledged' => AbsenceState.acknowledged,
          'silent' => AbsenceState.silent,
          _ => AbsenceState.waiting,
        },
        markedAt: DateTime.tryParse(_s(j['markedAt']))?.toLocal(),
        ackAt: DateTime.tryParse(_s(j['ackAt']))?.toLocal(),
        hoursWaiting: _i(j['hoursWaiting']),
      );

  bool get open => state != AbsenceState.acknowledged;
}

class Result {
  final String testId;
  final String title;
  final String date;
  final String batchName;
  final num score;
  final int maxMarks;
  final double percent;
  final int rank;
  final int outOf;
  final String note;

  const Result({
    required this.testId,
    required this.title,
    required this.date,
    required this.batchName,
    required this.score,
    required this.maxMarks,
    required this.percent,
    required this.rank,
    required this.outOf,
    required this.note,
  });

  factory Result.fromJson(Json j) => Result(
        testId: _s(j['testId']),
        title: _s(j['title'], 'Test'),
        date: _s(j['date']),
        batchName: _s(j['batchName']),
        score: (j['score'] as num?) ?? 0,
        maxMarks: _i(j['maxMarks'], 1),
        percent: _dn(j['percent']) ?? 0,
        rank: _i(j['rank']),
        outOf: _i(j['outOf']),
        note: _s(j['note']),
      );
}

class TestSummary {
  final String id;
  final String batchId;
  final String batchName;
  final String title;
  final String date;
  final int maxMarks;
  final int entered;
  final double? average;
  final double? averagePercent;

  const TestSummary({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.title,
    required this.date,
    required this.maxMarks,
    required this.entered,
    required this.average,
    required this.averagePercent,
  });

  factory TestSummary.fromJson(Json j) => TestSummary(
        id: _s(j['id']),
        batchId: _s(j['batchId']),
        batchName: _s(j['batchName']),
        title: _s(j['title'], 'Test'),
        date: _s(j['date']),
        maxMarks: _i(j['maxMarks'], 1),
        entered: _i(j['entered']),
        average: _dn(j['average']),
        averagePercent: _dn(j['averagePercent']),
      );
}

class TestRow {
  final String? studentId;
  final String name;
  final num score;
  final int rank;
  final bool isMine;
  final String note;

  const TestRow({
    required this.studentId,
    required this.name,
    required this.score,
    required this.rank,
    required this.isMine,
    required this.note,
  });

  factory TestRow.fromJson(Json j) => TestRow(
        studentId: j['studentId']?.toString(),
        name: _s(j['name'], 'Student'),
        score: (j['score'] as num?) ?? 0,
        rank: _i(j['rank']),
        isMine: j['isMine'] == true,
        note: _s(j['note']),
      );
}

class TestDetail {
  final TestSummary summary;
  final List<TestRow> rows;
  const TestDetail(this.summary, this.rows);

  factory TestDetail.fromJson(Json j) =>
      TestDetail(TestSummary.fromJson(j), _lj(j['rows']).map(TestRow.fromJson).toList());
}

class Session {
  final String batchId;
  final String date;
  final String status; // present | absent | late | excused
  const Session(this.batchId, this.date, this.status);
}

class StudentAttendance {
  final double? rate;
  final List<Session> sessions;
  const StudentAttendance(this.rate, this.sessions);

  factory StudentAttendance.fromJson(Json j) => StudentAttendance(
        _dn(j['rate']),
        _lj(j['sessions'])
            .map((s) => Session(_s(s['batchId']), _s(s['date']), _s(s['status'])))
            .toList(),
      );

  List<Session> get missed => sessions.where((s) => s.status == 'absent').toList();
}

class Member {
  final String id;
  final String name;
  final String role;
  final String email;
  final String phone;
  const Member(this.id, this.name, this.role, this.email, this.phone);

  factory Member.fromJson(Json j) =>
      Member(_s(j['id']), _s(j['name'], 'Member'), _s(j['role']), _s(j['email']), _s(j['phone']));
}

class BatchAttendance {
  final String batchId;
  final int present;
  final int total;
  final String topic;
  final Map<String, String> records;
  const BatchAttendance(this.batchId, this.present, this.total, this.topic, this.records);

  factory BatchAttendance.fromJson(Json j) {
    final sum = j['summary'] is Map ? (j['summary'] as Map) : const {};
    final rec = j['records'] is Map ? (j['records'] as Map) : const {};
    return BatchAttendance(
      _s(j['batchId']),
      _i(sum['present']) + _i(sum['late']),
      _i(sum['total']),
      _s(j['topic']),
      rec.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }
}
