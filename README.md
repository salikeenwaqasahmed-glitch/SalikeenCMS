# Salik CRM (Flutter)

Mobile contact management app for Saliks with role-based gender access, editor approval workflow, bilingual EN/UR support, and Firebase backend.

## Features

### Roles and access

Three roles in app code + `gender` field on each user. Firestore `users/{uid}` must match.

| Role | Firestore `role` | Gender scope | Permissions |
|------|------------------|--------------|-------------|
| **Global Admin** | `admin` | All | Full CRUD, approve any gender, set gender on add form |
| **Gender Admin** | `genderAdmin` | Own gender | Pending queue, approve/reject, full CRUD on approved |
| **Editor** | `editor` | Own gender | Add → `pending`; read all **approved** + **own pending** on Saliks list; My Submissions for pending/rejected; no edit/delete |

Legacy `crudUser` in Firestore is treated as `editor` in the app and rules.

Gender values must be **`Male`** or **`Female`** (capital M/F).

### Editor approval workflow

```text
Editor add form → approvalStatus: pending, isActive: false
       ↓ sync (online)
Gender Admin pending queue → Approve / Reject
       ↓ approve
Main Saliks list — approved for everyone; editor also sees own pending (badge)
```

- **Saliks tab (editor)** — all approved saliks in gender scope **plus** own pending submissions (orange **Pending** badge, sorted to top)
- **My Submissions** (`/saliks/pending`) — editor: own pending + rejected; genderAdmin: all pending to review
- **Pending Approvals** — genderAdmin / admin queue with approve/reject on profile
- Profile: **Added by** on create; **Approved by** after approval

### Dashboard

- Welcome + scope banner (role/gender access)
- **Salik overview** — Total / Male / Female stat cards
- **FAB + app bar** add button (role-gated)
- Pending approvals quick action (badge count) for editor / genderAdmin / admin

### Saliks

- Directory with search, browse tabs, filter chips
- **genderAdmin / admin** — main list shows **approved** saliks only
- **editor** — main list shows **approved** + **own pending** (with status badge)
- Profile with letter avatar, call / WhatsApp (approved only)
- **Single-page add/edit form** with EN/UR toggle
- Duplicate mobile or name+father blocked on create/update (among approved saliks)
- Editors: add only; success message *Submitted for approval*

### App experience

- Bilingual UI — English + Urdu (RTL)
- Dark mode
- **Offline-first** — local SQLite (Drift) cache
- **Offline login** — five demo users pre-seeded locally; password `12345678`
- **Auto-sync** — pending changes push when online; **Sync now** in Settings

### Offline login (seed users)

Five demo accounts are **hardcoded** and written to local Drift on **every app start** — no internet required.

| Source file | Purpose |
|-------------|---------|
| [`lib/core/auth/local_user_seed.dart`](lib/core/auth/local_user_seed.dart) | Email, name, role, gender |
| [`lib/core/auth/seed_credentials.dart`](lib/core/auth/seed_credentials.dart) | Shared demo password `12345678` |
| [`lib/main.dart`](lib/main.dart) | Calls `LocalUserSeed.ensureUsers()` at startup |

Offline `uid` is `local-{email}` until first successful online login (then Firebase `uid`).

**Online sync** still needs the same email in Firebase Authentication + `users/{uid}` with matching `role`.

### Offline mode and security

- SHA-256 password hash (per-device salt) in secure storage for offline login
- **Sign out** before switching users — avoids stale Firebase session flipping role (e.g. editor → admin)
- Sync re-auth uses **only the logged-in email** — never cycles through all seed accounts
- For **online sync**, each user needs Firebase Auth + matching `users/{uid}` doc
- Treat devices with cached credentials as **trusted**

### Firebase

- **Auth** — Email/password; requires matching `users/{uid}` Firestore profile
- **Firestore collections:**
  - `saliks` — contact records (+ approval fields); **no demo saliks** — list starts empty until editors create
  - `users` — profiles (`name`, `email`, `role`, `gender`)
  - `cities`, `areas` — reference data (also bundled offline in [`reference_data.dart`](lib/core/data/reference_data.dart))
  - `meta/seeded` — one-time seed flag (cities, areas, demo Auth users on first admin login)

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.2+)
- [Firebase CLI](https://firebase.google.com/docs/cli) + [FlutterFire CLI](https://firebase.flutter.dev/docs/cli-setup/)

## Setup checklist

1. **Install dependencies**

   ```bash
   flutter pub get
   dart run build_runner build
   ```

2. **Configure Firebase**

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

3. **Enable Firebase services** in [Firebase Console](https://console.firebase.google.com):
   - Authentication → Email/Password
   - Firestore Database (production mode)

4. **Deploy Firestore security rules** (required after any rules change)

   ```bash
   firebase login
   firebase use salikeencms   # or your project id
   firebase deploy --only firestore:rules
   ```

5. **User accounts** — create in Firebase Auth + `users/{uid}` docs (see demo accounts).  
   `SeedService` also seeds **cities, areas, and demo Auth users** on first Global Admin login if `meta/seeded` is missing (does **not** seed saliks).

6. **Run the app**

   ```bash
   flutter run
   ```

## Demo accounts

All five are pre-seeded for **offline login** in local DB. Password: **`12345678`**.

| Email | Role | Gender | Notes |
|-------|------|--------|-------|
| admin@salikeen.com | `admin` | Male | Superadmin |
| maleadmin@salikeen.com | `genderAdmin` | Male | Approve + CRUD male |
| femaleadmin@salikeen.com | `genderAdmin` | Female | Approve + CRUD female |
| maleeditor@salikeen.com | `editor` | Male | Add male → pending |
| femaleeditor@salikeen.com | `editor` | Female | Add female → pending |

**Saliks:** no sample contacts are bundled. Editors add real records; genderAdmin approves.

### Production cutover (remove old demo saliks)

If you previously ran an older build that seeded sample saliks:

1. **Firestore** — delete all documents in the `saliks` collection (`salik-1` … `salik-6` and any test UUIDs). Keep `users`, `cities`, `areas`.
2. **Browsers / devices** — if stale saliks still appear: clear site data (Chrome: DevTools → Application → Clear site data) or clear app storage, then reload. Offline users re-seed from `LocalUserSeed`; saliks stay empty.

### Firebase setup per user (required for online sync)

For each account:

1. **Authentication** → Add user (email + password)
2. **Firestore** → `users/{uid}`:

```json
{
  "email": "maleeditor@salikeen.com",
  "name": "Male Editor",
  "role": "editor",
  "gender": "Male"
}
```

Use `genderAdmin` or `admin` for other roles. **Do not** set `role: admin` on editor accounts.

### Multiple people, same role

Same role is fine — different **email** + **name** per person. Audit trail uses `addedByUid` / `addedByName` on saliks and `approvedByUid` / `approvedByName` on approve.

## Building APK for QA

Do **not** share `app-debug.apk` (~150 MB) via WhatsApp — MIUI installer often crashes.

```bash
flutter build apk --split-per-abi --release
```

Send **`app-arm64-v8a-release.apk`** (~24 MB) for most modern phones:

`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

## Salik document fields (reference)

| Field | Description |
|-------|-------------|
| `genderId` | `Male` / `Female` |
| `cityId`, `areaId` | Location refs |
| `referenceName` | Optional reference person name |
| `dateOfBaith` | ISO date string |
| `isNafiAsbat`, `isSahibEMehfil` | Spiritual flags |
| `mobileNumber`, `whatsappNumber` | Contact numbers |
| `isActive` | `false` while pending; `true` when approved |
| `approvalStatus` | `pending` \| `approved` \| `rejected` |
| `addedByUid`, `addedByName` | Who submitted (editors) |
| `approvedByUid`, `approvedByName`, `approvedAt` | Who approved/rejected and when |

Legacy fields (`bazamId`, `khanqahId`, etc.) may exist on old docs; the app no longer reads or writes them.

## Approval workflow (offline-first)

```
Editor        → local save (pending) → if online → Firestore pending
genderAdmin   → see pending queue   → approve local → if online → Firestore approved
admin         → all genders, same as genderAdmin + delete any gender
```

| Step | Local DB | Firestore (when online) |
|------|----------|-------------------------|
| Editor submit | `approvalStatus: pending`, `isActive: false` | Same |
| genderAdmin approve | `approved` + approver fields | Patch `approvalStatus`, `approvedBy*`, `isActive: true` |
| Offline | Queued in sync table | Pushed on next **Sync now** |

## Firestore rules summary

| Action | admin | genderAdmin | editor |
|--------|-------|-------------|--------|
| Read saliks | All genders | Own gender (pending + approved) | Own gender |
| Create salik | `approved` direct | `approved` direct | `pending` + `isActive: false` only |
| Approve/reject | Any gender pending | Own gender pending | **No** |
| Update approved | Yes | Own gender | **No** |
| Delete salik | Yes | Own gender | **No** |

Editor **cannot** update or delete after submit.

Rules file: [`firestore.rules`](firestore.rules) — deploy after changes:

```bash
firebase deploy --only firestore:rules
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `PERMISSION_DENIED` | Deploy Firestore rules |
| Editor login then shows **admin** | Log out fully; reinstall latest APK; check Firestore `role` is `editor`; sign out before switching users |
| Editor pending not in list | Rebuild latest APK; pending matched by uid / `local-{email}` / name |
| Editor sync fails | Create Firebase Auth user + `users/{uid}` with `role: editor` |
| Package installer keeps stopping (Xiaomi) | Use `app-arm64-v8a-release.apk`, not debug APK; avoid WhatsApp if possible |
| Duplicate mobile error | Same mobile already registered among approved saliks in scope |
| Offline login fails | Use seeded email + `12345678`, or login online once |
| Pending sync not clearing | Settings → Sync now when online; verify rules deployed |
| Old saliks missing from list | Migration sets existing rows to `approved`; full app restart after DB upgrade |
| Demo saliks reappear after clear | Delete Firestore `saliks` docs; rebuild app (no `kInitialSaliks`); clear browser/app storage |

## Development

```bash
flutter analyze lib
flutter test
flutter run
```

After Drift schema changes:

```bash
dart run build_runner build
```

Full app restart required after local DB migration (schema v3+).
