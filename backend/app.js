require('dotenv').config();

const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const newsRoutes = require('./routes/news');
const aiRoutes = require('./routes/ai');
const watchlistRoutes = require('./routes/watchlist');
const portfolioRoutes = require('./routes/portfolio');
const notificationRoutes = require('./routes/notifications');
const billingRoutes = require('./routes/billing');
const marketRoutes = require('./routes/market');
const feedbackRoutes = require('./routes/feedback');
const configRoutes = require('./routes/config');
const feedRoutes = require('./routes/feed');
const legalRoutes = require('./routes/legal');
const fundsRoutes = require('./routes/funds');
const { rateLimit } = require('./middleware/rateLimit');
const { startJobs } = require('./jobs');

const app = express();

app.use(cors());
app.use(express.json({ limit: '2mb' }));

// Health check is intentionally above the limiter so uptime probes are never
// throttled. Everything below gets a broad per-user/IP ceiling; /ai has its
// own tighter limit on top.
app.get('/health', (req, res) => res.json({ success: true, status: 'ok', uptime: process.uptime() }));

// Legal pages sit above the limiter too: these are the URLs given to Google
// Play and linked publicly, so they must always load.
app.use('/', legalRoutes);

app.use(rateLimit({ name: 'global', windowMs: 60_000, max: 120 }));

app.use('/auth', authRoutes);
app.use('/news', newsRoutes);
app.use('/ai', aiRoutes);
app.use('/watchlist', watchlistRoutes);
app.use('/portfolio', portfolioRoutes);
app.use('/notifications', notificationRoutes);
app.use('/billing', billingRoutes);
app.use('/market', marketRoutes);
app.use('/feedback', feedbackRoutes);
app.use('/config', configRoutes);
app.use('/feed', feedRoutes);
app.use('/funds', fundsRoutes);

// AI routes degrade gracefully instead of surfacing a 5xx — the app should
// keep working (with a fallback payload) even if Gemini/news APIs are down.
app.use((err, req, res, next) => {
  console.error(err);

  if (req.path.startsWith('/ai/')) {
    return res.status(200).json({
      success: true,
      fallback: true,
      data: null,
      error: 'AI service temporarily unavailable',
    });
  }

  res.status(500).json({ success: false, error: 'Internal server error' });
});

const PORT = process.env.PORT || 10000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`FinPulse backend listening on port ${PORT}`);
  startJobs();
});

module.exports = app;
