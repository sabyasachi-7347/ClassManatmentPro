import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'api_client.dart';
import 'live_models.dart';

String isoDay(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Everything a signed-in user's screens show, loaded from the API in one pass
/// and refreshed on pull-to-refresh or after an action.
///
/// Screens read it with `LiveScope.of(context)` and rebuild when it notifies.
/// What gets loaded depends on the role — a parent never asks for the
/// member list, a teacher never asks for fees.
class LiveStore extends ChangeNotifier {
  LiveStore(this.api, this.me);

  final ApiClient api;
  final Me me;

  bool loading = true;
  String? error;

  Dashboard? dashboard;
  List<LBatch> batches = [];
  List<LStudent> students = [];
  List<Absence> absences = [];
  List<TestSummary> tests = [];
  List<Member> teachers = [];

  /// Today's roll calls already saved, by batch id (teacher view).
  Map<String, BatchAttendance> todayAttendance = {};

  /// Per child (student/parent views).
  final Map<String, StudentAttendance> attendance = {};
  final Map<String, List<Result>> results = {};
  final Map<String, TestDetail> latestTest = {};

  String get today => isoDay(DateTime.now());

  LBatch? batch(String id) {
    for (final b in batches) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<LStudent> rosterOf(String batchId) =>
      students.where((s) => s.batchIds.contains(batchId)).toList()..sort((a, b) => a.name.compareTo(b.name));

  /// Children a parent (or the student themself) can see, in the order /me gave them.
  List<LStudent> get children {
    final byId = {for (final s in students) s.id: s};
    return [for (final id in me.studentIds) if (byId[id] != null) byId[id]!];
  }

  Future<void> load({bool quiet = false}) async {
    if (!quiet) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final role = me.role;
      final results0 = await Future.wait([
        api.get<Json>('/dashboard', query: {'date': today}),
        api.list('/batches'),
        api.list('/students'),
        role == ApiRole.student
            ? Future.value(<Json>[])
            : api.list('/absences', query: me.isStaff || role == ApiRole.teacher ? {'date': today} : null),
        api.list('/tests'),
        me.isStaff ? api.list('/members', query: {'role': 'teacher'}) : Future.value(<Json>[]),
      ]);
      dashboard = Dashboard.fromJson(results0[0] as Json);
      batches = (results0[1] as List<Json>).map(LBatch.fromJson).toList();
      students = (results0[2] as List<Json>).map(LStudent.fromJson).toList();
      absences = (results0[3] as List<Json>).map(Absence.fromJson).toList();
      tests = (results0[4] as List<Json>).map(TestSummary.fromJson).toList();
      teachers = (results0[5] as List<Json>).map(Member.fromJson).toList();

      if (role == ApiRole.teacher) await _loadTodayAttendance();
      if (role == ApiRole.student || role == ApiRole.parent) await _loadChildren();
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _loadTodayAttendance() async {
    final marked = dashboard?.today.where((c) => c.marked).map((c) => c.batchId).toSet() ?? {};
    final docs = await Future.wait(marked.map((id) =>
        api.list('/attendance/batches/$id', query: {'from': today, 'to': today})));
    todayAttendance = {
      for (final list in docs)
        for (final j in list) j['batchId'].toString(): BatchAttendance.fromJson(j),
    };
  }

  Future<void> _loadChildren() async {
    final from = isoDay(DateTime.now().subtract(const Duration(days: 180)));
    await Future.wait(children.map((c) async {
      final res = await Future.wait([
        api.get<Json>('/attendance/students/${c.id}', query: {'from': from}),
        api.list('/students/${c.id}/results'),
      ]);
      attendance[c.id] = StudentAttendance.fromJson(res[0] as Json);
      final r = (res[1] as List<Json>).map(Result.fromJson).toList();
      results[c.id] = r;
      if (r.isNotEmpty) {
        latestTest[c.id] = TestDetail.fromJson(await api.get<Json>('/tests/${r.first.testId}'));
      } else {
        latestTest.remove(c.id);
      }
    }));
  }

  // ---------------------------------------------------------------- actions --

  /// Saves a roll call. Everyone not in [absent] is present. Returns how many
  /// new absence alerts went out.
  Future<int> markAttendance(String batchId, Iterable<String> roster, Set<String> absent,
      {String? topic}) async {
    final res = await api.put<Json>('/attendance/batches/$batchId/$today', {
      'records': [
        for (final id in roster) {'studentId': id, 'status': absent.contains(id) ? 'absent' : 'present'},
      ],
      if (topic != null && topic.isNotEmpty) 'topic': topic,
    });
    await load(quiet: true);
    final alerts = res['alerts'];
    return alerts is Map ? (alerts['opened'] as num? ?? 0).toInt() : 0;
  }

  Future<void> acknowledge(String absenceId) async {
    final j = await api.post<Json>('/absences/$absenceId/ack');
    final updated = Absence.fromJson(j);
    absences = [for (final a in absences) a.id == absenceId ? updated : a];
    notifyListeners();
  }

  Future<int> nudge({List<String>? ids}) async {
    final j = await api.post<Json>('/absences/nudge', {
      if (ids != null) 'ids': ids,
      if (ids == null) 'date': today,
    });
    await load(quiet: true);
    return (j['nudged'] as num? ?? 0).toInt();
  }

  /// Teacher's "log what you covered": the current chapter becomes done and
  /// the next one becomes current. Returns the new coverage percent.
  Future<int?> logCoverage(String batchId) async {
    final b = batch(batchId);
    if (b == null || b.syllabus.isEmpty) return null;
    final ch = [...b.syllabus];
    var i = ch.indexWhere((c) => c.status == ChapterStatus.current);
    if (i < 0) i = ch.indexWhere((c) => c.status == ChapterStatus.todo);
    if (i < 0) return b.syllabusPercent;
    ch[i] = Chapter(ch[i].title, ChapterStatus.done);
    final next = ch.indexWhere((c) => c.status == ChapterStatus.todo);
    if (next >= 0) ch[next] = Chapter(ch[next].title, ChapterStatus.current);
    final j = await api.put<Json>('/batches/$batchId/syllabus', {'chapters': ch.map((c) => c.toJson()).toList()});
    final updated = LBatch.fromJson(j);
    batches = [for (final x in batches) x.id == batchId ? updated : x];
    notifyListeners();
    return updated.syllabusPercent;
  }

  Future<void> saveEnrollments(List<({String studentId, String batchId, bool enrolled})> changes) async {
    if (changes.isEmpty) return;
    await api.put<Json>('/enrollments', {
      'changes': [
        for (final c in changes) {'studentId': c.studentId, 'batchId': c.batchId, 'enrolled': c.enrolled},
      ],
    });
    await load(quiet: true);
  }

  Future<TestDetail> testDetail(String id) async => TestDetail.fromJson(await api.get<Json>('/tests/$id'));

  Future<void> createTest(String batchId, String title, int maxMarks) async {
    await api.post<Json>('/tests', {'batchId': batchId, 'title': title, 'maxMarks': maxMarks, 'date': today});
    await load(quiet: true);
  }

  Future<TestDetail> enterMarks(String testId, Map<String, num?> marks) async {
    final j = await api.put<Json>('/tests/$testId/marks', {
      'marks': [for (final e in marks.entries) {'studentId': e.key, 'score': e.value}],
    });
    await load(quiet: true);
    return TestDetail.fromJson(j);
  }
}

/// Makes the store available to every live screen and rebuilds them on change.
class LiveScope extends InheritedNotifier<LiveStore> {
  const LiveScope({super.key, required LiveStore store, required super.child}) : super(notifier: store);

  static LiveStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LiveScope>()?.notifier;

  static LiveStore of(BuildContext context) => maybeOf(context)!;
}
