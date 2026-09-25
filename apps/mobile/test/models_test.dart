import 'package:classes_os/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses /me for a parent', () {
    final me = Me.fromJson({
      'uid': 'u1',
      'email': 'p@x.com',
      'role': 'parent',
      'studentIds': ['s1'],
      'institute': {'id': 'i1', 'name': 'Apex'},
      'member': {'name': 'Mr. Shah'},
    });
    expect(me.role, Role.parent);
    expect(me.role.isLearner, isTrue);
    expect(me.role.canTeach, isFalse);
    expect(me.hasInstitute, isTrue);
    expect(me.studentIds, ['s1']);
  });

  test('parses /me without institute', () {
    final me = Me.fromJson({'uid': 'u1', 'institute': null});
    expect(me.hasInstitute, isFalse);
    expect(me.role, isNull);
  });

  test('parses staff dashboard', () {
    final d = Dashboard.fromJson({
      'role': 'owner',
      'batchCount': 2,
      'todaysClasses': [
        {'batchId': 'b1', 'name': 'JEE', 'subject': 'Physics', 'start': '17:00', 'end': '18:30', 'attendanceMarked': true},
      ],
      'activeStudents': 2,
      'attendanceToday': {'present': 1, 'total': 2, 'rate': 50},
      'fees': {'dueCount': 1, 'dueAmount': 1500, 'overdueCount': 1},
    });
    expect(d.role.isStaff, isTrue);
    expect(d.todaysClasses.single.attendanceMarked, isTrue);
    expect(d.attendanceRate, 50);
    expect(d.feesDueAmount, 1500);
  });

  test('unknown attendance status falls back to present', () {
    expect(statusFrom('absent'), AttendanceStatus.absent);
    expect(statusFrom(null), AttendanceStatus.present);
  });
}
