# Salikeen CMS (Kotlin / Jetpack Compose)

Native Android app. Offline-first Room + Firebase Auth/Firestore. Manual Sync only.

## Stack

- Kotlin, Jetpack Compose, Material 3, Hilt, Room
- Firebase Auth + Firestore (Dev / Real flavors)
- AES-256-GCM field encryption (`enc:v1:`) for salik PII on push

## Run / JDK

Requires **JDK 17** (Gradle fails on JDK 26+).

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

Android Studio: open **repo root**. Set Gradle JDK to 17.

## Build APKs

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# Dev APK — test Firebase (salikeencms), emails @dev.cms.com
./gradlew :app:assembleDevDebug
# → app/build/outputs/apk/dev/debug/app-dev-debug.apk
# applicationId: com.example.salik_management_system.dev

# Real APK — live Firebase (salikeencms-prod), emails @cms.com
./gradlew :app:assembleProdRelease
# → app/build/outputs/apk/prod/release/app-prod-release.apk
# applicationId: com.example.salik_management_system
```

Dev uses `applicationIdSuffix = ".dev"` so **Dev + Real can both install** on one phone.

Real APK is currently debug-signed (fine for internal checks). Add a store keystore later for Play.

Install:

```bash
./gradlew :app:installDevDebug
# or
./gradlew :app:installProdRelease
```

## Staff login pattern

```
Firebase Console
  → Auth user: madmin@dev.cms.com + password
  → Firestore users/{uid}: name, email, role, gender
App
  → User types username: madmin  (+ password)   ← no @domain on screen
  → App appends domain in code → madmin@dev.cms.com
  → Online first login → Room caches profile + password hash
  → Later offline login works from Room
```

### Create an editor (Dev)

1. Firebase project **salikeencms**
2. Authentication → Add user: `editor1@dev.cms.com` + password
3. Firestore `users/{thatAuthUid}`:
   - `name` (string)
   - `email` = `editor1@dev.cms.com`
   - `role` = `editor`
   - `gender` = `Male` or `Female`
4. Install **Dev APK**, stay online, username `editor1`, same password
5. After success → airplane mode → login still works

Real APK: same steps with `@cms.com` and project `salikeencms-prod`.

Optional Firestore `users/{uid}.password`: if set, wins on next online login; if missing, typed password is seeded.

## Sync

- Browse reads Room only.
- Saves enqueue outbox; tap bottom **Sync** (or Settings → Sync now).
- Login does **not** full-pull saliks.

### Bazams / areas

- Document id = `bazamId` / `areaId` (same string).
- Pull skips `isActive == false`.

## Roles

| Role | Scope | Notes |
|------|-------|-------|
| `admin` | All genders | Full CRUD + approve + delete |
| `approval` | Own gender | Approve/reject, update, duplicates |
| `editor` | Own gender | Create → pending |

## Tests

```bash
./gradlew :app:testDevDebugUnitTest
```

## QA checklist

- [ ] Username-only login (e.g. `madmin`) — no domain on field
- [ ] Dev online login → offline re-login
- [ ] Missing Firestore profile → clear error, no stuck session
- [ ] Dev + Real APKs install side-by-side
- [ ] Sync pulls bazam/area; empty directory copy OK
- [ ] Settings shows name + role (not email); DEV chip only on Dev
