// Generates the FinBrief app icon as a PNG, with no image-library dependency.
//
// Why hand-rolled: the project had no logo asset and no design tool in the
// loop, but it was still shipping Flutter's default icon. Encoding a PNG from
// raw pixels only needs zlib, which ships with Node, so the icon can live in
// version control as code and be regenerated at any size.
//
// Usage: node tool/generate_icon.js
// Outputs assets/icon/icon.png (full icon) and icon_foreground.png (Android
// adaptive foreground, which must keep its art inside the safe circle).
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const SIZE = 1024;

// Brand colours, matching AppColors in lib/theme/app_colors.dart.
const PRIMARY = [0x25, 0x63, 0xeb];
const DEEP = [0x0f, 0x2c, 0x7a];
const WHITE = [0xff, 0xff, 0xff];
const ACCENT = [0x22, 0xc5, 0x5e]; // AppColors.success — the rising line

const lerp = (a, b, t) => a + (b - a) * t;
const mix = (c1, c2, t) => [lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t)];
const clamp01 = (v) => (v < 0 ? 0 : v > 1 ? 1 : v);

/// Smooth 0..1 ramp, used to antialias every edge instead of leaving jaggies.
const smooth = (edge0, edge1, x) => {
  const t = clamp01((x - edge0) / (edge1 - edge0));
  return t * t * (3 - 2 * t);
};

/// Shortest distance from a point to a line segment — the basis for drawing
/// strokes of any thickness with rounded ends.
function distToSegment(px, py, x1, y1, x2, y2) {
  const dx = x2 - x1;
  const dy = y2 - y1;
  const lengthSq = dx * dx + dy * dy;
  const t = lengthSq === 0 ? 0 : clamp01(((px - x1) * dx + (py - y1) * dy) / lengthSq);
  const cx = x1 + t * dx;
  const cy = y1 + t * dy;
  return Math.hypot(px - cx, py - cy);
}

const distToPolyline = (px, py, pts) => {
  let best = Infinity;
  for (let i = 0; i < pts.length - 1; i += 1) {
    best = Math.min(best, distToSegment(px, py, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1]));
  }
  return best;
};

/// Signed distance to a rounded rectangle: negative inside, positive outside.
function roundedRectDist(px, py, cx, cy, halfW, halfH, radius) {
  const qx = Math.abs(px - cx) - (halfW - radius);
  const qy = Math.abs(py - cy) - (halfH - radius);
  const outside = Math.hypot(Math.max(qx, 0), Math.max(qy, 0));
  return outside + Math.min(Math.max(qx, qy), 0) - radius;
}

/// The rising line chart, in 0..1 space so it scales to any canvas size.
const CHART = [
  [0.20, 0.68],
  [0.36, 0.52],
  [0.50, 0.60],
  [0.68, 0.34],
  [0.80, 0.34],
];

/// Renders one icon. `adaptive` inflates the padding, because Android crops
/// adaptive foregrounds to a circle and anything near the edge is lost.
function render(size, { adaptive }) {
  const px = Buffer.alloc(size * size * 4);
  const s = (v) => v * size;
  const scale = adaptive ? 0.74 : 1;
  const centre = 0.5 * size;

  const strokeW = s(0.055) * scale;
  const bgHalf = s(0.5) * (adaptive ? 0.62 : 1);
  const bgRadius = s(0.225) * (adaptive ? 0.62 : 1);

  // Chart geometry, scaled about the centre for the adaptive variant.
  const chart = CHART.map(([x, y]) => [centre + (s(x) - centre) * scale, centre + (s(y) - centre) * scale]);
  const tip = chart[chart.length - 1];

  for (let y = 0; y < size; y += 1) {
    for (let x = 0; x < size; x += 1) {
      const cx = x + 0.5;
      const cy = y + 0.5;

      // Background: rounded square with a diagonal gradient for depth.
      const bg = roundedRectDist(cx, cy, centre, centre, bgHalf, bgHalf, bgRadius);
      let alpha = 1 - smooth(-1, 1, bg);
      let colour = mix(PRIMARY, DEEP, clamp01((cx + cy) / (2 * size)));

      // Rising line, drawn over the background.
      const lineDist = distToPolyline(cx, cy, chart) - strokeW / 2;
      const lineCoverage = 1 - smooth(-1, 1, lineDist);
      if (lineCoverage > 0) {
        colour = mix(colour, WHITE, lineCoverage);
        alpha = Math.max(alpha, lineCoverage);
      }

      // Accent dot at the tip — reads as "latest value" and gives the mark a
      // focal point at small sizes.
      const dotDist = Math.hypot(cx - tip[0], cy - tip[1]) - s(0.055) * scale;
      const dotCoverage = 1 - smooth(-1, 1, dotDist);
      if (dotCoverage > 0) {
        colour = mix(colour, ACCENT, dotCoverage);
        alpha = Math.max(alpha, dotCoverage);
      }

      const i = (y * size + x) * 4;
      px[i] = Math.round(colour[0]);
      px[i + 1] = Math.round(colour[1]);
      px[i + 2] = Math.round(colour[2]);
      px[i + 3] = Math.round(clamp01(alpha) * 255);
    }
  }
  return px;
}

// --- minimal PNG encoder ---------------------------------------------------

const CRC_TABLE = (() => {
  const table = new Int32Array(256);
  for (let n = 0; n < 256; n += 1) {
    let c = n;
    for (let k = 0; k < 8; k += 1) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    table[n] = c;
  }
  return table;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (const byte of buf) c = CRC_TABLE[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([length, body, crc]);
}

function encodePng(rgba, size) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // colour type: RGBA

  // Each scanline is prefixed with its filter byte (0 = none).
  const raw = Buffer.alloc(size * (size * 4 + 1));
  for (let y = 0; y < size; y += 1) {
    raw[y * (size * 4 + 1)] = 0;
    rgba.copy(raw, y * (size * 4 + 1) + 1, y * size * 4, (y + 1) * size * 4);
  }

  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

const outDir = path.join(__dirname, '..', 'assets', 'icon');
fs.mkdirSync(outDir, { recursive: true });

for (const [name, opts] of [
  ['icon.png', { adaptive: false }],
  ['icon_foreground.png', { adaptive: true }],
]) {
  const file = path.join(outDir, name);
  fs.writeFileSync(file, encodePng(render(SIZE, opts), SIZE));
  console.log(`wrote ${path.relative(path.join(__dirname, '..'), file)} (${SIZE}x${SIZE})`);
}
