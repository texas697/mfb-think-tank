# Publishing MFB Think Tank on F-Droid

How this app is prepared for the F-Droid main repository, and how to keep the
free-software build in sync with the Play / App Store build.

## Why a separate branch

F-Droid builds the app **from source** on its own buildserver and rejects any
APK containing proprietary SDK classes. Its `fdroidserver` dex scan fails on
`com/google/firebase/...`, `com/google/android/gms/...` and
`com/crashlytics/...`. Flutter resolves every `pubspec.yaml` dependency
unconditionally — `--flavor` and `--dart-define` gate Dart code only and do
**not** keep a plugin's native code out of the APK. So a free-software build
must have a dependency set with no Firebase / Play Services / Google Sign-In.

The two distribution channels are therefore:

| Channel | Branch | Auth | Signed by |
| --- | --- | --- | --- |
| Google Play, App Store | `main` | Firebase Auth + Google/Apple Sign-In | Play App Signing / Apple |
| F-Droid | `foss` (long-lived) | Crucix backend JWT (see `FDROID_BACKEND_AUTH.md`) | F-Droid's own key |

`main` is never the F-Droid source. F-Droid's metadata points at a tagged
commit on `foss`.

## Prerequisites

1. **License** — `LICENSE` (Apache-2.0) + `NOTICE` at the repo root. Done.
2. **Public source** — F-Droid clones the repo over unauthenticated HTTPS, so
   the GitHub repository must be public (or a public mirror must exist) and the
   `foss` branch pushed.
3. **Backend auth** — the Crucix endpoints in `FDROID_BACKEND_AUTH.md`
   (implemented on the Crucix `feat/mobile-auth` branch). The FOSS build has no
   sign-in until they are deployed.
4. **Fastlane metadata** — `fastlane/metadata/android/en-US/` (title, short and
   full description, changelogs, icon). Done.
5. **Tagged `foss` releases** — every F-Droid version is an exact commit, and
   carries a build number higher than the previous one (see below).

## Phase 1 — decouple Firebase from the UI (on `main`)

`firebase_auth.User` used to leak into the router and presentation layer. The
`AppUser` value type (`lib/features/auth/data/app_user.dart`) now crosses the
feature boundary instead, so the `foss` branch delta stays small. Only
`lib/features/auth/data/`, `lib/core/network/`, `lib/main.dart` and
`lib/firebase_options.dart` may import Firebase on `main`.

Verify before shipping:

```bash
grep -rn "package:firebase_auth" lib/app lib/features/*/presentation
# must print nothing
```

## Phase 2 — the `foss` branch

Created from a `main` release tag and kept as a long-lived branch. Its delta
from `main` is intentionally small (~15 files):

- `pubspec.yaml` — drop `firebase_auth`, `firebase_core`, `google_sign_in`,
  `sign_in_with_apple`; drop `firebase_auth_mocks` from dev deps.
- `lib/main.dart` — no `Firebase.initializeApp`.
- Delete `lib/firebase_options.dart`, `lib/app/firebase_setup_app.dart`,
  `lib/features/auth/data/google_sign_in_gateway.dart`,
  `lib/features/auth/data/apple_sign_in_gateway.dart`.
- Add `lib/features/auth/data/backend_session.dart` (token/user session +
  `shared_preferences` persistence), `lib/features/auth/data/backend_auth_api.dart`
  (JSON transport → `AuthFailure`), `lib/features/auth/data/backend_auth_repository.dart`
  (`BackendAuthRepository implements AuthRepository`) and
  `lib/features/auth/data/backend_id_token_provider.dart`
  (`BackendIdTokenProvider implements IdTokenProvider`). Add the
  `shared_preferences` dependency.
- `lib/features/auth/application/auth_providers.dart` — wire the backend
  implementations; `socialSignInOptionsProvider` reports Google and Apple off
  (the buttons already hide themselves).
- `android/app/build.gradle.kts` + `android/settings.gradle.kts` — drop the
  `com.google.gms.google-services` plugin; delete
  `android/app/google-services.json`.
- `codemagic.yaml` — exclude the `foss` branch from the Firebase check steps
  (Codemagic must not build `foss`; F-Droid builds it).

### Keeping it in sync

At each release:

```bash
git checkout foss && git merge main          # resolve the auth data/ and pubspec delta
# bump the build number on foss (see "Build numbers on foss"), then:
git tag foss-vX.Y.Z && git push origin foss foss-vX.Y.Z
```

Conflicts should only ever appear in `lib/features/auth/data/`,
`lib/features/auth/application/auth_providers.dart` and `pubspec.yaml` (the
build number). If a conflict shows up elsewhere, the Phase 1 seam has been
broken — fix it on `main`.

`.flutter-version`, `fastlane/metadata/android/`, `docs/FDROID.md` and the
`docs/fdroid/` metadata template are kept identical on both branches. They
exist for the F-Droid build, but `main` carries them too, so a release merge
never surfaces them and F-Droid always builds the recipe it was reviewed
against. If one of them conflicts, the branches have drifted — reconcile it on
`main`, then re-merge.

### Build numbers on `foss`

Play and App Store builds get a monotonic `versionCode` from Codemagic's
`--build-number`. F-Droid has no such override — its metadata reads the code
straight out of `pubspec.yaml` (`UpdateCheckData: ...\+(\d+)`, `%c`). So
**every F-Droid release must carry a `+N` higher than the last**. `main` always
ships `+1`, which Codemagic replaces at build time; on `foss` the number is real
and must be incremented once per release (`0.3.1+2`, then `0.4.0+3`, …). Two
releases with the same code look identical to F-Droid, and the newer one is
never offered as an update.

The metadata ships one `Builds` entry per ABI, with
`VercodeOperation: %c * 10 + N` turning the pubspec build number into the three
codes (`+2` → `21`, `22`, `23` for armeabi-v7a, arm64-v8a and x86_64). Add a
matching `fastlane/metadata/android/en-US/changelogs/<versionCode>.txt` for
each, or the release notes come out empty.

### Pinning Flutter

F-Droid's builder needs the Flutter version recorded **in this repo**, not just
in the fdroiddata metadata. `.flutter-version` (currently `3.47.7`) is the
source of truth; the fdroiddata `prebuild` reads it and checks the `flutter`
srclib out to that tag. Bump it here when moving Flutter versions.

### Verify the FOSS APK is clean

```bash
flutter build apk --release
# Any of these must return nothing:
$ANDROID_HOME/cmdline-tools/latest/bin/apkanalyzer dex packages \
  build/app/outputs/flutter-apk/app-release.apk | grep -E "com\.google\.(firebase|android\.gms)"
```

## Phase 3 — submit to fdroiddata

1. Fork <https://gitlab.com/fdroid/fdroiddata>, branch named
   `com.mfbservicesinc.mfb_think_tank`.
2. Copy `docs/fdroid/com.mfbservicesinc.mfb_think_tank.yml` to
   `metadata/com.mfbservicesinc.mfb_think_tank.yml` and fill the placeholders
   (the full `foss` commit hash).
3. Validate locally with `fdroidserver`:
   `fdroid readmeta && fdroid rewritemeta <id> && fdroid lint <id> && fdroid build <id>`.
4. Open the merge request (`New App: com.mfbservicesinc.mfb_think_tank`).

Reviewers will confirm the license, the build recipe, the absence of
proprietary classes, and the anti-feature flags.

## Signing

The app uses F-Droid's own per-app key (reproducible builds are **not** set
up — Flutter reproducibility is hard and needs the upstream build path and NDK
pinned byte-for-byte). Consequence: the F-Droid build has a different signature
from Play, so a user cannot cross-update between them; they must uninstall and
reinstall. That is a deliberate, documented trade-off.

## Anti-features

Disclose on submission:

- **NonFreeNet** — the app depends on the proprietary Crucix backend.
- **Tethered Network Services** — the backend is a single operator-run instance.

The FOSS build has no ads, analytics or crash-reporting SDKs, so no `Ads` or
`Tracking` flags apply.

## Ongoing maintenance

F-Droid runs `checkupdates` daily; with `AutoUpdateMode: Version` and
`UpdateCheckMode: Tags` a new `vX.Y.Z-foss` tag opens an MR automatically. If
the `foss` branch lags more than a release or two, F-Droid may drop the
package, so treat the release-time merge as part of the checklist.

## Alternative: IzzyOnDroid

If the fdroiddata MR stalls, IzzyOnDroid
(<https://izzyondroid.org/>) serves a developer-signed APK from GitHub
releases with a much faster review. It still rejects GMS-dependent APKs, so
the `foss` branch is required there too. It is a valid interim channel, not a
replacement for the AOSP-free guarantee of the F-Droid main repo.
