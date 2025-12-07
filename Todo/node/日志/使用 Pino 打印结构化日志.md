# 使用 Pino 打印结构化日志

目标
- 使用 Pino 记录结构化日志，并在 Express 中关联请求耗时与状态码。

依赖安装
```bash
npm i pino pino-http
```

示例：app.js
```js
const express = require('express');
const pino = require('pino');
const pinoHttp = require('pino-http');

const logger = pino({ level: process.env.LOG_LEVEL || 'info' });
const app = express();

app.use(pinoHttp({ logger }));
app.get('/health', (req, res) => res.json({ ok: true }));

app.listen(3000, () => logger.info('Listening on :3000'));
```

要点
- 结构化日志便于检索与聚合；生产使用 JSON 格式输出，不做彩色美化。
- 建议为每个请求生成并传递 `requestId`，用于问题定位与追踪。

