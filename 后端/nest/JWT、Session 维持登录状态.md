每次在网站上登录后，哪怕刷新页面或重启浏览器，网站依然能“认出”你，这背后到底藏着什么秘密？HTTP 协议本身是“无状态”的，意味着它不会记住你之前的操作。那网站是如何做到“有记忆”的呢？答案就在两种主流的身份认证方案上：**Session + Cookie** 和 **JWT (JSON Web Token)**。

---

## Session + Cookie：服务器的“记事本”
### 工作原理
Session + Cookie 就像你在游乐园拿到的手环和工作人员的记事本。你登录网站时，服务器会为你生成一个独一无二的 **Session ID**，并把你的信息（比如用户 ID、权限等）记录在服务器的“记事本”（Session）里。这个 Session ID 会通过一个叫 **Cookie** 的小文件发到你的浏览器。之后，每次你访问网站，浏览器都会自动带着这个 Cookie，服务器根据里面的 Session ID 找到你的记录，确认“哦，是你”。

具体流程是：

1. 你输入用户名和密码，服务器验证通过后，创建一个 Session，生成一个 Session ID。
2. 服务器把 Session ID 塞进 Cookie，发送给浏览器。
3. 浏览器每次请求都会自动携带这个 Cookie。
4. 服务器根据 Cookie 里的 Session ID，找到对应的 Session 数据，确认你的身份。

### 优缺点
**优点**：

+ 状态由服务器控制，随时可以让 Session 失效（比如强制用户下线）。
+ 成熟稳定，适合大多数传统 Web 应用。

**缺点**：

+ **CSRF 风险**：因为 Cookie 会被浏览器自动携带，如果用户访问了恶意网站，可能会被诱导发起伪造请求。
+ **分布式难题**：在多服务器环境下，Session 需要同步或集中存储（比如用 Redis），否则可能出现“认不出人”的问题。
+ **跨域限制**：Cookie 受同源策略限制，跨域请求需要额外配置。

### 应对方案
+ **防 CSRF**：在请求中加入一个随机 Token（不存 Cookie），服务器验证这个 Token 是否有效，防止伪造请求。
+ **分布式 Session**：用 Redis 集中存储 Session，所有服务器都能访问同一份数据。
+ **跨域处理**：设置 Cookie 的 domain 为顶级域名（如 `.xxx.com`），或在 AJAX 请求中配置 `withCredentials: true`，后端响应头加 `Access-Control-Allow-Credentials: true`。

---

## JWT：客户端的“数字身份证”
### 工作原理
JWT（JSON Web Token）就像一张你随身携带的“身份证”，包含了你的信息，服务器只负责验证它的真伪，不需要保存任何状态。JWT 是一串由三部分组成的字符串：**Header**、**Payload** 和 **Signature**，用点号（`.`）分隔。

+ **Header**：记录 Token 类型和加密算法，比如 `{"alg": "HS256", "typ": "JWT"}`。
+ **Payload**：包含用户信息（如用户 ID、过期时间等），通过 Base64 编码，**注意不是加密**，所以别放敏感信息。
+ **Signature**：用服务器的密钥对 Header 和 Payload 加密生成，防止 Token 被篡改。

登录时，服务器生成 JWT 并返回给你。你每次请求时，在请求头里带上 `Authorization: Bearer <token>`。服务器验证签名，确认 Token 没被改过，就能从 Payload 里读出用户信息。

### 优缺点
**优点**：

+ **无状态**：服务器不存任何信息，天然适合分布式系统。
+ **跨域友好**：没有 Cookie 的同源限制，只要请求头带上 Token 就能用。
+ **无 CSRF 风险**：Token 不会被浏览器自动携带，安全性更高。

**缺点**：

+ **明文风险**：Payload 是 Base64 编码，内容可读，必须配合 HTTPS 加密传输。
+ **性能开销**：Token 体积较大（包含用户信息），每次请求都会增加传输负担。
+ **无法主动失效**：Token 签发后在有效期内一直有效，无法中途作废。

### 应对方案
+ **安全性**：始终用 HTTPS，确保传输过程加密。
+ **性能优化**：Payload 只存必要信息，减少 Token 体积。
+ **主动失效**：维护一个 Redis 黑名单，记录需要作废的 Token，验证时检查黑名单。

---

## 使用 Session + Cookie 实现会话管理
### 创建 Nest.js 项目
首先，使用 @nest/cli 创建一个新的 Nest.js 项目：

```bash
nest new jwt-and-session -p pnpm
```

### 安装依赖
安装 express-session 及其类型定义：

```bash
pnpm install express-session @types/express-session
```

### 配置 Session
在项目的入口文件中启用 express-session：

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as session from 'express-session';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.use(
    session({
      secret: 'yun', // 加密的密钥
      resave: false, // 仅在 session 内容变化时更新 session
      saveUninitialized: false, // 不自动初始化 Session
    }),
  );

  await app.listen(3000);
}

bootstrap();
```



### 使用 Session
在控制器中使用 @Session 装饰器来访问 session 对象：

```typescript
import { Controller, Get, Session } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('session')
  sss(@Session() session) {
    // 如果会话对象中存在 count 属性，则将其值加 1，否则将其初始化为 1
    session.count = session.count ? session.count + 1 : 1;
    return session.count;
  }
}
```

每次访问 /session 路由时，session.count 的值会递增。



### 运行项目并测试
```bash
pnpm start:dev
```

第一次访问：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716725665858-dcd3410b-fd57-4211-9d30-5db175fc7437.png)

继续访问：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716725697050-2a0a8550-b07e-4f20-aa1a-01511d322cb8.png)



返回了一个 cookie connect.sid，这是对应的 session ID。

cookie 会在请求时自动携带，实现了状态管理：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716726536216-cf32f683-2640-4589-a3a2-e13cdeee287e.png)





## 使用 JWT 实现会话管理
### 安装依赖
安装 @nestjs/jwt：

```bash
pnpm install @nestjs/jwt
```



### 配置 JwtModule
在 AppModule 中引入 JwtModule 并进行配置：

```typescript
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [
    JwtModule.register({
      secret: 'yun', // 加密的密钥
      signOptions: {
        expiresIn: '7d', // 令牌过期时间
      },
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
```



### 生成和验证 JWT
在控制器中注入 JwtService 并添加处理方法：

```typescript
import {
  Controller,
  Get,
  Res,
  Headers,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Response } from 'express';

@Controller()
export class AppController {
  constructor(private readonly jwtService: JwtService) {}

  @Get('jwt')
  handleJwtRequest(
    @Headers('authorization') authorization: string,
    @Res({ passthrough: true }) response: Response,
  ): number {
    try {
      const count = this.getCountFromToken(authorization);

      const newToken = this.jwtService.sign({ count: count + 1 });

      response.setHeader('token', newToken);

      return count + 1;
    } catch (e) {
      console.error(e);
      throw new UnauthorizedException();
    }
  }

  // 从授权头中提取并验证 JWT，返回计数值
  private getCountFromToken(authorization: string): number {
    if (authorization) {
      const token = authorization.split(' ')[1];
      const data = this.jwtService.verify(token);
      return data.count;
    } else {
      return 0;
    }
  }
}
```

访问接口获取 token：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716727030316-b4e71ecf-ef06-41f4-b6ff-32e9d089c9a9.png)

将 token 放到请求头中请求，这次访问又会产生新 token：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716727103292-e5137b04-55ab-4cde-b631-e88a2f5a5609.png)

将新 token 继续放到请求头中访问：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716727203183-7e0cc3c1-dbaf-40a4-aa01-6de7577e0b34.png)

得到结果 2，它也是累加的。





## 如何选择：Session 还是 JWT？
| 特性 | Session + Cookie | JWT |
| --- | --- | --- |
| **状态存储** | 服务器端（Session） | 客户端（Token） |
| **优点** | 状态可控，可随时失效 | 无状态、跨域友好、分布式友好 |
| **缺点** | CSRF 风险、分布式复杂 | 明文风险、无法主动失效 |
| **适用场景** | 传统单体应用，需要频繁修改状态 | 微服务、移动端、前后端分离 |


**选择建议**：

+ 如果是传统 Web 应用，用户量不大，推荐 **Session + Redis**，简单可靠，状态可控。
+ 如果是微服务架构、前后端分离或移动端应用，推荐 **JWT + HTTPS + Redis 黑名单**，灵活且跨域友好。

