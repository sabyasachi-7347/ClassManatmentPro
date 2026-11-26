import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { FieldValue } from 'firebase-admin/firestore';
import { AuthUser, Role } from '../auth/auth.types';
import { BatchesService } from '../batches/batches.service';
import { paths, toDto } from '../common/firestore.util';
import { tenantOf } from '../common/tenant';
import { FirebaseService } from '../firebase/firebase.service';
import { StudentsService } from '../students/students.service';
import { CreateTestDto, EnterMarksDto } from './tests.dto';

type Marks = Record<string, number>;

/** Competition ranking: equal scores share a rank, the next rank skips (1, 2, 2, 4). */
export function rankOf(marks: Marks): Map<string, number> {
  const sorted = Object.entries(marks).sort((a, b) => b[1] - a[1]);
  const ranks = new Map<string, number>();
  sorted.forEach(([id, score], i) => {
    ranks.set(id, i > 0 && score === sorted[i - 1][1] ? ranks.get(sorted[i - 1][0])! : i + 1);
  });
  return ranks;
}

/** "Ishita Rane" -> "Ishita R." — what other students and parents see on a leaderboard. */
export function shortName(name: string): string {
  const [first, ...rest] = name.trim().split(/\s+/);
  const last = rest.at(-1);
  return last ? `${first} ${last[0].toUpperCase()}.` : first;
}

@Injectable()
export class TestsService {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly batches: BatchesService,
    private readonly students: StudentsService,
  ) {}

  private col(iid: string) {
    return this.firebase.db.collection(paths.tests(iid));
  }

  private isStaff(user: AuthUser) {
    return user.role === Role.Owner || user.role === Role.Admin || user.role === Role.Teacher;
  }

  async list(user: AuthUser, batchId?: string) {
    const iid = tenantOf(user);
    const visible = await this.batches.visibleBatchIds(user);
    if (batchId && visible && !visible.includes(batchId)) throw new ForbiddenException();

    let q: FirebaseFirestore.Query = this.col(iid);
    if (batchId) q = q.where('batchId', '==', batchId);
    const snap = await q.orderBy('date', 'desc').limit(200).get();
    return snap.docs
      .filter((d) => !visible || visible.includes(d.get('batchId')))
      .map((d) => this.summary(d));
  }

  async create(user: AuthUser, dto: CreateTestDto) {
    const iid = tenantOf(user);
    await this.batches.assertCanAccess(user, dto.batchId);
    const batch = await this.firebase.db.collection(paths.batches(iid)).doc(dto.batchId).get();
    if (!batch.exists) throw new NotFoundException('Batch not found');
    const ref = this.col(iid).doc();
    await ref.set({
      ...dto,
      batchName: batch.get('name') ?? null,
      marks: {},
      notes: {},
      studentIds: [],
      createdBy: user.uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    return this.summary(await ref.get());
  }

  async enterMarks(user: AuthUser, id: string, dto: EnterMarksDto) {
    const ref = this.col(tenantOf(user)).doc(id);
    const snap = await ref.get();
    if (!snap.exists) throw new NotFoundException('Test not found');
    await this.batches.assertCanAccess(user, snap.get('batchId'));

    const max = snap.get('maxMarks') as number;
    const marks: Marks = { ...(snap.get('marks') ?? {}) };
    const notes: Record<string, string> = { ...(snap.get('notes') ?? {}) };
    for (const m of dto.marks) {
      if (m.score != null && m.score > max) {
        throw new BadRequestException(`Score ${m.score} exceeds max ${max} for ${m.studentId}`);
      }
      if (m.score == null) delete marks[m.studentId];
      else marks[m.studentId] = m.score;
      if (m.note !== undefined) notes[m.studentId] = m.note;
    }
    await ref.update({
      marks,
      notes,
      studentIds: Object.keys(marks),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return this.get(user, id);
  }

  /**
   * Staff get every mark with names. Students and parents get the leaderboard
   * (short names, no other student's notes) plus their own row in full.
   */
  async get(user: AuthUser, id: string) {
    const iid = tenantOf(user);
    const snap = await this.col(iid).doc(id).get();
    if (!snap.exists) throw new NotFoundException('Test not found');
    await this.batches.assertCanAccess(user, snap.get('batchId'));

    const marks: Marks = snap.get('marks') ?? {};
    const notes: Record<string, string> = snap.get('notes') ?? {};
    const ranks = rankOf(marks);
    const ids = Object.keys(marks);
    const names = new Map<string, string>();
    if (ids.length) {
      const col = this.firebase.db.collection(paths.students(iid));
      const snaps = await this.firebase.db.getAll(...ids.map((sid) => col.doc(sid)));
      snaps.forEach((s) => names.set(s.id, String(s.get('name') ?? 'Student')));
    }

    const mine = new Set(user.studentIds ?? []);
    const staff = this.isStaff(user);
    const rows = ids
      .map((sid) => ({
        studentId: staff || mine.has(sid) ? sid : undefined,
        name: staff || mine.has(sid) ? names.get(sid) : shortName(names.get(sid) ?? ''),
        score: marks[sid],
        rank: ranks.get(sid)!,
        isMine: mine.has(sid),
        note: staff || mine.has(sid) ? (notes[sid] ?? null) : undefined,
      }))
      .sort((a, b) => a.rank - b.rank);

    return { ...this.summary(snap), rows };
  }

  /** Every test a student sat, newest first, with their score and rank. */
  async resultsFor(user: AuthUser, studentId: string) {
    await this.students.get(user, studentId); // enforces visibility
    const snap = await this.col(tenantOf(user))
      .where('studentIds', 'array-contains', studentId)
      .orderBy('date', 'desc')
      .limit(100)
      .get();
    return snap.docs.map((d) => {
      const marks: Marks = d.get('marks') ?? {};
      const max = d.get('maxMarks') as number;
      return {
        testId: d.id,
        title: d.get('title'),
        date: d.get('date'),
        batchId: d.get('batchId'),
        batchName: d.get('batchName'),
        score: marks[studentId],
        maxMarks: max,
        percent: Math.round((marks[studentId] / max) * 1000) / 10,
        rank: rankOf(marks).get(studentId),
        outOf: Object.keys(marks).length,
        note: (d.get('notes') ?? {})[studentId] ?? null,
      };
    });
  }

  private summary(d: FirebaseFirestore.DocumentSnapshot) {
    const marks: Marks = d.get('marks') ?? {};
    const scores = Object.values(marks);
    const max = d.get('maxMarks') as number;
    const avg = scores.length ? scores.reduce((a, b) => a + b, 0) / scores.length : null;
    const base = toDto<Record<string, unknown>>(d);
    delete base.marks;
    delete base.notes;
    delete base.studentIds;
    return {
      ...base,
      entered: scores.length,
      average: avg == null ? null : Math.round(avg * 10) / 10,
      averagePercent: avg == null ? null : Math.round((avg / max) * 1000) / 10,
    };
  }
}
