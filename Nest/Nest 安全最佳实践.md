构建安全的 Web 应用是后端开发的核心职责之一。一个健壮的应用不仅需要实现业务功能，更要能抵御来自网络世界的各种威胁。

本文将整合并深入探讨 NestJS 中最关键的几项安全措施，包括：

*   **CORS 跨域**：安全地实现前后端分离通信。
*   **速率限制**：保护 API 免受暴力破解和 DDoS 攻击。
*   **Helmet 安全头**：利用 HTTP 头增强浏览器端安全。
*   **CSRF 防护**：抵御跨站请求伪造攻击。
*   **综合实践**：提供环境区分、日志监控等高级策略。

---

### 一、CORS：打破同源限制，安全跨域通信

#### 1. 为什么需要 CORS？

浏览器出于安全考虑，实施了“同源策略”，即只允许网页向与其同协议、同域名、同端口的服务器发送请求。在前后端分离架构下（例如，前端 `http://frontend.com`，后端 `http://api.backend.com`），这一策略会阻止前端应用直接调用后端 API。

CORS (跨域资源共享) 是一种 W3C 标准，它允许服务器在 HTTP 响应头中声明哪些源站有权限访问其资源，从而安全地“豁免”同源策略的限制。

#### 2. 在 NestJS 中启用 CORS

NestJS 通过 `enableCors()` 方法提供了简洁的配置方式。

**方法一：全局快速启用 (适合开发环境)**

在 `main.ts` 中，可以允许所有来源的请求，并支持携带凭证（如 Cookie）。

```typescript
// main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({
    origin: true, // 允许所有来源
    credentials: true, // 允许携带凭证
  });
  await app.listen(3000);
}
bootstrap();
```

**方法二：动态配置白名单 (推荐用于生产环境)**

为了安全，生产环境应严格限制允许访问的域名。

```typescript
// main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const allowedOrigins = ['http://frontend.com', 'https://sub.frontend.com'];

  app.enableCors({
    origin: (origin, callback) => {
      // 允许来自白名单的源或无源请求（如服务器端请求、移动应用）
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
  });
  await app.listen(3000);
}
bootstrap();
```

---

### 二、速率限制：保护 API 免受滥用

#### 1. 为什么需要速率限制？

无限制的 API 就像一扇敞开的大门，容易遭受恶意攻击，例如：

*   **暴力破解**：高频尝试登录密码或验证码。
*   **DDoS 攻击**：通过海量请求耗尽服务器资源，导致服务瘫痪。
*   **资源滥用**：恶意爬取数据，增加服务器成本。

速率限制通过约束单个 IP 在单位时间内的请求次数，能有效抵御此类攻击。

#### 2. 使用 `@nestjs/throttler` 实现速率限制

`@nestjs/throttler` 是官方推荐的速率限制模块，集成简单且功能强大。

```bash
npm install @nestjs/throttler
```

**基础配置**

在 `app.module.ts` 中全局配置，例如限制每个 IP 每分钟最多请求 10 次。

```typescript
// app.module.ts
import { Module } from '@nestjs/common';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60, // 时间窗口（秒）
      limit: 10, // 在时间窗口内允许的最大请求数
    }),
  ],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard, // 将 ThrottlerGuard 设置为全局守卫
    },
  ],
})
export class AppModule {}
```

**跳过特定路由**

对于某些无需限制的路由（如静态资源），可以使用 `@SkipThrottle()` 装饰器。

```typescript
import { Controller, Get } from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';

@SkipThrottle() // 对整个控制器生效
@Controller('static')
export class StaticController {
  @SkipThrottle(false) // 也可以单独对某个路由取消跳过
  @Get('assets')
  getAssets() {
    return 'Static assets';
  }
}
```

**分布式环境：使用 Redis 存储**

在多实例部署的应用中，必须使用外部存储（如 Redis）来同步所有节点的速率限制状态。

```bash
npm install @nest-lab/throttler-storage-redis ioredis
```

```typescript
// app.module.ts
import { ThrottlerModule } from '@nestjs/throttler';
import { ThrottlerStorageRedisService } from '@nest-lab/throttler-storage-redis';
import Redis from 'ioredis';

@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60,
      limit: 10,
      storage: new ThrottlerStorageRedisService(
        new Redis({ host: 'localhost', port: 6379 })
      ),
    }),
  ],
  // ...
})
export class AppModule {}
```

---

### 三、Helmet：一键增强 HTTP 安全头

#### 1. 为什么需要 Helmet？

HTTP 安全头是浏览器安全机制的第一道防线，能够指示浏览器如何处理网页内容，从而有效降低 XSS、点击劫持、MIME 嗅探等风险。Helmet 是一个中间件集合，可以方便地为应用设置各种推荐的安全头。

#### 2. 在 NestJS 中集成 Helmet

**Express 平台**

```bash
npm i helmet
```

```typescript
// main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(helmet());
  // ...
}
```

**Fastify 平台**

```bash
npm i @fastify/helmet
```

```typescript
// main.ts
import helmet from '@fastify/helmet';
import { FastifyAdapter } from '@nestjs/platform-fastify';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, new FastifyAdapter());
  await app.register(helmet);
  // ...
}
```

#### 3. 常见安全头与推荐配置

Helmet 默认开启了一系列安全头，但精细化配置能更好地平衡安全与功能。

```typescript
// main.ts (以 Express 为例)
const isProd = process.env.NODE_ENV === 'production';

app.use(
  helmet({
    // 内容安全策略 (CSP)：强大的 XSS 防护，建议精细化配置
    contentSecurityPolicy: isProd ? undefined : false, // 生产环境启用默认值，开发环境关闭

    // 跨源嵌入策略：需要所有跨源资源支持 CORP/CORS
    crossOriginEmbedderPolicy: isProd,

    // HSTS：强制浏览器使用 HTTPS，仅在生产环境开启
    hsts: isProd
      ? { maxAge: 31536000, includeSubDomains: true }
      : false,
      
    // 其他常用且安全的默认值
    // hidePoweredBy: true,
    // noSniff: true,
    // frameguard: { action: 'deny' },
  })
);
```

**核心安全头解读**：

*   **Content-Security-Policy (CSP)**：最强大的 XSS 防护机制。它定义了资源白名单，只允许加载来自可信源的脚本、样式、图片等。
*   **Strict-Transport-Security (HSTS)**：强制客户端（如浏览器）使用 HTTPS 与服务器创建连接。
*   **X-Frame-Options**：防止页面被嵌入到 `<iframe>` 中，防御点击劫持攻击。
*   **X-Content-Type-Options**: 设置为 `nosniff`，防止浏览器对响应内容进行 MIME 类型嗅探。

#### 4. 高级技巧：为 CSP 添加动态 Nonce

为了在启用严格 CSP 的同时允许特定的内联脚本执行，最佳实践是为每个请求生成一个唯一的 `nonce`。

```typescript
// main.ts (Express 平台)
import crypto from 'crypto';
import helmet from 'helmet';

// 1. 为每个请求生成并附加 nonce
app.use((req, res, next) => {
  res.locals.cspNonce = crypto.randomBytes(16).toString('base64');
  next();
});

// 2. 使用动态 nonce 配置 CSP
app.use((req, res, next) => {
  helmet.contentSecurityPolicy({
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", `'nonce-${res.locals.cspNonce}'`], // 允许自身来源和带有 nonce 的脚本
      styleSrc: ["'self'", "'unsafe-inline'"], // 生产中建议移除 'unsafe-inline'
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      frameAncestors: ["'none'"], // 禁止被嵌入
    },
  })(req, res, next);
});

// 在你的模板引擎 (如 EJS, Pug) 中使用:
// <script nonce="{{ cspNonce }}">...</script>
```

---

### 四、CSRF 防护：挡住恶意请求

#### 1. CSRF 攻击的威胁

CSRF (跨站请求伪造) 是一种常见的 Web 攻击。攻击者诱导已登录的用户访问一个恶意网站，该网站会向用户登录过的应用（如银行网站）发送一个伪造的请求（如转账）。由于浏览器会自动携带用户的 Cookie，这个伪造请求会被服务器误认为是合法操作，从而导致严重后果。

CSRF 防护的核心机制是“令牌同步模式”：服务器为用户会话生成一个不可预测的随机令牌 (CSRF Token)，并要求所有状态变更的请求（如 POST, PUT, DELETE）都必须携带此令牌。由于恶意网站无法获取该令牌，其伪造的请求便会因验证失败而被拒绝。

#### 2. 在 NestJS 中实现 CSRF 防护

**Express 平台：使用 `csurf`**

`csurf` 是 Express 生态中久经考验的 CSRF 防护中间件。

```bash
npm install csurf cookie-parser
```

```typescript
// main.ts
import cookieParser from 'cookie-parser';
import csurf from 'csurf';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(cookieParser());
  app.use(csurf({ cookie: true })); // 将 token 存储在 cookie 中
  // ...
}
```

前端需要从一个特定的端点获取 token，然后在后续的写操作请求头（如 `X-CSRF-Token`）中附带它。

**Fastify 平台：使用 `@fastify/csrf-protection`**

```bash
npm install @fastify/csrf-protection
```

```typescript
// main.ts
import csrfProtection from '@fastify/csrf-protection';
import cookie from '@fastify/cookie';
import { FastifyAdapter } from '@nestjs/platform-fastify';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, new FastifyAdapter());
  await app.register(cookie, { secret: process.env.COOKIE_SECRET });
  await app.register(csrfProtection, { cookieOpts: { signed: true } });
  // ...
}
```

---

### 五、综合安全策略与最佳实践

将上述安全措施整合起来，并根据不同环境进行配置，是构建健壮应用的关键。

#### 1. 环境区分配置

使用一个专门的配置文件来管理不同环境下的安全策略。

```typescript
// src/config/security.config.ts
export const getSecurityConfig = () => {
  const isProduction = process.env.NODE_ENV === 'production';

  return {
    cors: {
      origin: isProduction ? process.env.ALLOWED_ORIGINS?.split(',') : true,
      credentials: true,
    },
    throttle: {
      ttl: isProduction ? 60 : 1, // 生产环境 60s，开发环境 1s
      limit: isProduction ? 20 : 100, // 生产环境 20 次，开发环境 100 次
    },
    helmet: {
      contentSecurityPolicy: isProduction ? undefined : false,
      crossOriginEmbedderPolicy: isProduction,
    },
  };
};
```

在 `main.ts` 中应用这些配置：

```typescript
// main.ts
import { getSecurityConfig } from './config/security.config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = getSecurityConfig();

  app.enableCors(config.cors);
  app.use(helmet(config.helmet));
  // ThrottlerModule.forRoot() 也应使用 config.throttle
  
  await app.listen(3000);
}
```

#### 2. 监控与日志

记录安全相关的事件对于发现攻击、排查问题至关重要。

```typescript
// src/common/security-logger.service.ts
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class SecurityLogger {
  private readonly logger = new Logger(SecurityLogger.name);

  logThrottleExceeded(ip: string, endpoint: string) {
    this.logger.warn(`[Throttler] Rate limit exceeded for IP ${ip} on ${endpoint}`);
  }

  logCsrfAttempt(ip: string, endpoint: string) {
    this.logger.error(`[CSRF] Potential CSRF attack from IP ${ip} on ${endpoint}`);
  }
  
  logCorsViolation(origin: string) {
    this.logger.warn(`[CORS] Blocked request from disallowed origin: ${origin}`);
  }
}
```

#### 3. 处理代理服务器与真实 IP

当应用部署在 Nginx 或其他反向代理之后，速率限制器默认获取到的 IP 将是代理服务器的 IP。必须配置应用以信任代理发送的 `X-Forwarded-For` 头，从而获取客户端的真实 IP。

对于 Fastify，可以在创建 Adapter 时设置：

```typescript
const app = await NestFactory.create(AppModule, new FastifyAdapter({ trustProxy: true }));
```

对于 Express，则需要单独设置：

```typescript
const app = await NestFactory.create(AppModule);
app.getHttpAdapter().getInstance().set('trust proxy', 1);
```

#### 4. 验证与排查

*   **浏览器开发者工具**：检查“网络 (Network)”面板中的响应头，确认 Helmet 设置的 `Content-Security-Policy`, `X-Frame-Options` 等是否生效。
*   **`curl` 命令**：使用 `curl -I http://localhost:3000` 查看纯文本的响应头。
*   **控制台错误**：如果 CSP 策略过于严格，浏览器控制台会明确提示哪个资源的加载被哪个指令所阻止，根据提示调整策略。

---

### 总结

安全并非一蹴而就，而是一个持续加固的系统工程。通过在 NestJS 应用中整合 CORS、速率限制、Helmet 和 CSRF 防护，我们可以构建一个坚实的多层防御体系。

核心要点包括：

*   **最小权限原则**：CORS 白名单应尽可能收紧。
*   **资源保护**：通过速率限制防止 API 被滥用。
*   **纵深防御**：利用 Helmet 和 CSRF 令牌加固客户端与服务器的交互。
*   **环境隔离**：为不同环境（开发、测试、生产）定制差异化的安全策略。
*   **持续监控**：通过日志记录和告警，及时发现并响应潜在的安全威胁。

将这些实践融入日常开发流程，将能显著提升你的 NestJS 应用的健壮性和可靠性。
