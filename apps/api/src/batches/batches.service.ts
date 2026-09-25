import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { FieldValue } from 'firebase-admin/firestore';
import { AuthUser, Role } from '../auth/auth.types';
import { paths, plain, toDto } from '../common/firestore.util';
import { tenantOf } from '../common/tenant';
import { FirebaseService } from '../firebase/firebase.service';
import { CreateBatchDto, UpdateBatchDto, UpdateEnrollmentsDto } from './batches.dto';

@Injectable()
export class BatchesService {
  constructor(private readonly firebase: FirebaseService) {}

  private col(iid: string) {
    return this.firebase.db.collection(paths.batches(iid));
  }

  /**
   * Batch ids the caller may see: `null` means all (staff).
   * Teachers see batches they teach; students/parents see their students' batches.
   */
  async visibleBatchIds(user: AuthUser): Promise<string[] | null> {
    const iid = tenantOf(user);
    if (user.role === Role.Owner || user.role === Role.Admin) return null;
    if (user.role === Role.Teacher) {
      const snap = await this.col(iid).where('teacherIds', 'array-contains', user.uid).get();
      return snap.docs.map((d) => d.id);
    }
    const ids = user.studentIds ?? [];
    if (!ids.length) return [];
    const students = this.firebase.db.collection(paths.students(iid));
    const snaps = await this.firebase.db.getAll(...ids.map((id) => students.doc(id)));
    return [...new Set(snaps.flatMap((s) => (s.get('batchIds') as string[] | undefined) ?? []))];
  }

  async assertCanAccess(user: AuthUser, batchId: string) {
    const visible = await this.visibleBatchIds(user);
    if (visible && !visible.includes(batchId)) {
      throw new ForbiddenException('You do not have access to this batch');
    }
  }

  async list(user: AuthUser, includeArchived = false) {
    const iid = tenantOf(user);
    const visible = await this.visibleBatchIds(user);
    const snap = await this.col(iid).orderBy('name').get();
    return snap.docs
      .filter((d) => (visible ? visible.includes(d.id) : true))
      .filter((d) => includeArchived || !d.get('archived'))
      .map((d) => toDto(d));
  }

  async get(user: AuthUser, id: string) {
    await this.assertCanAccess(user, id);
    const snap = await this.col(tenantOf(user)).doc(id).get();
    if (!snap.exists) throw new NotFoundException('Batch not found');
    const students = await this.firebase.db
      .collection(paths.students(tenantOf(user)))
      .where('batchIds', 'array-contains', id)
      .get();
    return { ...toDto(snap), students: students.docs.map((d) => toDto(d)) };
  }

  async create(iid: string, dto: CreateBatchDto) {
    const ref = this.col(iid).doc();
    await ref.set({
      teacherIds: [],
      schedule: [],
      ...plain(dto),
      archived: false,
      createdAt: FieldValue.serverTimestamp(),
    });
    return toDto(await ref.get());
  }

  async update(iid: string, id: string, dto: UpdateBatchDto) {
    const ref = this.col(iid).doc(id);
    if (!(await ref.get()).exists) throw new NotFoundException('Batch not found');
    await ref.update({ ...plain(dto), updatedAt: FieldValue.serverTimestamp() });
    return toDto(await ref.get());
  }

  /** Bulk add/remove students from batches (backs the web "paint" enrollment matrix). */
  async updateEnrollments(iid: string, dto: UpdateEnrollmentsDto) {
    const db = this.firebase.db;
    const batchIds = [...new Set(dto.changes.map((c) => c.batchId))];
    const snaps = await db.getAll(...batchIds.map((id) => this.col(iid).doc(id)));
    const missing = snaps.filter((s) => !s.exists).map((s) => s.id);
    if (missing.length) throw new BadRequestException(`Unknown batches: ${missing.join(', ')}`);

    const students = db.collection(paths.students(iid));
    const writer = db.batch();
    for (const c of dto.changes) {
      writer.update(students.doc(c.studentId), {
        batchIds: c.enrolled
          ? FieldValue.arrayUnion(c.batchId)
          : FieldValue.arrayRemove(c.batchId),
      });
    }
    await writer.commit();
    return { applied: dto.changes.length };
  }
}
