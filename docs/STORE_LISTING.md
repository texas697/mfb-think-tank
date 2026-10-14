# Store listings

Copy and settings for Google Play and the App Store. Keep this file the
source of truth; the Play listing text and images are pushed from it with the
Play Developer API (service account `mfb-think-tank-play-submit`), the App
Store side through App Store Connect.

Identifiers never change: Android `com.mfbservicesinc.mfb_think_tank`, iOS
`com.mfbservicesinc.mfbThinkTank`.

## Shared

| Field | Value |
| --- | --- |
| Name | MFB Think Tank |
| Operator | MFB Services, Inc. |
| Contact email (public) | rsanchezdev697@gmail.com |
| Privacy policy | https://mfbintelligence.com/privacy |
| Terms | https://mfbintelligence.com/terms |
| Website (marketing) | https://mfbintelligence.com/mfb-think-tank |
| Account deletion URL (Play) | https://mfbintelligence.com/privacy#delete-account |
| Support URL | https://mfbintelligence.com/support |
| Category | News (App Store) / News & Magazines (Play) |
| Age rating | App Store 13+ (questionnaire: infrequent realistic violence, weapons, mature real-world themes, alcohol/drug references); Play per content rating questionnaire |
| Price | Free, no in-app purchases, no ads |
| Reviewer demo account | `reviewer@mfbservicesinc.com`, password in `~/.secrets/store-reviewer-account.txt` |

Reviewer instructions: Sign in with the demo account using email and
password. Tap the initials in the top right to open the account sheet, which
holds the optional AI key. Rating, search and filters need no key.

## Google Play

Short description (80 max):

> Think-tank analysis with AI write-ups and a feed that learns what you read.

Full description: see `scripts/play_spec.json` (kept out of the repo; the
text is the App Store description below with the ★ section headers).

Graphics: icon 512×512 (`docs/store-assets/play-icon-512.png`), feature
graphic 1024×500 (`docs/store-assets/play-feature-graphic-1024x500.png`),
five 1080×1920 phone screenshots. Screenshot sources live in the Play Console
once uploaded.

Console-only settings (the API cannot set these):

- Store settings: category News & Magazines, tags News aggregator, News &
  magazines, Business (the Play tag list has no politics or research tags);
  website and privacy policy URL above.
- App content: no ads; app access restricted, demo account above; content
  rating questionnaire (News / Reference), target audience 18+; news app
  declaration: on behalf of the developer account's legal entity, contact
  URL https://mfbintelligence.com/support, commercial / private, aggregator
  yes, no credentials; advertising ID no; not a government app; no financial
  or health features.
- Data safety: collects email address and user ID (account management,
  required); app activity: ratings and saved deep dives (app functionality,
  personalisation); article text is sent to an AI provider (the operator's
  shared DeepSeek key by default, or the user's own key) when they request a
  write-up or deep dive; encrypted in transit; account deletion available in the app (Profile, Delete account)
  and described at the privacy URL under "Deleting your account and data".

## App Store

| Field | Value |
| --- | --- |
| Subtitle (30 max) | Think-tank analysis, ranked |
| Promotional text (170 max) | AI write-ups for long-form policy analysis, and a feed that learns from what you rate. |
| Keywords (100 max) | think tank,policy,analysis,news,defense,markets,geopolitics,research,digest,AI summary |
| Sign in with Apple | Required because Google sign-in is offered; already implemented |
| Account deletion | In app: Profile, Delete account (guideline 5.1.1(v)) |
| App privacy | Published 2026-10-13: email address, user ID, other user content (ratings, deep dives) and crash data (in-app error reports), all linked to the user, no tracking; policy URL https://mfbintelligence.com/privacy |
| Export compliance | Uses only standard HTTPS encryption (exempt) |
| Screenshots | 6.3" (1206×2622), iPhone Duo and iPad 13" sets of the five MFB-branded mockups (01-feed … 05-your-key) in the Asset Library |
| App icon | `docs/store-assets/asc-icon-1024.png` (square, no alpha; Apple applies the corners) |
| Header asset | `docs/store-assets/asc-header-5244x2950.png`, rendered from `asc-header.html` at 2622×1475 CSS px, DPR 2. The PNG still shows the old crosshair tile; re-render after dropping the phone screenshots (`p1_phone.png`, `p2_phone.png`, kept out of the repo) next to the HTML |

Description:

> MFB Think Tank collects long-form analysis from think tanks and the policy
> press in one feed, and helps you get through it faster.
>
> AI write-ups. Open any piece for a TL;DR, key points, why it matters and what
> to watch for. Pieces without a write-up can be summarized on demand with your
> own AI key.
>
> A feed that learns. Give a thumbs up or down to any piece. After five ratings
> the feed re-ranks itself around the topics you care about, and the For You
> filter shows only what matches your taste.
>
> Deep dives. Tap "Read more about it" on any story. MFB Think Tank gathers
> related coverage from across the web and has your model write a cited
> companion piece: background, competing interpretations, implications and what
> to watch. Results are saved to your account.
>
> Search and filter. Search titles, topics and write-ups. Filter by think tanks
> or news, and narrow by topic: defense, energy, markets, technology, Europe,
> Asia Pacific and more.
>
> Bring your own key. Connect an Anthropic, OpenAI, Gemini or other supported
> API key. Your key is encrypted at rest and used only for your own write-ups
> and deep dives.
>
> MFB Think Tank links to every original source. Summaries are generated by AI
> and may contain errors; always read the original for anything important.

## App Store status (2026-10-13)

Version 0.2.2 with build 4 attached, description, promo text, keywords,
review sign-in and notes, subtitle, category News, content rights (third
party, licensed), age rating 13+, app privacy published, price free in 175
countries. Product page header replaced 2026-10-13 with the MFB Think
Tank version; the old "Crucix Digest" header was deleted from the Asset
Library. Not yet submitted: press Add for Review on the version page
after TestFlight checks of Google and Apple sign-in on build 4.

## Play status (2026-10-13)

All App content declarations, store settings and the listing are submitted.
Internal testing: release 0.2.2 (version code 3), tester list "Default",
join link https://play.google.com/apps/internaltest/4701429656512098957.
Closed testing (Alpha): 178 countries, same tester list, release 0.2.2 sent
for review. Production access needs 12 opted-in closed testers for 14 days.

## Open items

- Grow the closed-test tester list to 12 and keep them opted in for 14 days,
  then apply for production access.
