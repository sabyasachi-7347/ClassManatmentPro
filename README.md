# CLASSES.OS

Class / coaching-institute management platform.

| Part | Stack | Path |
|---|---|---|
| **API** | NestJS 11 · Firebase Admin SDK · Swagger | [`apps/api`](apps/api) |
| **Web** (admin + teacher + parent portal) | React 19 · Vite · Firebase Auth | [`apps/web`](apps/web) |
| **Mobile** (teachers, students, parents) | Flutter · Riverpod · go_router · Dio | [`apps/mobile`](apps/mobile) |
| **Database / Auth** | Cloud Firestore · Firebase Authentication | [`firebase`](firebase) |

The web UI uses the CLASSES.OS v3 design system (bento dashboards, dark mode, "data as hero"
numerals, spring motion) ported from the original prototype into
[`apps/web/src/styles/os.css`](apps/web/src/styles/os.css). The Flutter theme mirrors the same tokens
in [`apps/mobile/lib/core/theme.dart`](apps/mobile/lib/core/theme.dart).

## Architecture

```
 Flutter app ─┐                         ┌─ Firebase Auth (sign-in, custom claims)
              ├─ Firebase ID token ──►  NestJS API ──► Firestore (institutes/{id}/…)
 React web  ──┘   (Authorization: Bearer)
```

- Clients sign in with **Firebase Auth** directly, then call the **NestJS API** with the ID token.
- The API verifies the token and reads the user's **custom claims** — `role`, `instituteId`,
  `studentIds` — to enforce access. Claims are set only by the API (onboarding / invite).
- **All Firestore access goes through the API** (Admin SDK). Client access is denied in
  [`firestore.rules`](firebase/firestore.rules).
- Multi-tenant: every record lives under `institutes/{instituteId}/…`.

### Roles

| Role | Can do |
|---|---|
| `owner` | Everything; created when someone onboards a new institute |
| `admin` | Everything except removing/changing the owner |
| `teacher` | See own batches + their students, take attendance, post announcements to own batches |
| `student` | See own batches, attendance, fees, announcements |
| `parent` | Same as student, for each linked child |

### Modules (v0.1)

Institutes & onboarding · Team/invites & roles · Batches (schedule, teachers, monthly fee) ·
Students · Enrollment matrix (drag-to-paint) · Attendance (per batch per day) ·
Fees (monthly generation, payments, overdue) · Announcements · Role-aware dashboard.

Swagger docs: `http://localhost:3000/docs` when the API is running.

## Local development (no Firebase project needed)

Prereqs: Node 20+, Java 11+ (for the Firestore emulator), `npm i -g firebase-tools`, Flutter 3.x.

```bash
npm install                     # installs api + web workspaces

# 1. Emulators (Auth :9099, Firestore :8080, UI :4000)
npm run emulators

# 2. API  (new terminal)
cp apps/api/.env.example apps/api/.env
npm run dev:api                 # http://localhost:3000/api/v1  · docs at /docs

# 3. Web  (new terminal)
cp apps/web/.env.example apps/web/.env.local
npm run dev:web                 # http://localhost:5173 — create an account, then your institute

# 4. Mobile (new terminal)
cd apps/mobile && flutter pub get
flutter run --dart-define=USE_EMULATORS=true
```

### Tests

```bash
npm test                        # API unit tests
npm run test:e2e -w apps/api    # 38-step API scenario against the emulators (wipes emulator data)
cd apps/mobile && flutter analyze && flutter test
```

## What's next

See [`docs/INPUTS_NEEDED.md`](docs/INPUTS_NEEDED.md) for the decisions and credentials needed to
go to production, and the proposed roadmap.
