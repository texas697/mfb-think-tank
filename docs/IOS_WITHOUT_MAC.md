# Shipping iOS without a Mac

You develop on Linux or Windows; Codemagic's cloud Macs build, sign and upload the iOS app.
Everything below happens in a web browser. You test on a real iPhone through TestFlight.

## 1. Apple Developer Program

Enroll at <https://developer.apple.com/programs/> ($99/year). Organisations need a D-U-N-S
number; enrollment can take a few days. Note your **Team ID** (Membership details).

## 2. Register the bundle id with Sign in with Apple

[Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)
→ **Identifiers → +** → **App IDs → App**:

- Description: your app name.
- Bundle ID: **Explicit**, exactly the iOS id of this project
  (`PRODUCT_BUNDLE_IDENTIFIER` in `ios/Runner.xcodeproj/project.pbxproj`, e.g. `com.acme.acmeNotes`).
- Capabilities: tick **Sign In with Apple** (leave "Enable as a primary App ID").
  Add others (Push Notifications, Associated Domains…) only when you use them.

The repo already ships `ios/Runner/Runner.entitlements` with the Sign in with Apple
entitlement, wired into every build configuration. If you change capabilities later,
the App Store provisioning profile must be regenerated: delete it in the portal and the next
Codemagic build creates a fresh one.

## 3. App Store Connect app record

[App Store Connect](https://appstoreconnect.apple.com) → **Apps → + → New App**:
platform iOS, a name (must be unique on the store), primary language, the bundle id from
step 2, and any SKU (e.g. the Dart package name), Full Access.

The `ios-release` workflow looks up the app's numeric Apple ID from the bundle id, so the
record must exist before the first build. (You can pin it with `APP_STORE_APPLE_ID` in
`codemagic.yaml`; it is shown under **App Information → Apple ID**.)

## 4. App Store Connect API key → Codemagic

1. App Store Connect → **Users and Access → Integrations → App Store Connect API →
   Team Keys → +**. Name it `codemagic`, access **App Manager**.
2. Download the `.p8` (possible **once**) and note the **Issuer ID** and **Key ID**.
3. Codemagic → **Team settings → Team integrations → Developer Portal → Manage keys →
   Add key**. Name it exactly **`codemagic_asc_key`** (the name `codemagic.yaml` uses),
   enter Issuer ID + Key ID, upload the `.p8`.

One key serves every app in your Apple team, so this is a one-time step.

## 5. Signing: the certificate private key

The workflow signs automatically: `app-store-connect fetch-signing-files "$BUNDLE_ID"
--type IOS_APP_STORE --create` (Codemagic CLI) uses the API key to find or create an
**Apple Distribution certificate** and an **App Store provisioning profile** for the
bundle id, then `xcode-project use-profiles` applies them. The only secret you provide is
the certificate's RSA private key, created once and reused for every app:

```bash
ssh-keygen -t rsa -b 2048 -m PEM -f cert_key -q -N ""
```

Codemagic → your app → **Environment variables**: add `CERTIFICATE_PRIVATE_KEY` with the
contents of `cert_key` (mark it **Secret**) to a group named **`app_store_signing`**. Better:
add the group under **Team settings → Global variables and secrets** so every app shares it.
Store `cert_key` in your password manager too.

Notes:

- The first run creates a certificate tied to this key. Apple allows only a few
  distribution certificates per team; if you hit the limit, revoke an unused one in the
  Developer portal.
- A certificate created elsewhere (e.g. by Xcode on someone's Mac) cannot be used with a
  different private key; the CLI will create a new one instead.
- Register the App ID with its capabilities (step 2) **before** the first build, so the
  profile Codemagic creates already includes the Sign in with Apple entitlement.

## 6. Build and test on your iPhone (TestFlight)

1. Push a tag / start the `ios-release` workflow in Codemagic. It bumps the build number
   past the latest TestFlight build, builds the IPA and uploads it.
2. After Apple's processing (5–30 min) the build appears in App Store Connect →
   **TestFlight**. Create an **Internal Testing** group, add yourself (your Apple ID must be
   a user in App Store Connect), and add the build.
3. Install the **TestFlight** app on the iPhone and accept the invite. Internal testers
   need no beta review; external testers do (first build per version).

## 7. Debugging on a device (optional)

TestFlight builds are release builds: no hot reload, no debugger. Options:

- Develop UI and logic on an Android emulator/device or in `flutter test`; almost all of
  this template is shared code. Use iOS builds to verify platform bits (Apple sign-in,
  Google sign-in URL scheme, permissions).
- [MobAI ios-builder](https://github.com/MobAI-App/ios-builder) (third-party) builds a debug
  IPA on GitHub Actions macOS runners, installs it on a USB-connected iPhone from
  Linux/Windows through the MobAI app, and attaches `flutter` for hot reload
  (`builder dev flutter`). Requires a GitHub repo with Actions enabled and the MobAI
  desktop app; treat it as a convenience, not part of the release pipeline.
- Rent a cloud Mac (e.g. MacinCloud, AWS EC2 Mac) when you need Xcode itself
  (Instruments, storyboard edits, capability debugging).

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `fetch-signing-files` cannot find the bundle id | Register the App ID in the Developer portal (step 2); it must equal `BUNDLE_ID` in `codemagic.yaml` and the project. |
| `Provisioning profile doesn't include the com.apple.developer.applesignin entitlement` | Enable Sign In with Apple on the App ID (step 2), delete the stale App Store profile in the portal, rebuild. |
| Google sign-in crashes on iOS immediately | `ios/Runner/Info.plist` still has `REVERSED_CLIENT_ID_PLACEHOLDER` — run `scripts/configure_firebase.sh`. |
| `No App Store Connect app found` | Create the app record (step 3) with exactly this bundle id. |
| "Missing Compliance" on each build | `ITSAppUsesNonExemptEncryption` must be in Info.plist (the template sets it to `false`). |
