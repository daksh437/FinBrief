# FinBrief — brief for legal review (SEBI)

**Prepared for:** a legal adviser / company secretary reviewing whether this app
requires registration under Indian securities regulation.

**Prepared by:** the development team. This document describes what the app
does today, in factual terms. It is not a legal opinion and makes no claim
about how the regulations apply.

**App:** FinBrief — Android, `com.FinBrief`, not yet published.
**Audience:** Indian retail investors, 18+.
**Status:** pre-launch. No public users. Closed testing pending.

---

## 1. The question we need answered

Does FinBrief, as described below, require registration under:

- **SEBI (Investment Advisers) Regulations, 2013**, or
- **SEBI (Research Analysts) Regulations, 2014**?

And if it does not today, which of the features described would push it across
that line if we added or changed them?

We have built the app on the assumption that it is a **news aggregator with
automated summarisation** rather than a research or advisory service. We need
that assumption confirmed or corrected.

---

## 2. What the app is

FinBrief collects financial news headlines from third-party publishers (Economic
Times, Business Standard, LiveMint, Moneycontrol, CNBC, Yahoo Finance,
Investing.com and Google News, all via their public RSS feeds), and uses a
large language model (Google Gemini) to summarise and translate them.

It also displays market prices (indices, individual stocks, gold, forex,
crypto) sourced from Yahoo Finance, CoinGecko and the ECB via Frankfurter.

**We do not:**

- execute, place, route or facilitate any trade
- hold, receive or transfer client funds or securities
- connect to any broker, depository, bank or trading account
- receive any fee for recommending any specific security or product
- employ or engage any research analyst
- publish research reports, ratings, target prices or price forecasts

Revenue comes from a consumer subscription (₹49 first month, then ₹199/month;
₹899 for six months; ₹999 a year) and from Google AdMob advertising. Neither is
tied to any particular security, issuer, broker or product. No third party pays
us to feature anything.

---

## 3. Every feature that touches securities

Listed so nothing has to be discovered by exploring the app.

### 3.1 News feed, live tape, search, bookmarks

Headline, source name, timestamp, a short snippet and a link to the
publisher's original article. Full articles are not reproduced. No commentary
is added.

### 3.2 AI summary (on demand, per article)

The user opens an article and taps a button. The model returns 2–3 sentences
and 2–4 bullet points restating the article. Example output:

> "Reliance Industries reported a 12% increase in quarterly profit, bolstered
> by solid growth in its retail and telecom segments. However, the company's
> refining margins continued to face ongoing pressure during the quarter."

### 3.3 Hindi translation (on demand, per article)

The same summary in conversational Hindi. No content is added.

### 3.4 "What this affects" (on demand, per article)

Names the parts of the market a story concerns, and why, in factual terms.
Example output:

> "This news concerns central bank monetary policy and interest-rate sensitive
> sectors following the RBI's decision to maintain the repo rate at 6.5% due to
> food inflation concerns."
> Sectors: Banking, Financial Services, Real Estate

It does **not** state whether the news is positive or negative for any
security. See §4.

### 3.5 "In Focus Today" (home screen)

Three companies that appear in the day's headlines, each with a one-sentence
factual statement drawn from those headlines, plus that company's current
market price and day change. Example:

> RELIANCE · ₹1,325 · +3.52%
> "Shares rallied up to 3.5% on heavy volumes, hitting a record high."

The list is generated from the day's actual headlines. The model is instructed
to include only names that appear in those headlines and may not introduce
others. No ranking, score or direction is attached.

### 3.6 Portfolio-linked news

The user manually types in stock symbols and, optionally, quantity and purchase
price. The app filters the news feed to stories that concern those symbols —
either by direct mention, or via a fixed keyword map (for example, an RBI
policy story is shown to a user holding a bank, because "RBI" and "repo" are
mapped to the banking sector).

Portfolio values are calculated from figures the user enters themselves. The
app has no access to any real holding, balance or transaction, and is not
connected to any broker.

### 3.7 AI chat

A free-text assistant. Questions about terminology and about why something is
in the news are answered. **Questions asking for an investment decision are
refused before they reach the model** — see §4.3.

### 3.8 Push notifications

Breaking headlines, plus a morning and evening summary. The body text is the
AI summary of the headline. No recommendations.

### 3.9 Not present

The app does not offer, and has never offered: buy/sell/hold calls, ratings,
target prices, price predictions, model portfolios, asset allocation, tips,
stock screeners with recommendation logic, referral links to brokers, or any
paid promotion of a security.

---

## 4. Controls we have deliberately built in

These were added specifically to keep the app on the reporting side of the
line. We would like to know whether they are sufficient, and whether any are
misconceived.

### 4.1 No directional labels anywhere

An earlier build labelled securities "BULLISH" or "BEARISH" in green and red,
with a confidence percentage. **All of this was removed** before launch. The
app now states what a story says and which sectors it concerns, and nothing
about direction.

### 4.2 The model is instructed against advice

Every AI request carries a system instruction:

> "You are FinBrief, a financial news assistant for Indian retail investors. Be
> accurate, concise and neutral. Never give personalised investment advice.
> Preserve company names, tickers and numbers exactly as written."

and, for the sections that name securities:

> "You never recommend buying, selling or holding anything, never say whether
> something will rise or fall, and never predict prices."

### 4.3 Advice questions are refused deterministically

We do not rely on the model complying. A rule-based check runs **before** the
request reaches the model and refuses the following categories outright:

- "should I buy / sell / hold / invest in X"
- "is now a good time to buy / for gold"
- "what is the target price for X"
- "will X go up / fall / crash"
- "how much should I invest in X"
- "which stock should I buy"
- "recommend a stock / give me tips"

The user receives:

> "I can't tell you what to buy, sell or hold — FinBrief reports the news and
> explains what it means, and I'm not a registered investment adviser. What I
> can do is explain the story behind a company, break down a term, or summarise
> what today's news says about it. For a decision about your own money, please
> speak to a SEBI-registered adviser."

Questions such as "what is a repo rate", "why did TCS fall today" and "what is
the share price of TCS" are answered normally.

### 4.4 Disclosures

The Terms of Service state that the app is not investment advice, does not rate
securities, does not predict direction, does not set price targets, and that we
are not a SEBI-registered investment adviser or research analyst. The same
statement appears in the Play Store listing, and an AI-generated-content
disclaimer appears in the app itself.

Terms: https://finbrief-backend.onrender.com/terms
Privacy Policy: https://finbrief-backend.onrender.com/privacy

---

## 5. Where we think the risk sits

Our own reading of the weak points, so they can be checked directly rather than
found:

1. **"In Focus Today" names specific securities.** Even without direction, the
   app is selecting three companies out of the day's news and putting them on
   the home screen with a live price. Is selection itself a problem?

2. **The AI can still say something we did not anticipate.** §4.3 blocks the
   questions we could foresee. A summary of a genuinely bullish article will
   read as positive because the article is positive. Is restating a
   publisher's reporting a risk where the publisher is registered and we are
   not?

3. **We charge a subscription.** The app is paid. Does taking payment for
   access to summarised market news change the analysis, even though nothing
   is charged for any specific security?

4. **Sector mapping is our own editorial judgement.** Deciding that an RBI
   story is relevant to a bank holder is a call we made in code, not something
   stated in the article.

---

## 6. What we would like out of the review

1. Whether registration is required as things stand — and if so, under which
   regulation and what that involves.
2. Any specific wording or feature changes needed to stay clear of it.
3. A short written opinion we can retain.
4. A note of which future features would cross the line, so we can avoid
   building them.

---

## 7. How to see the app

We can provide a test build and a demo account on request. The AI features in
§3.2–3.5 and the refusals in §4.3 are best seen directly; they take about five
minutes to exercise.
