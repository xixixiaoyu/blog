## CORS：打破同源限制，安全跨域通信

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
- 生产环境限制域名：开发时可以用 `origin: true`，但生产环境中应明确指定可信域名列表，避免安全风险。
- 支持 credentials：如果请求需要携带 cookie 或认证信息，记得设置 `credentials: true`。
- 记录非法请求：通过日志监控非法的跨域请求，及时发现潜在问题。
