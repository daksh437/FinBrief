const express = require('express');
const { requireAuth } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const watchlistController = require('../controllers/watchlistController');

const router = express.Router();

router.use(requireAuth);

router.get('/', asyncHandler(watchlistController.list));
router.post('/', asyncHandler(watchlistController.add));
router.patch('/:symbol', asyncHandler(watchlistController.update));
router.delete('/:symbol', asyncHandler(watchlistController.remove));

module.exports = router;
