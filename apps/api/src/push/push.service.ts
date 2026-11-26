import { Injectable, Logger } from '@nestjs/common';
import { FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { paths } from '../common/firestore.util';
import { FirebaseService } from '../firebase/firebase.service';

export interface PushMessage {
  title: string;
  body: string;
  /** String-only payload the app reads to route the tap (e.g. { type: 'absence', id }). */
  data?: Record<string, string>;
}

/**
 * Firebase Cloud Messaging fan-out. Device tokens live on the member document
 * (`fcmTokens`), registered by the app after sign-in.
 *
 * There is no FCM emulator, so against the local emulators sends are skipped
 * and only counted. Set PUSH_ENABLED=true to force real sends.
 */
@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);
  readonly enabled =
    process.env.PUSH_ENABLED === 'true' ||
    (process.env.PUSH_ENABLED !== 'false' && !process.env.FIRESTORE_EMULATOR_HOST);

  constructor(private readonly firebase: FirebaseService) {}

  async registerToken(iid: string, uid: string, token: string) {
    await this.firebase.db
      .collection(paths.members(iid))
      .doc(uid)
      .set({ fcmTokens: FieldValue.arrayUnion(token) }, { merge: true });
  }

  async removeToken(iid: string, uid: string, token: string) {
    await this.firebase.db
      .collection(paths.members(iid))
      .doc(uid)
      .set({ fcmTokens: FieldValue.arrayRemove(token) }, { merge: true });
  }

  /** Parents (and student accounts) linked to a student record. */
  async membersForStudent(iid: string, studentId: string) {
    const snap = await this.firebase.db
      .collection(paths.members(iid))
      .where('studentIds', 'array-contains', studentId)
      .get();
    return snap.docs.filter((d) => d.get('role') === 'parent');
  }

  /** Sends to every token of the given members. Returns how many devices were targeted. */
  async sendToMembers(
    iid: string,
    members: FirebaseFirestore.DocumentSnapshot[],
    msg: PushMessage,
  ): Promise<number> {
    const owners = new Map<string, string>(); // token -> member uid
    for (const m of members) {
      for (const t of (m.get('fcmTokens') as string[] | undefined) ?? []) owners.set(t, m.id);
    }
    const tokens = [...owners.keys()];
    if (!tokens.length) return 0;
    if (!this.enabled) {
      this.logger.log(`push skipped (disabled): "${msg.title}" to ${tokens.length} device(s)`);
      return tokens.length;
    }

    try {
      const res = await getMessaging(this.firebase.app).sendEachForMulticast({
        tokens,
        notification: { title: msg.title, body: msg.body },
        data: msg.data,
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      // Drop tokens FCM says are dead so they don't accumulate.
      const dead = res.responses
        .map((r, i) => ({ r, t: tokens[i] }))
        .filter(({ r }) =>
          ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'].includes(
            r.error?.code ?? '',
          ),
        );
      await Promise.all(dead.map(({ t }) => this.removeToken(iid, owners.get(t)!, t)));
      return res.successCount;
    } catch (e) {
      // A push failure must never fail the request that triggered it.
      this.logger.warn(`push failed: ${(e as Error).message}`);
      return 0;
    }
  }
}
