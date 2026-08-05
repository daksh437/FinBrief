const express = require('express');
const { requireAuth } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const feedbackController = require('../controllers/feedbackController');

const router = express.Router();

router.use(requireAuth);

router.post('/', asyncHandler(feedbackController.submit));

module.exports = router;
