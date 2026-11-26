import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { FieldValue } from 'firebase-admin/firestore';
import { AbsencesService } from '../absences/absences.service';
import { AuthUser, Role } from '../auth/auth.types';
import { BatchesService } from '../batches/batches.service';
import { ISO_DATE } from '../common/dates';
import { paths, toDto } from '../common/firestore.util';
import { tenantOf } from '../common/tenant';
import { FirebaseService } from '../firebase/firebase.service';
import { StudentsService } from '../students/students.service';
import { AttendanceRangeQuery, AttendanceStatus, MarkAttendanceDto } from './attendance.dto';

@Injectable()
export class AttendanceService {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly batches: BatchesService,
    private readonly students: StudentsService,
    private readonly absences: AbsencesService,
  ) {}

  private col(iid: string) {
    return this.firebase.db.collection(paths.attendance(iid));
  }

  /** One document per batch per day: attendance/{batchId}_{date}. Re-marking overwrites. */
  async mark(user: AuthUser, batchId: string, date: string, dto: MarkAttendanceDto) {
    if (!ISO_DATE.test(date)) throw new BadRequestException('date must be YYYY-MM-DD');
    if (user.role !== Role.Owner && user.role !== Role.Admin && user.role !== Role.Teacher) {
      throw new ForbiddenException();
    }
    await this.batches.assertCanAccess(user, batchId);

    const records: Record<string, AttendanceStatus> = {};
    for (const r of dto.records) records[r.studentId] = r.status;
    const ids = Object.keys(records);
    const count = (s: AttendanceStatus) => ids.filter((id) => records[id] === s).length;

    const iid = tenantOf(user);
    const batch = await this.firebase.db.collection(paths.batches(iid)).doc(batchId).get();
    if (!batch.exists) throw new NotFoundException('Batch not found');

    const ref = this.col(iid).doc(`${batchId}_${date}`);
    await ref.set({
      batchId,
      date,
      topic: dto.topic ?? null,
      records,
      studentIds: ids,
      summary: {
        total: ids.length,
        present: count('present'),
        late: count('late'),
        absent: count('absent'),
        excused: count('excused'),
      },
      markedBy: user.uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
    const alerts = await this.absences.sync(
      iid,
      { id: batchId, name: batch.get('name') },
      date,
      records,
      user.uid,
      dto.topic,
    );
    return { ...toDto(await ref.get()), alerts };
  }

  async forBatch(user: AuthUser, batchId: string, q: AttendanceRangeQuery) {
    await this.batches.assertCanAccess(user, batchId);
    let query = this.col(tenantOf(user)).where('batchId', '==', batchId);
    if (q.from) query = query.where('date', '>=', q.from);
    if (q.to) query = query.where('date', '<=', q.to);
    const snap = await query.orderBy('date', 'desc').limit(120).get();
    return snap.docs.map((d) => toDto(d));
  }

  async forStudent(user: AuthUser, studentId: string, q: AttendanceRangeQuery) {
    const student = await this.students.get(user, studentId); // enforces visibility
    let query = this.col(tenantOf(user)).where('studentIds', 'array-contains', studentId);
    if (q.from) query = query.where('date', '>=', q.from);
    if (q.to) query = query.where('date', '<=', q.to);
    const snap = await query.orderBy('date', 'desc').limit(365).get();

    const sessions = snap.docs.map((d) => ({
      batchId: d.get('batchId') as string,
      date: d.get('date') as string,
      status: d.get(`records.${studentId}`) as AttendanceStatus,
    }));
    const attended = sessions.filter((s) => s.status === 'present' || s.status === 'late').length;
    const counted = sessions.filter((s) => s.status !== 'excused').length;
    return {
      student: { id: student.id, name: (student as { name?: string }).name },
      rate: counted ? Math.round((attended / counted) * 1000) / 10 : null,
      sessions,
    };
  }
}
