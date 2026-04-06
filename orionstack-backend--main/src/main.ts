import * as http from 'http';

const PORT = parseInt(process.env.PORT ?? '3000', 10);

const router: Record<string, (res: http.ServerResponse) => void> = {
  '/api/v1/health/live': (res) => {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok' }));
  },
  '/api/v1/health': (res) => {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', timestamp: new Date().toISOString() }));
  },
};

const server = http.createServer((req, res) => {
  const pathname = new URL(req.url ?? '/', `http://localhost`).pathname;
  const handler = router[pathname];
  if (handler) {
    handler(res);
  } else {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ message: 'PromptGenie API', version: '1.0.0' }));
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`[PromptGenie] Server listening on port ${PORT}`);
});
