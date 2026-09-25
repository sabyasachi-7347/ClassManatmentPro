import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { FieldValue } from 'firebase-admin/firestore';
import { AuthUser, MemberClaims, Role } from '../auth/auth.types';
import { paths, toDto } from '../common/firestore.util';
import { FirebaseService } from '../firebase/firebase.service';
import { CreateInstituteDto, InviteMemberDto, UpdateMemberDto } from './institutes.dto';

@Injectable()
export class InstitutesService {
  constructor(private readonly firebase: FirebaseService) {}

  private get db() {
    return this.firebase.db;
  }

  async create(user: AuthUser, dto: CreateInstituteDto) {
    // Check the stored claims, not the token: a token issued before onboarding
    // wouldn't carry instituteId yet and could otherwise create a second institute.
    const claims = (await this.firebase.auth.getUser(user.uid)).customClaims as MemberClaims | undefined;
    if (user.instituteId || claims?.instituteId) {
      throw new ConflictException('You already belong to an institute');
    }

    const ref = this.db.collection('institutes').doc();
    const batch = this.db.batch();
    batch.set(ref, { ...dto, ownerUid: user.uid, createdAt: FieldValue.serverTimestamp() });
    batch.set(this.db.collection(paths.members(ref.id)).doc(user.uid), {
      role: Role.Owner,
      name: user.name ?? user.email ?? 'Owner',
      email: user.email ?? null,
      createdAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();

    await this.setClaims(user.uid, { role: Role.Owner, instituteId: ref.id });
    return { id: ref.id, ...dto, refreshToken: true };
  }

  async me(user: AuthUser) {
    if (!user.instituteId) return { uid: user.uid, email: user.email, institute: null };
    const [inst, member] = await Promise.all([
      this.db.doc(paths.institute(user.instituteId)).get(),
      this.db.collection(paths.members(user.instituteId)).doc(user.uid).get(),
    ]);
    return {
      uid: user.uid,
      email: user.email,
      role: user.role,
      studentIds: user.studentIds ?? [],
      institute: inst.exists ? toDto(inst) : null,
      member: member.exists ? toDto(member) : null,
    };
  }

  async listMembers(iid: string, role?: Role) {
    let q: FirebaseFirestore.Query = this.db.collection(paths.members(iid));
    if (role) q = q.where('role', '==', role);
    const snap = await q.orderBy('name').get();
    return snap.docs.map((d) => toDto(d));
  }

  async invite(iid: string, dto: InviteMemberDto) {
    const auth = this.firebase.auth;
    let uid: string;
    try {
      uid = (await auth.getUserByEmail(dto.email)).uid;
    } catch {
      uid = (await auth.createUser({ email: dto.email, displayName: dto.name })).uid;
    }

    const existing = (await auth.getUser(uid)).customClaims as MemberClaims | undefined;
    if (existing?.instituteId && existing.instituteId !== iid) {
      throw new ConflictException('This user already belongs to another institute');
    }
    if (existing?.role === Role.Owner) throw new ForbiddenException('Cannot change the owner');

    await this.assertStudentsExist(iid, dto.studentIds);
    await this.db.collection(paths.members(iid)).doc(uid).set(
      {
        role: dto.role,
        name: dto.name,
        email: dto.email,
        phone: dto.phone ?? null,
        studentIds: dto.studentIds ?? [],
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    if (dto.role === Role.Student && dto.studentIds?.length) {
      await this.db.collection(paths.students(iid)).doc(dto.studentIds[0]).update({ userId: uid });
    }
    await this.setClaims(uid, { role: dto.role, instituteId: iid, studentIds: dto.studentIds });

    // Share this link with the invitee so they can set a password.
    const setPasswordLink = await auth.generatePasswordResetLink(dto.email);
    return { uid, setPasswordLink };
  }

  async updateMember(iid: string, uid: string, dto: UpdateMemberDto) {
    const ref = this.db.collection(paths.members(iid)).doc(uid);
    const snap = await ref.get();
    if (!snap.exists) throw new NotFoundException('Member not found');
    if (snap.get('role') === Role.Owner) throw new ForbiddenException('Cannot change the owner');

    await this.assertStudentsExist(iid, dto.studentIds);
    await ref.update({ ...dto });
    const merged = { ...snap.data(), ...dto };
    await this.setClaims(uid, {
      role: merged.role,
      instituteId: iid,
      studentIds: merged.studentIds,
    });
    return toDto(await ref.get());
  }

  async removeMember(iid: string, uid: string) {
    const ref = this.db.collection(paths.members(iid)).doc(uid);
    const snap = await ref.get();
    if (!snap.exists) throw new NotFoundException('Member not found');
    if (snap.get('role') === Role.Owner) throw new ForbiddenException('Cannot remove the owner');
    await ref.delete();
    await this.firebase.auth.setCustomUserClaims(uid, null);
    await this.firebase.auth.revokeRefreshTokens(uid);
    return { removed: uid };
  }

  private async setClaims(uid: string, claims: MemberClaims) {
    const clean = Object.fromEntries(Object.entries(claims).filter(([, v]) => v !== undefined));
    await this.firebase.auth.setCustomUserClaims(uid, clean);
  }

  private async assertStudentsExist(iid: string, ids?: string[]) {
    if (!ids?.length) return;
    const col = this.db.collection(paths.students(iid));
    const snaps = await this.db.getAll(...ids.map((id) => col.doc(id)));
    const missing = snaps.filter((s) => !s.exists).map((s) => s.id);
    if (missing.length) throw new BadRequestException(`Unknown students: ${missing.join(', ')}`);
  }
}
