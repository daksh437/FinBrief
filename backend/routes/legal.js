const express = require('express');
const fs = require('fs');
const path = require('path');

// Publicly hosted Privacy Policy and Terms.
//
// Google Play requires a privacy policy reachable at a public URL, separate
// from the in-app screens. Both are rendered from backend/legal/*.json, which
// the Flutter app also bundles as an asset — one source of truth, so the web
// page and the in-app screen can never drift apart. Legal text saying two
// different things in two places is worse than having only one of them.
//
// Deliberately unauthenticated: a policy nobody can read without an account
// would not satisfy the requirement.
const router = express.Router();

// Google Play asks for the account-deletion URL separately from the privacy
// policy, and it must be reachable without installing the app — a reviewer
// checks it before approving.
const DOCS = {
  privacy: 'privacy.json',
  terms: 'terms.json',
  'delete-account': 'delete-account.json',
};
const cache = new Map();

function load(name) {
  if (cache.has(name)) return cache.get(name);
  const doc = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'legal', DOCS[name]), 'utf8'));
  cache.set(name, doc);
  return doc;
}

/// Escapes text before it goes into HTML. The content is ours, but rendering
/// unescaped is the kind of habit that eventually bites.
const escape = (str) =>
  String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

/// Blank lines in the source become separate paragraphs.
const paragraphs = (body) =>
  escape(body)
    .split('\n\n')
    .map((p) => `<p>${p.replace(/\n/g, '<br>')}</p>`)
    .join('\n');

function render(doc) {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(doc.title)} — FinBrief</title>
<style>
  :root { color-scheme: light dark; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    line-height: 1.6; margin: 0 auto; max-width: 46rem; padding: 2rem 1.25rem 4rem;
    color: #0f172a; background: #f8fafc;
  }
  h1 { font-size: 1.6rem; margin-bottom: .25rem; }
  h2 { font-size: 1.05rem; margin-top: 2rem; }
  .updated { color: #64748b; font-size: .875rem; margin-top: 0; }
  .intro { font-size: 1.05rem; }
  a { color: #2563eb; }
  @media (prefers-color-scheme: dark) {
    body { color: #e2e8f0; background: #0f172a; }
    .updated { color: #94a3b8; }
    a { color: #60a5fa; }
  }
</style>
</head>
<body>
<h1>FinBrief — ${escape(doc.title)}</h1>
<p class="updated">Last updated: ${escape(doc.lastUpdated)}</p>
<p class="intro">${escape(doc.intro)}</p>
${doc.sections.map((s) => `<h2>${escape(s.heading)}</h2>\n${paragraphs(s.body)}`).join('\n')}
</body>
</html>`;
}

for (const name of Object.keys(DOCS)) {
  router.get(`/${name}`, (req, res) => {
    res.type('html').send(render(load(name)));
  });
}

module.exports = router;
