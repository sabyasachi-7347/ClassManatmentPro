/// Plain immutable models. These mirror the Firestore documents the NestJS
/// API will return, so swapping mock_data.dart for a repository later is a
/// drop-in change — no widget needs to know where the data came from.
library;

enum Role { superAdmin, systemAdmin, classesAdmin, faculty, teacher, student, parent, guest }

extension RoleLabel on Role {
  String get label => switch (this) {
        Role.superAdmin => 'Super admin',
        Role.systemAdmin => 'System admin',
        Role.classesAdmin => 'Classes admin',
        Role.faculty => 'Faculty',
        Role.teacher => 'Teacher',
        Role.student => 'Student',
        Role.parent => 'Parent',
        Role.guest => 'Entry',
      };

  /// Admin-style roles get the desktop rail; the rest are phone-first.
  bool get isDesk => switch (this) {
        Role.superAdmin || Role.systemAdmin || Role.classesAdmin || Role.faculty => true,
        _ => false,
      };
}

class Institute {
  final String id;
  final String name;
  final String city;
  final int students;
  final int batches;
  final String admin;
  final String status;

  const Institute({
    required this.id,
    required this.name,
    required this.city,
    required this.students,
    required this.batches,
    required this.admin,
    required this.status,
  });

  bool get isActive => status == 'Active';
}

class SystemAdminAccount {
  final String id;
  final String name;
  final String email;
  final List<String> institutes;
  final bool active;

  const SystemAdminAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.institutes,
    required this.active,
  });

  SystemAdminAccount copyWith({bool? active}) => SystemAdminAccount(
        id: id,
        name: name,
        email: email,
        institutes: institutes,
        active: active ?? this.active,
      );
}

enum LeadState { fresh, called, enrolled }

class Lead {
  final String id;
  final String name;
  final String phone;
  final String institute;
  final String source;
  final String age;
  final LeadState state;

  const Lead({
    required this.id,
    required this.name,
    required this.phone,
    required this.institute,
    required this.source,
    required this.age,
    required this.state,
  });

  Lead copyWith({LeadState? state}) => Lead(
        id: id,
        name: name,
        phone: phone,
        institute: institute,
        source: source,
        age: age,
        state: state ?? this.state,
      );
}

class Batch {
  final String id;
  final String name;
  final String stream;
  final int students;
  final String teacher;
  final String slot;
  final int syllabus;

  const Batch({
    required this.id,
    required this.name,
    required this.stream,
    required this.students,
    required this.teacher,
    required this.slot,
    required this.syllabus,
  });

  bool get behindTarget => syllabus < 50;
}

class Teacher {
  final String id;
  final String name;
  final String subject;
  final String load;
  final String availability;
  final bool acceptedSchedule;

  const Teacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.load,
    required this.availability,
    required this.acceptedSchedule,
  });

  bool get isAvailable => availability == 'Available';
}

class Student {
  final String id;
  final String name;
  final String roll;
  final String standard;
  final List<String> batchIds;
  final int attendance;
  final int average;

  const Student({
    required this.id,
    required this.name,
    required this.roll,
    required this.standard,
    required this.batchIds,
    required this.attendance,
    required this.average,
  });
}

enum LectureState { done, live, upcoming }

class Lecture {
  final String id;
  final String start;
  final String end;
  final String batch;
  final String topic;
  final String room;
  final LectureState state;
  final int present;
  final int roster;

  const Lecture({
    required this.id,
    required this.start,
    required this.end,
    required this.batch,
    required this.topic,
    required this.room,
    required this.state,
    required this.present,
    required this.roster,
  });
}

class TestResult {
  final String id;
  final String test;
  final String date;
  final int score;
  final int max;
  final int rank;
  final int outOf;

  const TestResult({
    required this.id,
    required this.test,
    required this.date,
    required this.score,
    required this.max,
    required this.rank,
    required this.outOf,
  });
}

class LeaderboardRow {
  final int rank;
  final String name;
  final int score;
  final bool isMe;

  const LeaderboardRow({
    required this.rank,
    required this.name,
    required this.score,
    this.isMe = false,
  });
}

/// The acknowledgement state machine: a teacher marks the absence, the parent
/// is pushed a notification, the parent confirms. Faculty chase what is silent.
enum AckState { acknowledged, waiting, silent }

class AbsenceAlert {
  final String id;
  final String student;
  final String batch;
  final String lecture;
  final String markedAt;
  final String parent;
  final AckState state;
  final String? ackAt;

  const AbsenceAlert({
    required this.id,
    required this.student,
    required this.batch,
    required this.lecture,
    required this.markedAt,
    required this.parent,
    required this.state,
    this.ackAt,
  });

  AbsenceAlert copyWith({AckState? state, String? ackAt}) => AbsenceAlert(
        id: id,
        student: student,
        batch: batch,
        lecture: lecture,
        markedAt: markedAt,
        parent: parent,
        state: state ?? this.state,
        ackAt: ackAt ?? this.ackAt,
      );
}

/// Faculty capability. One person may hold all five or just one; the classes
/// admin grants them. The dashboard is assembled from whatever is on.
class FacultyModule {
  final String key;
  final String name;
  final String glyph;
  final bool enabled;

  const FacultyModule({
    required this.key,
    required this.name,
    required this.glyph,
    required this.enabled,
  });

  FacultyModule copyWith({bool? enabled}) =>
      FacultyModule(key: key, name: name, glyph: glyph, enabled: enabled ?? this.enabled);
}

/// One row of the "needs you" list on the classes admin overview.
class ActionItem {
  final String title;
  final String detail;
  final String action;
  final bool urgent;

  const ActionItem({
    required this.title,
    required this.detail,
    required this.action,
    required this.urgent,
  });
}
