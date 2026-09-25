import { Injectable } from '@nestjs/common';
import { AuthUser, Role } from '../auth/auth.types';
import { AttendanceService } from '../attendance/attendance.service';
import { BatchesService } from '../batches/batches.service';
import { isoDate } from '../common/dates';
import { paths } from '../common/firestore.util';
import { tenantOf } from '../common/tenant';
import { FeesService } from '../fees/fees.service';
import { FirebaseService } from '../firebase/firebase.service';

type Slot = { day: number; start: string; end: string };
type Batch = { id: string; name?: string; subject?: string; room?: string; schedule?: Slot[] };

@Injectable()
export class DashboardService {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly batches: BatchesService,
    private readonly attendance: AttendanceService,
    private readonly fees: FeesService,
  ) {}

  async get(user: AuthUser, date = isoDate()) {
    const iid = tenantOf(user);
    const db = this.firebase.db;
    const weekday = new Date(`${date}T00:00:00Z`).getUTCDay();

    const batches = (await this.batches.list(user)) as Batch[];
    const marked = await db.collection(paths.attendance(iid)).where('date', '==', date).get();
    const markedByBatch = new Map(marked.docs.map((d) => [d.get('batchId') as string, d]));

    const todaysClasses = batches
      .flatMap((b) =>
        (b.schedule ?? [])
          .filter((s) => s.day === weekday)
          .map((s) => ({
            batchId: b.id,
            name: b.name,
            subject: b.subject,
            room: b.room,
            start: s.start,
            end: s.end,
            attendanceMarked: markedByBatch.has(b.id),
          })),
      )
      .sort((a, b) => a.start.localeCompare(b.start));

    const base = { date, role: user.role, todaysClasses, batchCount: batches.length };

    if (user.role === Role.Owner || user.role === Role.Admin) {
      const [activeStudents, dueFees] = await Promise.all([
        db.collection(paths.students(iid)).where('status', '==', 'active').count().get(),
        this.fees.list(user, { status: 'due' }),
      ]);
      let present = 0;
      let total = 0;
      marked.docs.forEach((d) => {
        present += (d.get('summary.present') ?? 0) + (d.get('summary.late') ?? 0);
        total += d.get('summary.total') ?? 0;
      });
      return {
        ...base,
        activeStudents: activeStudents.data().count,
        attendanceToday: { present, total, rate: total ? Math.round((present / total) * 100) : null },
        fees: {
          dueCount: dueFees.length,
          dueAmount: dueFees.reduce((s, f) => s + ((f as { amount?: number }).amount ?? 0), 0),
          overdueCount: dueFees.filter((f) => f.overdue).length,
        },
      };
    }

    if (user.role === Role.Teacher) {
      return {
        ...base,
        pendingAttendance: todaysClasses.filter((c) => !c.attendanceMarked).length,
      };
    }

    // Student / parent
    const from = isoDate(new Date(Date.now() - 30 * 86_400_000));
    const [attendance, dues] = await Promise.all([
      Promise.all((user.studentIds ?? []).map((id) => this.attendance.forStudent(user, id, { from }))),
      this.fees.list(user, { status: 'due' }),
    ]);
    return {
      ...base,
      students: attendance.map((a) => ({ ...a.student, attendanceRate30d: a.rate })),
      dues,
    };
  }
}
