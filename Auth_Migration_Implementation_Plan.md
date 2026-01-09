# Auth Migration Plan

## Goal Description
Migrate from `MockAuthService` to a real `FirebaseAuthService` using `firebase_auth`.
This is required to resolve "Permission denied" errors in Firebase Realtime Database, as Security Rules require a valid Firebase Auth UID (`auth.uid`), which `MockAuthService` does not provide.

## User Review Required
> [!IMPORTANT]
> The app will now require a network connection to sign in (anonymously). First-time startup might take a moment.
> This change adds `firebase_auth` dependency.

## Proposed Changes

### Configuration
#### [MODIFY] [pubspec.yaml](file:///c:/HWS/Flutter/gyeong_do/pubspec.yaml)
- Add `firebase_auth: ^5.3.4` (or compatible version).

### Service Layer
#### [MODIFY] [lib/services/auth_service.dart](file:///c:/HWS/Flutter/gyeong_do/lib/services/auth_service.dart)
- Rename `MockAuthService` to `FirebaseAuthService`.
- Implement `signInAnonymously` using `FirebaseAuth.instance.signInAnonymously()`.
- Store `nickname` in `User.updateDisplayName(nickname)` so it persists across sessions.
- Map `FirebaseAuth.authStateChanges()` to `Stream<UserModel?>`.

### Dependency Injection
#### [MODIFY] [lib/main.dart](file:///c:/HWS/Flutter/gyeong_do/lib/main.dart)
- Replace `MockAuthService` with `FirebaseAuthService`.

## Verification Plan

### Manual Verification
1.  **Launch App**: Ensure no crash.
2.  **Join/Create Room**:
    - Observe `FirebaseAuth` sign-in (logs or valid behavior).
    - Verify "Permission denied" error is GONE.
    - Verify `participants` node in Firebase DB contains the real Firebase UID (if possible to check via behavior).
    - Restart app and verify user remains logged in (if applicable) or re-authenticates smoothly.
