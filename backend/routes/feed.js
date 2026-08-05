const express = require('express');
const { requireAuth } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const feedController = require('../controllers/feedController');

const router = express.Router();

router.use(requireAuth);

// Personalised, portfolio-aware news.
router.get('/personalised', asyncHandler(feedController.personalised));

module.exports = router;
