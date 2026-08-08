# Salikeen CMS (Kotlin / Jetpack Compose)

Native Android rewrite of the Salik Management System. Offline-first Room + Firebase Auth/Firestore. Manual Sync only.

## Stack

- Kotlin, Jetpack Compose, Material 3
- Hilt, Navigation Compose, Room, Coroutines
- Firebase Auth + Firestore (`dev` / `prod` flavors)
- AES-256-GCM field encryption (`enc:v1:`) for salik PII on push

## Run

Requires **JDK 17** (Gradle Kotlin DSL fails on JDK 26+ with `IllegalArgumentException: 26.0.1`).

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
./gradlew :app:assembleDevDebug
./gradlew :app:installDevDebug
# or
./gradlew :app:installProdDebug
./gradlew :app:testDevDebugUnitTest
```

Android Studio: open this repo root (Gradle project). Select flavor `dev` or `prod`. Set Gradle JDK to 17 in Settings → Build → Gradle.

## Flavors

| Flavor | Firebase project | Staff email domain | Room DB |
|--------|------------------|--------------------|---------|
| `dev` | `salikeencms` | `@dev.cms.com` | `salik_crm_local_dev` |
| `prod` | `salikeencms-prod` | `@cms.com` | `salik_crm_local_prod` |

`google-services.json` lives under `app/src/dev/` and `app/src/prod/`.

Optional shared crypto key override in `app/build.gradle.kts` → `FIELD_CRYPTO_KEY_BASE64` (must match .NET / other clients).

## Auth

- Login: **username only** (local part). App appends flavor domain.
- First login needs internet; profile + password hash cached in Room for offline login.
- Firestore `users/{uid}.password`: if set, source of truth on online login (local hash + Auth updated). If missing, typed password is seeded.
- No in-app change-password UI — edit password in Console when needed.

## Sync

- Browse reads **Room only**.
- Saves enqueue `sync_queue` outbox.
- Tap bottom-nav **Sync** (or Settings → Sync now): push queue then pull bazams / gender-scoped saliks / areas.
- Login does **not** full-pull saliks (admin seed of default bazams/areas only).

### Bazams / areas

- Firestore **document id = `bazamId` / `areaId`** (same string).
- Pull skips `isActive == false`; dashboard/bazam screens show `bazamName` / area name (count 0 OK).
- Add bazam in Console → Sync → appears on dashboard.

## Roles

| Role | Scope | Notes |
|------|-------|-------|
| `admin` | All genders | Full CRUD + approve + delete |
| `approval` | Own gender | Approve/reject, update, duplicates |
| `editor` | Own gender | Create → pending; no update after submit |

## Screens

Login · Dashboard · Bazam areas · Salik directory / profile / add-edit · Pending · Duplicates · Message queue · Settings (theme, sync, CSV export, contacts preview, logout).

## Firestore collections

`users`, `saliks`, `delete_saliks`, `areas`, `bazams`, `meta/seeded`, `meta/bazamsSeeded`

Rules: [`firestore.rules`](firestore.rules). Deploy with Firebase CLI as before.

## Tests

```bash
./gradlew :app:testDevDebugUnitTest
```

Covers field crypto round-trip, access control, staff email validation.

## QA checklist

- [ ] `dev` / `prod` install with correct Firebase project
- [ ] Online login + offline re-login
- [ ] Sync pulls new bazam/area (`doc.id` = field id)
- [ ] Create salik offline → Sync push
- [ ] Editor pending → approver approve
- [ ] Dashboard bazam → areas (0 count visible) → directory
- [ ] Message queue opens WhatsApp/SMS
- [ ] CSV export share sheet
- [ ] Dark mode toggle persists
- [ ] Console `users.password` change applies next online login

## Migration note

Flutter clients can coexist on the same Firebase projects during cutover. Do not change rules in ways that break remaining Flutter installs until they are retired.
