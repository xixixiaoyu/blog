# Express 最小路由与中间件（JS/TS）

目标
- 通过 Express 快速搭建路由与中间件，理解请求处理流程。

依赖安装
```bash
npm i express
npm i -D tsx typescript @types/express
```

JS：app.js
```js
const express = require('express');
const app = express();

// 内置中间件
app.use(express.json());

// 简单日志中间件
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    console.log(`${req.method} ${req.url} -> ${res.statusCode} ${Date.now() - start}ms`);
  });
  next();
});

app.get('/health', (req, res) => res.json({ ok: true }));
app.get('/hello/:name', (req, res) => res.send(`Hello, ${req.params.name}`));

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Express on http://localhost:${port}`));
```

TS：app.ts
```ts
import express, { Request, Response, NextFunction } from 'express';
const app = express();

app.use(express.json());

app.use((req: Request, res: Response, next: NextFunction) => {
  const start = Date.now();
  res.on('finish', () => {
    console.log(`${req.method} ${req.url} -> ${res.statusCode} ${Date.now() - start}ms`);
  });
  next();
});

app.get('/health', (_req: Request, res: Response) => res.json({ ok: true }));
app.get('/hello/:name', (req: Request, res: Response) => res.send(`Hello, ${req.params.name}`));

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Express on http://localhost:${port}`));
```

运行
- JS：`node app.js`
- TS：`npx tsx app.ts`

要点
- 使用 `express.json()` 解析 JSON 请求体。
- 中间件通过 `next()` 串联，请注意错误处理中间件签名 `(err, req, res, next)`。

