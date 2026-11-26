import 'package:classes_os/data/models.dart';
import 'package:classes_os/live/live_models.dart';
import 'package:classes_os/live/live_screens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Me', () {
    test('reads role, institute and linked students', () {
      final me = Me.fromJson({
        'uid': 'u1',
        'email': 'parent@demo.test',
        'role': 'parent',
        'studentIds': ['s1', 's2'],
        'institute': {'name': 'Sunrise Academy', 'city': 'Kalyan'},
        'member': {'name': 'Sanjay Kulkarni'},
      });
      expect(me.role, ApiRole.parent);
      expect(me.hasInstitute, isTrue);
      expect(me.studentIds, ['s1', 's2']);
      expect(me.name, 'Sanjay Kulkarni');
    });

    test('an account with no institute is not let in', () {
      final me = Me.fromJson({'uid': 'u1', 'email': 'new@x.com', 'institute': null});
      expect(me.role, ApiRole.none);
      expect(me.hasInstitute, isFalse);
      expect(me.name, 'new');
    });
  });

  group('LBatch', () {
    test('syllabus percent counts finished chapters only', () {
      final b = LBatch.fromJson({
        'id': 'b1',
        'name': 'JEE A',
        'syllabus': [
          {'title': 'A', 'status': 'done'},
          {'title': 'B', 'status': 'current'},
          {'title': 'C', 'status': 'todo'},
          {'title': 'D', 'status': 'todo'},
        ],
      });
      expect(b.syllabusPercent, 25);
    });

    test('no syllabus means no percent rather than 0%', () {
      expect(LBatch.fromJson({'id': 'b1'}).syllabusPercent, isNull);
    });

    test('tolerates missing fields', () {
      final b = LBatch.fromJson({'id': 'b1'});
      expect(b.name, 'Batch');
      expect(b.schedule, isEmpty);
      expect(b.teacherIds, isEmpty);
    });
  });

  group('Absence', () {
    test('parses state and acknowledgement time', () {
      final a = Absence.fromJson({
        'id': 'x',
        'state': 'acknowledged',
        'ackAt': '2026-11-26T10:41:00.000Z',
        'studentName': 'Aarav',
      });
      expect(a.state, AbsenceState.acknowledged);
      expect(a.open, isFalse);
      expect(a.ackAt, isNotNull);
    });

    test('silent is still open', () {
      expect(Absence.fromJson({'id': 'x', 'state': 'silent'}).open, isTrue);
    });
  });

  test('slot duration in minutes', () {
    expect(const Slot(1, '07:00', '08:30').minutes, 90);
    expect(const Slot(1, '18:00', '17:00').minutes, 0);
  });

  test('lecture state follows the clock', () {
    final at = DateTime(2026, 11, 26, 11, 45);
    expect(lectureState('07:00', '08:30', at), LectureState.done);
    expect(lectureState('11:30', '13:00', at), LectureState.live);
    expect(lectureState('16:30', '18:00', at), LectureState.upcoming);
  });

  test('week ahead maps API weekdays (Sunday = 0) onto dates', () {
    final today = DateTime.now();
    final apiDay = today.weekday % 7;
    final b = LBatch.fromJson({
      'id': 'b1',
      'name': 'JEE A',
      'schedule': [
        {'day': apiDay, 'start': '18:00', 'end': '19:00'},
        {'day': apiDay, 'start': '07:00', 'end': '08:30'},
      ],
    });
    final week = weekAhead([b]);
    expect(week, hasLength(7));
    expect(week.first.$2.map((s) => s.$1.start), ['07:00', '18:00']); // sorted
    expect(week.skip(1).take(5).every((d) => d.$2.isEmpty), isTrue);
    expect(week.last.$2, isEmpty); // same weekday is 7 days out, not 6
  });

  test('hours label', () {
    expect(hoursLabel(405), '6h45');
    expect(hoursLabel(120), '2h');
    expect(hoursLabel(45), '45m');
  });
}
