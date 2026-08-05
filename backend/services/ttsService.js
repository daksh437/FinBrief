const fetch = require('node-fetch');

const API_KEY = process.env.GOOGLE_TTS_API_KEY;
const MOCK_MODE = !API_KEY;

const DEFAULT_LANGUAGE = 'en-IN';
const DEFAULT_VOICE = 'en-IN-Neural2-A';
const HINDI_VOICE = 'hi-IN-Neural2-A';

function resolveVoice(languageCode) {
  const lang = (languageCode || DEFAULT_LANGUAGE).toLowerCase();
  return lang.startsWith('hi') ? HINDI_VOICE : DEFAULT_VOICE;
}

// Not real audio — just a valid base64 placeholder so mock mode can exercise
// the full request/response/decode path without a real TTS credential.
const MOCK_AUDIO_BASE64 = Buffer.from('finbrief-mock-audio-placeholder-not-real-mp3').toString('base64');

async function synthesize(text, languageCode = DEFAULT_LANGUAGE) {
  if (MOCK_MODE) {
    return { audioContent: MOCK_AUDIO_BASE64, mock: true };
  }

  const res = await fetch(`https://texttospeech.googleapis.com/v1/text:synthesize?key=${API_KEY}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      input: { text },
      voice: { languageCode, name: resolveVoice(languageCode) },
      audioConfig: { audioEncoding: 'MP3', speakingRate: 1.0, pitch: 0 },
    }),
  });

  if (!res.ok) {
    throw new Error(`TTS API error: ${res.status}`);
  }

  const json = await res.json();
  if (!json.audioContent) {
    throw new Error('TTS API returned no audioContent');
  }

  return { audioContent: json.audioContent, mock: false };
}

module.exports = { synthesize, MOCK_MODE };
