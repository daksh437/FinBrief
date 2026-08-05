const fetch = require('node-fetch');

// Free RSS news provider — no API key, no daily quota, no paid tier.
//
// Why this is the PRIMARY source, not a fallback:
//   * MarketAux free allows ~100 requests/DAY (≈ one poll per 15 min).
//     RSS has no quota, so the breaking-news job can poll every 1-2 min.
//   * Verified 2026-08-05: Indian publisher feeds (ET, Business Standard,
//     LiveMint, Moneycontrol) carry BOTH real descriptions and images — the
//     two things a paid aggregator was actually adding. Google News RSS does
//     not (its <description> is just link markup), so publisher feeds are
//     listed first and Google News is used only to widen coverage.
//
// Scope: RSS gives headline + snippet + link + image. We show those with
// source attribution and link back to the publisher — never full articles.
const TIMEOUT_MS = 12_000;
const GOOGLE_NEWS = 'https://news.google.com/rss/search';

const gnews = (q, { gl = 'IN', hl = 'en-IN' } = {}) =>
  `${GOOGLE_NEWS}?q=${encodeURIComponent(q)}&hl=${hl}&gl=${gl}&ceid=${gl}:en`;

// Publisher feeds first (rich), Google News last (broad).
const FEEDS = {
  india: [
    { name: 'Economic Times', url: 'https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms' },
    { name: 'Business Standard', url: 'https://www.business-standard.com/rss/markets-106.rss' },
    { name: 'LiveMint', url: 'https://www.livemint.com/rss/markets' },
    { name: 'Moneycontrol', url: 'https://www.moneycontrol.com/rss/business.xml' },
    { name: 'Google News', url: gnews('sensex OR nifty OR "indian stock market"') },
  ],
  // World coverage: major wire/finance desks plus Google News for the US,
  // Europe and Asia so the feed isn't India-only.
  global: [
    { name: 'CNBC', url: 'https://search.cnbc.com/rs/search/combinedcderived/view.xml?partnerId=wrss01&id=100003114' },
    { name: 'Yahoo Finance', url: 'https://finance.yahoo.com/news/rssindex' },
    { name: 'Investing.com', url: 'https://www.investing.com/rss/news_25.rss' },
    { name: 'Google News', url: gnews('stock market OR federal reserve OR inflation', { gl: 'US', hl: 'en-US' }) },
    { name: 'Google News', url: gnews('europe markets OR ECB OR FTSE', { gl: 'GB', hl: 'en-GB' }) },
    { name: 'Google News', url: gnews('asia markets OR nikkei OR hang seng', { gl: 'SG', hl: 'en-SG' }) },
  ],
  crypto: [
    { name: 'Google News', url: gnews('bitcoin OR ethereum OR crypto') },
  ],
  gold: [
    { name: 'Google News', url: gnews('gold price OR silver price India') },
  ],
  forex: [
    { name: 'Google News', url: gnews('rupee OR "usd inr" OR forex India') },
  ],
  ipo: [
    { name: 'Google News', url: gnews('IPO listing India') },
  ],
  economy: [
    { name: 'Economic Times', url: 'https://economictimes.indiatimes.com/news/economy/rssfeeds/1373380680.cms' },
    { name: 'Google News', url: gnews('RBI OR inflation OR GDP India') },
  ],
};

const CATEGORY_MAP = {
  business: 'india',
  stocks: 'india',
  general: 'india',
  all: 'india',
  world: 'global',
  global: 'global',
  international: 'global',
  crypto: 'crypto',
  gold: 'gold',
  forex: 'forex',
  ipo: 'ipo',
  economy: 'economy',
  technology: 'global',
  'global markets': 'global',
};

function decodeEntities(str = '') {
  return str
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#0?39;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&');
}

function clean(str = '') {
  return decodeEntities(
    str.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
  )
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tag(item, name) {
  const m = item.match(new RegExp(`<${name}[^>]*>([\\s\\S]*?)</${name}>`, 'i'));
  return m ? clean(m[1]) : null;
}

/// Images arrive three different ways depending on the publisher, so try all.
function extractImage(item) {
  const enclosure = item.match(/<enclosure[^>]+url=["']([^"']+)["']/i);
  if (enclosure) return enclosure[1];

  const media = item.match(/<media:(?:content|thumbnail)[^>]+url=["']([^"']+)["']/i);
  if (media) return media[1];

  // Moneycontrol embeds the image inside the description HTML.
  const raw = (item.match(/<description>([\s\S]*?)<\/description>/i) || [])[1] || '';
  const inline = decodeEntities(raw).match(/<img[^>]+src=["']([^"']+)["']/i);
  return inline ? inline[1] : null;
}

/// Google News titles are "Headline - Publisher"; split so we can attribute
/// the real publisher instead of leaving it stuck in the headline.
function splitPublisher(title, fallbackSource) {
  const idx = title.lastIndexOf(' - ');
  if (idx > 20) {
    return { title: title.slice(0, idx).trim(), source: title.slice(idx + 3).trim() };
  }
  return { title, source: fallbackSource };
}

function parse(xml, feedName) {
  const items = xml.match(/<item[\s\S]*?<\/item>/gi) || [];

  return items.map((item) => {
    const { title, source } = splitPublisher(tag(item, 'title') || '', feedName);
    const link = (item.match(/<link[^>]*>([\s\S]*?)<\/link>/i) || [])[1]?.trim() || '';
    const description = tag(item, 'description');
    const pubDate = tag(item, 'pubDate');

    // Google News descriptions are pure link markup — drop anything that
    // still looks like navigation rather than a real snippet.
    const usableSummary =
      description && description.length > 60 && !description.startsWith('http') ? description.slice(0, 500) : null;

    return {
      id: link || title,
      title,
      source: tag(item, 'source') || source,
      url: link || null,
      publishedAt: pubDate ? new Date(pubDate).toISOString() : new Date().toISOString(),
      summary: usableSummary,
      imageUrl: extractImage(item),
    };
  });
}

async function fetchFeed(feed) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(feed.url, {
      signal: controller.signal,
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; FinBrief/1.0)' },
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return parse(await res.text(), feed.name);
  } finally {
    clearTimeout(timer);
  }
}

const rss = {
  name: 'rss',
  available: true, // no key required

  async fetchNews({ category = 'business', limit = 20 } = {}) {
    const group = CATEGORY_MAP[String(category).toLowerCase()] || 'india';
    const feeds = FEEDS[group] || FEEDS.india;

    // allSettled so one dead feed never takes the whole request down.
    const settled = await Promise.allSettled(feeds.map(fetchFeed));
    const articles = settled.filter((s) => s.status === 'fulfilled').flatMap((s) => s.value);

    const failed = settled.filter((s) => s.status === 'rejected').length;
    if (failed) console.error(`[rss] ${failed}/${feeds.length} feed(s) failed for "${group}"`);

    return articles
      .filter((a) => a.title)
      .sort((a, b) => Date.parse(b.publishedAt) - Date.parse(a.publishedAt))
      .slice(0, limit);
  },

  async search(query, { limit = 20 } = {}) {
    const results = await fetchFeed({ name: 'Google News', url: gnews(query) });
    return results.slice(0, limit);
  },
};

module.exports = { rss, FEEDS, CATEGORY_MAP, parse, splitPublisher, extractImage };
