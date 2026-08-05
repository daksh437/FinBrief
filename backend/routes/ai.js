const express = require('express');
const { requireAuth } = require('../middleware/auth');
const { aiAccess, withIdempotency } = require('../middleware/aiAccess');
const { rateLimit } = require('../middleware/rateLimit');
const asyncHandler = require('../utils/asyncHandler');
const aiController = require('../controllers/aiController');

const router = express.Router();

// Ordering matters: requireAuth first so the limiter can key on uid, then the
// limiter, then aiAccess — a rate-limited request must be rejected *before*
// aiAccess debits a daily credit for it.
router.use(requireAuth, rateLimit({ name: 'ai', windowMs: 60_000, max: 20 }), aiAccess);

router.post('/translate', asyncHandler(withIdempotency(aiController.translate)));
router.post('/summary', asyncHandler(withIdempotency(aiController.summary)));
router.post('/impact', asyncHandler(withIdempotency(aiController.impact)));
router.post('/explain', asyncHandler(withIdempotency(aiController.explain)));
router.post('/chat', asyncHandler(withIdempotency(aiController.chat)));
router.post('/voice-summary', asyncHandler(withIdempotency(aiController.voiceSummary)));

module.exports = router;
