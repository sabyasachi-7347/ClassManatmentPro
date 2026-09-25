# CLASSES.OS — mobile (Flutter)

For teachers (take attendance, notices), students and parents (dashboard, classes, fees, notices), and
owners/admins on the go.

```
lib/
  main.dart               Firebase init (+ Auth emulator when USE_EMULATORS=true)
  app.dart                go_router with auth / onboarding redirects, theming
  firebase_options.dart   PLACEHOLDER: replace via `flutterfire configure`
  core/                   config, Dio API client (adds ID token), models, Riverpod providers, theme tokens
  features/               dashboard, attendance, batches, fees, announcements, more, auth
  widgets/os_widgets.dart CLASSES.OS building blocks (FeatureCard, StatTile, Pill, …)
```

## Run against local emulators

```bash
flutter pub get
flutter run --dart-define=USE_EMULATORS=true
```

Android emulators reach your machine at `10.0.2.2`, which the app handles. Debug builds allow cleartext
HTTP (`android/app/src/debug/AndroidManifest.xml`) and iOS allows local networking (`Info.plist`).

## Run against a real Firebase project

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<firebase-project-id>   # generates lib/firebase_options.dart
flutter run --dart-define=API_URL=https://api.example.com/api/v1
```

Institutes are created on the web app. Mobile users sign in with the account an admin invited.
