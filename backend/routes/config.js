const express = require('express');
const asyncHandler = require('../utils/asyncHandler');
const configController = require('../controllers/configController');

const router = express.Router();

// Unauthenticated on purpose — the client needs force-update / feature flags
// before a user has signed in.
router.get('/', asyncHandler(configController.get));

module.exports = router;
