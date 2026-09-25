import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { FieldValue } from 'firebase-admin/firestore';
import { AuthUser, Role } from '../auth/auth.types';
import { isoDate } from '../common/dates';
import { paths, toDto } from '../common/firestore.util';
import { tenantOf } from '../common/tenant';
import { FirebaseService } from '../firebase/firebase.service';
import { CreateFeeDto, GenerateFeesDto, ListFeesQuery, RecordPaymentDto } from './fees.dto';

@Injectable()
export class FeesService {
  constructor(private readonly firebase: FirebaseService) {}

  private col(iid: string) {
    return this.firebase.db.collection(paths.fees(iid));
  }

  async list(user: AuthUser, q: ListFeesQuery) {
    const iid = tenantOf(user);
    let studentIds: string[] | undefined;
    if (user.role === Role.Student || user.role === Role.Parent) {
      studentIds = user.studentIds ?? [];
      if (q.studentId && !studentIds.includes(q.studentId)) throw new ForbiddenException();
      if (!studentIds.length) return [];
    } else if (user.role === Role.Teacher) {
      throw new ForbiddenException('Teachers cannot view fees');
    }

    let query: FirebaseFirestore.Query = this.col(iid);
    if (q.studentId) query = query.where('studentId', '==', q.studentId);
    else if (studentIds) query = query.where('studentId', 'in', studentIds.slice(0, 30));
    if (q.status) query = query.where('status', '==', q.status);
    if (q.period) query = query.where('period', '==', q.period);
    const snap = await query.orderBy('dueDate', 'desc').limit(500).get();

    const today = isoDate();
    return snap.docs.map((d) => {
      const fee = toDto<{ status: string; dueDate: string }>(d);
      return { ...fee, overdue: fee.status === 'due' && fee.dueDate < today };
    });
  }

  async create(iid: string, dto: CreateFeeDto) {
    const student = await this.firebase.db.collection(paths.students(iid)).doc(dto.studentId).get();
    if (!student.exists) throw new NotFoundException('Student not found');
    const ref = dto.period
      ? this.col(iid).doc(`${dto.studentId}_${dto.period}`)
      : this.col(iid).doc();
    try {
      await ref.create({
        ...dto,
        studentName: student.get('name'),
        status: 'due',
        createdAt: FieldValue.serverTimestamp(),
      });
    } catch {
      throw new ConflictException('An invoice for this student and period already exists');
    }
    return toDto(await ref.get());
  }

  /**
   * Creates one invoice per active student for the period, summing the monthly fee of
   * every batch they are enrolled in. Idempotent: existing invoices are skipped.
   */
  async generate(iid: string, dto: GenerateFeesDto) {
    const db = this.firebase.db;
    const [batches, students] = await Promise.all([
      db.collection(paths.batches(iid)).get(),
      db.collection(paths.students(iid)).where('status', '==', 'active').get(),
    ]);
    const feeByBatch = new Map(batches.docs.map((b) => [b.id, (b.get('monthlyFee') as number) ?? 0]));

    let created = 0;
    let skipped = 0;
    const writer = db.bulkWriter();
    for (const s of students.docs) {
      const batchIds = (s.get('batchIds') as string[]) ?? [];
      const amount = batchIds.reduce((sum, id) => sum + (feeByBatch.get(id) ?? 0), 0);
      if (amount <= 0) {
        skipped++;
        continue;
      }
      writer
        .create(this.col(iid).doc(`${s.id}_${dto.period}`), {
          studentId: s.id,
          studentName: s.get('name'),
          amount,
          period: dto.period,
          dueDate: dto.dueDate,
          status: 'due',
          createdAt: FieldValue.serverTimestamp(),
        })
        .then(() => created++)
        .catch(() => skipped++);
    }
    await writer.close();
    return { period: dto.period, created, skipped };
  }

  async recordPayment(user: AuthUser, id: string, dto: RecordPaymentDto) {
    const ref = this.col(tenantOf(user)).doc(id);
    const snap = await ref.get();
    if (!snap.exists) throw new NotFoundException('Invoice not found');
    if (snap.get('status') !== 'due') throw new ConflictException('Invoice is not due');
    await ref.update({
      status: 'paid',
      payment: {
        method: dto.method,
        reference: dto.reference ?? null,
        paidOn: dto.paidOn ?? isoDate(),
        recordedBy: user.uid,
      },
      updatedAt: FieldValue.serverTimestamp(),
    });
    return toDto(await ref.get());
  }

  async waive(iid: string, id: string) {
    const ref = this.col(iid).doc(id);
    if (!(await ref.get()).exists) throw new NotFoundException('Invoice not found');
    await ref.update({ status: 'waived', updatedAt: FieldValue.serverTimestamp() });
    return toDto(await ref.get());
  }
}
