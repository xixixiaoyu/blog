在构建现代 Web 应用时，我们经常遇到这样的需求：记住用户的登录状态、保存购物车内容、或者追踪用户的个性化设置。

由于 HTTP 协议天生无状态的特性，每次请求都是独立的，服务器无法直接识别"这是同一个用户的请求"。

这时候，Cookie 和 Session 就成了我们的得力助手。

## Cookie：浏览器里的小纸条
想象一下，Cookie 就像是网站在你浏览器里贴的一张便签纸。

当你首次访问某个网站时，服务器可以在响应中附带一些数据，要求浏览器保存下来。

之后每次访问这个网站，浏览器都会自动把这张"便签纸"带上，服务器看到后就能认出你了。

### 在 Nest 中配置 Cookie 支持
NestJS 默认基于 Express 框架，要处理 Cookie，我们需要安装 `cookie-parser` 中间件：

```bash
npm install cookie-parser
npm install -D @types/cookie-parser
```

接下来在 `main.ts` 中注册这个中间件：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749439631248-a56dc6ab-c595-4249-9963-0e7557812083.png)

### 读取和设置 Cookie
配置完成后，我们就可以在控制器中轻松操作 Cookie 了：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749439656298-a1c6cde6-1278-4e67-8010-f38b415dd6f2.png)

注意，当设置 Cookie 时，可以传递一个选项对象来指定 Cookie 的属性。

### **测试 Cookie 读写**
![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749439673437-dc43b957-f051-494b-908f-5027af58221c.png)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749439676625-c68f9674-544f-4b02-abc6-f90bf189eb1a.png)

### 创建便捷的装饰器
每次都写 `@Req() request: Request` 然后访问 `request.cookies` 有些繁琐。我们可以创建一个自定义装饰器来简化操作：

```typescript
// src/common/decorators/cookies.decorator.ts
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const Cookies = createParamDecorator(
  (data: string, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return data ? request.cookies?.[data] : request.cookies;
  },
);
```

使用起来就更简洁了：

```typescript
@Controller('dashboard')
export class DashboardController {
  
  @Get()
  getDashboard(
    @Cookies('username') username: string,
    @Cookies('theme') theme: string,
    @Cookies() allCookies: Record<string, any>
  ) {
    return {
      welcome: `欢迎回来，${username}！`,
      currentTheme: theme || 'light',
      allSettings: allCookies
    };
  }
}
```

### Cookie 签名
之前我们的 cookie 都是明文存储的，浏览器控制台可以看见：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749439905791-a2be8504-ce39-49cb-b874-32b76bf29b3b.png)

我们可以提供密钥用于签名 Cookie，增强安全性

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749439921960-5d6993e5-4c9f-475e-8498-25c1d730d13d.png)

设置 cookie 的时候配置 signed 属性：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749440368921-7bd79f92-b0b5-421d-a983-04f3243d2dc1.png)

访问下页面重新设置 cookie：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749440374572-7618ede2-2365-4bb3-8cec-ca11ada00b57.png)

存储后的值已经变成签名后的了：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749440388165-8ff9ef5b-47b1-4b8c-8c8b-69227f068f3c.png)

注意现在代码里面获取 cookie 要这样写：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749440394840-d7b8512f-12f0-42b8-a654-57c38a24a480.png)

访问下页面：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749440403458-f79f40b1-6945-4aad-a362-b551795083d6.png)

成功获取到了我们设置的值。

### Cookie 常用参数选项
使用 `response.cookie(name, value, options)` 设置 Cookie 时，`options` 对象可以控制其行为：

1. `maxAge`: 存活时间 (毫秒)。设置后会自动计算 `Expires`。
    - 示例: `{ maxAge: 1000 * 60 * 60 * 24 }` (24小时)
2. `expires`: 指定具体的过期 `Date` 对象。
    - 示例: `{ expires: new Date('2025-12-31') }`
3. `httpOnly`: `true` 时，禁止客户端脚本 (JS) 访问，增强安全性 (防 XSS)。
    - 示例: `{ httpOnly: true }`
4. `secure`: `true` 时，仅在 HTTPS 连接下发送 Cookie。生产环境推荐。
    - 示例: `{ secure: true }`
5. `domain`: 限制 Cookie 生效的域名。
    - 示例: `{ domain: 'example.com' }`
6. `path`: 限制 Cookie 生效的路径。
    - 示例: `{ path: '/' }` (整个网站)
7. `sameSite`: 控制跨站请求时是否发送 Cookie (防 CSRF)。
    - `'Strict'`: 仅同站发送。
    - `'Lax'` (常用/默认): 部分跨站允许 (如链接跳转)。
    - `'None'`: 跨站发送，但**必须**同时设置 `secure: true`。
    - 示例: `{ sameSite: 'Lax' }`
8. `signed`: `true` 时，对 Cookie 值进行签名，防止篡改 (需要配合密钥)。
    - 示例: `{ signed: true }`

**要点:**

+ **安全设置**: 对于敏感 Cookie (如 Session ID)，建议设置 `httpOnly: true`, `secure: true` (生产环境)，`sameSite: 'Lax'` 或 `'Strict'`，并设置有效期 (`maxAge` / `expires`)。
+ **删除 Cookie**: 设置 `maxAge: 0` 或 `expires` 为一个过去的时间即可。
    - 示例: `res.cookie('token', '', { maxAge: 0 })`



## Session：服务器端的专属储物柜
如果说 Cookie 是贴在浏览器上的便签，那么 Session 更像是服务器为每个用户开设的专属储物柜。

工作流程：

1. 用户第一次访问服务器时，服务器创建一个 Session 对象，并生成一个唯一的 Session ID
2. 将 Session ID（通过 Set-Cookie 响应头）发送回用户的浏览器进行存储
3. 用户再次访问时，浏览器自动在请求头中携带这个 Session ID Cookie
4. 服务器根据 Session ID 找到对应的 Session 数据，获取用户状态信息

Session 的优势显而易见：

+ **更安全**：敏感信息不会暴露在客户端
+ **容量更大**：不受 Cookie 大小限制
+ **更灵活**：可以存储复杂的数据结构

### 配置 Session 支持
首先安装必要的依赖：

```bash
npm install express-session
npm install -D @types/express-session
npm install connect-redis // 如果使用 Redis 存储 session
```

然后在 `main.ts` 中配置：

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as session from 'express-session';
import * as cookieParser from 'cookie-parser';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // session 中间件需要先解析出 Cookie（特别是 Session ID Cookie）才能工作
  app.use(cookieParser());
  
  app.use(
    session({
      secret: 'your-very-secure-secret-key', // 务必使用强密钥
      resave: false, // 不强制保存未修改的 session，避免了即使 session 没有变化，每次请求也强制将其写回存储，减少不必要的存储开销，尤其是在使用外部存储（如 Redis）时。
      saveUninitialized: false, // 不保存空的 session，避免为没有任何信息的匿名用户创建和存储 session，节省存储空间，也有助于满足某些隐私法规（如 GDPR）的要求，只在 session 被修改时（例如用户登录或添加购物车）才创建。
      cookie: {
        httpOnly: true, // 防止 XSS 攻击
        secure: process.env.NODE_ENV === 'production', // 生产环境仅 HTTPS
        maxAge: 1000 * 60 * 60 * 24 * 7, // 7 天有效期
      },
      // 生产环境必须配置持久化存储！
      // store: new RedisStore({ client: redisClient }),
    }),
  );
  
  await app.listen(3000);
}
bootstrap();
```

**重要提醒**：默认的内存存储只适合开发环境。生产环境中必须使用 Redis、MongoDB 等持久化存储方案，否则会有内存泄漏风险，且无法在多实例间共享 Session。

### 使用 Session 进行用户认证
配置完成后，中间件会自动在 Express 的 `Request` 对象上添加 `session` 属性。你可以直接读写它，我们可以轻松实现用户认证功能：

```typescript
import { Controller, Get, Post, Body, Session } from '@nestjs/common';

@Controller('auth')
export class AuthController {
  
  @Post('login')
  async login(
    @Body() loginDto: { username: string; password: string },
    @Session() session: Record<string, any>
  ) {
    // 这里应该有真实的用户验证逻辑
    if (loginDto.username === 'admin' && loginDto.password === 'password') {
      // 登录成功，在 session 中记录用户信息
      session.userId = 1;
      session.username = loginDto.username;
      session.loginTime = new Date();
      
      return {
        success: true,
        message: '登录成功',
        user: {
          id: session.userId,
          username: session.username
        }
      };
    }
    
    return {
      success: false,
      message: '用户名或密码错误'
    };
  }
  
  @Get('profile')
  getProfile(@Session() session: Record<string, any>) {
    if (!session.userId) {
      return {
        success: false,
        message: '请先登录'
      };
    }
    
    return {
      success: true,
      user: {
        id: session.userId,
        username: session.username,
        loginTime: session.loginTime
      }
    };
  }
  
  @Post('logout')
  logout(@Session() session: Record<string, any>) {
    return new Promise((resolve) => {
      session.destroy((err: any) => {
        if (err) {
          console.error('销毁 session 失败:', err);
          resolve({
            success: false,
            message: '退出登录失败'
          });
        } else {
          resolve({
            success: true,
            message: '已安全退出'
          });
        }
      });
    });
  }
}
```

### 实现访问计数器
Session 还可以用来实现一些有趣的功能，比如访问计数器：

```typescript
@Controller('stats')
export class StatsController {
  
  @Get('visits')
  trackVisits(@Session() session: Record<string, any>) {
    // 初始化或递增访问次数
    session.visits = (session.visits || 0) + 1;
    
    // 记录首次访问时间
    if (!session.firstVisit) {
      session.firstVisit = new Date();
    }
    
    session.lastVisit = new Date();
    
    return {
      visits: session.visits,
      firstVisit: session.firstVisit,
      lastVisit: session.lastVisit,
      message: `欢迎！这是您第 ${session.visits} 次访问`
    };
  }
}
```



## `cookie-session` vs `express-session`
+ `express-session`: 将 Session 数据存储在**服务器端**（内存、Redis、DB 等），只将 Session ID 存在 Cookie 中（这是文中详细介绍的方式）。
+ `cookie-session`: 将**整个 Session 数据加密后**存储在 Cookie 中，服务器端不存储（或只存少量）。适用于 Session 数据量不大且不想依赖服务端存储的场景，注意Cookie 大小有限制（通常 4KB），不适合存储大量数据；如果密钥泄露，所有用户的 Session 数据都可能被解密。



## 安全最佳实践
在实际项目中使用 Cookie 和 Session 时，安全性至关重要：

### Cookie 安全配置
```typescript
// 设置安全的 Cookie
response.cookie('sensitive-data', value, {
  httpOnly: true,    // 防止 XSS 攻击
  secure: true,      // 仅在 HTTPS 下传输
  sameSite: 'strict', // 防止 CSRF 攻击
  maxAge: 1000 * 60 * 60, // 设置合理的过期时间
});
```

### Session 安全配置
```typescript
// // 生产环境推荐配置 Redis Store
// const redisClient = createClient({ url: process.env.REDIS_URL }); // 根据实际情况配置
// redisClient.connect().catch(console.error);
// const redisStore = new RedisStore({
//   client: redisClient,
//   prefix: 'myapp-session:', // 可选前缀
// });

app.use(
  session({
    secret: process.env.SESSION_SECRET, // 从环境变量读取
    name: 'sessionId', // 自定义 session cookie 名称
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: process.env.NODE_ENV === 'production',
      httpOnly: true,
      maxAge: 1000 * 60 * 60 * 2, // 2 小时过期
      sameSite: 'strict',
    },
    // 生产环境使用 Redis
    store: process.env.NODE_ENV === 'production' 
      ? new RedisStore({ client: redisClient })
      : undefined,
  }),
);
```



## 实际应用场景
### 购物车功能
```typescript
@Controller('cart')
export class CartController {
  
  @Post('add')
  addToCart(
    @Body() item: { id: number; name: string; price: number },
    @Session() session: Record<string, any>
  ) {
    if (!session.cart) {
      session.cart = [];
    }
    
    const existingItem = session.cart.find((cartItem: any) => cartItem.id === item.id);
    
    if (existingItem) {
      existingItem.quantity += 1;
    } else {
      session.cart.push({ ...item, quantity: 1 });
    }
    
    return {
      success: true,
      cart: session.cart,
      total: session.cart.reduce((sum: number, item: any) => sum + item.price * item.quantity, 0)
    };
  }
  
  @Get()
  getCart(@Session() session: Record<string, any>) {
    const cart = session.cart || [];
    const total = cart.reduce((sum: number, item: any) => sum + item.price * item.quantity, 0);
    
    return {
      items: cart,
      total,
      count: cart.length
    };
  }
}
```

### 用户偏好设置
```typescript
@Controller('preferences')
export class PreferencesController {
  
  @Post('theme')
  setTheme(
    @Body('theme') theme: string,
    @Res({ passthrough: true }) response: Response
  ) {
    response.cookie('user-theme', theme, {
      maxAge: 1000 * 60 * 60 * 24 * 365, // 1 年
      httpOnly: false, // 允许客户端读取以应用主题
    });
    
    return { success: true, theme };
  }
  
  @Get('theme')
  getTheme(@Cookies('user-theme') theme: string) {
    return { theme: theme || 'light' };
  }
}
```

