import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { App, applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import { Auth, getAuth } from 'firebase-admin/auth';
import { Firestore, getFirestore } from 'firebase-admin/firestore';

@Injectable()
export class FirebaseService {
  private readonly logger = new Logger(FirebaseService.name);
  readonly app: App;
  readonly auth: Auth;
  readonly db: Firestore;

  constructor(config: ConfigService) {
    const projectId = config.get<string>('firebase.projectId');
    const clientEmail = config.get<string>('firebase.clientEmail');
    const privateKey = config.get<string>('firebase.privateKey');

    const credential =
      clientEmail && privateKey
        ? cert({ projectId, clientEmail, privateKey })
        : process.env.FIRESTORE_EMULATOR_HOST
          ? undefined
          : applicationDefault();

    this.app = getApps()[0] ?? initializeApp({ projectId, ...(credential && { credential }) });
    this.auth = getAuth(this.app);
    this.db = getFirestore(this.app);
    try {
      this.db.settings({ ignoreUndefinedProperties: true });
    } catch {
      // settings() can only be called once per process (e.g. on hot reload)
    }

    if (process.env.FIRESTORE_EMULATOR_HOST) {
      this.logger.warn(`Using Firestore emulator at ${process.env.FIRESTORE_EMULATOR_HOST}`);
    }
  }
}
