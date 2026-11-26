import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { AuthUser, Role } from '../auth/auth.types';
import { BatchesService } from '../batches/batches.service';
import { isoDate } from '../common/dates';
import { paths, toDto } from '../common/firestore.util';
import { tenantOf } from '../common/tenant';
import { FirebaseService } from '../firebase/firebase.service';
import { PushService } from '../push/push.service';
import { ListAbsencesQuery } from './absences.dto';

/**
 * The absence acknowledgement state machine:
 *
 *   teacher marks absent → push to parents → parent acknowledges
 *                                         ↘ still waiting after N hours → "silent", staff chase
 *
 * One document per (batch, date, student): absences/{batchId}_{date}_{studentId}.
 * "silent" is derived on read rather than stored, so no scheduler is needed.
 */
export type AbsenceState = 'waiting' | 'acknowledged' | 'silent';

const SILENT_AFTER_HOURS = Number(process.env.ABSENCE_SILENT_HOURS ?? 3);

@Injectable()
export class AbsencesService {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly batches: BatchesService,
    private readonly push: PushService,
  ) {}

  private col(iid: string) {
    return this.firebase.db.collection(paths.absences(iid));
  }

  /**
   * Called after attendance is saved. Opens an alert for each newly absent
   * student, closes alerts for students since marked present, and pushes to
   * parents only for alerts that are new — re-saving a roll call never re-notifies.
   */
  async sync(
    iid: string,
    batch: { id: string; name?: string },
    date: string,
    records: Record<string, string>,
    markedBy: string,
    topic?: string | null,
  ) {
    const db = this.firebase.db;
    const existing = await this.col(iid).where('batchId', '==', batch.id).where('date', '==', date).get();
    const open = new Map(existing.docs.map((d) => [d.get('studentId') as string, d]));
    const absent = Object.keys(records).filter((id) => records[id] === 'absent');

    const writer = db.batch();
    for (const [sid, doc] of open) if (!absent.includes(sid)) writer.delete(doc.ref);

    const fresh = absent.filter((sid) => !open.has(sid));
    const students = fresh.length
      ? await db.getAll(...fresh.map((sid) => db.collection(paths.students(iid)).doc(sid)))
      : [];
    for (const s of students) {
      writer.set(this.col(iid).doc(`${batch.id}_${date}_${s.id}`), {
        batchId: batch.id,
        batchName: batch.name ?? null,
        date,
        topic: topic ?? null,
        studentId: s.id,
        studentName: s.get('name') ?? null,
        guardianName: s.get('guardianName') ?? null,
        guardianPhone: s.get('guardianPhone') ?? null,
        state: 'waiting',
        markedBy,
        markedAt: FieldValue.serverTimestamp(),
        notified: 0,
      });
    }
    await writer.commit();

    // Push after the commit so a slow FCM call never holds the roll call.
    await Promise.all(
      students.map(async (s) => {
        const n = await this.notifyParents(iid, s.id, String(s.get('name') ?? 'Your child'), batch.name, topic);
        await this.col(iid).doc(`${batch.id}_${date}_${s.id}`).update({ notified: n });
      }),
    );
    return { opened: fresh.length, closed: [...open.keys()].filter((k) => !absent.includes(k)).length };
  }

  private async notifyParents(
    iid: string,
    studentId: string,
    name: string,
    batchName?: string,
    topic?: string | null,
    nudge = false,
  ) {
    const parents = await this.push.membersForStudent(iid, studentId);
    const where = [topic, batchName].filter(Boolean).join(' · ');
    return this.push.sendToMembers(iid, parents, {
      title: nudge ? `Reminder: ${name} was absent` : `${name} is absent`,
      body: `${name} wasn't in class${where ? ` (${where})` : ''}. Tap to confirm you've seen this.`,
      data: { type: 'absence', studentId },
    });
  }

  async list(user: AuthUser, q: ListAbsencesQuery) {
    const iid = tenantOf(user);
    let query: FirebaseFirestore.Query = this.col(iid);

    if (user.role === Role.Parent || user.role === Role.Student) {
      const ids = user.studentIds ?? [];
      if (!ids.length) return [];
      query = query.where('studentId', 'in', ids.slice(0, 30));
      // Parents see history, not just today: default to the last 60 days.
      const from = q.from ?? isoDate(new Date(Date.now() - 60 * 86_400_000));
      query = query.where('date', '>=', from);
      if (q.date) query = query.where('date', '==', q.date);
    } else {
      query = query.where('date', '==', q.date ?? isoDate());
    }

    const snap = await query.limit(500).get();
    let rows = snap.docs.map((d) => this.view(d));

    if (user.role === Role.Teacher) {
      const visible = await this.batches.visibleBatchIds(user);
      rows = rows.filter((r) => !visible || visible.includes(r.batchId));
    }
    if (q.state) rows = rows.filter((r) => r.state === q.state);
    return rows.sort((a, b) => (b.date + (b.markedAt ?? '')).localeCompare(a.date + (a.markedAt ?? '')));
  }

  async acknowledge(user: AuthUser, id: string) {
    if (user.role !== Role.Parent) throw new ForbiddenException('Only parents acknowledge absences');
    const ref = this.col(tenantOf(user)).doc(id);
    const snap = await ref.get();
    if (!snap.exists) throw new NotFoundException('Absence not found');
    if (!(user.studentIds ?? []).includes(snap.get('studentId'))) throw new ForbiddenException();
    if (snap.get('state') !== 'acknowledged') {
      await ref.update({
        state: 'acknowledged',
        ackAt: FieldValue.serverTimestamp(),
        ackBy: user.uid,
        ackByName: user.name ?? user.email ?? null,
      });
    }
    return this.view(await ref.get());
  }

  /** Re-push to parents who have not acknowledged. Staff and teachers of the batch. */
  async nudge(user: AuthUser, ids?: string[], date?: string) {
    const iid = tenantOf(user);
    let targets: FirebaseFirestore.DocumentSnapshot[];
    if (ids?.length) {
      targets = await this.firebase.db.getAll(...ids.map((id) => this.col(iid).doc(id)));
    } else {
      targets = (await this.col(iid).where('date', '==', date ?? isoDate()).get()).docs;
    }
    targets = targets.filter((d) => d.exists && d.get('state') !== 'acknowledged');

    if (user.role === Role.Teacher) {
      const visible = (await this.batches.visibleBatchIds(user)) ?? [];
      targets = targets.filter((d) => visible.includes(d.get('batchId')));
    }

    let devices = 0;
    for (const d of targets) {
      devices += await this.notifyParents(
        iid,
        d.get('studentId'),
        String(d.get('studentName') ?? 'Your child'),
        d.get('batchName'),
        d.get('topic'),
        true,
      );
      await d.ref.update({ nudgedAt: FieldValue.serverTimestamp(), nudges: FieldValue.increment(1) });
    }
    return { nudged: targets.length, devices };
  }

  private view(d: FirebaseFirestore.DocumentSnapshot) {
    const row = toDto<{
      batchId: string;
      date: string;
      state: AbsenceState;
      markedAt?: string;
    }>(d);
    const marked = d.get('markedAt') as Timestamp | undefined;
    const hoursWaiting = marked ? (Date.now() - marked.toMillis()) / 3_600_000 : 0;
    const state: AbsenceState =
      row.state === 'waiting' && hoursWaiting >= SILENT_AFTER_HOURS ? 'silent' : row.state;
    return { ...row, state, hoursWaiting: Math.floor(hoursWaiting) };
  }
}
