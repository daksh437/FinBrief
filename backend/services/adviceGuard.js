// Refuses questions that ask the app to make an investment decision.
//
// The chat prompt already tells the model never to give personalised advice,
// and it usually complies — but "usually" is not a control. A model that slips
// once and tells someone to buy a specific stock has made the app something
// SEBI's investment-adviser regulations cover, and no amount of prompt wording
// prevents that deterministically.
//
// This runs BEFORE the request reaches Gemini, so a refusal can't be argued
// with, jailbroken, or lost to a bad generation. It also costs nothing: a
// blocked question never spends a Gemini call.
//
// Deliberately tuned to catch decision questions, not topic questions.
// "What is a repo rate?" and "Why did TCS fall today?" must still work — they
// are the whole point of the app. Only "should I buy / sell / hold", "is it a
// good time to invest", price targets and portfolio allocation are refused.

const DECISION_PATTERNS = [
  // "should I buy", "should i sell it", "shall I invest in"
  /\b(should|shall|must|can|could)\s+(i|we|you)\b[^?]{0,40}\b(buy|sell|hold|invest|book|exit|enter|purchase|dump)\b/i,
  // "is it a good time to buy", "is it worth buying", "good stock to buy"
  /\b(good|right|best|worth|safe)\b[^?]{0,30}\b(time|moment|idea|stock|entry|price)\b[^?]{0,30}\b(buy|sell|invest|enter|exit)\b/i,
  /\bworth\s+(buying|selling|investing|holding)\b/i,
  // "buy or sell", "hold or sell"
  /\b(buy|sell|hold)\s+or\s+(buy|sell|hold)\b/i,
  // "what will the price be", "target price", "how high will it go"
  /\b(target|price target|how (high|low|much)\s+will|where will).{0,30}\b(go|reach|be|hit)\b/i,
  // Both orders: "price target" and "target price" — the second slipped
  // through when only the first was listed.
  /\bprice\s+(target|prediction|forecast)\b/i,
  /\b(target|expected|predicted|fair)\s+price\b/i,
  // "will X go up", "will it rise/fall/crash"
  /\bwill\s+\w[\w\s.&-]{0,30}\b(go up|go down|rise|fall|crash|rally|double|recover)\b/i,
  // "how much should I invest", "what percent in equity"
  /\bhow much\b[^?]{0,30}\b(invest|put|allocate|buy)\b/i,
  // "which stock should I", "which is better to buy"
  /\bwhich\b[^?]{0,40}\b(should i (buy|sell|pick|choose)|is better to (buy|invest))\b/i,
  // "recommend a stock", "suggest me stocks", "give me tips"
  /\b(recommend|suggest|tip|tips)\b[^?]{0,25}\b(stock|share|fund|mutual fund|sip|invest|portfolio)\b/i,
  /\b(stock|share|investment)\s+(tips|recommendation|advice)\b/i,
];

const REFUSAL =
  "I can't tell you what to buy, sell or hold — FinBrief reports the news and "
  + "explains what it means, and I'm not a registered investment adviser.\n\n"
  + 'What I can do is explain the story behind a company, break down a term, or '
  + 'summarise what today\'s news says about it. For a decision about your own '
  + 'money, please speak to a SEBI-registered adviser.';

/// True when the question is asking for an investment decision.
function seeksAdvice(text) {
  const question = String(text || '');
  if (!question.trim()) return false;
  return DECISION_PATTERNS.some((pattern) => pattern.test(question));
}

module.exports = { seeksAdvice, REFUSAL, DECISION_PATTERNS };
