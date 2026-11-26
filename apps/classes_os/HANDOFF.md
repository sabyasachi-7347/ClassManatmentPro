# classes.os — handoff

Flutter front end for a multi-tenant coaching institute platform.
Flutter (mobile + web) → NestJS API → Firestore via the Admin SDK. The client
never touches Firestore directly.

## Run it

```bash
cd classes_os
flutter pub get
flutter run -d chrome     # or: flutter run
```

Only one dependency: `google_fonts`. First launch fetches the three families
and caches them, so the first run needs a network connection.

The top bar is a prototype affordance — it switches between all eight roles so
you can see every screen without eight logins. It comes out when real auth
lands; see "When the API arrives" below.

## What is done

| Area | File | State |
|---|---|---|
| Colour, type, radii, motion tokens | `lib/core/tokens.dart` | Done |
| Light + dark ThemeData | `lib/core/theme.dart` | Done |
| Models | `lib/data/models.dart` | Done |
| Mock API | `lib/data/mock_data.dart` | Done |
| Bento grid, KPI, buttons, toggles, chips, skeletons | `lib/widgets/primitives.dart` | Done |
| Line / bar / ring charts (CustomPainter, no chart package) | `lib/widgets/charts.dart` | Done |
| Swipe-to-reveal rows | `lib/widgets/swipe_row.dart` | Done |
| Sheets, toasts, quick actions, roll call | `lib/widgets/sheets.dart` | Done |
| Tables | `lib/widgets/app_table.dart` | Done |
| Shell: rail, bottom nav, FAB, pull-to-refresh, tab swipe | `lib/shell/app_shell.dart` | Done |
| Command palette (⌘K / Ctrl+K) | `lib/shell/command_palette.dart` | Done |
| Super admin | `lib/features/super_admin.dart` | Done |
| System admin | `lib/features/system_admin.dart` | Done |
| Classes admin | `lib/features/classes_admin.dart` | Done |
| Drag-paint mapping matrix | `lib/features/mapping_matrix.dart` | Done |
| Entry flow (directory, OTP, login, role picker) | `lib/features/entry_flow.dart` | Done |

## What is left

Nothing from the original spec. Teacher, Student, Parent and Faculty were
ported from `classes_os_v3.jsx` and the `PendingScreen` scaffold has been
removed. The open product questions those stubs carried are listed under
"Still undecided" below.

| Area | File | State |
|---|---|---|
| Teacher: day rail, week, availability | `lib/features/teacher.dart` | Done |
| Student: home, results, syllabus, attendance | `lib/features/student.dart` | Done |
| Parent: absence banner, attendance (swipe rows), timetable | `lib/features/parent.dart` | Done |
| Faculty: modular desk, attendance, timetable grid | `lib/features/faculty.dart` | Done |

Session-only state (schedule accepted, lectures logged, absence
acknowledged, faculty modules) lives in file-level `ValueNotifier`s so it
survives tab switches. Swap these for the API repository when it lands.

## The three interactions that carry the product

**Drag-paint mapping** (`mapping_matrix.dart`). Press a cell and sweep; every
cell crossed takes the value the first one got. Enrolling a batch is one
gesture, not thirty taps, and un-enrolling works the same way because the first
cell sets the direction. Cells are located by arithmetic on the pointer
position rather than hit testing, which is why the grid uses fixed metrics
(`_cell`, `_row`, `_head`, `_nameCol`). Change those constants together.

**Roll call** (`sheets.dart`, `showRollCall`). Everyone starts present; the
teacher taps only the absentees. A 34-strong batch is two taps. Saving fires
the parent notifications.

**Absence acknowledgement** — the one real state machine in the app:

```
teacher marks absent  →  FCM push to parent  →  parent acknowledges
                                             ↘  silent after N hours → faculty chases
```

`AckState` in `models.dart` carries it. This is what forces FCM into the
stack — the single-flow architecture gives no free realtime, so push is
required rather than optional.

## The API is connected

Live mode (`lib/live/`) signs in with Firebase Auth and reads everything from the NestJS API; the
mock-data screens in `lib/features/` remain as demo mode and as the design reference. See
`README.md` for how to run, test and build.

- A user is **one identity with one membership** in the API today (`role` + `instituteId` custom
  claims). The membership picker in `entry_flow.dart` is ready for when an account can hold several.
- Owner and admin both open the classes-admin desk. Faculty, system admin and super admin have no
  API role yet and stay demo-only.
- The absence state machine is real: `absences/{batchId}_{date}_{studentId}` is opened when a roll
  call marks someone absent, pushed to parents, acknowledged by a parent, and derived as *silent*
  after `ABSENCE_SILENT_HOURS`. Re-saving a roll call never re-notifies.

## Still undecided

Carried forward from the design sessions, none of it blocking:

- Fees — never specified at all. No screen, no model, no mention.
- Leaderboard: real names or anonymised ranks?
- Does a valid session skip login on relaunch? The stated rule says login every
  time, which is unusual.
- Teacher unavailability: advance planning only, or same-day cancellation?
- Do lecture cancellations need parent acknowledgement, like absences do?
- Super Admin, System Admin, Classes Admin, Teacher, Parent and Guest each have
  a "will add more later" against them.

## Notes

- `withOpacity` is used throughout rather than `withValues(alpha:)` for
  compatibility with older Flutter. Deprecation warnings are suppressed in
  `analysis_options.yaml`; swap them if you are pinned to 3.27+.
- If a `google_fonts` family name fails to resolve, change it in `AppType`
  (`lib/core/tokens.dart`) — every call site goes through those three methods.
- Charts are hand-painted. Keeps the dependency list at one and lets the line,
  fill and end-point dot animate on the same curve as everything else.
