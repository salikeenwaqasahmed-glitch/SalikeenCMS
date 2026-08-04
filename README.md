# Salikeen CMS (Flutter)

Mobile contact management for Saliks with role-based gender access, editor approval workflow, bilingual EN/UR support, offline-first sync, and Firebase backend.

## Features

### Roles and access

Three roles in app + `gender` on each `users/{uid}` doc. Firestore must match.

| Role | Firestore `role` | Gender scope | Permissions |
|------|------------------|--------------|-------------|
| **Global Admin** | `admin` | All | Full CRUD, approve any gender, delete any gender, duplicate cleanup |
| **Approval** | `approval` | Own gender | Pending queue, approve/reject, CRUD on approved, duplicate cleanup (own gender) |
| **Editor** | `editor` | Own gender | Add → `pending`; read approved + own pending; no edit/delete after submit |

Legacy values: `genderAdmin` → `approval`, `crudUser` → `editor`.

Gender must be **`Male`** or **`Female`**.

### Editor approval workflow

```text
Editor add form → approvalStatus: pending, isActive: false
       ↓ sync (online)
Approval pending queue → Approve / Reject
       ↓ approve
Main Saliks list — approved for everyone; editor also sees own pending (badge)
```

- **Saliks tab (editor)** — approved in gender scope + own pending (orange badge)
- **My Submissions** (`/saliks/pending`) — editor: own pending/rejected; approval/admin: queue to review
- **Duplicate Data** (`/saliks/duplicates`) — approval + admin only; merge or delete duplicate saliks

### Duplicate data (approval + admin)

Duplicates detected when records share:

- same mobile number, or
- same English name + father's name, or
- same Urdu name + father's name

Open **Saliks → copy icon** → pick **Keep this record** → **Merge & remove others** (fills empty fields on keeper, deletes rest) or delete individual rows.

### Dashboard

- Welcome + scope banner (role/gender)
- Salik overview — Total / Male / Female
- FAB + app bar add (role-gated)
- Pending quick action with badge

### Saliks

- Directory with search, browse tabs, filter chips
- **20 per page** with Prev / Next pager
- Search ranks **name/father** matches first, then **reference**, then mobile/address
- List sorted by name (locale-aware EN/UR)
- **Settings → Import & Export** — import contacts, export all CSV
- **Saliks → Export** — select on directory list → CSV of picked only
- **Saliks → Message** — select on directory list (filters apply) → WhatsApp or SMS → one-by-one Send/Skip
- **approval / admin** — main list shows **approved** saliks (gender-scoped for approval)
- **editor** — approved + own pending with status badge
- Profile with avatar, call / WhatsApp (approved); area shown as one field (`English / Urdu` when both exist)
- Single-page add/edit form with EN/UR fields
- Delete (admin/approval) removes from live `saliks` and archives to Firestore `delete_saliks` (not hard-erased)
- Duplicate mobile or name+father blocked on create/update/approve (among approved)
- Editors: add only; message *Submitted for approval*

### App experience

- Bilingual UI — English + Urdu (RTL)
- Dark mode
- **Offline-first** — SQLite (Drift) cache + sync queue
- **Offline login** — after first online Firebase login; user + roster cached in Drift
- **Manual sync only** — Settings → **Sync now** (no pull-to-refresh / no auto hydrate)
- Launcher icon from `android/app/src/main/res/` (also used in-app + web/iOS)

### Environments (dev vs prod)

| Build | Firebase project | Staff email domain |
|-------|------------------|--------------------|
| **dev** | `salikeencms` | `@dev.cms.com` |
| **prod** | `salikeencms-prod` | `@cms.com` |

`APP_ENV` dart-define + Android flavor must match (`dev`/`dev`, `prod`/`prod`). Default is **dev** so `flutter run` never hits prod by accident.

Optional shared PII crypto key (all installs + .NET must match):

`--dart-define=FIELD_CRYPTO_KEY_BASE64=<32-byte-base64>`

Dev builds show **Dev App** chip on splash, login, and settings. Prod builds show no env badge.

### Offline login (CMS staff)

On the login screen, enter **username only** (local part). Field stays blank (no hint, no `@domain` suffix). App appends the domain on submit (e.g. `madmin` → `madmin@dev.cms.com` on dev).

**Accounts live only in Firebase Auth + Firestore `users/{uid}`** — create them in Firebase Console (or your backend). No staff list or passwords are hardcoded in the app.

First login on a device **requires internet**: Firebase Auth + profile read, then password hash and the users roster are cached in Drift. Later logins work offline for that account. Unknown user + offline → blocking dialog ("Internet required").

Profile fields on `users/{uid}`: `name`, `email`, `role`, `gender` (`Male` / `Female`). Roles: `admin`, `approval`, `editor`.

### Offline mode and security

- SHA-256 password hash (per-device salt) for offline login
- **Sign out** before switching users — avoids stale Firebase session
- Session stays until **Sign out** (no idle auto-logout)
- Sync re-auth uses logged-in email only
- Devices with cached credentials are **trusted**
- **Firestore PII encryption** — AES-256-GCM client-side on push for name, father, phones, address, reference, notes. Drift local DB stays plaintext (search/sort). Org key stored in Drift `local_app_kv` only (never Firestore). Seed shared key with `--dart-define=FIELD_CRYPTO_KEY_BASE64=<32-byte-base64>` (same string for .NET). Without dart-define, app generates a per-install key. Legacy plaintext docs decrypt as-is until next push. Delete old Console docs `meta/fieldCrypto` and `users/*/private/fieldKey` if present.
- **Contact import** — Settings → Import & Export; requires `READ_CONTACTS` / `NSContactsUsageDescription`; name + primary phone
- **Export saliks** — Saliks → export icon → select rows → CSV share; Settings still exports all role-scoped
- **Message saliks** — Saliks → select → channel/template → auto one-by-one open chats (return to app for next; Skip/Done)

### Local-first sync

- Browse reads Drift only (no live Firestore listeners)
- Saves enqueue outbox locally (no auto push/pull)
- Settings **Sync now** → full push + pull
- Offline / reopen → last cached Drift data

### Firebase

- **Auth** — Email/password; `users/{uid}` profile required for rules
- **Android** — Firebase keys live in flavor `google-services.json` only (`android/app/src/dev|prod/`). Dart `firebase_options_*.dart` is **web only**; Android calls `Firebase.initializeApp()` without Dart options.
- **Firestore collections:**
  - `saliks` — contacts + approval fields
  - `users` — `name`, `email`, `role`, `gender`
  - `bazams` — bazam reference (default `i-10` / I-10); areas belong to a bazam via `bazamId`
  - `areas` — area reference data + `bazamId` (also in [`reference_data.dart`](lib/core/data/reference_data.dart))
  - `meta/seeded` — areas seeded once
  - `meta/bazamsSeeded` — bookkeeping flag; default bazams are upserted on every admin online login

On **admin** online login, `SeedService` seeds areas once (`meta/seeded`) and always upserts default bazams (background; login is not blocked). Data sync/pull only when user taps **Sync** (bottom nav or Settings).

**Dashboard:** bazam cards. Tap a bazam → Bazam screen lists all that bazam’s areas → tap area → saliks filtered by area.

**Assign areas to bazams later:** set `areas/{areaId}.bazamId` in Firestore (or backend). New local areas default to `i-10`. Salik saves denormalize `bazamId` from the selected area.

**Add a new bazam in Firebase Console:**

1. Collection `bazams` → add document. Document ID = bazam id (e.g. `g-9`).
2. Fields: `bazamId` (string, same as doc id), `bazamName` (string, display name).
3. For each area in that bazam, set `areas/{areaId}.bazamId` to the new id.
4. Sync (bottom nav **Sync**) or log in online — app pulls `bazams` + areas into local Drift; dashboard bazam cards update automatically.

Default `kBazams` (e.g. `i-10` / I-10) are upserted to Firestore on every **admin** online login (`SeedService`).

**Re-seed canonical areas** (Gulshan, Model Town, etc. from `kAreas` in [`reference_data.dart`](lib/core/data/reference_data.dart)):

1. In Firebase Console → Firestore → delete document `meta/seeded` (dev and/or prod as needed).
2. Optionally clear stale `areas` docs if you want a clean slate.
3. Log in online as **admin** — `SeedService.seedIfNeeded()` writes `kAreas` to Firestore once.
4. Pull-to-sync on any device (or restart app online) — sync prunes ghost local areas not on Firestore, then pulls fresh docs.

Local Drift cache is pruned on sync: `synced` areas missing from Firestore are removed; `pendingCreate` rows are kept until push succeeds.

Deploy the same [`firestore.rules`](firestore.rules) to **both** Firebase projects (dev + prod).

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.2+)
- [Firebase CLI](https://firebase.google.com/docs/cli) + [FlutterFire CLI](https://firebase.flutter.dev/docs/cli-setup/)

## Setup checklist

1. **Install dependencies**

   ```bash
   flutter pub get
   dart run build_runner build
   ```

2. **Configure Firebase** (already generated in repo; re-run if projects change)

   ```bash
   dart pub global activate flutterfire_cli
   # Android keys live in flavor google-services.json (not Dart).
   flutterfire configure --project=salikeencms --out=lib/firebase_options_dev.dart --platforms=web --yes
   flutterfire configure --project=salikeencms-prod --out=lib/firebase_options_prod.dart --platforms=web --yes
   # Copy/regenerate android/app/src/dev|prod/google-services.json from Firebase console per flavor.
   ```

3. **Enable Firebase services** in both consoles:
   - [salikeencms (dev)](https://console.firebase.google.com/project/salikeencms) — Authentication → Email/Password, Firestore
   - [salikeencms-prod](https://console.firebase.google.com/project/salikeencms-prod) — same

4. **Deploy Firestore security rules** to both projects

   ```bash
   firebase login
   firebase deploy --only firestore:rules --project salikeencms
   firebase deploy --only firestore:rules --project salikeencms-prod
   ```

5. **Create staff in Firebase** — Authentication (email/password) + Firestore `users/{uid}` with `name`, `email`, `role`, `gender`. No in-app roster.

6. **Run the app (dev default)**

   ```bash
   flutter run --flavor dev --dart-define=APP_ENV=dev
   ```

## Staff accounts (Firebase only)

Create each staff user in Firebase Console:

1. Authentication → Add user (email + password)
2. Firestore → `users/{uid}` matching Auth uid:

```json
{
  "email": "naveed@cms.com",
  "name": "Naveed",
  "role": "editor",
  "gender": "Male"
}
```

Use `approval` or `admin` for other roles. Login domain: `@dev.cms.com` (dev) or `@cms.com` (prod).

**Saliks:** no sample contacts bundled. Editors add records; approval approves.

### Multiple people, same role

Different **email** + **name** per person. Audit: `addedByUid` / `addedByName`, `approvedByUid` / `approvedByName`.

## Building APK

Single universal APK per environment (no `--split-per-abi`).

**Dev / QA** (`salikeencms`):

```bash
flutter build apk --flavor dev --dart-define=APP_ENV=dev --release
```

Output: `build/app/outputs/flutter-apk/app-dev-release.apk`

**Production** (`salikeencms-prod`):

```bash
flutter build apk --flavor prod --dart-define=APP_ENV=prod --release
```

Output: `build/app/outputs/flutter-apk/app-prod-release.apk`

`--dart-define=APP_ENV=prod` is required for prod Firebase project; flavor alone is not enough.

## Salik document fields (reference)

| Field | Description |
|-------|-------------|
| `genderId` | `Male` / `Female` |
| `areaId` | Area reference (dropdown) |
| `address` | Free-text address (1–50 chars; required) |
| `referenceName` | Optional reference person |
| `dateOfBaith` | ISO date string |
| `isNafiAsbat`, `isSahibEMehfil` | Spiritual flags |
| `mobileNumber`, `whatsappNumber` | Contact numbers |
| `isActive` | `false` while pending; `true` when approved |
| `approvalStatus` | `pending` \| `approved` \| `rejected` |
| `addedByUid`, `addedByName` | Who submitted |
| `approvedByUid`, `approvedByName`, `approvedAt` | Approval decision |

## Approval workflow (offline-first)

```
Editor    → local save (pending) → if online → Firestore pending
approval  → pending queue        → approve local → if online → Firestore approved
admin     → all genders + delete any gender + duplicate tools
```

| Step | Local DB | Firestore (when online) |
|------|----------|-------------------------|
| Editor submit | `pending`, `isActive: false` | Same |
| Approve | `approved` + approver fields | Patch approval fields |
| Offline | Sync queue | Pushed on **Sync now** |

## Firestore rules summary

| Action | admin | approval | editor |
|--------|-------|----------|--------|
| Read saliks | All genders | Own gender | Own gender |
| Create salik | `approved` direct | `approved` direct | `pending` only |
| Approve/reject | Any gender | Own gender | No |
| Update approved | Yes | Own gender | No |
| Delete salik | Yes | Own gender | No |

**Location validation** (`validSalikLocation`): writes need non-empty `areaId` + `address` (1–50 chars). No `cityId`.

Rules file: [`firestore.rules`](firestore.rules). Deploy to both projects:

```bash
firebase deploy --only firestore:rules --project salikeencms
firebase deploy --only firestore:rules --project salikeencms-prod
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `PERMISSION_DENIED` on salik save | Deploy rules; saliks need `areaId` + `address` (1–50 chars) |
| `PERMISSION_DENIED` (other) | Verify `users/{uid}` exists with correct `role` + `gender` |
| Login spinner stuck | Hot restart; ensure online; area seed runs in background after admin login |
| Wrong role after login | Sign out; check Firestore `users/{uid}.role`; clear app data if stale offline cache |
| Editor pending missing | Rebuild app; pending matched by Firebase `uid` / `local-{email}` |
| Duplicate mobile on save | Same mobile exists among approved saliks — use **Duplicate Data** to merge |
| Offline login fails | First login needs internet; then cached account works offline |
| Pending sync not clearing | Settings → Sync now when online |
| `users/{uid}` missing | Create Auth user + Firestore profile in Console; then login online once |

## Development

```bash
flutter analyze lib
flutter test
flutter run --flavor dev --dart-define=APP_ENV=dev
```

After Drift schema changes:

```bash
dart run build_runner build
```

Full app restart after local DB migration.
