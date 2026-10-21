import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname, resolve, sep } from 'node:path';
import { networkInterfaces } from 'node:os';

const root = resolve(process.argv.includes('--study')?'web':'dist');
const mime = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.svg': 'image/svg+xml', '.png':'image/png', '.webp':'image/webp', '.webmanifest': 'application/manifest+json' };
const server = http.createServer(async (req, res) => {
  try {
    const pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    const file = resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
    if (!file.startsWith(root + sep)) { res.writeHead(403).end(); return; }
    const data = await readFile(file);
    res.writeHead(200, { 'Content-Type': mime[extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store' });
    res.end(data);
  } catch { res.writeHead(404).end('Not found'); }
});
const port=Number(process.env.PORT || 4173);
server.listen(port, '0.0.0.0', () => {
  console.log(`Threefold: http://localhost:${port}`);
  for (const values of Object.values(networkInterfaces())) for (const value of values || []) {
    if (value.family === 'IPv4' && !value.internal) console.log(`Phone: http://${value.address}:${port}`);
  }
});
