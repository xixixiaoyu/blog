## 一、CORS：打破同源限制，安全跨域通信
### 为什么需要 CORS？
浏览器为了保护用户，设置了同源策略：一个网页只能访问与它同协议、同域名、同端口的资源。比如，运行在 `http://frontend.com` 的前端页面无法直接请求 `http://api.backend.com` 的 API。这种限制在前后端分离的场景下会阻碍开发。

CORS（跨域资源共享）是一种标准化的机制，允许服务器明确告诉浏览器哪些外部域名可以访问它的资源。它就像一个“通行证”，让前后端在不同域名下也能顺畅通信。

### 在 NestJS 中启用 CORS
NestJS 提供了简单的方式来配置 CORS。以下是两种常见方法：

#### 方法一：全局启用 CORS
在 `main.ts` 中使用 `enableCors()` 方法：

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({
    origin: true, // 允许所有来源，适合开发环境
    credentials: true, // 支持携带 cookie 或认证头
  });
  await app.listen(3000);
}
bootstrap();
```

#### 方法二：动态配置 CORS
如果需要更精细的控制，比如只允许特定域名，可以动态配置：

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const allowedOrigins = ['http://frontend.com', 'http://sub.frontend.com'];

  app.enableCors({
    origin: (origin, callback) => {
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

### 最佳实践
+ **生产环境限制域名**：开发时可以用 `origin: true`，但生产环境中应明确指定可信域名列表，避免安全风险。
+ **支持 credentials**：如果请求需要携带 cookie 或认证信息，记得设置 `credentials: true`。
+ **记录非法请求**：通过日志监控非法的跨域请求，及时发现潜在问题。

## 二、CSRF 防护：挡住恶意请求
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
+ **使用 secure 和 sameSite cookie**：确保 CSRF token 的 cookie 设置为 `secure: true` 和 `sameSite: 'strict'`，防止被窃取。
+ **为每个会话生成唯一 token**：避免使用固定 token，增加安全性。
+ **记录异常请求**：监控 CSRF 攻击尝试，及时发现潜在威胁。

## 三、速率限制：保护 API 免受滥用
### 为什么需要速率限制？
没有速率限制的 API 容易被恶意用户攻击，比如：

+ **暴力破解**：尝试大量密码组合。
+ **DDoS 攻击**：通过高频请求瘫痪服务器。
+ **资源滥用**：恶意爬取数据或占用服务器资源。

速率限制通过限制单个用户在特定时间内的请求次数，有效降低这些风险。

### 在 NestJS 中实现速率限制
NestJS 提供了 `@nestjs/throttler` 模块，简单易用：

```bash
npm install @nestjs/throttler
```

在 `app.module.ts` 中配置：

```typescript
import { Module } from '@nestjs/common';
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60, // 1 分钟（单位为秒）
      limit: 10, // 每分钟最多 10 次请求
    }),
  ],
})
export class AppModule {}
```

#### 跳过特定路由
某些路由（如静态资源）可能不需要限制：

```typescript
import { ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

@Module({
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
```

在控制器中跳过限制：

```typescript
import { SkipThrottle } from '@nestjs/throttler';

@Controller('static')
export class StaticController {
  @SkipThrottle()
  @Get('assets')
  getAssets() {
    return 'Static assets';
  }
}
```

#### 使用 Redis 存储限制状态
在分布式环境中，使用 Redis 确保跨实例同步：

```bash
npm install @nestjs/throttler @nest-lab/throttler-storage-redis ioredis
```

配置 Redis：

```typescript
import { ThrottlerModule } from '@nestjs/throttler';
import { ThrottlerStorageRedisService } from '@nest-lab/throttler-storage-redis';
import Redis from 'ioredis';

@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60, // 单位为秒
      limit: 10,
      storage: new ThrottlerStorageRedisService({
        client: new Redis({ host: 'localhost', port: 6379 }),
      }),
    }),
  ],
})
export class AppModule {}
```

### 处理代理服务器环境
在生产环境中，应用常部署在 Nginx 等代理服务器后。需要正确获取客户端真实 IP：

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('api');
  app.use((req, res, next) => {
    req['realIp'] = req.get('X-Forwarded-For') || req.ip;
    next();
  });
  await app.listen(3000);
}
bootstrap();
```

### 最佳实践
+ **区分环境**：开发环境使用宽松限制，生产环境收紧策略。
+ **监控超限请求**：记录超出限制的请求，分析潜在攻击。
+ **多层防护**：结合身份验证、防火墙等，形成全面防御。

## 四、综合最佳实践：打造健壮的安全策略
### 环境区分配置
不同环境需要不同策略。以下是一个示例配置文件：

```typescript
// config/security.config.ts
export const getSecurityConfig = () => {
  const isProduction = process.env.NODE_ENV === 'production';

  return {
    cors: {
      origin: isProduction ? process.env.ALLOWED_ORIGINS?.split(',') : true,
      credentials: true,
    },
    throttle: {
      ttl: isProduction ? 60 : 10, // 单位为秒，@nestjs/throttler 的 ttl 为秒
      limit: isProduction ? 10 : 100,
    },
  };
};
```

在 `main.ts` 中使用：

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { getSecurityConfig } from './config/security.config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = getSecurityConfig();
  app.enableCors(config.cors);
  await app.listen(3000);
}
bootstrap();
```

### 监控和日志
记录安全事件对排查问题至关重要：

```typescript
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class SecurityLogger {
  private readonly logger = new Logger(SecurityLogger.name);

  logThrottleExceeded(ip: string, endpoint: string) {
    this.logger.warn(`Rate limit exceeded for IP ${ip} on ${endpoint}`);
  }

  logCsrfAttempt(ip: string) {
    this.logger.error(`Potential CSRF attack from IP ${ip}`);
  }
}
```

### 渐进式安全策略
+ **开发环境**：测试所有安全配置，确保功能正常。
+ **测试环境**：进行压力测试，验证高负载下的表现。
+ **生产环境**：先用宽松限制，观察后逐步收紧。
+ **定期审查**：根据日志和监控数据调整策略。

## 五、总结
CORS、CSRF 防护和速率限制是构建安全 Web 应用的基础。CORS 让前后端分离更顺畅，CSRF 防护阻挡恶意请求，速率限制保护 API 免受滥用。在 NestJS 中，这些功能通过简单配置和第三方库即可实现。

通过区分环境、记录日志和渐进式收紧策略，你可以打造一个既安全又高效的 Web 应用。
