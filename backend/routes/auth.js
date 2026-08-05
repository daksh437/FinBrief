const express = require('express');
const { requireAuth } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const authController = require('../controllers/authController');

const router = express.Router();

router.use(requireAuth);

router.post('/bootstrap', asyncHandler(authController.bootstrap));
router.get('/profile', asyncHandler(authController.profile));

module.exports = router;
