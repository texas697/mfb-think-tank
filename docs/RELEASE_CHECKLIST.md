# Release checklist

Work through this before the first store submission. Most items are store-policy
requirements that cause rejections when missed.

## Identity and branding

- [ ] App name, Dart package, Android id and iOS bundle id are final (they cannot change
      after the first store upload). Set when the app was created from
      flutter-firebase-template (`scripts/new_app.sh`).
- [ ] App icon. Easiest: add [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons)
      as a dev dependency, point it at a 1024×1024 PNG **without transparency** (App Store
      rejects alpha), and run `dart run flutter_launcher_icons`. Provide an adaptive icon
      foreground for Android.
- [ ] Splash screen: [`flutter_native_splash`](https://pub.dev/packages/flutter_native_splash)
      replaces the default white launch screen on both platforms.
- [ ] `version:` in `pubspec.yaml` set to the marketing version (e.g. `1.0.0+1`). CI overrides
      the build number automatically; only bump the part before `+`.

## Auth and accounts

- [ ] Email/Password, Google and Apple providers enabled in Firebase ([FIREBASE_SETUP.md](FIREBASE_SETUP.md)).
- [ ] SHA-1/SHA-256 of debug, upload **and Play App Signing** keys registered in Firebase;
      `google-services.json` re-downloaded (re-run `scripts/configure_firebase.sh`).
- [ ] Sign in with Apple is offered on iOS whenever Google sign-in is (App Store Review
      Guideline 4.8). The template does this already; keep it if you add more providers.
- [ ] **In-app account deletion** works (App Store Guideline 5.1.1(v) and Google Play's account
      deletion policy). It must delete the Firebase user *and* the user's data in your
      backend. For Apple users, revoke the Apple token (needs the Services ID + OAuth code
      flow configured in the Firebase Apple provider).
- [ ] **Account deletion web URL** for Google Play: a public page explaining how to request
      deletion without reinstalling the app (Play Console → App content → Data deletion).
- [ ] Password reset email template and sender name customised in Firebase.

## Legal and privacy

- [ ] **Privacy policy** hosted at a public URL (Firebase Hosting works) and linked in both
      store listings and inside the app (e.g. on the sign-in and profile screens).
- [ ] Terms of service if you have paid features or user-generated content.
- [ ] **App Store → App Privacy** ("nutrition labels"): declare at least *Contact Info → Email
      Address* and *Identifiers → User ID* (linked to the user, used for App Functionality),
      plus anything your own features or SDKs (Analytics, Crashlytics…) collect.
- [ ] **Play Console → Data safety** form: same data as above; Firebase Auth data is
      encrypted in transit; state that users can request deletion.
- [ ] Privacy manifest: Firebase iOS SDKs ship their own `PrivacyInfo.xcprivacy`. Add one to
      `ios/Runner/` only if your own code uses Required Reason APIs.
- [ ] Export compliance: `ITSAppUsesNonExemptEncryption = NO` is already set in Info.plist
      (HTTPS only). Change it if you add custom encryption.

## Store listings

- [ ] **Google Play**: app created in Play Console, first AAB uploaded **manually** to the
      internal track ([CODEMAGIC.md](CODEMAGIC.md)), store listing (short + full description,
      feature graphic 1024×500, at least 2 phone screenshots), content rating questionnaire,
      target audience, ads declaration, app access instructions **with a demo account** for
      reviewers.
- [ ] Play: new personal developer accounts must run a closed test with at least 12 testers for
      14 days before production access.
- [ ] **App Store Connect**: app record ([IOS_WITHOUT_MAC.md](IOS_WITHOUT_MAC.md)), screenshots
      for 6.9" (and 13" iPad if you support iPad), description, keywords, support URL,
      privacy policy URL, age rating, **demo account** in App Review Information.
- [ ] iPad: if you don't design for iPad, remove iPad from `TARGETED_DEVICE_FAMILY` (Xcode
      build setting `1` = iPhone only), otherwise iPad screenshots are required.

## Quality

- [ ] `flutter analyze` and `flutter test` are green (Codemagic `ci` workflow).
- [ ] Tested a **release** build from TestFlight and the Play internal track on real devices:
      email sign-up/sign-in, password reset, Google, Apple, sign-out, account deletion.
- [ ] Crash reporting (e.g. `firebase_crashlytics`) and App Check considered.
- [ ] Firebase Security Rules locked down for every Firebase product you added
      (Firestore/Storage default to deny in production mode).
