# Codemagic CI/CD

`codemagic.yaml` at the repo root defines four workflows:

| Workflow | Trigger | Machine | Does |
| --- | --- | --- | --- |
| `ci` | push to `main`, PRs into `main` (docs-only changes skipped) | `linux_x2` | `flutter analyze` + `flutter test` |
| `android-release` | tag `v*` | `linux_x2` | signed AAB → Google Play **internal** track (as draft) |
| `ios-release` | tag `v*` | `mac_mini_m2` | signed IPA → **TestFlight** |
| `release-all` | manual | `mac_mini_m2` | both stores from one build |

Build numbers are never taken from `pubspec.yaml`: Android uses
`google-play get-latest-build-number` + 1 (across all tracks), iOS uses
`app-store-connect get-latest-testflight-build-number` + 1. You only maintain the
marketing version (`version: 1.2.3+1` → `1.2.3`).

> **Free plan:** Linux instances need billing enabled on the team. On the free plan change
> `instance_type` of `ci` and `android-release` to `mac_mini_m2`.

## One-time account setup (shared by all your apps)

Personal accounts and teams have the same sections under different names: on a
**personal account** use **Settings** in the left sidebar; on a **team** use **Team settings**.

1. **Integrations → Developer Portal → Manage keys → Add key**: App Store Connect API
   key named **`codemagic_asc_key`** ([IOS_WITHOUT_MAC.md §4](IOS_WITHOUT_MAC.md#4-app-store-connect-api-key--codemagic)).
2. Group **`app_store_signing`**: `CERTIFICATE_PRIVATE_KEY`
   (secret) — see [IOS_WITHOUT_MAC.md §5](IOS_WITHOUT_MAC.md#5-signing-the-certificate-private-key).
3. Group **`google_play`**:
   `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` (secret) — the full JSON key of a Google Cloud
   service account that has access to your apps in Play Console:
   1. Google Cloud Console → (any project, e.g. the Firebase one) → **IAM & Admin → Service
      accounts → Create**. No roles needed. **Keys → Add key → JSON**, download.
   2. Enable the **Google Play Android Developer API** for that Cloud project.
   3. Play Console → **Users and permissions → Invite new users** → the service account email.
      Under **App permissions** add the app(s) and grant the *Releases* permissions
      (release to testing tracks / production). Do not make it an admin.
   4. Paste the JSON as the variable value.

Where to define groups 2 and 3:

- **Personal account:** the app's **Environment variables** tab (global variables are a
  team-only feature), so repeat them for each app. In the *Group* field type the new group
  name and pick *Create*; "No groups found" just means it does not exist yet.
- **Team:** **Team settings → Global variables and secrets**, shared by every app.

Never leave a `vars:` entry empty in `codemagic.yaml` — Codemagic rejects empty strings
("ensure this value has at least 1 characters"); comment the line out instead.

## Per-app setup

1. **Add the app**: Codemagic → *Add application* → connect GitHub/GitLab/Bitbucket → pick the
   repo → project type *Flutter App (via codemagic.yaml)*. If the app page shows the
   **Workflow Editor** (builds named "Default Workflow"), click **Switch to YAML
   configuration** — otherwise `codemagic.yaml` is ignored and tags trigger nothing.
   Variables entered in the Workflow Editor are not visible to YAML builds.
2. **Android keystore**: run `scripts/create_upload_keystore.sh`, then **Settings** (personal) /
   **Team settings** (team) **→ codemagic.yaml settings → Code signing identities → Android keystores**: upload the
   `.jks`, enter its password, alias `upload` and key password, reference name
   **`upload_keystore`**. Codemagic cannot export it back — keep your own backup. Inside the
   build the keystore is exposed as `CM_KEYSTORE_PATH`, `CM_KEYSTORE_PASSWORD`,
   `CM_KEY_ALIAS`, `CM_KEY_PASSWORD`, which `android/app/build.gradle.kts` reads.
   (Reference names are team-wide; for several apps give each keystore its own name and
   update `android_signing` in that app's `codemagic.yaml`.)
3. **Firebase**: run `scripts/configure_firebase.sh` and commit the output. Release
   workflows fail fast if `lib/firebase_options.dart` is still the placeholder or
   `Info.plist` still has `_PLACEHOLDER` values.
4. **Google Play**: create the app in Play Console. **The very first AAB must be uploaded
   manually** — Google's API cannot create the first release. Either build locally
   (`flutter build appbundle --dart-define-from-file=config/app_config.json`, needs the
   Android SDK) or run `android-release` once (publishing will fail) and download the AAB
   from the build's artifacts, then upload it to the internal testing track by hand.
   Afterwards add the **Play App Signing** SHA-1/SHA-256 to Firebase
   ([FIREBASE_SETUP.md §4](FIREBASE_SETUP.md#4-sha-fingerprints-android-google-sign-in)).
5. **App Store**: App ID with Sign In with Apple + App Store Connect record
   ([IOS_WITHOUT_MAC.md](IOS_WITHOUT_MAC.md)).

`PACKAGE_NAME` and `BUNDLE_ID` are defined once at the top of `codemagic.yaml`
(`definitions.app_ids`); they were set when the app was created from
flutter-firebase-template (`scripts/new_app.sh`).

## Releasing

```bash
# bump the marketing version in pubspec.yaml, e.g. version: 1.3.0+1
git commit -am "chore: release 1.3.0"
git tag v1.3.0
git push && git push --tags
```

The tag starts `android-release` and `ios-release` in parallel. A warning is printed (the
build continues) if the tag does not match `pubspec.yaml`.

- Android lands on the **internal** track as a draft (`submit_as_draft: true`, required while
  the app has never been published). Once the app is live you can set it to `false`, or
  promote releases in Play Console.
- iOS is uploaded to **TestFlight**; internal testers get it automatically after processing.
  `submit_to_testflight` is `false`, so builds are not sent to Beta App Review. For
  external testers set it to `true` and uncomment `beta_groups`; that requires Test
  Information (description, feedback email, contact) and a demo account for the login
  screen in App Store Connect.

Run a workflow by hand: Codemagic → app → **Start new build** → pick branch/tag and workflow.

## Running checks locally

`ci` runs exactly what you can run locally:

```bash
flutter analyze
flutter test --dart-define-from-file=config/app_config.json
```

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `No keystore. Upload it in Codemagic as 'upload_keystore'` | Step 2 above; the reference name must match `android_signing`. |
| Play: `Package not found` / `The caller does not have permission` | First upload not done manually, or the service account was not granted access to this app. Permissions can take up to a day to propagate. |
| Play: `APK specifies a version code that has already been used` | Usually a manual upload with a higher version code; the next build recomputes it from Play. |
| Google sign-in fails only in Play-installed builds | Play App Signing SHA fingerprints missing in Firebase. |
| iOS signing errors | [IOS_WITHOUT_MAC.md → Troubleshooting](IOS_WITHOUT_MAC.md#troubleshooting). |
