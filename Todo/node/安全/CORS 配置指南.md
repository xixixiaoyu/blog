# CORS 配置指南

目标
- 正确配置跨域策略，确保前后端安全联通。

依赖安装
```bash
npm i cors express
```

示例：Express 中使用 CORS
```js
const express = require('express');
const cors = require('cors');
const app = express();

const allowed = ['http://localhost:3000', 'https://your-site.com'];
app.use(cors({
  origin(origin, cb) {
    if (!origin || allowed.includes(origin)) return cb(null, true);
    cb(new Error('Not allowed by CORS'));
  },
  credentials: true,
}));

app.get('/health', (req, res) => res.json({ ok: true }));
app.listen(4000);
```

要点
- 带凭证请求需设置 `credentials: true`，并明确 `Access-Control-Allow-Credentials` 与 `Access-Control-Allow-Origin`。
- 生产中建议将允许域名放入配置管理，避免硬编码。

