# Backend auth contract for the F-Droid (free-software) build

**Status: REQUIRED — not yet implemented in Crucix.** This file is the contract
the Crucix repo (`server.mjs`, `lib/auth/*.mjs`) must satisfy before the FOSS
build can sign in.

## Why

F-Droid's Inclusion Policy forbids Firebase and Google Play Services in the
shipped APK, and its build-time dex scan rejects any APK containing
`com/google/firebase/...` or `com/google/android/gms/...` classes. The Play and
App Store builds keep Firebase Auth untouched. The `foss` build
(`feat/fdroid` → `foss` branch) drops the Firebase SDKs and therefore cannot
produce Firebase ID tokens. It needs a Crucix-issued credential instead.

The app already isolates this behind two seams, so no UI or feature code
changes:

- `lib/features/auth/data/auth_repository.dart` — `AuthRepository`
- `lib/core/network/id_token_provider.dart` — `IdTokenProvider`

`ApiClient` (`lib/core/network/api_client.dart`) is unchanged: it asks the
`IdTokenProvider` for a string and sets `Authorization: Bearer <token>`.

## Token format

- JWT (HS256 or RS256), with claims: `iss: "crucix"`, `sub: <user id>`,
  `email`, `exp` (short-lived, ~1 h), `iat`.
- Sent exactly as today: `Authorization: Bearer <jwt>`.
- Refresh tokens are opaque and rotated on every refresh.

## Middleware change

`requireAuth` (today `lib/auth/firebase.mjs`, branch
`feature/mobile-bearer-auth`) must accept **both** credential types:

1. Firebase ID token — verified with `verifyIdToken` (Play/App Store clients).
2. Crucix-issued JWT — verified with the Crucix signing key (FOSS clients).

Distinguish by the `iss` claim. A Firebase token's issuer is
`https://securetoken.google.com/<project-id>`; Crucix's is `"crucix"`.

## Endpoints to add

All are under the existing `CRUCIX_API_BASE_URL`
(`https://crucix-qa65slel7a-uc.a.run.app`).

| Method | Path | Body | Success response |
| --- | --- | --- | --- |
| POST | `/api/auth/signup` | `{email, password, displayName?}` | `{token, refreshToken, user}` |
| POST | `/api/auth/signin` | `{email, password}` | `{token, refreshToken, user}` |
| POST | `/api/auth/refresh` | `{refreshToken}` | `{token, refreshToken}` |
| POST | `/api/auth/reset-password` | `{email}` | `204` |
| POST | `/api/auth/verify-email` | `{}` (Bearer auth) | `204` |

`user` has the shape the FOSS `BackendAuthRepository` maps to `AppUser`:

```json
{
  "uid": "usr_123",
  "email": "user@example.com",
  "displayName": "Ada",
  "emailVerified": false,
  "providerIds": ["password"]
}
```

Existing endpoints the FOSS build reuses unchanged: `GET /api/me` (profile
reload), `DELETE /api/me` (account deletion, already used by
`HttpAccountDeletionGateway`).

## Error shape

```json
{ "error": { "code": "wrong-password", "message": "…" } }
```

Use the code strings `AuthFailure.messageForCode`
(`lib/features/auth/data/auth_failure.dart`) already understands, so the FOSS
repository maps them without change: `invalid-credential`,
`email-already-in-use`, `weak-password`, `user-not-found`, `wrong-password`,
`too-many-requests`, `invalid-email`, `user-disabled`, `network-request-failed`.

## Security requirements

- Hash passwords with Argon2id (preferred) or bcrypt; never store plaintext.
- Rate-limit `signin` / `reset-password` and return `too-many-requests`.
- Rotate refresh tokens and revoke the family on reuse.
- The reset/verify emails must link back to the backend, not Firebase.
- Keep TLS-only transport; the app targets HTTPS.

## Anti-feature disclosure

Because the FOSS client depends entirely on the proprietary Crucix service,
the fdroiddata metadata carries `NonFreeNet` (and likely `Tethered Network
Services`). That is a disclosure flag, not a rejection. See `docs/FDROID.md`.
