const express = require('express');
const { requireAuth } = require('../middleware/auth');
const { requireAdmin } = require('../middleware/requireAdmin');
const asyncHandler = require('../utils/asyncHandler');
const adminController = require('../controllers/adminController');

const router = express.Router();

// Signed in first, then admin. Both are enforced here rather than per-route so
// a route added later cannot be left open by accident.
router.use(requireAuth, requireAdmin);

router.get('/overview', asyncHandler(adminController.overview));
router.get('/users', asyncHandler(adminController.listUsers));
router.patch('/users/:uid/plan', asyncHandler(adminController.setPlan));
router.get('/errors', asyncHandler(adminController.errors));
router.get('/feedback', asyncHandler(adminController.feedback));

module.exports = router;
