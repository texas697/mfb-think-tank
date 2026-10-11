# Firebase setup

One-time console work for each app, plus what `scripts/configure_firebase.sh` does
for you. You need a Google account and the Firebase CLI (`npm i -g firebase-tools`,
then `firebase login`) and the FlutterFire CLI (`dart pub global activate flutterfire_cli`).

## 1. Create the project

1. <https://console.firebase.google.com> → **Create a project**. Google Analytics is optional.
2. Note the **project id** (e.g. `acme-notes-1a2b3`); it is shown under the project name and
   in **Project settings → General**.

You do **not** need to add Android/iOS apps by hand: the configure script registers them
with the ids from this repo.

## 2. Enable sign-in providers

**Build → Authentication → Get started → Sign-in method**:

| Provider | What to do |
| --- | --- |
| Email/Password | Enable. (Leave "Email link" off unless you implement it.) |
| Google | Enable, choose a support email, save. This creates the **Web client** OAuth id that the app uses as `GOOGLE_SERVER_CLIENT_ID`. |
| Apple | Enable. Native iOS **sign-in** works with nothing else filled in (Firebase checks the token against your bundle id). **Account deletion** does not: see below. |

### Apple: Services ID and private key (needed for account deletion)

Apple requires in-app account deletion and expects the Sign in with Apple token to be
revoked. The template's *Delete account* revokes it via Firebase
(`revokeTokenWithAuthorizationCode`), which only works when the Apple provider's
**Services ID** and **OAuth code flow configuration** are filled in. Do this before shipping:

1. Apple Developer portal → **Identifiers → + → Services IDs**: identifier e.g.
   `<your bundle id>.signin`, enable *Sign In with Apple*, configure it with your App ID as
   primary, domain `<project-id>.firebaseapp.com` and return URL
   `https://<project-id>.firebaseapp.com/__/auth/handler`.
2. **Keys → +**: enable *Sign In with Apple* (primary App ID = your app), download the
   `.p8` (once) and note the **Key ID**.
3. Firebase → Apple provider: Services ID, **Apple Team ID**, Key ID and the `.p8` contents.

## 3. Run the configure script

```bash
scripts/configure_firebase.sh <firebase-project-id>
```

It is safe to run repeatedly. It:

1. Runs `flutterfire configure --platforms=android,ios` with the Android package and iOS
   bundle id read from `android/app/build.gradle.kts` and `ios/Runner.xcodeproj`. This
   registers the apps (if needed), writes `lib/firebase_options.dart`, `firebase.json` and
   `android/app/google-services.json`, and adds the Google Services Gradle plugin.
2. Registers the SHA-1/SHA-256 of your **debug keystore** (`~/.android/debug.keystore`)
   and **upload keystore** (`android/key.properties`) on the Firebase Android app.
3. Downloads fresh `google-services.json` and `GoogleService-Info.plist` with the Firebase CLI.
   (On Linux/Windows FlutterFire does not write the iOS plist itself.)
4. Patches `ios/Runner/Info.plist` (`GIDClientID` and the reversed-client-id URL scheme)
   and fills `config/app_config.json`:
   - `GOOGLE_IOS_CLIENT_ID` ← `CLIENT_ID` from `GoogleService-Info.plist`
   - `GOOGLE_SERVER_CLIENT_ID` ← the `client_type: 3` (web) OAuth client in `google-services.json`

If `GOOGLE_SERVER_CLIENT_ID` comes out empty, the Google provider is not enabled yet:
enable it and re-run the script.

Commit everything it produces. These files identify your Firebase project but are not
secrets; access is controlled by Firebase Security Rules and API-key restrictions.

## 4. SHA fingerprints (Android Google Sign-In)

Google Sign-In on Android only works for APKs/AABs signed with a key whose SHA-1 is
registered on the Firebase Android app (**Project settings → Your apps → Android → Add
fingerprint**). Register SHA-1 **and** SHA-256 for all three keys:

| Key | Where to get it |
| --- | --- |
| Debug keystore | Created on the first Android build. `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` |
| Upload keystore | Printed by `scripts/create_upload_keystore.sh` |
| Play App Signing key | Play Console → your app → **Test and release → App integrity → App signing**. Exists after your first upload to Play. Builds installed from Play are signed with this key, so without it Google Sign-In fails for testers. |

After adding fingerprints, re-run `scripts/configure_firebase.sh` so the Android OAuth
clients end up in `google-services.json`.

## 5. Optional hardening

- **App Check** (Play Integrity / App Attest) to block abusive clients.
- **API key restrictions** in Google Cloud Console → APIs & Services → Credentials: restrict
  the Android key to your package + SHA-1 and the iOS key to your bundle id.
- **Authentication → Settings → User actions**: decide whether to allow account creation
  from the client and enable email enumeration protection.
- **Authentication → Templates**: set the sender name and customise the password-reset email.
