# JWT 登录与刷新

目标
- 在 Express 中实现基于 JWT 的登录、鉴权与刷新令牌。

依赖安装
```bash
npm i express jsonwebtoken
npm i -D tsx typescript @types/express @types/jsonwebtoken
```

示例：app.ts
```ts
import express from 'express';
import jwt from 'jsonwebtoken';

const app = express();
app.use(express.json());

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';
const REFRESH_SECRET = process.env.REFRESH_SECRET || 'dev-refresh';

// 演示用：内存存储刷新令牌，生产请使用数据库/缓存
const refreshStore = new Set<string>();

function signAccess(payload: object) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '15m' });
}
function signRefresh(payload: object) {
  const token = jwt.sign(payload, REFRESH_SECRET, { expiresIn: '7d' });
  refreshStore.add(token);
  return token;
}

app.post('/login', (req, res) => {
  const { username } = req.body;
  // 省略校验与密码流程
  const access = signAccess({ sub: username });
  const refresh = signRefresh({ sub: username });
  res.json({ access, refresh });
});

function auth(req: express.Request, res: express.Response, next: express.NextFunction) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '');
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    (req as any).user = payload;
    next();
  } catch {
    res.status(401).json({ message: 'unauthorized' });
  }
}

app.get('/me', auth, (req, res) => {
  res.json({ user: (req as any).user });
});

app.post('/refresh', (req, res) => {
  const { token } = req.body;
  if (!token || !refreshStore.has(token)) return res.status(401).json({ message: 'invalid refresh token' });
  try {
    const payload = jwt.verify(token, REFRESH_SECRET) as any;
    const access = signAccess({ sub: payload.sub });
    res.json({ access });
  } catch {
    res.status(401).json({ message: 'invalid refresh token' });
  }
});

app.listen(3000, () => console.log('http://localhost:3000'));
```

要点
- Access 短期、Refresh 长期；服务端需可吊销刷新令牌。
- 谨慎处理 Cookie/Storage 与跨域；HTTPS 下传输令牌更安全。

