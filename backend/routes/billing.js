const express = require('express');
const { requireAuth } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const billingController = require('../controllers/billingController');

const router = express.Router();

router.use(requireAuth);

router.post('/verify', asyncHandler(billingController.verify));
router.get('/status', asyncHandler(billingController.status));
router.get('/history', asyncHandler(billingController.history));

module.exports = router;
