const express = require('express');
const { requireAuth } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const newsController = require('../controllers/newsController');

const router = express.Router();

// Feed and search are free/unlimited — only the AI features are credit-gated.
router.get('/feed', asyncHandler(newsController.feed));
router.get('/breaking', asyncHandler(newsController.breaking));
router.get('/search', asyncHandler(newsController.search));
router.get('/trending-searches', asyncHandler(newsController.trendingSearches));

router.get('/bookmarks', requireAuth, asyncHandler(newsController.listBookmarks));
router.post('/bookmarks', requireAuth, asyncHandler(newsController.addBookmark));
router.delete('/bookmarks/:id', requireAuth, asyncHandler(newsController.removeBookmark));

module.exports = router;
