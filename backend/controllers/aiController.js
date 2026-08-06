const gemini = require('../services/geminiService');
const tts = require('../services/ttsService');
const aiHistory = require('../services/aiHistoryService');
const chatContext = require('../services/chatContextService');
const adviceGuard = require('../services/adviceGuard');
const languages = require('../config/languages');

async function translate(req, res) {
  const { text, language } = req.body;
  if (!text) return res.status(400).json({ success: false, error: 'text is required' });

  // An unknown or missing code resolves to Hindi rather than failing — an
  // older client that doesn't send one still works.
  const code = languages.resolveLanguage(language);

  const translated = await gemini.translate(text, code);
  aiHistory.log({
    userId: req.user.uid,
    action: `translate:${code}`,
    prompt: text,
    response: translated,
  });
  res.json({
    success: true,
    data: { translated, language: code, languageName: languages.nameOf(code) },
    fallback: gemini.MOCK_MODE,
  });
}

// Returns { summary, keyPoints, confidence }. `summary` stays a plain string
// so older clients that only read that field keep working.
async function summary(req, res) {
  const { text } = req.body;
  if (!text) return res.status(400).json({ success: false, error: 'text is required' });

  const result = await gemini.summarizeStructured(text);
  aiHistory.log({ userId: req.user.uid, action: 'summary', prompt: text, response: result });
  res.json({ success: true, data: result, fallback: gemini.MOCK_MODE });
}

async function explain(req, res) {
  const { text, mode } = req.body;
  if (!text) return res.status(400).json({ success: false, error: 'text is required' });

  try {
    const explanation = await gemini.explain(text, mode);
    aiHistory.log({ userId: req.user.uid, action: `explain:${mode}`, prompt: text, response: explanation });
    res.json({ success: true, data: { explanation, mode }, fallback: gemini.MOCK_MODE });
  } catch (err) {
    if (err.code === 'UNKNOWN_MODE') {
      return res.status(400).json({
        success: false,
        error: 'mode must be one of: why-it-matters, future-impact, beginner, hindi',
      });
    }
    throw err;
  }
}

async function impact(req, res) {
  const { text } = req.body;
  if (!text) return res.status(400).json({ success: false, error: 'text is required' });

  const analysis = await gemini.analyzeImpact(text);
  aiHistory.log({ userId: req.user.uid, action: 'impact', prompt: text, response: analysis });
  res.json({ success: true, data: analysis, fallback: gemini.MOCK_MODE });
}

async function chat(req, res) {
  const { messages } = req.body;
  if (!Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({ success: false, error: 'messages array is required' });
  }

  const lastUserMessage = messages[messages.length - 1]?.text || '';

  // Refuse decision questions before they reach the model. The prompt already
  // forbids advice and the model usually complies, but "usually" is not a
  // control — one slip telling someone to buy a named stock is the thing SEBI's
  // adviser regulations cover. Refusing here can't be jailbroken or lost to a
  // bad generation, and a blocked question spends no Gemini quota.
  if (adviceGuard.seeksAdvice(lastUserMessage)) {
    aiHistory.log({
      userId: req.user.uid,
      action: 'chat_refused',
      prompt: lastUserMessage,
      response: adviceGuard.REFUSAL,
    });
    return res.json({ success: true, data: { reply: adviceGuard.REFUSAL, refused: true } });
  }

  // Context is best-effort — a failure here must not block the reply.
  let context = null;
  try {
    context = await chatContext.build(req.user.uid);
  } catch (err) {
    console.error('[chat] context build failed:', err.message);
  }

  const reply = await gemini.chat(messages, context);
  aiHistory.log({ userId: req.user.uid, action: 'chat', prompt: lastUserMessage, response: reply });
  res.json({ success: true, data: { reply }, fallback: gemini.MOCK_MODE });
}

async function voiceSummary(req, res) {
  const { text, languageCode } = req.body;
  if (!text) return res.status(400).json({ success: false, error: 'text is required' });

  const summarized = await gemini.summarize(text);
  const { audioContent, mock } = await tts.synthesize(summarized, languageCode);

  // Log the text only — audio bytes would bloat the history documents.
  aiHistory.log({ userId: req.user.uid, action: 'voice-summary', prompt: text, response: summarized });

  res.json({
    success: true,
    data: { summary: summarized, audioContent, mimeType: 'audio/mpeg' },
    fallback: gemini.MOCK_MODE || mock,
  });
}

module.exports = { translate, summary, impact, explain, chat, voiceSummary };
