# Backend auth contract for the F-Droid (free-software) build

**Status: implemented on the Crucix `feat/mobile-auth` branch.** Crucix proxies
Firebase Auth's Identity Toolkit REST API, so a Firebase-SDK-free client can
obtain a **real Firebase ID token** by talking only to Crucix.

## Why

F-Droid's Inclusion Policy forbids Firebase and Google Play Services in the
shipped APK, and its build-time dex scan rejects any APK containing
`com/google/firebase/...` or `com/google/android/gms/...` classes. The Play and
App Store builds keep Firebase Auth untouched. The `foss` build drops the
Firebase SDK and therefore cannot mint a Firebase ID token on-device — it asks
Crucix for one instead.

The app isolates this behind two seams, so no UI or feature code changes:

- `lib/features/auth/data/auth_repository.dart` — `AuthRepository`
- `lib/core/network/id_token_provider.dart` — `IdTokenProvider`

`ApiClient` (`lib/core/network/api_client.dart`) is unchanged: it asks the
`IdTokenProvider` for a string and sets `Authorization: Bearer <token>`.

## How it works

`requireAuth` (`lib/auth/firebase.mjs`) already verifies
`Authorization: Bearer <Firebase ID token>` via `verifyIdToken`. The FOSS client
just needs a way to *get* that token without the SDK. Crucix provides it:

1. Client `POST /api/auth/signin {email, password}`.
2. Crucix calls Identity Toolkit
   `accounts:signInWithPassword?key=<WEB_API_KEY>` (key stays server-side) and
   receives `{idToken, refreshToken, ...}`.
3. Crucix verifies the token and returns
   `{token: <idToken>, refreshToken, user}`.

No new token type, **no middleware change**, and Play / F-Droid share the same
Firebase accounts.

## Endpoints

All under the existing `CRUCIX_API_BASE_URL`
(`https://crucix-qa65slel7a-uc.a.run.app`). Public (no session cookie).

| Method | Path | Body | Success |
| --- | --- | --- | --- |
| POST | `/api/auth/signup` | `{email, password, displayName?}` | `200 {token, refreshToken, user}` |
| POST | `/api/auth/signin` | `{email, password}` | `200 {token, refreshToken, user}` |
| POST | `/api/auth/refresh` | `{refreshToken}` | `200 {token, refreshToken}` |
| POST | `/api/auth/reset-password` | `{email}` | `200 {ok: true}` |
| POST | `/api/auth/verify-email` | `{}` (Bearer ID token) | `200 {ok: true}` |

`user` is the shape `BackendAuthRepository` maps to `AppUser`:

```json
{
  "uid": "abc123",
  "email": "user@example.com",
  "displayName": "Ada",
  "emailVerified": false,
  "providerIds": ["password"]
}
```

`signup` honors the existing policy: `AUTH_ALLOW_SIGNUP=false` → `403`
`signup-disabled`; an address outside `AUTH_ALLOWED_EMAILS` /
`AUTH_ALLOWED_DOMAINS` → `403` `not-allowed`.

Existing endpoints reused unchanged: `GET /api/me` (profile reload),
`DELETE /api/me` (account deletion).

## Error shape

```json
{ "error": { "code": "invalid-credential", "message": "…" } }
```

Codes are the strings `AuthFailure.messageForCode`
(`lib/features/auth/data/auth_failure.dart`) understands, so the client maps
them without change: `invalid-credential`, `email-already-in-use`,
`weak-password`, `user-not-found`, `too-many-requests`, `invalid-email`,
`user-disabled`, `requires-recent-login`.

## Configuration

The Web API key comes from `FIREBASE_WEB_API_KEY`, else the `apiKey` inside
`FIREBASE_WEB_CONFIG`. If neither is set, all five endpoints return
`503 {error:{code:"unavailable"}}` and nothing else changes.

## Security

- Passwords are never stored by Crucix; Firebase Identity Toolkit hashes them
  and applies its own rate limiting / abuse protection (`TOO_MANY_ATTEMPTS` →
  `too-many-requests`).
- The Web API key stays server-side; it is not shipped in the APK.
- Password-reset and verification emails are sent by Firebase, so they use the
  existing Firebase email templates adding no new infrastructure.
- TLS-only transport; the app targets HTTPS.

## Anti-feature disclosure

Because the FOSS client depends entirely on the proprietary Crucix service,
the fdroiddata metadata carries `NonFreeNet` (and `TetheredNet`).
That is a disclosure flag, not a rejection. See `docs/FDROID.md`.
