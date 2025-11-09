# 最小 HTTP 服务（JS/TS 版本）

目标
- 使用 Node 原生 http 模块启动一个最小可运行的服务，理解请求/响应与超时设置。

依赖
- 无（使用 Node 原生模块）。

JS 版本：server.js
```js
// server.js
const http = require('http');

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ ok: true }));
  }
  res.writeHead(200, { 'content-type': 'text/plain' });
  res.end('Hello from Node.js http server');
});

// 设置服务器超时（避免长时间占用连接）
server.timeout = 30_000; // 30s

const port = process.env.PORT || 3000;
server.listen(port, () => {
  console.log(`HTTP server listening on http://localhost:${port}`);
});
```

TS 版本：server.ts（推荐使用 tsx 运行）
```ts
// server.ts
import http, { IncomingMessage, ServerResponse } from 'http';

const server = http.createServer((req: IncomingMessage, res: ServerResponse) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ ok: true }));
  }
  res.writeHead(200, { 'content-type': 'text/plain' });
  res.end('Hello from Node.js http server (TS)');
});

server.timeout = 30_000;

const port = process.env.PORT || 3000;
server.listen(port, () => {
  console.log(`HTTP server listening on http://localhost:${port}`);
});
```

运行
- JS：`node server.js`
- TS：安装 tsx（一次性）`npm i -D tsx`，运行：`npx tsx server.ts`

要点
- 默认 Keep-Alive 由 Node 管理；合理设置超时可避免资源占用。
- 通过 `req.url` 路由简化实现，生产建议使用框架（如 Express/Koa）。

