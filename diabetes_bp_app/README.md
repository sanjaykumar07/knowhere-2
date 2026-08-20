# Diabetes & Hypertension Manager (Flutter + Firebase Prototype)

Single Flutter mobile app. Dart for the frontend/logic, Firebase
(Authentication + Cloud Firestore) for the backend. The "IoT" glucometer
and BP monitor are simulated Dart modules inside the app — there is no
physical hardware in this prototype.

## 1. Install prerequisites (one-time, on your computer)

1. **Flutter SDK** — install from https://docs.flutter.dev/get-started/install
   and confirm it works:
   ```bash
   flutter --version
   flutter doctor
   ```
   Resolve anything `flutter doctor` flags as missing (Android SDK, Xcode,
   etc.) for whichever platform you'll run on. For a first test, running on
   **Chrome** (`flutter run -d chrome`) needs nothing extra.

2. **VS Code** — install the **Flutter** extension (it pulls in the Dart
   extension automatically). Command Palette → `Extensions: Install
   Extensions` → search "Flutter".

3. **Node.js** (needed only for the Firebase/FlutterFire CLIs) —
   https://nodejs.org (LTS version).

## 2. Open the project in VS Code

1. Unzip the project you downloaded.
2. `File → Open Folder…` → select the `diabetes_bp_app` folder (the one
   containing `pubspec.yaml`).
3. Open a terminal in VS Code (`` Ctrl+` ``) and run:
   ```bash
   flutter pub get
   ```
   This downloads all packages listed in `pubspec.yaml` (Firebase, fl_chart,
   provider, intl, uuid, etc.).

At this point the app will **not run yet** — it needs a real Firebase
project connected. That's step 3.

## 3. Firebase setup (this is the part that "connects everything")

### 3a. Create the Firebase project
1. Go to https://console.firebase.google.com → **Add project** → name it
   (e.g. `diabetes-bp-app`) → finish the wizard (Google Analytics is
   optional, you can skip it).

### 3b. Turn on Authentication
1. In the Firebase console: **Build → Authentication → Get started**.
2. Under **Sign-in method**, enable **Email/Password**.

### 3c. Create the Firestore database
1. **Build → Firestore Database → Create database**.
2. Choose **Start in production mode** (we'll deploy proper rules in
   step 3f) and pick a region close to you.

### 3d. Connect your Flutter app to this Firebase project
This is the step that generates `lib/firebase_options.dart` for real —
replacing the placeholder file already in the project.

In the VS Code terminal, from the `diabetes_bp_app` folder:
```bash
dart pub global activate flutterfire_cli
npm install -g firebase-tools
firebase login
flutterfire configure
```
`flutterfire configure` will:
- ask you to pick the Firebase project you just created,
- ask which platforms to support (choose at least `android` and/or
  `ios`, or `web` for the quickest first test),
- automatically rewrite `lib/firebase_options.dart` with your project's
  real API keys, and register the app in the Firebase console for you.

You do not need to hand-edit `firebase_options.dart` — the CLI does it.

### 3e. (Android only) Extra file
If you selected Android, `flutterfire configure` also downloads
`android/app/google-services.json` for you automatically — nothing to do
manually. If you add Android support later, just re-run `flutterfire
configure`.

### 3f. Deploy the security rules
The project already includes `firestore.rules`, which restricts every
patient to only reading/writing their own data (matched on their Firebase
UID). Deploy it:
```bash
firebase init firestore   # first time only — point it at this project,
                           # and when asked for the rules file, keep the
                           # existing firestore.rules
firebase deploy --only firestore:rules
```

## 4. Run the app

In VS Code: open `lib/main.dart`, then press **F5** (or use the Run and
Debug panel) and pick a target device — or from the terminal:
```bash
flutter run -d chrome     # fastest way to see it working
# or
flutter run                # runs on a connected phone/emulator
```

## 5. Try the flow end-to-end

1. **Sign Up for Free** → fill in account info, health profile, and
   (optionally) medications → this calls `AuthService.signUp` (creates the
   Firebase Auth account + UID) then `FirestoreService.createUserProfile`
   (writes the profile to `users/{uid}`).
2. You land on the **Dashboard**.
3. Tap **Update My Glucose** → pick a measurement type and scenario → **Generate
   Reading** → **Save Reading**. This calls `GlucoseSimulator.generateReading`
   then `FirestoreService.saveGlucoseReading`, writing to
   `users/{uid}/glucoseReadings/{id}`. The dashboard card updates
   immediately because it's built on a Firestore `StreamBuilder`.
4. Same idea for **Update My BP**.
5. Add a medication (or during sign-up) → mark it **Taken** / **Not Taken**
   on the dashboard's medication list → check **History → Adherence** to see
   the weekly % calculated from `medicationLogs`.
6. Use the **feeling/symptom buttons** on the dashboard (no typing) →
   **Save Check-In**.
7. **History & Trends** shows glucose and BP line charts (via `fl_chart`)
   plus the medication adherence percentage.

## Project structure

```
lib/
├── main.dart                     # App entry point, Firebase init, auth routing
├── firebase_options.dart         # Generated by `flutterfire configure`
├── models/                       # Plain Dart data classes + Firestore (de)serialization
├── screens/
│   ├── auth/                     # Login, Sign Up
│   ├── patient/                  # Dashboard, Glucose, BP, Medication, History, Profile
│   └── doctor/                   # Minimal clinician view (future work)
├── services/
│   ├── auth_service.dart         # Firebase Authentication wrapper
│   ├── firestore_service.dart    # ALL Firestore reads/writes go through here
│   ├── glucose_simulator.dart    # Simulated IoT glucometer
│   ├── bp_simulator.dart         # Simulated IoT BP monitor
│   └── notification_service.dart # In-app threshold-based alerts
└── widgets/                      # Reusable UI pieces (cards, chart, selectors)
```

## Notes on what's simulated vs. real

- **Real:** Firebase Authentication, Cloud Firestore storage, the
  real-time dashboard updates, charts, medication adherence calculation.
- **Simulated:** the glucometer and BP monitor. `glucose_simulator.dart`
  and `bp_simulator.dart` generate plausible values inside configurable
  scenario ranges (Normal / Elevated / High) rather than fully random
  numbers, tag every reading with `source: "simulated_glucometer"` /
  `"simulated_bp_monitor"`, and the UI always labels them as a
  "Simulated Device." To move to real hardware later, only those two
  files need to be replaced with actual BLE reads — the Firestore schema
  and the rest of the app stay the same.

## Troubleshooting

- **`flutter doctor` shows issues** → fix those first; most `flutter run`
  problems trace back here.
- **"Firebase has not been correctly initialized"** → you skipped step 3d;
  run `flutterfire configure` from the project root.
- **Permission-denied errors from Firestore** → you skipped step 3f
  (deploying `firestore.rules`), or you're not logged in.
- **iOS build issues on Windows/Linux** → iOS builds require macOS + Xcode;
  use `flutter run -d chrome` or an Android emulator instead.
