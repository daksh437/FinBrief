const express = require('express');
const { requireAuth } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const fundsController = require('../controllers/fundsController');

const router = express.Router();

router.use(requireAuth);

router.get('/search', asyncHandler(fundsController.search));
router.get('/', asyncHandler(fundsController.list));
router.post('/', asyncHandler(fundsController.add));
router.delete('/:schemeCode', asyncHandler(fundsController.remove));

module.exports = router;
