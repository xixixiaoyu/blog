## 使用 Helmet 配置 HTTP 安全头

通过合理的 HTTP 安全头可以显著降低 XSS、点击劫持、MIME 嗅探、信息泄露等风险。Helmet 是 Express/Fastify 生态中最常用的安全头中间件，适合在 NestJS 中全局集成并按环境细化配置。

### 一、快速集成

#### 1）Express 平台
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
  const isProd = process.env.NODE_ENV === 'production';

  app.use(
    helmet({
      // 在生产环境开启 HSTS；开发环境通常关闭（避免非 HTTPS 下报错）
      hsts: isProd
        ? { maxAge: 31536000, includeSubDomains: true, preload: false }
        : false,

      // 点击劫持防护：限制页面被置于 <iframe>
      frameguard: { action: 'sameorigin' }, // 或 'deny'

      // 引荐来源策略：兼顾隐私与可用性
      referrerPolicy: { policy: 'strict-origin-when-cross-origin' },

      // 内容安全策略（CSP）：强力的 XSS 防护（下文提供动态 nonce 配置）
      // 这里先关闭，避免未配置指令时干扰开发；可在生产或需要时开启
      contentSecurityPolicy: false,

      // 跨源隔离相关策略（COOP/COEP/CORP）
      crossOriginOpenerPolicy: { policy: 'same-origin' },
      crossOriginResourcePolicy: { policy: 'same-origin' },
      crossOriginEmbedderPolicy: isProd, // 需要所有跨源资源满足 CORP/CORS

      // 禁用 DNS 预解析以避免隐私泄露（如需性能可按需开启）
      dnsPrefetchControl: { allow: false },

      // 其他常见安全头
      hidePoweredBy: true, // 去除 X-Powered-By
      noSniff: true,       // X-Content-Type-Options: nosniff
      ieNoOpen: true,      // X-Download-Options: noopen（IE）
      originAgentCluster: true, // 隔离代理上下文（现代浏览器）
    })
  );

  await app.listen(3000);
}
bootstrap();
```

#### 2）Fastify 平台
```bash
npm i @fastify/helmet
```

```typescript
// main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { FastifyAdapter } from '@nestjs/platform-fastify';
import helmet from '@fastify/helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, new FastifyAdapter());
  const isProd = process.env.NODE_ENV === 'production';

  await app.register(helmet, {
    hsts: isProd ? { maxAge: 31536000, includeSubDomains: true } : false,
    frameguard: { action: 'sameorigin' },
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
    contentSecurityPolicy: false,
    crossOriginOpenerPolicy: { policy: 'same-origin' },
    crossOriginResourcePolicy: { policy: 'same-origin' },
    crossOriginEmbedderPolicy: isProd,
    dnsPrefetchControl: { allow: false },
    hidePoweredBy: true,
    noSniff: true,
    ieNoOpen: true,
    originAgentCluster: true,
  });

  await app.listen(3000);
}
bootstrap();
```

> 说明：具体默认值可能随 Helmet 版本演进而变化。若遇到行为与预期不一致，请以对应版本的官方文档为准并显式配置。

### 二、常见安全头与推荐策略

- Strict-Transport-Security (HSTS)：强制浏览器使用 HTTPS 访问站点。仅在生产环境及 HTTPS 下启用；示例：`maxAge=31536000; includeSubDomains`。
- X-Frame-Options (frameguard)：防止点击劫持，推荐 `SAMEORIGIN` 或 `DENY`，按实际嵌入需求选择。
- X-Content-Type-Options：设置 `nosniff`，阻止 MIME 嗅探，避免把非脚本资源当作脚本执行。
- Referrer-Policy：推荐 `strict-origin-when-cross-origin`，在跨站时仅发送来源，不泄露完整 URL。
- Content-Security-Policy (CSP)：强力的 XSS 防护与资源加载白名单机制。建议结合 nonce/hash 管理内联脚本和样式，阻止不受信任的脚本执行。
- Cross-Origin-Opener-Policy (COOP)：隔离同源上下文，推荐 `same-origin`，减少跨站数据泄漏风险。
- Cross-Origin-Embedder-Policy (COEP)：要求嵌入资源满足 CORP/CORS，通常设为 `require-corp`；启用后需确保第三方资源响应携带相应头，否则可能被阻止。
- Cross-Origin-Resource-Policy (CORP)：限制跨源资源可被其他源读取，推荐 `same-origin`（或按业务选 `same-site`/`cross-origin`）。
- X-DNS-Prefetch-Control：是否允许 DNS 预解析；注重隐私时可关闭，性能优先时可开启。
- Origin-Agent-Cluster：启用代理上下文隔离，提升跨站隔离与稳定性。

### 三、为 CSP 添加动态 nonce（每请求唯一）

在生产中建议使用 nonce（或 hash）来允许特定内联脚本执行，其他脚本一律禁止。下面示例展示如何为每个请求生成 nonce 并设置 CSP：

```typescript
// main.ts（Express）
import crypto from 'crypto';
import helmet from 'helmet';

// 生成并注入 nonce
app.use((req, res, next) => {
  res.locals.cspNonce = crypto.randomBytes(16).toString('base64');
  next();
});

// 使用每请求独立的 CSP（通过单独调用 helmet.contentSecurityPolicy）
app.use((req, res, next) => {
  helmet.contentSecurityPolicy({
    useDefaults: true,
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", `'nonce-${res.locals.cspNonce}'`],
      styleSrc: ["'self'", "https:", "'unsafe-inline'"], // 尽量改为 nonce/hash，减少 'unsafe-inline'
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", process.env.API_ORIGIN].filter(Boolean),
      fontSrc: ["'self'", "https:"],
      frameAncestors: ["'self'"],
      // 可选：自动升级混合内容（所有 http 资源尝试升级到 https）
      upgradeInsecureRequests: true,
    },
  })(req, res, next);
});

// 在模板/SSR 中为内联脚本添加 nonce 属性，例如：
// <script nonce="{{ cspNonce }}">/* inline JS */</script>
```

> 注意：启用 COEP 后，所有跨源资源（字体、图片、脚本等）都需要满足 CORP 或通过 CORS 允许，否则将被阻止。启用前请全面评估第三方资源响应头是否满足要求。

### 四、按路由细化或覆盖 Helmet 行为

对于需要嵌入的页面（例如开放的嵌入组件），可以对特定路径关闭或调整某些安全头：

```typescript
// 仅对 /public/embed 路径关闭 frameguard（允许被 iframe 引用）
app.use('/public/embed', helmet({ frameguard: false }));

// 或者在控制器中按需设置/覆盖响应头
import { Controller, Get, Header } from '@nestjs/common';

@Controller('public')
export class PublicController {
  @Get('embed')
  @Header('X-Frame-Options', 'ALLOW-FROM https://partner.example') // 注意：ALLOW-FROM 在部分浏览器不再支持，建议用 CSP 的 frame-ancestors
  getEmbed() {
    return { ok: true };
  }
}
```

### 五、环境区分与常见坑

- 开发环境：可以暂时关闭 CSP 或放宽 `script-src`，确保调试体验；上线前务必收紧策略。
- 生产环境：开启 HSTS、严格的 CSP 与跨源策略；提前扫描第三方资源响应头是否兼容（COEP/CORP）。
- HTTPS 要求：HSTS 仅在全站 HTTPS 时启用，否则可能导致浏览器强制升级并出现访问问题。
- 与 CORS 的配合：CSP 与跨源策略不等同于 CORS；跨域访问仍需在服务端正确设置 CORS（参见 CORS 文档）。

### 六、验证与排查

- 使用 curl 验证：
```bash
curl -s -D - -o /dev/null http://localhost:3000/
```
- 浏览器开发者工具的“网络”面板查看响应头。
- 若 CSP 阻止资源加载，控制台会提示被拦截的指令与资源来源，根据提示调整 `directives`。

### 相关阅读

- CORS：后端/nest/安全/CORS 跨域.md
- CSRF 防护：后端/nest/安全/CSRF 防护.md
- 请求限流：后端/nest/安全/请求限流 Throttler.md

### 总结

Helmet 能快速为 NestJS 应用提供全面的安全头防护。建议在生产环境启用 HSTS、严格 CSP、COOP/COEP/CORP，并结合按路由细化与动态 nonce 策略，在确保安全的同时兼顾实际业务与第三方资源的兼容性。
