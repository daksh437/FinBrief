const express = require('express');
const { requireAuth } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const portfolioController = require('../controllers/portfolioController');

const router = express.Router();

router.use(requireAuth);

router.get('/', asyncHandler(portfolioController.list));
router.get('/insight', asyncHandler(portfolioController.insight));
router.post('/', asyncHandler(portfolioController.add));
router.patch('/:symbol', asyncHandler(portfolioController.update));
router.delete('/:symbol', asyncHandler(portfolioController.remove));

module.exports = router;
