// Serverless TTS trên Vercel: đọc chữ tiếng Việt bằng Google Gemini (giọng Kore)
// qua ShopAIKey. Trả về audio và đặt Cache-Control 1 năm → CDN Vercel tự lưu
// lại, mỗi chữ chỉ gọi ShopAIKey đúng 1 lần đầu, lần sau lấy từ cache.
//
// Key đặt ở biến môi trường SHOPAIKEY_API_KEY (Vercel → Settings → Env Vars),
// KHÔNG lộ ra client và không dính CORS (web gọi cùng domain).

const HOSTS = ['https://api.shopaikey.com', 'https://direct.shopaikey.com'];

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

    const body = JSON.stringify({
      model: 'gemini-2.5-flash-preview-tts',
      text,
      voice,
    });

    // Gọi Google TTS qua ShopAIKey → nhận JSON có url audio.
    let genUrl = null;
    let lastErr = 'unknown';
    for (const host of HOSTS) {
      try {
        const r = await fetch(`${host}/tts/google/generations`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${key}`,
            'Content-Type': 'application/json',
            Accept: 'application/json',
          },
          body,
        });
        const j = await r.json().catch(() => ({}));
        if (r.ok && j && j.url) {
          genUrl = j.url;
          break;
        }
        lastErr = `HTTP ${r.status}: ${JSON.stringify(j).slice(0, 200)}`;
      } catch (e) {
        lastErr = String(e); // lỗi mạng → thử host tiếp theo
      }
    }
    if (!genUrl) {
      res.status(502).json({ error: 'TTS thất bại', detail: lastErr });
      return;
    }

    // Tải audio thật (Google trả WAV).
    const audioRes = await fetch(genUrl);
    if (!audioRes.ok) {
      res.status(502).json({ error: 'tải audio thất bại', status: audioRes.status });
      return;
    }
    const buf = Buffer.from(await audioRes.arrayBuffer());
    const contentType = audioRes.headers.get('content-type') || 'audio/wav';

    res.setHeader('Content-Type', contentType);
    // Cache lâu ở cả trình duyệt lẫn CDN Vercel (chữ cố định nên an toàn).
    res.setHeader('Cache-Control', 'public, max-age=31536000, s-maxage=31536000, immutable');
    res.status(200).send(buf);
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
};
