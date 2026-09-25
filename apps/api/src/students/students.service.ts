import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { FieldValue } from 'firebase-admin/firestore';
import { AuthUser, Role } from '../auth/auth.types';
import { BatchesService } from '../batches/batches.service';
import { paths, toDto } from '../common/firestore.util';
import { tenantOf } from '../common/tenant';
import { FirebaseService } from '../firebase/firebase.service';
import { CreateStudentDto, UpdateStudentDto } from './students.dto';

@Injectable()
export class StudentsService {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly batches: BatchesService,
  ) {}

  private col(iid: string) {
    return this.firebase.db.collection(paths.students(iid));
  }

  async list(user: AuthUser, batchId?: string) {
    const iid = tenantOf(user);

    if (user.role === Role.Student || user.role === Role.Parent) {
      const ids = user.studentIds ?? [];
      if (!ids.length) return [];
      const snaps = await this.firebase.db.getAll(...ids.map((id) => this.col(iid).doc(id)));
      return snaps.filter((s) => s.exists).map((s) => toDto(s));
    }

    if (batchId) {
      await this.batches.assertCanAccess(user, batchId);
      const snap = await this.col(iid).where('batchIds', 'array-contains', batchId).get();
      return snap.docs.map((d) => toDto(d)).sort(byName);
    }

    const visible = await this.batches.visibleBatchIds(user);
    if (visible === null) {
      const snap = await this.col(iid).orderBy('name').get();
      return snap.docs.map((d) => toDto(d));
    }
    if (!visible.length) return [];
    // array-contains-any accepts at most 30 values
    const chunks: string[][] = [];
    for (let i = 0; i < visible.length; i += 30) chunks.push(visible.slice(i, i + 30));
    const results = await Promise.all(
      chunks.map((c) => this.col(iid).where('batchIds', 'array-contains-any', c).get()),
    );
    const seen = new Map<string, Record<string, unknown> & { id: string }>();
    results.flatMap((r) => r.docs).forEach((d) => seen.set(d.id, toDto(d)));
    return [...seen.values()].sort(byName);
  }

  async get(user: AuthUser, id: string) {
    const snap = await this.col(tenantOf(user)).doc(id).get();
    if (!snap.exists) throw new NotFoundException('Student not found');
    await this.assertCanSee(user, id, (snap.get('batchIds') as string[]) ?? []);
    return toDto(snap);
  }

  async create(iid: string, dto: CreateStudentDto) {
    const ref = this.col(iid).doc();
    await ref.set({
      batchIds: [],
      ...dto,
      status: 'active',
      createdAt: FieldValue.serverTimestamp(),
    });
    return toDto(await ref.get());
  }

  async update(iid: string, id: string, dto: UpdateStudentDto) {
    const ref = this.col(iid).doc(id);
    if (!(await ref.get()).exists) throw new NotFoundException('Student not found');
    await ref.update({ ...dto, updatedAt: FieldValue.serverTimestamp() });
    return toDto(await ref.get());
  }

  async assertCanSee(user: AuthUser, studentId: string, batchIds: string[]) {
    if (user.role === Role.Student || user.role === Role.Parent) {
      if (!(user.studentIds ?? []).includes(studentId)) throw new ForbiddenException();
      return;
    }
    const visible = await this.batches.visibleBatchIds(user);
    if (visible && !batchIds.some((b) => visible.includes(b))) throw new ForbiddenException();
  }
}

const byName = (a: Record<string, unknown>, b: Record<string, unknown>) =>
  String(a.name ?? '').localeCompare(String(b.name ?? ''));
