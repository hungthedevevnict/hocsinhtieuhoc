// Serverless TTS trên Vercel: đọc chữ tiếng Việt bằng Google (Gemini) giọng Kore.
//
// Google giọng Việt hay nhất NHƯNG chập chờn (~40% lần trả "no audio") → thử lại
// nhiều lần. Nếu Google hỏng hẳn thì trả 502; phía app tự lùi về giọng trình
// duyệt / giọng máy (KHÔNG dùng OpenAI vì đọc tiếng Việt lơ lớ).
// Trả audio + Cache-Control 1 năm → CDN Vercel lưu lại, mỗi chữ chỉ tốn 1 lần.
//
// Key ở biến môi trường SHOPAIKEY_API_KEY (Vercel → Settings → Env Vars).

const HOSTS = ['https://api.shopaikey.com', 'https://direct.shopaikey.com'];
const GOOGLE_TRIES = 8; // Google hay lỗi nên thử nhiều lần
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Gọi Google 1 lần → trả URL audio hoặc null.
async function googleOnce(key, text, voice, host) {
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

// MiniMax (có language_boost tiếng Việt) → trả {buf} hoặc {err}.
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
          speed: 1.0,
          vol: 1,
          pitch: 0,
          english_normalization: false,
          emotion: 'happy',
        },
        audio_setting: { format: 'mp3', sample_rate: 32000, bitrate: 128000 },
      }),
    });
    const j = await r.json().catch(() => ({}));
    if (!r.ok) return { err: `HTTP ${r.status}: ${JSON.stringify(j).slice(0, 220)}` };
    const audio = (j.data && j.data.audio) || j.audio;
    if (!audio) return { err: `no audio: ${JSON.stringify(j).slice(0, 220)}` };
    return { buf: Buffer.from(audio, 'hex') };
  } catch (e) {
    return { err: String(e) };
  }
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
    const provider = (req.query.provider || 'google').toString();
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

    // MiniMax (thử nghiệm) — ?provider=minimax&voice=female-shaonv
    if (provider === 'minimax') {
      const voiceId = voice || 'female-shaonv';
      let lastErr = 'unknown';
      for (let i = 0; i < 3; i++) {
        const out = await minimaxOnce(key, text, voiceId, HOSTS[i % HOSTS.length]);
        if (out.buf && out.buf.length >= 200) {
          sendAudio(res, out.buf, 'audio/mpeg', 'minimax');
          return;
        }
        lastErr = out.err || 'unknown';
        await sleep(300);
      }
      res.status(502).json({ error: 'MiniMax lỗi', detail: lastErr });
      return;
    }

    // Google Kore (mặc định) — thử nhiều lần, luân phiên 2 host.
    const gVoice = voice || 'Kore';
    let genUrl = null;
    for (let i = 0; i < GOOGLE_TRIES && !genUrl; i++) {
      genUrl = await googleOnce(key, text, gVoice, HOSTS[i % HOSTS.length]);
      if (!genUrl && i < GOOGLE_TRIES - 1) await sleep(250);
    }
    if (genUrl) {
      const audioRes = await fetch(genUrl).catch(() => null);
      if (audioRes && audioRes.ok) {
        const buf = Buffer.from(await audioRes.arrayBuffer());
        if (buf.length >= 200) {
          sendAudio(res, buf, audioRes.headers.get('content-type') || 'audio/wav', 'google');
          return;
        }
      }
    }

    // Google hỏng hẳn → 502; app tự lùi về giọng trình duyệt / giọng máy.
    res.status(502).json({ error: 'Google TTS không phản hồi audio' });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
};
