# Reader’s Digest implementation plan

## Goal and scope

Implement the supplied Reader’s Digest design as native Flutter screens in
`mfb-think-tank`, backed by Crucix’s existing Reader’s Digest behavior and APIs.
The signed-in landing experience becomes the digest. Deliver the library,
article reader, ratings/personalization, AI write-ups, cited research, and the
account/BYOK sheet required by that flow.

Dashboard, maps, live media, market/stall functionality, and investment ideas
are outside this feature. Existing sign-in and profile flows remain integration
points. This document is a plan; application implementation has not started.

## Sources of truth inspected

- UI archive: `/home/rsanchez/Downloads/Stall_ Farmers Market App.zip`.
- `Digest Flow.dc.html`: actual feed, reader, and account interaction design.
- `Crucix Digest App.dc.html`: 390×844 phone framing around that flow. Device
  chrome is preview decoration; Flutter uses real system insets.
- Crucix source root: `/home/rsanchez/Development/texas697/crucix`.
- `lib/digest/index.mjs`: API payloads, filtering, voting, summary/research calls.
- `lib/digest/prefs.mjs`: personalization rules.
- `lib/digest/store.mjs`: shared articles and per-user persistence.
- `lib/digest/summarize.mjs`, `research.mjs`: generated Markdown and research stages.
- `server.mjs`, `lib/auth/firebase.mjs`, `lib/auth/users.mjs`: endpoint/auth/BYOK contracts.
- Flutter: `lib/app/router.dart`, `theme.dart`, `features/home/presentation/home_screen.dart`,
  `features/auth/application/auth_providers.dart`, `core/config/app_config.dart`.

**Precedence:** supplied HTML determines presentation; Crucix determines real
business behavior. The prototype’s hard-coded articles, account, model name,
library count, key toggle, and timed AI simulations do not become production data.

## 1. Resolve integration prerequisites before building screens

### Identity: mandatory first gate

Flutter’s generated Firebase options name project `mfb-think-tank`; Crucix’s
`.firebaserc` names `crucix-intel-41718`. Confirm the actual backend project at
deployment, then choose the identity model explicitly.

Recommended default: move this app onto the Crucix Firebase project
(`crucix-intel-41718`). The app has no production users yet (the home screen is
still the template placeholder), so switching now is cheaper than running two
projects. It gives shared accounts, preferences, BYOK settings, and research
records with the Crucix web app for free, and removes any UID-collision mapping.

Cost of switching: regenerate `lib/firebase_options.dart` with
`flutterfire configure`, create new Google OAuth client ids for
`config/app_config.json`, register the Android SHA fingerprints, and replace
`ios/Runner/GoogleService-Info.plist`. Existing Google/Apple sign-in code and
tests do not change.

Backend change (either way): Crucix only accepts Bearer tokens on the internal
sweep/ingest endpoints. `requireAuth` in `lib/auth/firebase.mjs` must also
accept `Authorization: Bearer <Firebase ID token>` via `verifyIdToken`, keep the
existing `__session` cookie path for the browser, and apply the same
`isEmailAllowed` policy to both.

Fallback only if a shared project is rejected: keep `mfb-think-tank`, verify
tokens with a second Admin Auth instance, and namespace backend user ids by
project. This creates independent mobile records and must be decided before the
adapter is written.

- Read UID/email from verified claims. Never equate accounts by email alone.
- Add an auth/data-layer token gateway in Flutter; SDK types never enter digest UI.
- Refresh an expired token once on 401; then expose a reauthentication state.
  Do not treat access denial or network failure as Firebase sign-out.
- Clear user-bound providers and pending operations on sign-out/account change.
- Preserve protected digest deep links through existing `authRedirect`.
- Do not manually edit `lib/firebase_options.dart`; any shared-project choice
  requires deliberate Firebase provisioning and regenerated configuration.

**Gate:** authenticated `/api/me` and `/api/digest/list` succeed with the selected
identity, and two users cannot read/change one another’s settings or research.

### Backend availability and research execution

- Configure a real HTTPS Crucix API base URL via `AppConfig` and
  `config/app_config.json`; no embedded deployment hostname or secret.
- Verify digest ingestion, a populated library, Firestore access, and
  `BYOK_ENCRYPTION_KEY` availability. Settings endpoints exist only with auth enabled.
- Research POST returns 202 and continues in an unawaited in-process promise.
  `deploy/cloudrun.sh` pins one instance with a 3600-second request timeout but
  does not pass `--no-cpu-throttling`, so CPU after the 202 response is not
  guaranteed. Add that flag on the Crucix branch (raises cost) and verify a full
  research run completes with no open request. A durable worker is out of scope
  unless `--max-instances` rises above one.
- Validate stale-running/retry behavior after instance restart. The
  deduplication map is process-local, which is acceptable under one instance;
  the real gap is the stored `running` record, which blocks regeneration for
  five minutes after a crash.
- `/api/me` and all `/api/me/llm*` endpoints exist only when Crucix auth mode is
  on. Local development with auth off cannot exercise the BYOK sheet; use a
  deployed or auth-enabled instance for that milestone.
- Native mobile is the primary target indicated by the archive and Flutter config.
  If Flutter web becomes a target, add explicit allowed-origin CORS/preflight and
  verify web Firebase configuration as a separate prerequisite.

## 2. Contract and data layer

Use Crucix over HTTP; leave ingestion, extraction, scoring, LLM execution, and
Firestore ownership in the backend. Add `http`, `url_launcher`, and SVG support
if using the supplied brand SVG. The original `flutter_markdown` package is
discontinued; pick its maintained successor (`flutter_markdown_plus` or
`markdown_widget`) in milestone 2 and record the choice here before the reader
is built.
Bundle Geist/Geist Mono with their licenses for reproducible typography.

| Interaction | Existing contract |
|---|---|
| Library | `GET /api/digest/list?filter=&topic=&q=&limit=` |
| Article | `GET /api/digest/article/:id` |
| Rating | `POST /api/digest/:id/feedback`, `{rating: -1, 0, 1}` |
| Write-up | `POST /api/digest/:id/summarize`, returns full article |
| Begin/regenerate research | `POST /api/digest/:id/research`, 202 |
| Research status/result | `GET /api/digest/:id/research` |
| Account/capabilities | `GET /api/me` |
| Save key/provider/model | `PUT /api/me/llm` |
| Remove configuration | `DELETE /api/me/llm` |
| Check saved provider | `POST /api/me/llm/test` |

`POST /api/digest/open` is dashboard URL-ingestion behavior and is not needed for
the digest-only journey.

Typed models: article card, article detail, feed response/query, topic count,
taste entry, research result/source, and public AI settings/provider metadata.
Parse nullable timestamps/optional fields defensively. Keep summary/research
Markdown intact rather than expecting prototype-only `tldr`/`points` fields.

Server-fixed values to encode in the models:

- Filter values are the server strings `all`, `foryou`, `thinktank`, `news`.
- The server truncates `q` to 100 characters, `topic` to 40, and ids to 40.
  Mirror those caps in the query model.
- The research object has two shapes: the article endpoint returns a trimmed
  projection, and the research GET returns the raw stored document or
  `{state: 'none'}`. One decoder must accept both, treating unknown fields as
  optional.
- `summarizedBy` is the role string `user` or `operator`, not an identity. The
  reader attributes write-ups by model, never as "by you".
- Research `sources` are only written at the `synthesizing` stage, so an empty
  list during `searching`/`reading` is correct, not an error.
- `SUPPORTED_PROVIDERS` has eight entries. `openai-compatible` has
  `needsKey: false` and `needsBaseUrl: true`. The settings model must carry
  `baseUrl` so a same-provider update does not drop it.

Repository contracts expose feature failures for unauthenticated/forbidden,
not-found, insufficient article text, missing/invalid AI settings, unavailable,
timeout/network, and malformed responses. Map SDK/HTTP exceptions in data.
Use bounded timeouts appropriate to summaries (backend allows 60 seconds),
settings tests, and short polling calls. Never automatically retry a rating or
AI-generation POST: a lost response can conceal a successful mutation.

The list defaults to 120 items and caps `limit` at 300; there is no cursor.
First delivery requests up to 300, displays loaded and matching counts honestly,
and does not pretend to paginate the full library. Cursor pagination is a backend
contract extension if loading beyond that cap becomes a requirement.

## 3. State and routing

- Keep `/` as the digest by replacing `HomeScreen`; do not add a `/digest`
  redirect. `authRedirect` special-cases the home path for deep-link memory, and
  a redirect hop would make `/digest` the remembered location on every cold
  start. Add `AppRoutes.article = '/article/:id'` nested under home, matching
  the existing `/profile` pattern. `/profile` remains reachable.
- Encode `filter`, `topic`, and `q` in the route. Default invalid filters to `all`.
  Push explicit filter/topic changes; replace debounced search changes so typing
  does not create a history entry per keystroke.
- Preserve query and scroll position when opening/closing an article. Back closes
  the reader; a cold article deep link has an explicit fallback to the digest.
- Query state drives a Riverpod feed provider. Debounce search by 250 ms and
  prevent older responses from replacing newer queries.
- Key article/research state by article and authenticated user. Discard late
  responses from closed readers or previous users.
- Serialize ratings per article and disable duplicate taps while saving. Apply the
  server’s returned rating: pressing the selected thumb clears it. Reconcile feed,
  reader, taste, counts, and ranking after success; show retryable failures visibly.
- Poll research about every 2.5 seconds while the reader is visible and app is
  active. Stop on close, dispose, sign-out, or terminal state. Back off transient
  failures; refresh authoritative state on resume/reopen, with no new generation.
- Disable duplicate summary/research actions. Successful summaries refresh the
  article and invalidate feed metadata/topics; failed actions retain readable content.

### Preserve Crucix semantics

- `All` and `For you` use server ordering: chronological below five saved ratings,
  then 55% topic affinity plus 45% exponentially decayed recency.
- `For you` excludes negatively rated articles. Think tanks/News stay chronological.
- Topic scores use a Beta prior and require two observations to move off that
  prior. Taste and personalization readiness come directly from the API response.
- Search matches title, description, source, topics, and summary Markdown.
- Topic identity remains the server’s original tag; only its displayed label is
  prettified. Never send a title-cased label as the filter value.
- Featured item is the first server-ordered result when search/topic are clear;
  its label follows server `mode`, not a client-only sorting rule.
- `storeSize` represents the backend’s cached library size, not every historical
  Firestore article. Avoid presenting it as an unlimited archive count.
- Write-ups are shared article data; votes and research are user-specific.
  Preserve this distinction when caching and attributing results.

## 4. Flutter presentation

### Library

Match the dark supplied flow: `#05070b` background, `#0a0d14` cards,
`#111520` raised surfaces, subtle borders, blue accent, purple think-tank badges,
blue news badges, Geist typography, and mono status text. Use a feature theme
and named tokens; read `Theme.of(context)` in consuming widgets.

Build the brand/account header, title/subtitle, pinned search + four filters,
horizontal topic counts, taste row, truthful library/ranking status, featured
card, article cards, write-up tags, and independent thumbs controls. Use a lazy
scrolling layout and preserve content during refresh. Include initial loading,
empty library, no matches/clear filters, refresh error, and retry states.

### Reader

Full-screen slide-in on phones, constrained readable content on wider screens.
Sticky back/rate/original toolbar; source, kind, time, author, title, topic links;
selectable Markdown write-up styled with the supplied section hierarchy.

Show the real excerpt when no AI write-up exists, generation/no-key CTA,
writing state, attribution from `summaryModel`/`summarizedBy`, and extraction
limitations with Original fallback. Research supports none/running/done/error,
real stage/progress, cited Markdown, source links, actual model/time, and regenerate.
Launch only valid HTTP(S) original/source links and surface launch failures.

### Account/BYOK sheet

Use actual user initials/email/sign-in provider. Include AI provider selection,
model/default, masked saved key hint, obscured entry, save/update/remove/test,
saving/error states, and Done. Expose the three designed providers first
(Anthropic/OpenAI/Gemini), while preserving other existing saved provider values.
Provider/model defaults come from `/api/me` metadata.

The server stores one active AI configuration, not three independent keys.
Switching providers requires an appropriate replacement key, never silent reuse
of a different provider’s key. Omitted `apiKey` retains the current key for a
same-provider update. Always resend the saved `baseUrl` on update so the
`openai-compatible` provider keeps working. The prototype toggle is not a real enable/disable endpoint:
use explicit connect/change/remove behavior rather than inventing saved state.
Do not expose `autoIdeas` in this digest feature; preserve its stored value.
Raw keys are transient form input, cleared after use, never logged/persisted by
Flutter. Display encryption copy only when backend BYOK capability is enabled.

### Responsive/accessibility acceptance

Match the 390-pixel reference and verify 320/390/430-pixel widths plus a wide
layout. Keep safe areas, keyboard insets, 48-pixel control targets, semantic
labels, focus navigation, sufficient contrast, and 200% text scaling without
overflow. No simulated OS status bar/home indicator or fixed phone-height canvas.

## 5. Proposed code ownership

```
lib/core/network/                       authenticated HTTP transport/token gateway
lib/features/readers_digest/data/       models, repository contract/HTTP implementation, failure
lib/features/readers_digest/application/ providers, feed/actions/research controllers
lib/features/readers_digest/presentation/ shell, screens, layout, small widgets/theme
lib/features/digest_settings/data/      AI settings models/repository/failure
lib/features/digest_settings/application/ settings providers/controller
lib/features/digest_settings/presentation/ account sheet and key form
assets/brand/                          supplied mark
assets/fonts/                          licensed bundled typography
test/                                  mirrors production files
```

Use package imports and `material_ui` widgets. One primary type per file;
production files target 120 lines, split past 160, never grow past the repo’s
220-line limit. Keep UI SDK-free, providers in application, injected transports
and repositories, private leaf widgets, and keys on interactive test controls.

## 6. Ordered delivery milestones and exit gates

1. **Identity/API foundation.** Resolve account-sharing decision, add verified
   mobile auth bridge/configuration, prove user isolation and real list access.
   Backend changes belong to a separately prepared Crucix branch; Flutter branch
   is `feature/readers-digest`. Do not deploy an incomplete auth adapter.
2. **Models/repositories/state.** Capture sanitized real response fixtures;
   implement typed decoding, feature failures, query/routing, and injected providers.
   Gate: null/partial payloads, 401 refresh, stale requests, and mutation failures
   covered without Firebase/network in widget tests.
3. **Library vertical slice.** Real cards, filters/search/topics/taste, feature
   styling, featured selection, and persisted ratings. Gate: list↔reader rating
   parity, correct server-driven ranking, no-matches recovery, responsive review.
4. **Reader and BYOK.** Real article/excerpt/Markdown/original/topic navigation,
   functioning settings sheet and write-up generation. Gate: save/test/reload key
   hint, missing-key path, provider switch, 404/422, and summary metadata refresh.
5. **Research lifecycle.** Start/poll/error/retry/regenerate/result/sources; prove
   backend execution survives expected deployment conditions. Gate: close/reopen
   and app pause/resume recover saved work, pollers stop, user data never leaks.
6. **Release verification.** Run required checks, exercise real authenticated
   end-to-end journey, compare reference visuals, and resolve remaining blockers.

## 7. Verification and definition of done

Meaningful automated coverage:

- Repository contract fixtures and HTTP/status mapping; nullable article dates,
  missing fields, summary Markdown, research state/source decoding.
- Feed search debounce/out-of-order completion, routing/back/deep-link restoration,
  query preservation, user change cleanup, serialized server-confirmed votes.
- Research disposal/pause/resume/backoff and stale response rejection using fake
  time; successful/failed generation without duplicate POSTs.
- Widgets: featured/card/thumb behavior, loading/empty/error, Markdown/source
  links, BYOK validation/provider replacement, keyboard and large text layouts.
- Backend adapter: accepted/rejected project tokens, expiry/revocation policy,
  access policy, cookie compatibility, and cross-user isolation.

Required Flutter commands after implementation:

```bash
dart format <changed files>
flutter analyze
flutter test --dart-define-from-file=config/app_config.json
```

Run with `scripts/run.sh`. Manually verify: sign in → filter/search → open
article → rate → connect/test key → generate write-up → start research → close
and reopen → read cited result → open source → sign out → sign in as another
user. Perform at least one live AI/research check with a configured test account;
unit tests must not spend provider credits.

Done means reference-aligned native UI using real Crucix contracts, passing
checks, verified auth/deployment prerequisites, complete failure/recovery states,
and no hard-coded demo content or nonfunctional controls.

## Decisions confirmed before milestone 1

1. **Firebase project:** move to `crucix-intel-41718` (completed: apps
   registered, `firebase_options.dart` / `google-services.json` /
   `GoogleService-Info.plist` regenerated, debug+release SHA-1/SHA-256
   registered, OAuth client ids updated in `config/app_config.json`).
2. **API origin:** `https://crucix-qa65slel7a-uc.a.run.app` via
   `CRUCIX_API_BASE_URL` in `config/app_config.json`.
3. **Cloud Run CPU:** `--no-cpu-throttling` added to Crucix
   `deploy/cloudrun.sh` (Crucix branch `feature/mobile-bearer-auth`, which
   also adds Bearer Firebase ID token support to `requireAuth`). Redeploy
   Crucix to pick both changes up.
