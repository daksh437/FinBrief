const { messaging } = require('../config/firebaseAdmin');

async function sendToToken(token, { title, body, data = {} }) {
  return messaging.send({
    token,
    notification: { title, body },
    data,
  });
}

async function sendToTokens(tokens, { title, body, data = {} }) {
  if (!tokens.length) return { successCount: 0, failureCount: 0 };
  return messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
  });
}

module.exports = { sendToToken, sendToTokens };
