# Inputs needed from you

Development ran against the Firebase **emulators**, so none of these block local work. They are
needed to deploy, or to lock in product decisions I had to guess.

## 1. Firebase project (needed to deploy)

| # | What | Where it goes |
|---|---|---|
| 1 | **Firebase project ID** (create one at console.firebase.google.com, Blaze plan recommended) | `firebase/.firebaserc`, `apps/api/.env`, `apps/web/.env.local` |
| 2 | **Enable Authentication providers**: Email/Password (required), Google (optional), Phone OTP (optional — see §3) | Firebase console |
| 3 | **Create Firestore** (Native mode) + pick a **region** (e.g. `asia-south1` for India) | Firebase console |
| 4 | **Service account JSON** for the API (Project settings → Service accounts). Never commit it. | `GOOGLE_APPLICATION_CREDENTIALS` or `FIREBASE_CLIENT_EMAIL`/`FIREBASE_PRIVATE_KEY` |
| 5 | **Web app config** (apiKey, authDomain, appId) | `apps/web/.env.local` |
| 6 | **Android package name / iOS bundle ID** (currently `com.classesos.app`) and then run `flutterfire configure` in `apps/classes_os` | `apps/classes_os/lib/firebase_options.dart` (generated) |
| 7 | **APNs key** for iOS push (Apple Developer → Keys), uploaded in Firebase → Cloud Messaging | Firebase console |
| 8 | **Android release keystore** before Play Store upload (test APKs use the debug key) | `apps/classes_os/android` |

## 2. Hosting (needed to deploy)

- Where should the **NestJS API** run? Options: Google Cloud Run (recommended, same GCP project, no
  key file needed), Render/Railway, or a VPS.
- **Domain names** for web and API (e.g. `app.yourschool.com`, `api.yourschool.com`) → CORS + mobile `API_URL`.
- Web can go on Firebase Hosting (`firebase/firebase.json` is already set up for it).

## 3. Product decisions (please confirm or correct)

I assumed these. Each is easy to change now and harder later.

1. **Roles**: owner, admin, teacher, student, parent. Anything else, such as an accountant or receptionist?
2. **Login method for students/parents**: currently email + password (admin invites, gets a
   set-password link). In India, **phone OTP** is often better for parents. Should I switch?
3. **One institute per account**, with multiple branches later? Or is multi-branch needed now?
4. **Currency & fees**: amounts are whole units, formatted by locale (₹ assumed). Is the fee
   **per batch per month** (current model) right? What about one-time admission fees, discounts,
   instalments, late fees?
5. **Online payments**: Razorpay / Stripe / UPI integration, or record offline payments only (current)?
6. **Attendance statuses**: present / absent / late / excused. OK?
7. **Timezone**: "today" uses the client's local date. Single timezone (IST)?
8. **The prototype was cut off** in the message you pasted (it ended mid-CSS at `.cnt b{...`).
   Please share the **rest of the React prototype** (components/screens) so I can match every
   screen exactly. Leaderboard, swipe actions, FAB quick-actions and bottom sheets are styled but
   not yet wired to features, because I couldn't see what they were for.

## 4. Features not built yet (proposed next steps)

- ~~Tests/exams & marks → leaderboard~~ (done)
- ~~Push notifications for absence alerts~~ (done); still to do for announcements and fee reminders
- Leaderboards show other students as "Ishita R." (first name + initial). Confirm or choose anonymised ranks
- Teacher availability / "can't take this lecture" and timetable publishing (designed in the app, no API yet)
- Faculty, system-admin and super-admin roles (designed in the app, no API roles yet)
- Homework / study material uploads (Firebase Storage)
- Timetable view & holidays calendar
- Reports: attendance and fee collection exports (CSV/PDF)
- Parent–teacher messaging
- Audit log & soft-delete
- CI/CD (GitHub Actions → Cloud Run + Firebase Hosting; Fastlane for store builds)
