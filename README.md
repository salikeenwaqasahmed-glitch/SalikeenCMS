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
- **Offline login** — CMS staff pre-seeded locally; password `cms@1234`
- **Auto-sync** — background sync after login; **Sync now** in Settings
- Launcher icon from `android/app/src/main/res/` (also used in-app + web/iOS)

### Offline login (CMS staff)

Nine staff accounts are defined in [`lib/core/auth/staff_users.dart`](lib/core/auth/staff_users.dart) and written to local Drift on app start via [`lib/core/auth/local_user_seed.dart`](lib/core/auth/local_user_seed.dart). Password: **`cms@1234`** ([`seed_credentials.dart`](lib/core/auth/seed_credentials.dart)).

Offline `uid` is `local-{email}` until online login binds Firebase Auth `uid` → `users/{uid}` in Firestore + local cache.

**Online** still needs Firebase Auth + matching `users/{uid}` (`name`, `email`, `role`, `gender`).

### Offline mode and security

- SHA-256 password hash (per-device salt) for offline login
- **Sign out** before switching users — avoids stale Firebase session
- Sync re-auth uses logged-in email only
- Devices with cached credentials are **trusted**

### Firebase

- **Auth** — Email/password; `users/{uid}` profile required for rules
- **Firestore collections:**
  - `saliks` — contacts + approval fields
  - `users` — `name`, `email`, `role`, `gender`
  - `cities`, `areas` — reference data (also in [`reference_data.dart`](lib/core/data/reference_data.dart))
  - `meta/seeded` — cities/areas seeded once
  - `meta/staffProvisioned` — CMS Auth + user profiles provisioned once

On first **admin** online login, `SeedService` seeds cities/areas (if needed) and provisions all CMS staff in Firebase Auth + `users/{uid}` (background; login is not blocked).

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

3. **Enable Firebase services** in [Firebase Console](https://console.firebase.google.com/project/salikeencms):
   - Authentication → Email/Password
   - Firestore Database (production mode)

4. **Deploy Firestore security rules** (required after any rules change)

   ```bash
   firebase login
   firebase use salikeencms
   firebase deploy --only firestore:rules
   ```

5. **Staff accounts** — either:
   - Log in once as `sarkar@cms.com` or `waqas@cms.com` (admin) online so `SeedService` provisions all `@cms.com` users, or
   - Create each user manually in Auth + `users/{uid}` (see table below).

6. **Run the app**

   ```bash
   flutter run
   ```

## CMS staff accounts

Password for all: **`cms@1234`**. Pre-seeded offline + provisioned online by admin login.

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

## Building APK for QA

```bash
flutter build apk --split-per-abi --release
```

Send **`app-arm64-v8a-release.apk`** for most phones:

`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

Avoid sharing debug APK via WhatsApp on Xiaomi devices.

## Salik document fields (reference)

| Field | Description |
|-------|-------------|
| `genderId` | `Male` / `Female` |
| `cityId`, `areaId` | Location refs |
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

Rules file: [`firestore.rules`](firestore.rules)

```bash
firebase deploy --only firestore:rules
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `PERMISSION_DENIED` | Deploy Firestore rules; verify `users/{uid}` exists with correct `role` + `gender` |
| Login spinner stuck | Hot restart; ensure online; admin seed runs in background after login |
| Wrong role after login | Sign out; check Firestore `users/{uid}.role`; clear app data if stale offline cache |
| Editor pending missing | Rebuild app; pending matched by Firebase `uid` / `local-{email}` |
| Duplicate mobile on save | Same mobile exists among approved saliks — use **Duplicate Data** to merge |
| Offline login fails | Use `@cms.com` email + `cms@1234` |
| Pending sync not clearing | Settings → Sync now when online |
| `users/{uid}` missing | Login online once; admin provisions staff; or bootstrap creates doc from local roster |

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

Full app restart after local DB migration.
