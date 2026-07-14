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
- **approval / admin** — main list shows **approved** saliks (gender-scoped for approval)
- **editor** — approved + own pending with status badge
- Profile with avatar, call / WhatsApp (approved)
- Single-page add/edit form with EN/UR fields
- Duplicate mobile or name+father blocked on create/update/approve (among approved)
- Editors: add only; message *Submitted for approval*

### App experience

- Bilingual UI — English + Urdu (RTL)
- Dark mode
- **Offline-first** — SQLite (Drift) cache + sync queue
- **Offline login** — CMS staff pre-seeded locally per environment (dev vs prod passwords)
- **Auto-sync** — background sync after login; **Sync now** in Settings
- Launcher icon from `android/app/src/main/res/` (also used in-app + web/iOS)

### Environments (dev vs prod)

| Build | Firebase project | Staff emails | Password |
|-------|------------------|--------------|----------|
| **dev** | `salikeencms` | `*@dev.cms.com` (see table) | `12345678` |
| **prod** | `salikeencms-prod` | `*@cms.com` | `cms@1234` |

`APP_ENV` dart-define + Android flavor must match (`dev`/`dev`, `prod`/`prod`). Default is **dev** so `flutter run` never hits prod by accident.

Dev builds show **Dev App** chip on splash, login, and settings. Prod builds show no env badge.

### Offline login (CMS staff)

On the login screen, enter **username only** (local part). The app appends the domain automatically:

| Env | Type | Full email |
|-----|------|------------|
| dev | `madmin` | `madmin@dev.cms.com` |
| prod | `sarkar` | `sarkar@cms.com` |

The suffix (`@dev.cms.com` or `@cms.com`) is shown in the email field. You can still paste a full email if needed.

Staff rosters: [`staff_users_dev.dart`](lib/core/auth/staff_users_dev.dart) and [`staff_users_prod.dart`](lib/core/auth/staff_users_prod.dart), selected at compile time via [`app_config.dart`](lib/core/config/app_config.dart). Written to local Drift on app start via [`local_user_seed.dart`](lib/core/auth/local_user_seed.dart). Passwords in [`seed_credentials.dart`](lib/core/auth/seed_credentials.dart).

Offline `uid` is `local-{email}` until online login binds Firebase Auth `uid` → `users/{uid}` in Firestore + local cache.

**Online** still needs Firebase Auth + matching `users/{uid}` (`name`, `email`, `role`, `gender`).

### Offline mode and security

- SHA-256 password hash (per-device salt) for offline login
- **Sign out** before switching users — avoids stale Firebase session
- Sync re-auth uses logged-in email only
- Devices with cached credentials are **trusted**

### Firebase

- **Auth** — Email/password; `users/{uid}` profile required for rules
- **Android** — Firebase keys live in flavor `google-services.json` only (`android/app/src/dev|prod/`). Dart `firebase_options_*.dart` is **web only**; Android calls `Firebase.initializeApp()` without Dart options.
- **Firestore collections:**
  - `saliks` — contacts + approval fields
  - `users` — `name`, `email`, `role`, `gender`
  - `cities`, `areas` — reference data (also in [`reference_data.dart`](lib/core/data/reference_data.dart))
  - `meta/seeded` — cities/areas seeded once
  - `meta/staffProvisioned` — CMS Auth + user profiles provisioned once

On first **admin** online login, `SeedService` seeds cities/areas (if needed) and provisions all CMS staff in Firebase Auth + `users/{uid}` (background; login is not blocked).

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

5. **Staff accounts** — log in once as admin online so `SeedService` provisions the roster:
   - **Dev:** `madmin@dev.cms.com` / `12345678` on `salikeencms` (provisions all dev accounts)
   - **Prod:** `sarkar@cms.com` / `cms@1234` on `salikeencms-prod`

6. **Run the app (dev default)**

   ```bash
   flutter run --flavor dev --dart-define=APP_ENV=dev
   ```

## CMS staff accounts

### Development (`salikeencms`)

QA accounts per role + gender. Password for all: **`12345678`**.

| Email | Role | Gender |
|-------|------|--------|
| meditor@dev.cms.com | `editor` | Male |
| feditor@dev.cms.com | `editor` | Female |
| mapprove@dev.cms.com | `approval` | Male |
| fapprove@dev.cms.com | `approval` | Female |
| madmin@dev.cms.com | `admin` | Male |
| fadmin@dev.cms.com | `admin` | Female |

### Production (`salikeencms-prod`)

All nine CMS staff (matches Firebase Authentication roster). Password for all: **`cms@1234`**.

| Email | Role | Gender |
|-------|------|--------|
| naveed@cms.com | `editor` | Male |
| ayaz@cms.com | `editor` | Male |
| mawaz@cms.com | `editor` | Male |
| imran@cms.com | `editor` | Male |
| adil@cms.com | `approval` | Male |
| waheed@cms.com | `approval` | Male |
| usman@cms.com | `approval` | Male |
| sarkar@cms.com | `admin` | Male |
| waqas@cms.com | `admin` | Male |

**Saliks:** no sample contacts bundled. Editors add records; approval approves.

### Firebase `users/{uid}` example

```json
{
  "email": "naveed@cms.com",
  "name": "Naveed",
  "role": "editor",
  "gender": "Male"
}
```

Use `approval` or `admin` for other roles. `uid` must match Firebase Authentication user id.

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

`--dart-define=APP_ENV=prod` is required for prod Firebase project + staff roster; flavor alone is not enough.

## Salik document fields (reference)

| Field | Description |
|-------|-------------|
| `genderId` | `Male` / `Female` |
| `cityId` | City reference (dropdown) |
| `address` | Free-text address (1–50 chars; required on new saliks) |
| `areaId` | Legacy area ref (optional; old records only) |
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

**Location validation** (`validSalikLocation`): new writes need non-empty `address` (max 50 chars) **or** legacy non-empty `areaId`. `cityId` optional string.

Rules file: [`firestore.rules`](firestore.rules). Deploy to both projects:

```bash
firebase deploy --only firestore:rules --project salikeencms
firebase deploy --only firestore:rules --project salikeencms-prod
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `PERMISSION_DENIED` on salik save | Deploy rules; new saliks need `address` (1–50 chars); legacy docs may use `areaId` only |
| `PERMISSION_DENIED` (other) | Verify `users/{uid}` exists with correct `role` + `gender` |
| Login spinner stuck | Hot restart; ensure online; admin seed runs in background after login |
| Wrong role after login | Sign out; check Firestore `users/{uid}.role`; clear app data if stale offline cache |
| Editor pending missing | Rebuild app; pending matched by Firebase `uid` / `local-{email}` |
| Duplicate mobile on save | Same mobile exists among approved saliks — use **Duplicate Data** to merge |
| Offline login fails | Dev: `*@dev.cms.com` + `12345678`; prod: `@cms.com` + `cms@1234` |
| Pending sync not clearing | Settings → Sync now when online |
| `users/{uid}` missing | Login online once; admin provisions staff; or bootstrap creates doc from local roster |

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
