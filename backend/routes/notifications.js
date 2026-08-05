const express = require('express');
const { requireAuth } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const notificationController = require('../controllers/notificationController');

const router = express.Router();

router.use(requireAuth);

router.get('/inbox', asyncHandler(notificationController.listInbox));
router.post('/token', asyncHandler(notificationController.registerToken));
router.get('/preferences', asyncHandler(notificationController.getPreferences));
router.patch('/preferences', asyncHandler(notificationController.updatePreferences));

module.exports = router;
