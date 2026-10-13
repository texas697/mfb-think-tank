# Agent instructions

Follow these when changing this repo. Cursor also loads the matching files
in `.cursor/rules/`.

## Commands

```bash
dart format <changed files>
flutter analyze
flutter test --dart-define-from-file=config/app_config.json
```

Run the app with `scripts/run.sh` (it passes `config/app_config.json`).

## Workflow

- Do all work in a git worktree on a feature branch, never in the main
  checkout: `git worktree add ../<repo>-<topic> -b <type>/<topic> main`.
  Remove it after the PR merges.
- Land changes through a pull request. Do not push to `main`.
- Do not push `v*` tags or deploy unless asked. Codemagic bills per build:
  `ci` runs on pushes to and PRs targeting `main`, and a `v*` tag starts the
  Android and iOS release builds. Batch changes into one PR.
- Changes that only touch `*.md` or `docs/` skip `ci`.

## Layout

```
lib/main.dart                         Firebase init, then ProviderScope + App
lib/app/                              MaterialApp, go_router, theme
lib/core/config/                      AppConfig from config/app_config.json
lib/core/network/                     Authenticated Crucix HTTP client, ID token seam
lib/features/<name>/{data,application,presentation}
test/                                 mirrors lib/
test/helpers/                         shared mocks
```

- New features go in `lib/features/<feature>/{data,application,presentation}`.
  Skip an empty layer.
- `data` never imports `presentation` or Flutter widgets. UI never imports
  Firebase, Google, or Apple SDK types. It talks to a repository and a
  feature failure type (`AuthRepository`, `AuthFailure`).
- Route paths live on `AppRoutes`. Import app code with
  `package:mfb_think_tank/...`. Widgets come from
  `package:material_ui/material_ui.dart`.
- Do not edit `lib/firebase_options.dart`. Never commit
  `android/key.properties` or `*.jks`.

## Structure

- Production files target 120 lines, split past 160, and must not grow once
  they pass 220. Tests and generated files are exempt.
- One primary type per file. Keep helpers private until another file needs
  them. No `utils.dart`, `helpers.dart`, or barrel `index.dart`.
- Booleans are `isX` / `hasX` / `canX`. Callbacks are `onX`. Methods name the
  action (`signIn`). Colocate a type with the behavior it describes.
- `///` documents the public API. A `//` comment only records a constraint
  the name cannot show.

## Widgets

- Keep each `build` method to about 6 levels of nesting. Extract a widget
  class when deeper, not a `Widget _buildX()` method.
- Split a screen into an app shell, a screen whose content is a flat
  `children` list, a layout wrapper (scaffold, centering, scroll, max width),
  and small leaf widgets.
- Do not use `Builder` only to get a context below `MaterialApp`. Extract a
  widget so its own `build` context is in the right place.
- Make extracted widgets private unless another file needs them. Reuse
  `AuthScaffold` before adding another centered layout.
- Read `Theme.of(context)` in the widget that uses it. Prefer `const`
  constructors.

## Riverpod

- Providers live in `application/` and are named `<thing>Provider`. Depend on
  other providers with `ref.watch`.
- Inject SDKs and config through providers (`firebaseAuthProvider`,
  `appConfigProvider`, `targetPlatformProvider`). Widgets must not call
  `FirebaseAuth.instance`.
- `ref.watch` for UI state; `ref.read` inside callbacks and `runAuthAction`.
- Repository methods throw only the feature failure type. Map SDK exceptions
  in `data`.
- Auth screens run async work through `AuthActionMixin.runAuthAction`.
- Keep redirect decisions in the pure `authRedirect` function.
  `authStateChangesProvider` drives routing; `currentUserProvider` is for
  display.

## Tests

- Mirror `lib/` under `test/`. Shared mocks live in `test/helpers/mocks.dart`.
  Prefer `firebase_auth_mocks`; use mocktail when it cannot cover the case.
- Test pure functions directly. Widget tests override providers instead of
  touching Firebase.
- Find controls by `Key` (`sign-in-email`, `sign-in-submit`). Add a `Key` on
  a new control a test will tap or fill.
- Reset `tester.view` and dispose `GoRouter` with `addTearDown`.
