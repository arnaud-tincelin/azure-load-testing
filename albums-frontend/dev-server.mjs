import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = 8080;
const API_TARGET = 'http://localhost:5080';

const server = http.createServer((req, res) => {
  // Proxy /albums and /cart to the API
  if (req.url.startsWith('/albums') || req.url.startsWith('/cart')) {
    const proxyReq = http.request(
      `${API_TARGET}${req.url}`,
      { method: req.method, headers: { ...req.headers, host: 'localhost:5080' } },
      (proxyRes) => {
        res.writeHead(proxyRes.statusCode, proxyRes.headers);
        proxyRes.pipe(res);
      }
    );
    proxyReq.on('error', (e) => {
      res.writeHead(502);
      res.end('Bad Gateway');
    });
    req.pipe(proxyReq);
    return;
  }

  // Serve static files
  const filePath = path.join(__dirname, req.url === '/' ? 'index.html' : req.url);
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not Found');
      return;
    }
    const ext = path.extname(filePath);
    const types = { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css' };
    res.writeHead(200, { 'Content-Type': types[ext] || 'application/octet-stream' });
    res.end(data);
  });
});

server.listen(PORT, () => console.log(`Dev server on http://localhost:${PORT}`));
