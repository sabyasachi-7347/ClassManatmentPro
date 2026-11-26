# classes.os — Flutter app

The app for teachers, students, parents and institute owners/admins: Android, iOS and web.
Design and screen history are in [`HANDOFF.md`](HANDOFF.md).

It runs in one of two modes:

| Mode | When | What you get |
|---|---|---|
| **Live** | Firebase is configured (or `USE_EMULATORS=true`) | Sign in, and the app opens the one role your account holds, with real data from the NestJS API |
| **Demo** | `--dart-define=DEMO=true`, or Firebase not configured yet | Mock data and a role switcher across all eight roles. Good for design review |

## What is live

| Role (API) | Screen | Live features |
|---|---|---|
| `teacher` | Teacher | Today's lectures on the day rail, **roll call** (saves attendance, raises absence alerts), edit a roll call, **log syllabus coverage**, next 7 days, today's absences + nudge |
| `parent` | Parent | **Absence banner → "I've seen this"** (acknowledges), attendance by month, missed lectures, results, rank, progress chart, leaderboard, timetable; switch between children |
| `student` | Student | Rank, attendance ring, score trend vs batch average, leaderboard, results, syllabus, attendance |
| `owner` / `admin` | Classes admin desk | Today's attendance %, absence alerts with acknowledgement status + nudge, "needs you", syllabus coverage, batches, **drag-to-enrol mapping** (saves), people, **tests: create and enter marks** |

Super admin, system admin and faculty have no backend role yet, so they exist in demo mode only.
Creating batches, students and invites is done on the web app (`apps/web`).

## 1. Test locally (no Firebase project needed)

Run everything on your computer against the Firebase emulators. From the repo root:

```bash
npm install
npm run emulators                                     # terminal 1
cp apps/api/.env.example apps/api/.env && npm run dev:api   # terminal 2
npm run seed -w apps/api                              # terminal 3: fills a demo institute (wipes emulator data)
```

Then run the app:

```bash
cd apps/classes_os
flutter pub get
flutter run -d chrome --dart-define=USE_EMULATORS=true    # web
flutter run --dart-define=USE_EMULATORS=true              # Android emulator (reaches your PC at 10.0.2.2)
```

For Chrome, add `http://localhost:<port>` to `CORS_ORIGINS` in `apps/api/.env`, or run Chrome with a
fixed port: `flutter run -d chrome --web-port 8765 ...` and set
`CORS_ORIGINS=http://localhost:5173,http://localhost:8765`.

**Seeded accounts** (password `secret123` for all):

| Email | Role | Try |
|---|---|---|
| `teacher@demo.test` | Teacher | Take the live lecture's roll call, mark someone absent |
| `parent@demo.test` | Parent of Aarav + Sara | See the absence banner, tap "I've seen this" |
| `student@demo.test` | Student (Aarav) | Rank, results, leaderboard |
| `owner@demo.test` | Owner | Watch the acknowledgement turn green on the overview; enrol; enter marks |

The seed places today's lectures around the current time, so the teacher always has one finished,
one live and one upcoming.

### On a real phone against your computer

The phone and computer must be on the same Wi-Fi. Find your computer's LAN IP (e.g. `192.168.1.20`), then:

```bash
# start the emulators listening on all interfaces
cd firebase && firebase emulators:start --project demo-classes-os --only auth,firestore
# (set "host": "0.0.0.0" for auth and firestore in firebase/firebase.json first)

flutter run --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=192.168.1.20
```

## 2. Build against a real Firebase project (for testers)

1. Create the Firebase project and enable **Email/Password** sign-in (see `docs/INPUTS_NEEDED.md`).
2. Register the apps and generate the config. Android package: **`com.classesos.app`**.
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<firebase-project-id>
   ```
   This overwrites `lib/firebase_options.dart`, and the app switches to live mode.
3. Deploy the API (e.g. Cloud Run) and pass its URL at build time:
   ```bash
   flutter build apk --release --dart-define=API_URL=https://api.example.com/api/v1
   flutter build appbundle --release --dart-define=API_URL=https://api.example.com/api/v1   # Play Store
   flutter build ipa --release --dart-define=API_URL=https://api.example.com/api/v1          # iOS, on a Mac
   ```
   The APK lands in `build/app/outputs/flutter-apk/app-release.apk`. Install it with
   `adb install` or share it via Firebase App Distribution.
4. Create accounts: the owner signs up on the web app and creates the institute, then invites
   teachers, parents and students. Each invite returns a set-password link.

> Release builds are signed with the **debug key** unless `android/key.properties` exists (see
> [CI builds](#ci-builds-github-actions)). That's fine for sideloaded test builds; add a real
> keystore before uploading to the Play Store.

### Push notifications (absence alerts)

Push is wired end to end: after sign-in the app registers its FCM token (`POST /me/devices`), and
the API pushes to a student's parents when a teacher marks them absent and when staff nudge.

- **Android:** works once `flutterfire configure` has run. Android 13+ asks for the permission on first sign-in.
- **iOS:** needs an APNs key uploaded in Firebase console → Project settings → Cloud Messaging,
  plus the *Push Notifications* and *Background Modes → Remote notifications* capabilities in Xcode.
- **Web and emulators:** skipped. There's no FCM emulator; the API logs "push skipped" instead.

A parent without the app still gets an alert record. It shows as *Waiting*, then *Silent* after
`ABSENCE_SILENT_HOURS` (default 3) on the staff screens, so someone can call.

## CI builds (GitHub Actions)

[`.github/workflows/flutter-app.yml`](../../.github/workflows/flutter-app.yml) runs analyze + tests,
then builds a release **APK**, an **App Bundle** and the **web** build. It runs when:

- a push to the default branch (or `main`) or a pull request touches `apps/classes_os/` (artifacts on the run page, kept 30 days)
- you start it by hand from **Actions → Flutter app build → Run workflow**, where you can set the
  API URL or make a demo build
- you push a tag like `app-v0.1.0`, which also creates a **GitHub Release** with the APK, AAB and web zip

**Getting the APK**

- **Latest build, direct link:** every push to the default branch replaces the `latest-apk`
  pre-release, so the newest APK is always at
  `https://github.com/sabyasachi-7347/ClassManatmentPro/releases/download/latest-apk/classes-os.apk`
  (also listed under **Releases**).
- **Any run (including PRs):** open the run under **Actions**, scroll to *Artifacts*, download
  **classes-os-<run>.apk**. It downloads as the APK itself, not a zip. The Play Store bundle is
  **classes-os-aab** (zipped).
  Artifacts are kept 30 days.

The build number is the workflow run number, so each new APK installs over the previous one.

Optional settings (repo **Settings → Secrets and variables → Actions**):

| Name | Kind | What it does |
|---|---|---|
| `API_URL` | variable | API URL baked into builds (`--dart-define=API_URL=…`) |
| `FIREBASE_OPTIONS_DART` | secret | `base64 -w0 lib/firebase_options.dart`, if you don't commit that file |
| `ANDROID_KEYSTORE_BASE64` | secret | `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | secrets | keystore credentials |

Without the keystore secrets, release builds are debug-signed (fine for sideloading, not for the
Play Store). Create a keystore with
`keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
Locally, the same signing works by creating `android/key.properties` (git-ignored) with
`storeFile`, `storePassword`, `keyAlias`, `keyPassword`.

Without Firebase config, CI builds start in demo mode.

## 3. Checks

```bash
flutter analyze
flutter test          # live-model parsing, lecture timing, week builder
```

## Layout

```
lib/
  main.dart            picks live or demo mode
  firebase_options.dart  generated by flutterfire (placeholder until then)
  live/                everything that talks to the API
    config.dart          --dart-define settings (API_URL, USE_EMULATORS, EMULATOR_HOST, DEMO)
    api_client.dart      Dio + Firebase ID token
    live_models.dart     API response shapes
    live_store.dart      loads a role's data, actions (roll call, ack, enrol, marks…)
    auth_gate.dart       login, /me, role routing, sign-out
    push.dart            FCM registration
    live_*.dart          the live screens per role
  features/            demo screens (mock data) — also the design reference
  shell/ widgets/ core/  shared shell, components and design tokens
```
