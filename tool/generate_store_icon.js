// Produces the 512x512 Play Store icon from the source artwork.
//
// Two things have to happen beyond a resize:
//
// 1. The source is RGB with no alpha, so its rounded corners are stored as
//    pure black. Uploaded as-is that is a black-cornered square on the store
//    listing. The corners are refilled with the logo's own gradient, giving a
//    full-bleed square — which is what Play wants, since it applies its own
//    rounded mask on every surface it shows the icon.
//
// 2. Downscaling 1254 -> 512 is a 2.45x reduction. Point sampling at that
//    ratio drops most of the source pixels and visibly aliases the diagonal
//    arrow, so each output pixel averages the full source area behind it.
//
// Usage: node tool/generate_store_icon.js
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const SIZE = 512;

// The logo's own gradient, sampled from the artwork.
const TOP_LEFT = [0x92, 0x26, 0xf6];
const BOTTOM_RIGHT = [0x21, 0x03, 0x87];

// Anything darker than this is a corner, not art — the logo's darkest purple
// (#210387) sums to 171.
const CORNER_BLACK = 40;

const clamp01 = (v) => (v < 0 ? 0 : v > 1 ? 1 : v);
const lerp = (a, b, t) => a + (b - a) * t;

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

function encodePng(rgb, size) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8;
  ihdr[9] = 2; // RGB, no alpha — Play does the rounding itself

  const stride = size * 3;
  const raw = Buffer.alloc(size * (stride + 1));
  for (let y = 0; y < size; y += 1) {
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

const src = decodePng(path.join(__dirname, '..', 'assets', 'icon', 'icon.png'));

/// Source pixel, with black corners replaced by the gradient behind them.
function sample(x, y) {
  const i = y * src.stride + x * src.channels;
  const r = src.px[i];
  const g = src.px[i + 1];
  const b = src.px[i + 2];

  if (r + g + b > CORNER_BLACK) return [r, g, b];

  const t = clamp01((x / src.w) * 0.5 + (y / src.h) * 0.5);
  return [
    lerp(TOP_LEFT[0], BOTTOM_RIGHT[0], t),
    lerp(TOP_LEFT[1], BOTTOM_RIGHT[1], t),
    lerp(TOP_LEFT[2], BOTTOM_RIGHT[2], t),
  ];
}

const out = Buffer.alloc(SIZE * SIZE * 3);
const outStride = SIZE * 3;
const scale = src.w / SIZE;

for (let y = 0; y < SIZE; y += 1) {
  const y0 = Math.floor(y * scale);
  const y1 = Math.min(src.h, Math.ceil((y + 1) * scale));

  for (let x = 0; x < SIZE; x += 1) {
    const x0 = Math.floor(x * scale);
    const x1 = Math.min(src.w, Math.ceil((x + 1) * scale));

    let r = 0;
    let g = 0;
    let b = 0;
    let n = 0;

    for (let sy = y0; sy < y1; sy += 1) {
      for (let sx = x0; sx < x1; sx += 1) {
        const c = sample(sx, sy);
        r += c[0];
        g += c[1];
        b += c[2];
        n += 1;
      }
    }

    const o = y * outStride + x * 3;
    out[o] = Math.round(r / n);
    out[o + 1] = Math.round(g / n);
    out[o + 2] = Math.round(b / n);
  }
}

const outDir = path.join(__dirname, '..', 'docs', 'store');
fs.mkdirSync(outDir, { recursive: true });
const file = path.join(outDir, 'play_icon_512.png');
const png = encodePng(out, SIZE);
fs.writeFileSync(file, png);

console.log(`wrote ${path.relative(path.join(__dirname, '..'), file)}`);
console.log(`  ${SIZE}x${SIZE}, ${(png.length / 1024).toFixed(0)} KB (Play allows up to 1 MB)`);
