const fetch = require('node-fetch');

// Indian mutual fund NAVs, from AMFI.
//
// Why this matters: most Indian retail money is in mutual funds, not direct
// equity. An app that only tracks stocks is invisible to the majority of the
// people it is trying to reach.
//
// AMFI publishes every scheme's NAV as one semicolon-delimited file, free and
// without a key — the official source, not a scrape. Verified 2026-08-07:
// 17,734 schemes.
//
// Use portal.amfiindia.com directly. The www.amfiindia.com path 302s here, and
// a client that doesn't follow redirects gets an HTML stub instead of data.
const NAV_URL = 'https://portal.amfiindia.com/spages/NAVAll.txt';
const TIMEOUT_MS = 60_000;

// NAV is struck once per day after markets close, so there is nothing to gain
// from fetching more often. Six hours keeps it fresh across the evening
// publish without hammering AMFI.
const CACHE_TTL_MS = 6 * 60 * 60 * 1000;

let cache = null; // { at, schemes: [], byCode: Map }

/// One row of the AMFI file.
///
/// `category` is the "Open Ended Schemes(Equity Scheme - Large Cap Fund)"
/// heading the rows sit under — the file is grouped, not tabular, so the
/// heading has to be carried down as rows are read.
function parse(text) {
  const schemes = [];
  let category = null;
  let house = null;

  for (const raw of text.split('\n')) {
    const line = raw.trim();
    if (!line) continue;

    // Data rows have five semicolons; anything else is a heading.
    if (!line.includes(';')) {
      if (/schemes?\s*\(/i.test(line)) category = line;
      else house = line;
      continue;
    }

    const parts = line.split(';');
    if (parts.length < 6) continue;
    if (parts[0] === 'Scheme Code') continue; // header row

    const nav = Number(parts[4]);
    if (!Number.isFinite(nav)) continue; // some schemes report "N.A."

    schemes.push({
      code: parts[0].trim(),
      isin: parts[1].trim() === '-' ? null : parts[1].trim(),
      name: parts[3].trim(),
      nav,
      date: parts[5].trim(),
      house,
      category,
    });
  }

  return schemes;
}

async function load() {
  if (cache && Date.now() - cache.at < CACHE_TTL_MS) return cache;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const res = await fetch(NAV_URL, {
      signal: controller.signal,
      headers: { 'User-Agent': 'Mozilla/5.0 (compatible; FinBrief/1.0)' },
    });
    if (!res.ok) throw new Error(`AMFI HTTP ${res.status}`);

    const schemes = parse(await res.text());
    if (!schemes.length) throw new Error('AMFI returned no parseable schemes');

    cache = {
      at: Date.now(),
      schemes,
      byCode: new Map(schemes.map((s) => [s.code, s])),
    };
    return cache;
  } catch (err) {
    console.error('[amfi] load failed:', err.message);
    // Serve yesterday's data rather than nothing: a stale NAV clearly labelled
    // with its date is more use than an empty screen.
    if (cache) return cache;
    throw err;
  } finally {
    clearTimeout(timer);
  }
}

// SEBI's scheme-category rationalisation renamed a number of well-known funds,
// and AMFI carries only the current name. People still call them by the old
// one — "SBI Bluechip" is what crores of investors have in their heads, and
// searching for it in the raw file returns nothing at all.
//
// Only entries verified against the live file belong here. Where a fund kept
// its old name in brackets ("(erstwhile Bluechip Fund)") no entry is needed —
// those are picked up automatically below.
const RENAMED = {
  'sbi bluechip': 'sbi large cap',
};

/// Old names a scheme is still searchable by.
///
/// Extracted from the data rather than hand-listed: 23 schemes carry
/// "(erstwhile X)" in their name, and that stays correct as AMFI updates.
function aliasFor(name) {
  const match = name.match(/\(erstwhile\s+([^)]+)\)/i);
  return match ? match[1].toLowerCase() : null;
}

/// Normalises for matching: people type "bluechip", the file says "Blue Chip".
const squash = (s) => s.toLowerCase().replace(/[^a-z0-9]/g, '');

/// Searches scheme names.
///
/// Every scheme exists several times over (Direct/Regular × Growth/IDCW), so a
/// plain substring match buries the fund the user meant under its own
/// variants. Results are ranked to put Direct Growth plans first — the ones a
/// retail investor buying through an app actually holds.
async function search(query, { limit = 20 } = {}) {
  let q = String(query || '').trim().toLowerCase();
  if (q.length < 3) return [];

  for (const [oldName, currentName] of Object.entries(RENAMED)) {
    if (q.includes(oldName)) q = q.replace(oldName, currentName);
  }

  const { schemes } = await load();
  const terms = q.split(/\s+/);
  const squashedQuery = squash(q);

  const scored = [];
  for (const scheme of schemes) {
    const name = scheme.name.toLowerCase();
    const alias = aliasFor(scheme.name);

    // Three ways to match: every term present, the whole query with
    // punctuation and spaces ignored, or the bracketed old name.
    const matches =
      terms.every((t) => name.includes(t)) ||
      squash(name).includes(squashedQuery) ||
      (alias !== null && alias.includes(q));

    if (!matches) continue;

    let score = 0;
    if (name.startsWith(q)) score += 10;
    if (name.includes('direct')) score += 4;
    if (/\bgrowth\b/.test(name)) score += 3;
    // Shorter names are the plain plan rather than a niche variant.
    score -= name.length / 100;

    scored.push({ score, scheme });
    if (scored.length > 400) break; // enough to rank well without scanning all
  }

  return scored
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(({ scheme }) => scheme);
}

/// Current NAV for a set of scheme codes. Unknown codes are omitted rather
/// than guessed — same rule as stock quotes.
async function navFor(codes = []) {
  if (!codes.length) return [];
  const { byCode } = await load();
  return codes.map((c) => byCode.get(String(c))).filter(Boolean);
}

module.exports = { search, navFor, load, parse, NAV_URL };
