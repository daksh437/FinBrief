const express = require('express');
const asyncHandler = require('../utils/asyncHandler');
const marketController = require('../controllers/marketController');

const router = express.Router();

// Free/unlimited, same as news feed/search — no auth required.
router.get('/overview', asyncHandler(marketController.overview));
router.get('/insight', asyncHandler(marketController.insight));
router.get('/ai-picks', asyncHandler(marketController.aiPicks));
router.get('/quotes', asyncHandler(marketController.quotes));

module.exports = router;
