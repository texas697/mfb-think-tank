# Mobile Crucix feature parity

## Goal and decisions

Deliver Dashboard, Reader’s Digest, Live Media, and Telegram in MFB Think Tank, preserving the existing dark Geist design, native navigation, reader, account sheet, feedback, and authentication. Implementation is authorized immediately after this plan; no separate approval milestone is required.

Baseline: mobile `d415c6f`, Crucix `17d26fd` (2026-10-15). Source of truth is the current Crucix application, not its older worktrees. Recheck contracts when implementation exposes a disagreement.

Use a native four-destination shell. Open Dashboard by default on launch and after sign-in (user preference). Keep Digest at `/` so existing links and article navigation continue working; add `/dashboard`, `/media/:channel?`, and `/telegram/:chat?`. Dashboard is the complete trusted-origin Crucix dashboard in a system WebView. Digest, Live Media, and Telegram remain native Flutter screens. Rebuilding the dashboard’s eighteen map layers and all its panels would create a second intelligence renderer and a large ongoing parity risk. The user was offered the choice; absent another preference, this is the recommended implementation.

Keep the dashboard’s actual map/tools/panels, not a screenshot or a summary. Native shell chrome replaces duplicate web navigation/account chrome. The WebView owns its own scroll and touch gestures. The dashboard remains responsive at phone and tablet widths. User refinement (2026-10-15): hide the map drawing/tools toolbar in the mobile Dashboard.

## Parity inventory and acceptance matrix

| Surface | Required behavior | Verification |
| --- | --- | --- |
| Shell | Four labeled destinations, retained branch location/scroll, narrow-phone and tablet layout, protected deep links, account/feedback on every destination | Router/widget tests at phone/tablet and enlarged text; Android smoke |
| Dashboard map | Pan/zoom, six regions, search, eighteen supported layers (chips appear for populated layers), layer search/info, all/none, all/1h/24h/7d windows, marker popups, signal guide | Real WebView against deterministic Crucix fixture server; JS navigation/adapter tests |
| Dashboard selection | Preserve area-brief API compatibility; hide the drawing/tools toolbar in mobile per user request | Shape API compatibility tests; fixture and on-device checks |
| Dashboard panels | Sensors, news, health, signal core, nuclear, risk, delta, disasters/quakes, outages, ideas, maritime, space, air raids, threats, tracks, predictions, macro/markets | Full hosted renderer preserved; fixture screenshot and visible panel checks |
| Dashboard live | Current sweep, health/startup/error, SSE on supported origin with existing polling fallback, live secondary feeds, AI settings/ideas | Existing web transport retained; close all web work on tab leave/background/sign-out |
| Digest | Existing filters/topics/search/taste, ratings, original article, write-up, research, account and feedback | Existing full suite plus tab-switch/back/deep-link regression coverage |
| Live Media | Exact six broadcasters, channel deep links, previous/next, native HLS, loading/buffering/error/retry, source link, existing YouTube alternatives | Channel contract test, fake-player widget tests, deterministic HLS Android smoke |
| Live Media controls | Play/pause, mute, volume (initial .6), fullscreen, supported-device PiP, muted first-four 2×2 monitor grid | Player adapter tests; Android fullscreen/PiP/grid smoke; iOS checklist |
| Telegram directory | Status/setup/disconnected distinction, only server-published chats, region groups, search, real avatars, unread count/last message, refresh | Repository and native screen tests with connected/disconnected/empty/error fakes |
| Telegram messages | Read-only selected channel, dates, reply indicators, incoming/outgoing styling, translated-first text and per-post original toggle, safe clickable URLs, refresh | Contract and widget tests, rapid-selection/sign-out races |
| Telegram attachments | Authenticated avatars/photos/full-size photo view, video/audio playback, video thumbnails, webpage previews, explicit unsupported/oversize states | Binary transport 401-refresh tests, media URL/kind tests, fixture smoke |
| Shared quality | Honest loading/empty/error/retry; no false empty results, no duplicate mutations, no offscreen streams/audio, no cross-user private data | Failure/race/lifecycle tests; full analyze/test/build |

Map layer keys: `air`, `militaryAir`, `thermal`, `conflict`, `maritime`, `ships`, `nuke`, `sdr`, `health`, `news`, `weather`, `radiation`, `space`, `gdelt`, `track`, `quake`, `disaster`, `outage`.

Channels: `aljazeera`, `rt`, `presstv`, `iranintl`, `dw`, `france24`. Copy URLs/names/regions from `crucix/dashboard/react/features/media/channels.ts`; do not invent replacement streams.

## Architecture and contracts

### Native shell and routing

- `StatefulShellRoute.indexedStack`, destination order Dashboard / Digest / Live Media / Telegram. Use Dashboard `/dashboard` as the default authenticated location; preserve Digest `/` and `/article/:id` and `/profile`.
- Shared native brand/account/feedback toolbar and destination title; reuse the existing visual proportions. Adaptive bottom navigation/rail, safe-area handling, accessible labels and stable keys.
- Split route paths and route composition if needed to keep production files within repository limits. Keep `authRedirect` pure.
- Feature controllers watch user identity; reset branch/private state on account change. Track active destination and lifecycle separately from retained branch widgets.

### Dashboard session and browser boundary

- New `dashboard/{application,data,presentation}` with an overridable browser adapter so widgets can be tested without platform views.
- Use the configured Crucix HTTPS origin only. First load its `/login` document, then execute same-origin `fetch('/api/session', {method:'POST', headers:{'Content-Type':'application/json'}, credentials:'same-origin', body:JSON.stringify({idToken})})` with a freshly obtained ID token. The browser receives the existing HttpOnly session cookie. Then navigate to `/` and restore the safe dashboard query/scroll.
- Token never enters query strings, localStorage, logs, file fixtures, or persistent Dart state. Only inject it after verifying the current main document’s exact trusted origin. No TLS bypass, file access, arbitrary script inputs, or unbounded auth retries.
- Loading overlay hides the bootstrap/login and unstyled header; failure has a clear retry action. A bounded bootstrap deadline handles network/load failures. Handle main-document failures without treating missing map tiles as a failed whole screen.
- Bounded fresh-token re-exchange on expired session. Never silently show a second login form.
- Restrict main-frame navigation. Intercept web SPA history and link clicks so Digest/Media/Telegram open the matching native route. External HTTP(S) links use the system browser. Reject executable/custom schemes. Block `/api/logout` from independently revoking app authentication.
- Hide the verified duplicate web brand/navigation/account controls, retaining the compact source-status and theme controls, with React and legacy hooks explicitly documented/tested. Retain source status, theme toggle, settings and all feature controls through native toolbar or dashboard content. Default dark; web light-mode choice must be intentional and accessible if retained.
- Normalize React `rect`/`poly` area-brief request shapes to the server’s polygon coordinate contract. This is a verified upstream mismatch: server accepts `circle` or `polygon` with `[lng,lat]`; current web UI emits `rect` or `poly` with `{lng,lat}`. Preserve already-correct payloads.
- Save only safe dashboard URL/query and scroll position and presentation filters in memory, unload the page when inactive/backgrounded, restore on return. This explicitly closes SSE, timers and map rendering; an indexed stack alone does not pause a WebView. Clear browser cookies/storage on user change and sign-out before any new user can mount it. Do not call server `/api/logout` merely when switching tabs (it revokes sessions).

### Live Media and shared playback

- `live_media/data/media_channel.dart` and channel catalog; provider/state for current channel, volume/mute, grid and active destination. Query/channel state is URL-backed.
- Use `better_player_plus` for native HLS, fullscreen and supported-device PiP, including authenticated Telegram video/audio. Pin the audited release and keep it behind a small app-owned playback abstraction. This avoids omitting PiP or maintaining our own native AVPlayer/Media3 integration. No disk cache of private attachments.
- `webview_flutter` provides Dashboard and an in-app YouTube fallback. Use direct platform implementation packages only where platform configuration is necessary (inline WebKit playback/fullscreen).
- Player lifecycle explicitly handles foreground/background, tab changes, fullscreen and PiP; only user-entered PiP may remain playing in background. Close muted grid players outside the active tab; never create all six streams eagerly. A grid uses the first four broadcasters, with one audible main stream maximum.
- Preserve selected channel and volume across tab changes. Retrying initializes a single replacement controller; stale initialization cannot attach or play after selection/disposal. Show stream failures without hiding source/YouTube alternatives.
- Android manifest: network permission and PiP activity support. iOS: background audio capability for explicit PiP and supported orientations; no broad ATS exceptions.

### Telegram data and native UI

- Typed status/dialog/message/media/webpage/translation models, a `TelegramRepository`, mapped `TelegramFailure`, HTTP implementation, injected providers. No Firebase or Telegram SDK types in UI.
- `GET api/telegram/status`: disconnected is a valid 200 status, not a transport failure. Fetch dialogs only when authenticated/connected. `GET api/telegram/dialogs?limit=200`: server groups and allowlist remain authoritative.
- `GET api/telegram/messages/:id?limit=100`: messages and `translated` flag. No invented older-message pagination (server has no cursor). Say when displaying the latest bounded window. Manual refresh matches web behavior.
- Directory search is local and retains server group order. Native chat screen opens by protected route; wide layout may show directory beside messages. Returning to directory preserves search/scroll.
- Translation uses server text with a per-message original toggle and automatic RTL for originals. Do not call another translator or expose provider secrets.
- URLs: `api/telegram/avatar/:id`; `api/telegram/media/:id/:message?kind=photo|full|thumb|file|webpage`. Encode path segments. Full-size photo viewer uses authenticated bytes and no external unauthenticated browser handoff.
- Add a byte-response method to the existing API transport, reusing exactly-one 401 refresh. Private images use an account-scoped in-memory provider, bounded fetch time/size and eviction. Video/audio get authenticated headers through the playback adapter; handle expired token without credentials in URLs. A 404 attachment gets a compact unavailable placeholder; failed messages retain previous successful messages with a retry notice.
- Maximum streamable file is 60 MiB, as enforced server-side; show size/unsupported labels for large documents. Render webpage text safely and link only to validated HTTP(S). No message composer, Telegram login, or write API.

## Implementation order

1. Create `../mfb-think-tank-feature-parity`, branch `feat/mobile-feature-parity` from `main`; copy this plan into `docs/MOBILE_FEATURE_PARITY_PLAN.md`. Run dependency resolution and baseline checks there. Main checkout stays untouched.
2. Add shell/routes/shared chrome and lifecycle/identity seams; keep Digest tests passing before adding feature logic.
3. Build/test Dashboard browser policy, bootstrap, native bridge, shape compatibility, error/retry, background teardown, and route restoration.
4. Implement playback adapter/platform capabilities, exact channel catalog and native Live Media player, controls/grid/YouTube fallback.
5. Extend transport for private binaries; implement Telegram contracts/repositories/provider lifecycle and native directory/chat/attachments.
6. Integrate identity cleanup, account/settings refresh across web/native surfaces, protected deep links, text scale/layout, loading transitions, and Android back behavior.
7. Execute automated and emulator validation, update this plan with evidence and any remaining hardware-only checks. Commit and open one reviewable PR; do not merge, release-tag or deploy.

## Verification and completion gates

Before changing tests, search repository memory for testing conventions, then verify against current tests. Tests mirror `lib`, fake repositories/browser/player adapters, use keys for controls, and dispose routers/reset tester views.

- Transport/repository tests: exact paths/query/body; 401 retry once; no credentials in URLs; network/timeout/403/404/429/5xx/malformed responses; binary size limits; no private state reuse across users.
- Bridge tests: trusted origin and redirect restrictions, token serialization, no persistent token storage, route mapping, bounded recovery, rectangle/polygon normalization, external links, inactive teardown and restore.
- UI tests: each surface loading/error/empty/success; two channel/chat switches resolving out of order; tab state preservation; translated original toggle; media oversize; grid toggling; tap targets; 320/390/768 widths and large text.
- Regression: full existing Digest/auth/settings/feedback tests. `dart format <changed files>`, `flutter analyze`, `flutter test --dart-define-from-file=config/app_config.json`.
- Android: build debug APK without release keys; emulator exercise shell, sign-in/auth bootstrap, dashboard map/tool interaction, directory/chat media, deterministic HLS playback, fullscreen/PiP, grid and background/tab shutdown. Use controlled fixtures rather than real user credentials for repeatable checks.
- iOS: Linux cannot run or compile iOS. Implement platform configuration and document physical-device checks for WebKit session cookies, HLS, fullscreen/PiP and memory pressure. Report those as unverified; do not claim an iOS device pass.
- Inspect git diff, line limits, dependency/license/platform impact. No edits to generated Firebase config, secrets, release keys, deployment workflows or tags.

Completion means every implementation row above is shipped and locally testable with passing automated checks and recorded Android evidence. External broadcaster availability, server Telegram configuration/allowlist, upstream source outages, and iOS hardware verification are operational limits to report explicitly, not reasons to replace working features with placeholders.

## Known upstream limits to preserve honestly

- React Dashboard currently passes `ships: null`; its ships toggle does not poll `/api/ais`. This pre-existing web omission is not evidence of working vessel data. Retain the web feature baseline and record the discrepancy rather than fabricate markers.
- Telegram is a bounded snapshot, not an infinite history or realtime stream. A configured-but-disconnected server is a real UI state.
- Broadcaster URLs may be offline or geographically restricted. Source links, retries and existing alternatives remain accessible.
- The configured API host responds successfully to `/api/healthz` and `/login` at planning time; authenticated data still needs fixture/emulator verification.

## Delivery status

Implemented all four destinations in `feat/mobile-feature-parity`, including the user refinements to open Dashboard by default and hide its map tools. Automated checks, native Android fullscreen/PiP, authenticated attachment playback, and the configured-backend phone installation are recorded in [the validation evidence](MOBILE_FEATURE_PARITY_VALIDATION.md). iOS build/device checks remain explicitly unverified on Linux.

## Audited sources

Mobile: `lib/app/{app,router,theme}.dart`, `lib/core/network/api_client.dart`, Digest repositories/providers/screens, `test/app/router_test.dart`, `docs/READERS_DIGEST_PLAN.md`.

Crucix: `server.mjs`, `lib/auth/firebase.mjs`, `lib/map/region-news.mjs`, `dashboard/react/features/dashboard`, `features/map`, `features/media/{channels,playback}.ts`, `features/telegram`, and their API/UI fixture tests.

Dependency rationale and APIs: [WebView Flutter](https://pub.dev/packages/webview_flutter), [Better Player Plus](https://pub.dev/packages/better_player_plus). Native player selected for its HLS, headers, fullscreen and PiP support; WebView selected to keep the complete dashboard/map implementation and server session contract.
