# FinBrief Backend

Node/Express API for the FinBrief AI Financial Intelligence Platform (news, AI translation/summary/impact/voice-summary, watchlist alerts, billing). Structure: `routes/` → `controllers/` → `services/`.

## Setup

```bash
npm install
cp .env.example .env   # fill in real keys as they become available
npm start
```

Without `GEMINI_API_KEY`, `GOOGLE_TTS_API_KEY`, `NEWS_API_KEY`, or `ANDROID_PACKAGE_NAME` set, the corresponding service runs in **mock mode** (sample data / auto-approved purchases) so the app is usable end-to-end before real credentials exist.

## Routes

| Path | Auth | Notes |
| --- | --- | --- |
| `GET /health` | none | liveness check |
| `POST /auth/bootstrap` | Firebase ID token | creates user profile + starts trial on first call |
| `GET /auth/profile` | Firebase ID token | |
| `GET /config` | none | server-driven feature flags / min version |
| `GET /news/feed`, `GET /news/breaking`, `GET /news/search` | none | free/unlimited, server-cached |
| `GET/POST/DELETE /news/bookmarks` | Firebase ID token | |
| `POST /ai/translate`, `/summary`, `/impact`, `/chat`, `/voice-summary` | Firebase ID token | gated by `aiAccess` middleware (trial/free-credits/premium) |
| `GET/POST/PATCH/DELETE /watchlist` | Firebase ID token | |
| `POST /notifications/token`, `GET/PATCH /notifications/preferences` | Firebase ID token | WhatsApp alerts require `plan: premium` |
| `POST /billing/verify`, `GET /billing/status` | Firebase ID token | verifies Google Play purchase tokens |

## Access model

7-day unlimited trial, then `DAILY_CREDITS_FREE` AI calls/day (resets midnight UTC) for free users, unlimited for `plan: premium`. Enforced server-side from Firestore (`middleware/aiAccess.js`) — never trust client-side counters. `X-Idempotency-Key` header prevents double-charging on retries.

## Scheduled jobs

`jobs/breakingNewsJob.js` implements the v11 notification flow: detect new breaking news → AI summary → write to each user's `notifications` subcollection → FCM push. Disabled by default; set `ENABLE_CRON_JOBS=true` to run it (every 15 min). It dedupes against `app_config/breaking_seen` so a quiet news cycle is a no-op, and sends at most one article per run.

## Firestore collections

`users` (+ `bookmarks`, `watchlist`, `portfolio`, `notifications`, `purchases` subcollections), `feedback`, `ai_history`, `ai_request_keys`, `news_cache`, `app_config`.

Security rules live in `../firestore.rules`. Note the Admin SDK used here **bypasses** those rules — they exist to constrain the Flutter client's direct Firestore access.

## Not yet wired up

- Scheduled jobs (daily digest, watchlist price alerts, morning brief/evening summary notifications) — no `node-cron` jobs yet, add under a `jobs/` folder when ready.
- Real news/AI/TTS/billing credentials — currently all mock mode.
- Firestore security rules / indexes for this project.
- Portfolio module (distinct from Watchlist per the PRD) — not yet built.
