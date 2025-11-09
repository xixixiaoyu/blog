## CSRF 防护：挡住恶意请求

### CSRF 攻击的威胁
CSRF（跨站请求伪造）是一种狡猾的攻击方式。假设你登录了一个银行网站，然后访问了一个恶意网站。恶意网站可能偷偷发送一个转账请求，浏览器会自动附带你的登录 cookie，导致攻击者以你的身份操作。

CSRF 防护的核心是生成一个随机 token，要求所有状态更改请求（如 POST、PUT）都携带这个 token。恶意网站无法获取 token，因此无法伪造有效请求。

### 在 NestJS 中实现 CSRF 防护
NestJS 本身不提供内置 CSRF 防护，但可以借助第三方库实现。

#### Express 平台的 CSRF 防护
对于使用 Express 的 NestJS 应用，推荐 `csrf-csrf` 库：

```bash
npm install csrf-csrf
```

在 `main.ts` 中配置：

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { doubleCsrf } from 'csrf-csrf';

const { doubleCsrfProtection } = doubleCsrf({
  getSecret: () => 'your-secret', // 建议使用环境变量
  cookieName: '__Host-csrf',
  cookieOptions: { secure: true, sameSite: 'strict' },
});

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(doubleCsrfProtection);
  await app.listen(3000);
}
bootstrap();
```

创建一个控制器提供 CSRF token：

```typescript
import { Controller, Get, Req, Res } from '@nestjs/common';
import type { Request, Response } from 'express';
import { doubleCsrf } from 'csrf-csrf';

// 从同一处初始化获取 generateToken（也可在 main.ts 中一并初始化并导出）
const { generateToken } = doubleCsrf({
  getSecret: () => 'your-secret',
  cookieName: '__Host-csrf',
  cookieOptions: { secure: true, sameSite: 'strict' },
});

@Controller('auth')
export class AuthController {
  @Get('csrf-token')
  getCsrfToken(@Req() req: Request, @Res() res: Response) {
    const csrfToken = generateToken(req, res);
    return { csrfToken };
  }
}
```

前端通过调用 `/auth/csrf-token` 获取 token，并在后续请求的 header（如 `X-CSRF-Token`）中携带。

#### Fastify 平台的 CSRF 防护
如果使用 Fastify，可以安装 `@fastify/csrf-protection`：

```bash
npm install @fastify/csrf-protection
```

配置方式类似：

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { FastifyAdapter } from '@nestjs/platform-fastify';
import csrfProtection from '@fastify/csrf-protection';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, new FastifyAdapter());
  await app.register(csrfProtection);
  await app.listen(3000);
}
bootstrap();
```

### 最佳实践
- 使用 secure 和 sameSite cookie：确保 CSRF token 的 cookie 设置为 `secure: true` 和 `sameSite: 'strict'`，防止被窃取。
- 为每个会话生成唯一 token：避免使用固定 token，增加安全性。
- 记录异常请求：监控 CSRF 攻击尝试，及时发现潜在威胁。
