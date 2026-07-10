// Serverless TTS trên Vercel: đọc chữ tiếng Việt.
//
// Google (Gemini) giọng Việt hay nhất NHƯNG chập chờn (~40% lần trả "no audio")
// → thử lại nhiều lần; nếu vẫn hỏng thì fallback sang OpenAI tts-1-hd (ổn định).
// Trả audio + Cache-Control 1 năm → CDN Vercel lưu lại, mỗi chữ chỉ tốn 1 lần.
//
// Key ở biến môi trường SHOPAIKEY_API_KEY (Vercel → Settings → Env Vars).

const HOSTS = ['https://api.shopaikey.com', 'https://direct.shopaikey.com'];
const GOOGLE_TRIES = 6; // Google hay lỗi nên thử nhiều lần
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

// OpenAI tts-1-hd → trả bytes mp3 hoặc null.
async function openaiBytes(key, text, host) {
  try {
    const r = await fetch(`${host}/v1/audio/speech`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'tts-1-hd',
        input: text,
        voice: 'nova',
        response_format: 'mp3',
      }),
    });
    if (!r.ok) return null;
    const buf = Buffer.from(await r.arrayBuffer());
    if (buf.length < 200) return null;
    return { buf, contentType: r.headers.get('content-type') || 'audio/mpeg' };
  } catch (_) {
    return null;
  }
}

module.exports = async (req, res) => {
  try {
    const text = (req.query.text || '').toString().trim().slice(0, 300);
    const voice = (req.query.voice || 'Kore').toString().slice(0, 20);
    if (!text) {
      res.status(400).json({ error: 'thiếu tham số text' });
      return;
    }
    const key = process.env.SHOPAIKEY_API_KEY;
    if (!key) {
      res.status(500).json({ error: 'server chưa cấu hình SHOPAIKEY_API_KEY' });
      return;
    }

    // 1) Google Kore — thử nhiều lần, luân phiên 2 host.
    let genUrl = null;
    for (let i = 0; i < GOOGLE_TRIES && !genUrl; i++) {
      genUrl = await googleOnce(key, text, voice, HOSTS[i % HOSTS.length]);
      if (!genUrl && i < GOOGLE_TRIES - 1) await sleep(250);
    }
    if (genUrl) {
      const audioRes = await fetch(genUrl).catch(() => null);
      if (audioRes && audioRes.ok) {
        const buf = Buffer.from(await audioRes.arrayBuffer());
        if (buf.length >= 200) {
          res.setHeader('Content-Type', audioRes.headers.get('content-type') || 'audio/wav');
          res.setHeader('Cache-Control', 'public, max-age=31536000, s-maxage=31536000, immutable');
          res.setHeader('X-TTS-Provider', 'google');
          res.status(200).send(buf);
          return;
        }
      }
    }

    // 2) Fallback OpenAI tts-1-hd (giọng kém hơn nhưng ổn định, khỏi câm).
    for (const host of HOSTS) {
      const out = await openaiBytes(key, text, host);
      if (out) {
        res.setHeader('Content-Type', out.contentType);
        res.setHeader('Cache-Control', 'public, max-age=31536000, s-maxage=31536000, immutable');
        res.setHeader('X-TTS-Provider', 'openai');
        res.status(200).send(out.buf);
        return;
      }
    }

    res.status(502).json({ error: 'TTS thất bại cả Google lẫn OpenAI' });
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
};
