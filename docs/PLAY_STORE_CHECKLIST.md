# Play Store submission — answers and outstanding items

Derived from what the code actually does, not from what the app intends to do.
If a feature changes, re-check the matching row here before the next release.

---

## 1. Store listing URLs

| Field | Value |
|---|---|
| Privacy Policy | `https://finbrief-backend.onrender.com/privacy` |
| Terms of Service | `https://finbrief-backend.onrender.com/terms` |
| Account deletion | `https://finbrief-backend.onrender.com/delete-account` |
| Support email | `instaflow38@gmail.com` |

All three pages are served by the backend from `backend/legal/*.json`, need no
login, and sit above the rate limiter so a Play reviewer can always reach them.

---

## 2. Data Safety form

Answer **Yes** to "Does your app collect or share any of the required user data
types?" and **Yes** to "Is all of the user data collected by your app encrypted
in transit?" (every call is HTTPS). Answer **Yes** to "Do you provide a way for
users to request that their data be deleted?" and give the deletion URL above.

For every row below, "Collected" is ticked. "Shared" is only ticked where noted
— data going to Google as our infrastructure provider counts as *processing*,
not sharing, so those rows are collected-only.

### Personal info

| Data type | Collected | Shared | Ephemeral | Required? | Purposes |
|---|---|---|---|---|---|
| Email address | Yes | No | No | Required | App functionality, Account management |
| Name | Yes | No | No | Optional | App functionality, Account management |
| User IDs | Yes | No | No | Required | App functionality, Account management |

Name is optional because it only exists when the user chooses Google Sign-In.

### Financial info

| Data type | Collected | Shared | Ephemeral | Required? | Purposes |
|---|---|---|---|---|---|
| Purchase history | Yes | No | No | Optional | App functionality, Account management |
| Credit info | No | — | — | — | — |
| Other financial info | Yes | No | No | Optional | App functionality, Personalisation |

"Other financial info" covers portfolio holdings the user types in (symbol,
quantity, purchase price). These are **self-entered figures, not linked to any
broker or bank account** — the app has no access to real balances or trades. It
still has to be declared. Both are optional: a user can use the whole app
without adding a holding or buying anything.

### App activity

| Data type | Collected | Shared | Ephemeral | Required? | Purposes |
|---|---|---|---|---|---|
| App interactions | Yes | No | No | Required | Analytics, App functionality |
| Other user-generated content | Yes | No | No | Optional | App functionality |
| Search history | No | — | — | — | — |

"Other user-generated content" is bookmarks, watchlist entries, feedback text,
and the questions asked in AI chat. Search history and reading history are
**not** declared: they never leave the device (stored in SharedPreferences),
which is exactly the exemption for on-device-only data.

### App info and performance

| Data type | Collected | Shared | Ephemeral | Required? | Purposes |
|---|---|---|---|---|---|
| Crash logs | Yes | No | No | Required | Analytics |
| Diagnostics | Yes | No | No | Required | Analytics |

### Device or other IDs

| Data type | Collected | Shared | Ephemeral | Required? | Purposes |
|---|---|---|---|---|---|
| Device or other IDs | Yes | **Yes** | No | Required | Advertising or marketing, App functionality |

This is the one row with **Shared** ticked. AdMob receives the advertising ID to
serve ads, and AdMob is a third party rather than infrastructure we run. The FCM
push token also sits under this type and is used for App functionality.

### Not collected

Do not tick: Location, Health and fitness, Messages, Photos and videos, Audio
files, Files and docs, Calendar, Contacts, Web browsing history, Sports,
Installed apps. None of these are touched anywhere in the codebase.

> The voice feature reads text aloud with the phone's own TTS engine. Nothing is
> recorded and there is no microphone permission, so it is not an audio
> declaration.

---

## 3. Content ratings and declarations

- **Ads**: Yes — the app contains ads (AdMob).
- **Target audience**: 18+. The app is financial and the Terms require it.
- **News app declaration**: FinBrief aggregates third-party financial news, so
  expect the News category questions. It is an aggregator, not a publisher.
- **Financial features declaration**: Play asks whether the app offers financial
  services. FinBrief does **not** — no trading, lending, payments, or investment
  advice. Answer accordingly, but read the section below first.

---

## 4. Outstanding before you can publish

These are blockers, in the order they will stop you.

1. **Upload keystore.** The APK is currently signed with the debug key
   (`android/app/build.gradle.kts`). Play rejects debug-signed uploads. Once
   created, back the keystore up somewhere you will not lose it — losing it
   means you can never update this app again.

2. **Real AdMob App ID.** The manifest still carries Google's public test ID
   (`ca-app-pub-3940256099942544~3347511713`). Ads earn nothing with it, and
   shipping a test ID risks a policy strike.

3. **Play Console billing products.** Create ONE subscription with three base
   plans — not three separate products, so a user can change period without
   cancelling:

   | Field | Value |
   |---|---|
   | Subscription ID | `finbrief_premium` |
   | Base plan `monthly` | P1M, ₹199 |
   | └ Offer on `monthly` | ₹49, first billing period, **new subscribers only** |
   | Base plan `six-month` | P6M, ₹899 |
   | Base plan `yearly` | P1Y, ₹999 |

   Then grant the backend's service account **"View financial data"** under
   Play Console → Setup → API access, or purchase verification fails and nobody
   gets Premium after paying.

   The ₹49 is an *introductory offer* attached to the monthly base plan, not a
   separate product — Play then enforces one-per-user by itself.

4. **Legal review, specifically SEBI.** The app comments on named securities to
   Indian users. The Terms state plainly that nothing is investment advice and
   the AI sections are written as observation rather than recommendation, but
   whether that is sufficient under the SEBI investment-adviser and
   research-analyst regulations is a question for a lawyer, not for us.

5. **A support inbox you actually read.** The address above is published in
   three places; Play checks that it works.

---

## 5. Known gaps worth fixing, not blockers

- Gemini runs on the free tier (20 requests/day/model), so AI features stop
  working partway through a busy day. A paid key is the single biggest
  functional upgrade available.
- Firestore composite index for `news_archive` (category + publishedAtMs) is
  not created; the archive falls back to a slower index-free query.
- Test coverage is thin — one widget test plus the backend smoke suite.
- The app has never been used by anyone other than us.
