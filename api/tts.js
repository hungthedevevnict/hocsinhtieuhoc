// Serverless TTS trên Vercel: đọc chữ tiếng Việt.
//
// ƯU TIÊN MiniMax (language_boost tiếng Việt, giọng cute_boy) — nhanh + ổn định
// + giọng Việt chuẩn. Nếu MiniMax lỗi thì lùi về Google Kore. Cả 2 hỏng → 502,
// app tự lùi về giọng máy.
// Trả audio + Cache-Control 1 năm → CDN Vercel + cache máy giữ lại, mỗi chữ chỉ
// tốn 1 lần render.
//
// Key ở biến môi trường SHOPAIKEY_API_KEY (Vercel → Settings → Env Vars).

const HOSTS = ['https://api.shopaikey.com', 'https://direct.shopaikey.com'];
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// --- MiniMax (giọng Việt, có giọng trẻ con) → trả {buf} hoặc {err} ---
async function minimaxOnce(key, text, voiceId, host) {
  try {
    const r = await fetch(`${host}/tts/minimax/t2a_v2`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        model: 'speech-02-hd',
        text,
        language_boost: 'Vietnamese',
        voice_setting: {
          voice_id: voiceId,
          speed: 0.8, // đọc chậm chút cho bé dễ nghe
          vol: 1,
          pitch: 0,
          english_normalization: false,
          emotion: 'happy',
        },
        audio_setting: { format: 'mp3', sample_rate: 32000, bitrate: 128000 },
      }),
    });
    const j = await r.json().catch(() => ({}));
    if (!r.ok) return { err: `HTTP ${r.status}: ${JSON.stringify(j).slice(0, 200)}` };
    const audio = (j.data && j.data.audio) || j.audio;
    if (!audio) return { err: `no audio: ${JSON.stringify(j).slice(0, 200)}` };
    return { buf: Buffer.from(audio, 'hex') };
  } catch (e) {
    return { err: String(e) };
  }
}

async function tryMinimax(key, text, voiceId) {
  for (let i = 0; i < 4; i++) {
    const out = await minimaxOnce(key, text, voiceId, HOSTS[i % HOSTS.length]);
    if (out.buf && out.buf.length >= 200) return out.buf;
    if (i < 3) await sleep(300);
  }
  return null;
}

// --- Google (Gemini) Kore → trả Buffer hoặc null ---
async function googleUrlOnce(key, text, voice, host) {
  try {
    const r = await fetch(`${host}/tts/google/generations`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({ model: 'gemini-2.5-flash-preview-tts', text, voice }),
    });
    const j = await r.json().catch(() => ({}));
    if (r.ok && j && j.url) return j.url;
  } catch (_) {}
  return null;
}

async function tryGoogle(key, text, voice) {
  for (let i = 0; i < 6; i++) {
    const url = await googleUrlOnce(key, text, voice, HOSTS[i % HOSTS.length]);
    if (url) {
      const a = await fetch(url).catch(() => null);
      if (a && a.ok) {
        const buf = Buffer.from(await a.arrayBuffer());
        if (buf.length >= 200) return { buf, contentType: a.headers.get('content-type') || 'audio/wav' };
      }
    }
    if (i < 5) await sleep(250);
  }
  return null;
}

function sendAudio(res, buf, contentType, provider) {
  res.setHeader('Content-Type', contentType);
  res.setHeader('Cache-Control', 'public, max-age=31536000, s-maxage=31536000, immutable');
  res.setHeader('X-TTS-Provider', provider);
  res.status(200).send(buf);
}

module.exports = async (req, res) => {
  try {
    const text = (req.query.text || '').toString().trim().slice(0, 300);
    const provider = (req.query.provider || 'auto').toString();
    const voice = (req.query.voice || '').toString().slice(0, 30);
    if (!text) {
      res.status(400).json({ error: 'thiếu tham số text' });
      return;
    }
    const key = process.env.SHOPAIKEY_API_KEY;
    if (!key) {
      res.status(500).json({ error: 'server chưa cấu hình SHOPAIKEY_API_KEY' });
      return;
    }

    const mmVoice = (provider === 'minimax' && voice) || 'cute_boy';
    const gVoice = (provider === 'google' && voice) || 'Kore';

    // Google-only (test)
    if (provider === 'google') {
      const g = await tryGoogle(key, text, gVoice);
      if (g) return sendAudio(res, g.buf, g.contentType, 'google');
      res.status(502).json({ error: 'Google TTS lỗi' });
      return;
    }

    // MiniMax trước (mặc định + provider=minimax).
    const mm = await tryMinimax(key, text, mmVoice);
    if (mm) return sendAudio(res, mm, 'audio/mpeg', 'minimax');

    if (provider === 'minimax') {
      res.status(502).json({ error: 'MiniMax lỗi' });
      return;
    }

    // auto: MiniMax hỏng → thử Google Kore.
    const g = await tryGoogle(key, text, 'Kore');
    if (g) return sendAudio(res, g.buf, g.contentType, 'google');

    res.status(502).json({ error: 'MiniMax và Google đều lỗi' });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
};
