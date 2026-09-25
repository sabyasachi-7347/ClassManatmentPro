import { Injectable } from '@nestjs/common';
import { FieldValue } from 'firebase-admin/firestore';
import { AuthUser, Role } from '../auth/auth.types';
import { BatchesService } from '../batches/batches.service';
import { paths, toDto } from '../common/firestore.util';
import { tenantOf } from '../common/tenant';
import { FirebaseService } from '../firebase/firebase.service';
import { CreateAnnouncementDto } from './announcements.dto';

@Injectable()
export class AnnouncementsService {
  constructor(
    private readonly firebase: FirebaseService,
    private readonly batches: BatchesService,
  ) {}

  private col(iid: string) {
    return this.firebase.db.collection(paths.announcements(iid));
  }

  async list(user: AuthUser) {
    const visible = await this.batches.visibleBatchIds(user);
    const snap = await this.col(tenantOf(user)).orderBy('createdAt', 'desc').limit(100).get();
    return snap.docs
      .map((d) => toDto<{ batchIds?: string[] }>(d))
      .filter((a) => !visible || !a.batchIds?.length || a.batchIds.some((b) => visible.includes(b)));
  }

  async create(user: AuthUser, dto: CreateAnnouncementDto) {
    if (user.role === Role.Teacher) {
      // Teachers may only post to their own batches.
      const own = (await this.batches.visibleBatchIds(user)) ?? [];
      dto.batchIds = (dto.batchIds?.length ? dto.batchIds : own).filter((b) => own.includes(b));
    }
    const ref = this.col(tenantOf(user)).doc();
    await ref.set({
      ...dto,
      batchIds: dto.batchIds ?? [],
      createdBy: user.uid,
      authorName: user.name ?? user.email ?? null,
      createdAt: FieldValue.serverTimestamp(),
    });
    return toDto(await ref.get());
  }
}
