// Generates the Play Store feature graphic (1024x500) from the app icon.
//
// Same approach as the icon work: encoded from raw pixels with nothing but
// zlib, so the asset is reproducible from version control rather than being a
// binary someone has to keep track of. Re-run after changing the logo.
//
// Usage: node tool/generate_feature_graphic.js
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const W = 1024;
const H = 500;

// Sampled from the logo's own gradient so the banner and the icon read as one
// thing on the store page.
const LEFT = [0x92, 0x26, 0xf6];
const RIGHT = [0x21, 0x03, 0x87];

const clamp01 = (v) => (v < 0 ? 0 : v > 1 ? 1 : v);
const lerp = (a, b, t) => a + (b - a) * t;
const mix = (c1, c2, t) => [lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t)];
const smooth = (e0, e1, x) => {
  const t = clamp01((x - e0) / (e1 - e0));
  return t * t * (3 - 2 * t);
};

// --- PNG decode (for the logo) --------------------------------------------

function decodePng(file) {
  const buf = fs.readFileSync(file);
  let p = 8;
  let w = 0;
  let h = 0;
  let colourType = 0;
  const idat = [];

  while (p < buf.length) {
    const len = buf.readUInt32BE(p);
    const type = buf.slice(p + 4, p + 8).toString('ascii');
    const data = buf.slice(p + 8, p + 8 + len);
    if (type === 'IHDR') {
      w = data.readUInt32BE(0);
      h = data.readUInt32BE(4);
      colourType = data[9];
    }
    if (type === 'IDAT') idat.push(data);
    if (type === 'IEND') break;
    p += 12 + len;
  }

  const channels = colourType === 6 ? 4 : 3;
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = w * channels;
  const px = Buffer.alloc(h * stride);

  // Undo the per-scanline filters.
  let q = 0;
  for (let y = 0; y < h; y += 1) {
    const filter = raw[q];
    q += 1;
    const line = raw.slice(q, q + stride);
    q += stride;

    for (let x = 0; x < stride; x += 1) {
      const a = x >= channels ? px[y * stride + x - channels] : 0;
      const b = y > 0 ? px[(y - 1) * stride + x] : 0;
      const c = x >= channels && y > 0 ? px[(y - 1) * stride + x - channels] : 0;
      let v = line[x];

      if (filter === 1) v += a;
      else if (filter === 2) v += b;
      else if (filter === 3) v += (a + b) >> 1;
      else if (filter === 4) {
        const pp = a + b - c;
        const pa = Math.abs(pp - a);
        const pb = Math.abs(pp - b);
        const pc = Math.abs(pp - c);
        v += pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
      }
      px[y * stride + x] = v & 255;
    }
  }

  return { w, h, channels, stride, px };
}

// --- PNG encode ------------------------------------------------------------

const CRC_TABLE = (() => {
  const table = new Int32Array(256);
  for (let n = 0; n < 256; n += 1) {
    let c = n;
    for (let k = 0; k < 8; k += 1) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c;
  }
  return table;
})();

const crc32 = (buf) => {
  let c = 0xffffffff;
  for (const byte of buf) c = CRC_TABLE[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
};

function chunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([length, body, crc]);
}

function encodePng(rgb, w, h) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8;
  ihdr[9] = 2; // RGB — Play wants no alpha on the feature graphic

  const stride = w * 3;
  const raw = Buffer.alloc(h * (stride + 1));
  for (let y = 0; y < h; y += 1) {
    raw[y * (stride + 1)] = 0;
    rgb.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }

  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// --- Compose ---------------------------------------------------------------

const logo = decodePng(path.join(__dirname, '..', 'assets', 'icon', 'icon.png'));
const out = Buffer.alloc(W * H * 3);
const stride = W * 3;

// Centred, and generously inset. Play crops this graphic differently across
// its surfaces, so anything near an edge risks being cut.
const LOGO_SIZE = 340;
const LOGO_X = (W - LOGO_SIZE) / 2;
const LOGO_Y = (H - LOGO_SIZE) / 2;

// The source artwork is RGB with no alpha, so its rounded corners are stored
// as pure black rather than transparency. Composited naively they draw a black
// square around the mark. Anything this dark is corner, not art — the logo's
// own darkest purple (#210387) sums to 171, well clear of the threshold.
const CORNER_BLACK = 40;

for (let y = 0; y < H; y += 1) {
  for (let x = 0; x < W; x += 1) {
    // Diagonal gradient, matching the icon.
    let colour = mix(LEFT, RIGHT, clamp01((x / W) * 0.85 + (y / H) * 0.15));

    // Soft light from the upper left, so the flat banner has some depth.
    const glow = 1 - clamp01(Math.hypot(x - 180, y - 120) / 620);
    colour = mix(colour, [0xff, 0xff, 0xff], glow * 0.10);

    // Composite the logo, sampling the source with its rounded corners intact.
    const lx = x - LOGO_X;
    const ly = y - LOGO_Y;
    if (lx >= 0 && lx < LOGO_SIZE && ly >= 0 && ly < LOGO_SIZE) {
      const sx = Math.floor((lx / LOGO_SIZE) * logo.w);
      const sy = Math.floor((ly / LOGO_SIZE) * logo.h);
      const i = sy * logo.stride + sx * logo.channels;
      const src = [logo.px[i], logo.px[i + 1], logo.px[i + 2]];

      // Skip the black corner pixels so the gradient shows through and the
      // mark keeps its rounded shape.
      if (src[0] + src[1] + src[2] > CORNER_BLACK) {
        colour = src;
      }
    }

    const o = y * stride + x * 3;
    out[o] = Math.round(colour[0]);
    out[o + 1] = Math.round(colour[1]);
    out[o + 2] = Math.round(colour[2]);
  }
}

const outDir = path.join(__dirname, '..', 'docs', 'store');
fs.mkdirSync(outDir, { recursive: true });
const file = path.join(outDir, 'feature_graphic.png');
fs.writeFileSync(file, encodePng(out, W, H));
console.log(`wrote ${path.relative(path.join(__dirname, '..'), file)} (${W}x${H})`);
