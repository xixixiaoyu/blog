在构建任何现代 Web 应用时，确保“正确的用户”在“正确的权限”下执行操作，是安全体系的基石。这背后涉及两个核心概念：**认证（Authentication）** 和 **授权（Authorization）**。

- **认证**：确认“你是谁”。这通常是通过验证用户名、密码、令牌（Token）或其他凭证来完成的。
- **授权**：决定“你能做什么”。一旦用户身份被确认，系统需要根据其角色或权限，判断其是否有权访问特定资源或执行某个操作。

本文将作为一份终极指南，带你深入探索在 NestJS 中实现认证与授权的各种技术方案。我们将从传统的 **Session + Cookie** 机制讲起，过渡到现代无状态应用首选的 **JWT (JSON Web Token)**，然后引入强大的 **Passport.js** 框架统一管理多种认证策略（包括本地登录和第三方 OAuth），最后通过 **RBAC（基于角色的访问控制）** 模型实现精细化的权限管理。

---

## Part 1：两种主流认证方案对比

在开始实战之前，我们先理解两种主流的会话管理机制：Session + Cookie 和 JWT。

### 方案一：Session + Cookie（服务器的“记事本”）

这是一种传统的、有状态的认证方式。

**工作原理**：

1.  **登录**：用户提交用户名和密码。服务器验证通过后，创建一个 Session 对象（存储用户信息），并为其生成一个独一无二的 Session ID。
2.  **下发凭证**：服务器通过 `Set-Cookie` 响应头，将这个 Session ID 发送给浏览器。
3.  **后续请求**：浏览器在后续访问同域名的网站时，会自动在请求头的 `Cookie` 字段中携带这个 Session ID。
4.  **身份识别**：服务器根据接收到的 Session ID，在自己的“记事本”（内存、Redis 或数据库）中查找对应的 Session 数据，从而识别用户身份。

**优缺点**：

-   **优点**：
    -   敏感数据存储在服务端，相对安全。
    -   服务器可以主动让 Session 失效，方便管理（如强制用户下线）。
-   **缺点**：
    -   **分布式难题**：在多服务器集群中，需要引入 Redis 等集中式存储来同步 Session 数据，增加了架构复杂性。
    -   **CSRF 风险**：Cookie 会被浏览器自动携带，容易受到跨站请求伪造（CSRF）攻击。
    -   **跨域限制**：受浏览器同源策略影响，跨域场景处理相对繁琐。

### 方案二：JWT（客户端的“数字身份证”）

JWT (JSON Web Token) 是一种无状态的认证方案，服务器不再需要存储任何会话信息。

**工作原理**：

JWT 本质上是一串紧凑且自包含的字符串，由三部分组成，用点号（`.`）分隔：

1.  **Header (头部)**：包含令牌类型（`JWT`）和所使用的签名算法（如 `HS256`）。
2.  **Payload (载荷)**：包含需要传递的数据（称为 Claims），如用户 ID、角色、过期时间等。**注意：Payload 仅经过 Base64 编码，并非加密，因此切勿存放敏感信息！**
3.  **Signature (签名)**：使用服务器持有的密钥，对 `Header` 和 `Payload` 进行签名。这个签名的作用是验证信息在传输过程中未被篡改。

**流程**：

1.  **登录**：用户登录成功后，服务器生成一个 JWT 并返回给客户端。
2.  **客户端存储**：客户端（如浏览器）将 JWT 存储在本地（通常是 `localStorage` 或 `sessionStorage`）。
3.  **后续请求**：客户端在每次请求需要认证的接口时，通过 `Authorization` 请求头将 JWT 发送给服务器（通常格式为 `Bearer <token>`）。
4.  **服务器验证**：服务器收到 JWT 后，使用密钥验证其签名。如果签名有效，则信任其中的用户信息，完成认证。

**优缺点**：

-   **优点**：
    -   **无状态**：服务器无需存储会话，天然适合分布式和微服务架构。
    -   **跨域友好**：没有 Cookie 的跨域限制，适用于前后端分离和移动端应用。
    -   **无 CSRF 风险**：由于令牌不会被浏览器自动携带，从根本上避免了 CSRF 攻击。
-   **缺点**：
    -   **无法主动失效**：一旦签发，在过期前始终有效。若需强制下线，需要引入黑名单机制（如 Redis）。
    -   **体积较大**：Payload 中包含用户信息，可能比 Session ID 更大，增加网络开销。
    -   **明文风险**：Payload 内容是可读的，必须配合 HTTPS 确保传输安全。

### 如何选择？

| 特性 | Session + Cookie | JWT |
| --- | --- | --- |
| **状态存储** | 服务器端（Session） | 客户端（Token） |
| **优点** | 状态可控，可随时失效 | 无状态、跨域友好、分布式友好 |
| **缺点** | CSRF 风险、分布式复杂 | 明文风险、无法主动失效 |
| **适用场景** | 传统单体应用，需要频繁修改状态 | 微服务、移动端、前后端分离 |

**选择建议**：

-   对于传统的、用户量不大的单体 Web 应用，**Session + Redis** 方案简单可靠。
-   对于现代的前后端分离项目、微服务架构或移动端 App，强烈推荐 **JWT + HTTPS + Redis 黑名单** 方案。

---

## Part 2：实战 Session 与 Cookie 管理

尽管 JWT 更为现代，但理解并掌握 Session 和 Cookie 的用法仍然非常重要。

### 2.1 Cookie：浏览器里的小纸条

Cookie 就像是网站贴在你浏览器上的便签。服务器通过 `response` 设置它，浏览器在后续请求中自动带上它。

#### 在 NestJS 中配置 Cookie

NestJS 默认不解析 Cookie，我们需要 `cookie-parser` 中间件。

1.  **安装依赖**：
    ```bash
    npm install cookie-parser
    npm install -D @types/cookie-parser
    ```

2.  **注册中间件**：
    在 `main.ts` 中，使用 `app.use()` 注册。如果需要签名以防篡改，可以提供一个密钥。

    ```typescript
    // main.ts
    import * as cookieParser from 'cookie-parser';
    import { NestFactory } from '@nestjs/core';
    import { AppModule } from './app.module';
    
    async function bootstrap() {
      const app = await NestFactory.create(AppModule);
      // 使用密钥 'your-secret' 对 Cookie 进行签名
      app.use(cookieParser('your-secret'));
      await app.listen(3000);
    }
    bootstrap();
    ```

#### 读写 Cookie

-   **设置 Cookie**：通过 `@Res()` 注入响应对象，并调用 `res.cookie()`。
-   **读取 Cookie**：通过 `@Req()` 注入请求对象，从未签名的 `req.cookies` 或已签名的 `req.signedCookies` 中读取。

```typescript
import { Controller, Get, Req, Res } from '@nestjs/common';
import { Request, Response } from 'express';

@Controller('cookie-demo')
export class CookieDemoController {
  @Get('set')
  setCookie(@Res({ passthrough: true }) res: Response) {
    // 设置普通 Cookie
    res.cookie('username', 'yunmu', { maxAge: 1000 * 60 * 60 });
    // 设置签名 Cookie
    res.cookie('theme', 'dark', { signed: true });
    return 'Cookie has been set';
  }

  @Get('get')
  getCookie(@Req() req: Request) {
    return {
      username: req.cookies.username, // 读取普通 Cookie
      theme: req.signedCookies.theme, // 读取签名 Cookie
    };
  }
}
```

#### 创建便捷的 `@Cookies` 装饰器

为了避免重复编写 `@Req() req: Request`，我们可以创建一个自定义参数装饰器。

```typescript
// src/common/decorators/cookies.decorator.ts
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export const Cookies = createParamDecorator(
  (data: string, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    // 根据是否提供 data 参数，返回特定 cookie 或所有 cookies
    return data ? request.cookies?.[data] : request.cookies;
  },
);

// 同样可以为 signedCookies 创建一个装饰器
export const SignedCookies = createParamDecorator(
  (data: string, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return data ? request.signedCookies?.[data] : request.signedCookies;
  },
);
```

使用起来就非常简洁了：

```typescript
@Get('get-with-decorator')
getWithDecorator(
  @Cookies('username') username: string,
  @SignedCookies('theme') theme: string,
) {
  return { username, theme };
}
```

#### Cookie 常用选项

设置 Cookie 时，`options` 对象非常关键：

-   `maxAge`: 存活时间（毫秒），会自动计算 `Expires`。
-   `expires`: 指定具体的过期 `Date` 对象。
-   `httpOnly`: 设为 `true` 时，禁止客户端脚本（JS）访问，有效防止 XSS 攻击。
-   `secure`: 设为 `true` 时，仅在 HTTPS 连接下发送，生产环境必备。
-   `domain`: 限制 Cookie 生效的域名。
-   `path`: 限制 Cookie 生效的路径（默认为 `'/'`）。
-   `sameSite`: 控制跨站请求时是否发送 Cookie，有效防止 CSRF 攻击。
    -   `'strict'`: 仅同站发送。最安全。
    -   `'lax'`: 允许链接跳转等部分跨站请求携带。
    -   `'none'`: 任何跨站请求都发送，但**必须**同时设置 `secure: true`。
-   `signed`: 设为 `true` 时，对 Cookie 值进行签名。

**安全建议**：对于敏感 Cookie，务必设置 `httpOnly: true`, `secure: true`, `sameSite: 'lax'` 或 `'strict'`，并设置合理的有效期。

### 2.2 Session：服务器端的专属储物柜

Session 将数据存储在服务端，只通过 Cookie 发送一个 Session ID，更安全、容量更大。

#### 配置 Session 支持

1.  **安装依赖**：
    ```bash
    npm install express-session
    npm install -D @types/express-session
    # 如果使用 Redis 持久化，还需安装
    # npm install connect-redis
    ```

2.  **注册中间件**：
    在 `main.ts` 中配置 `express-session`。

    ```typescript
    // main.ts
    import * as session from 'express-session';
    import * as cookieParser from 'cookie-parser';
    import { NestFactory } from '@nestjs/core';
    import { AppModule } from './app.module';
    
    async function bootstrap() {
      const app = await NestFactory.create(AppModule);
    
      // 建议先注册 cookie-parser
      app.use(cookieParser());
    
      app.use(
        session({
          secret: 'your-very-secure-secret-key', // 强密钥
          resave: false, // true 表示即使 session 没有变化，每次请求也强制将其写回存储。这会增加不必要的存储开销，尤其是在使用外部存储（如 Redis）时。
          saveUninitialized: false, // true 表示即使 session 是全新的、未被修改的，也强制将其存储。这会为大量匿名用户创建空 session，浪费存储空间。
          cookie: {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production', // 生产环境应为 true
            maxAge: 1000 * 60 * 60 * 24 * 7, // 7 天有效期
          },
          // 生产环境必须配置持久化存储，否则服务重启后 session 会丢失
          // store: new RedisStore({ client: redisClient }),
        }),
      );
    
      await app.listen(3000);
    }
    bootstrap();
    ```

    **重要提醒**：默认的内存存储仅适用于开发。生产环境中，必须使用 Redis、MongoDB 等持久化方案，否则会导致内存泄漏，且无法在多实例间共享 Session。

#### 使用 Session

配置完成后，NestJS 会自动在 `Request` 对象上附加 `session` 属性。我们可以通过 `@Session()` 装饰器方便地访问它。

**示例：实现访问计数器**

```typescript
import { Controller, Get, Session } from '@nestjs/common';

@Controller('stats')
export class StatsController {
  @Get('visits')
  trackVisits(@Session() session: Record<string, any>) {
    // 初始化或递增访问次数
    session.visits = (session.visits || 0) + 1;
    
    return {
      message: `欢迎！这是您第 ${session.visits} 次访问。`,
      visits: session.visits,
    };
  }
}
```

每次刷新 `/stats/visits` 页面，计数器都会增加，这证明了服务器成功地维持了用户的会话状态。

---

## Part 3：拥抱无状态：JWT 与 Passport.js

现在，我们进入现代应用开发的核心——基于 JWT 的无状态认证，并引入 Passport.js 来优雅地管理认证策略。

### 3.1 为什么选择 Passport.js？

Passport 是 Node.js 中最流行的认证中间件，其核心是**策略（Strategy）模式**。无论是本地用户名密码、JWT 还是第三方 OAuth，Passport 都将其抽象为统一的、可插拔的“策略”，极大简化了认证逻辑的实现和扩展。

### 3.2 实战：从零构建 Passport 认证系统

#### 项目初始化

```bash
# 安装 Passport 及相关策略
npm install --save @nestjs/passport passport passport-local @nestjs/jwt passport-jwt
npm install --save-dev @types/passport-local @types/passport-jwt
```

#### 步骤 1：实现本地认证（Local Strategy）

这是最基础的用户名密码登录。

1.  **创建用户服务 (`UserService`)**
    为了演示，我们使用一个内存数组模拟用户数据。

    ```typescript
    // src/user/user.service.ts
    import { Injectable } from '@nestjs/common';
    import * as bcrypt from 'bcrypt';
    
    @Injectable()
    export class UserService {
      private users;
    
      constructor() {
        // 在构造函数中初始化，以便使用 async/await
        this.initializeUsers();
      }
    
      private async initializeUsers() {
        this.users = [
          {
            userId: 1,
            username: 'admin',
            password: await bcrypt.hash('admin123', 10),
            roles: ['admin'],
          },
          {
            userId: 2,
            username: 'user',
            password: await bcrypt.hash('user123', 10),
            roles: ['user'],
          },
        ];
      }
    
      async findOne(username: string) {
        // 确保 users 已经初始化
        if (!this.users) await this.initializeUsers();
        return this.users.find((user) => user.username === username);
      }
    }
    ```
    **安全核心**：密码必须使用 `bcrypt` 等库进行哈希加盐处理，绝不能明文存储。

2.  **创建认证服务 (`AuthService`)**
    `AuthService` 负责验证用户凭证。

    ```typescript
    // src/auth/auth.service.ts
    import { Injectable, UnauthorizedException } from '@nestjs/common';
    import { UserService } from '../user/user.service';
    import { JwtService } from '@nestjs/jwt';
    import * as bcrypt from 'bcrypt';
    
    @Injectable()
    export class AuthService {
      constructor(
        private userService: UserService,
        private jwtService: JwtService,
      ) {}
    
      async validateUser(username: string, pass: string): Promise<any> {
        const user = await this.userService.findOne(username);
        if (user && (await bcrypt.compare(pass, user.password))) {
          const { password, ...result } = user;
          return result;
        }
        return null;
      }
    
      async login(user: any) {
        const payload = { username: user.username, sub: user.userId, roles: user.roles };
        return {
          access_token: this.jwtService.sign(payload),
        };
      }
    }
    ```

3.  **实现本地策略 (`LocalStrategy`)**
    这是 Passport 的核心，它定义了如何使用用户名和密码进行验证。

    ```typescript
    // src/auth/local.strategy.ts
    import { Strategy } from 'passport-local';
    import { PassportStrategy } from '@nestjs/passport';
    import { Injectable, UnauthorizedException } from '@nestjs/common';
    import { AuthService } from './auth.service';
    
    @Injectable()
    export class LocalStrategy extends PassportStrategy(Strategy) {
      constructor(private authService: AuthService) {
        super();
      }
    
      async validate(username: string, password: string): Promise<any> {
        const user = await this.authService.validateUser(username, password);
        if (!user) {
          throw new UnauthorizedException('用户名或密码错误');
        }
        return user;
      }
    }
    ```

4.  **创建登录接口**
    使用 `@UseGuards(AuthGuard('local'))` 来触发 `LocalStrategy`。

    ```typescript
    // src/auth/auth.controller.ts
    import { Controller, Post, UseGuards, Request } from '@nestjs/common';
    import { AuthGuard } from '@nestjs/passport';
    import { AuthService } from './auth.service';
    
    @Controller('auth')
    export class AuthController {
      constructor(private authService: AuthService) {}
    
      @UseGuards(AuthGuard('local'))
      @Post('login')
      async login(@Request() req) {
        // LocalStrategy 验证成功后，用户信息会挂载到 req.user
        return this.authService.login(req.user);
      }
    }
    ```

#### 步骤 2：实现 JWT 认证

登录成功后，我们返回 JWT。后续的请求将使用此 JWT 进行认证。

1.  **配置 `JwtModule`**
    在 `AuthModule` 中注册 `JwtModule`，并提供密钥和过期时间。

    ```typescript
    // src/auth/auth.module.ts
    import { Module } from '@nestjs/common';
    import { PassportModule } from '@nestjs/passport';
    import { JwtModule } from '@nestjs/jwt';
    import { AuthService } from './auth.service';
    import { AuthController } from './auth.controller';
    import { LocalStrategy } from './local.strategy';
    import { JwtStrategy } from './jwt.strategy';
    import { GoogleStrategy } from './google.strategy';
    import { UserModule } from '../user/user.module';
    
    @Module({
      imports: [
        UserModule,
        PassportModule,
        JwtModule.register({
          secret: process.env.JWT_SECRET || 'your-secret-key', // 强烈建议使用环境变量
          signOptions: { expiresIn: '1h' },
        }),
      ],
      controllers: [AuthController],
      providers: [AuthService, LocalStrategy, JwtStrategy, GoogleStrategy],
      exports: [AuthService],
    })
    export class AuthModule {}
    ```

2.  **实现 JWT 策略 (`JwtStrategy`)**
    此策略负责验证从客户端发来的 JWT。

    ```typescript
    // src/auth/jwt.strategy.ts
    import { ExtractJwt, Strategy } from 'passport-jwt';
    import { PassportStrategy } from '@nestjs/passport';
    import { Injectable } from '@nestjs/common';
    
    @Injectable()
    export class JwtStrategy extends PassportStrategy(Strategy) {
      constructor() {
        super({
          jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
          ignoreExpiration: false,
          secretOrKey: process.env.JWT_SECRET || 'your-secret-key',
        });
      }
    
      async validate(payload: any) {
        // payload 是解码后的 JWT 内容
        return { userId: payload.sub, username: payload.username, roles: payload.roles, permissions: payload.permissions };
      }
    }
    ```

3.  **保护路由**
    使用 `@UseGuards(AuthGuard('jwt'))` 来保护需要认证的接口。

    ```typescript
    // 在 AuthController 中添加一个受保护的接口
    @UseGuards(AuthGuard('jwt'))
    @Get('profile')
    getProfile(@Request() req) {
      return req.user;
    }
    ```

#### 步骤 3：实现第三方登录（OAuth 2.0）

以 Google 登录为例。

1.  **在 Google Cloud Console 配置应用**
    -   创建一个 OAuth 2.0 客户端 ID。
    -   设置授权回调 URL 为 `http://localhost:3000/auth/google/callback`。
    -   获取 `Client ID` 和 `Client Secret`。

2.  **安装 Google 策略**
    ```bash
    npm install --save passport-google-oauth20
    npm install --save-dev @types/passport-google-oauth20
    ```

3.  **实现 Google 策略 (`GoogleStrategy`)**
    ```typescript
    // src/auth/google.strategy.ts
    import { PassportStrategy } from '@nestjs/passport';
    import { Strategy, Profile } from 'passport-google-oauth20';
    import { Injectable } from '@nestjs/common';
    
    @Injectable()
    export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
      constructor() {
        super({
          clientID: process.env.GOOGLE_CLIENT_ID,
          clientSecret: process.env.GOOGLE_CLIENT_SECRET,
          callbackURL: 'http://localhost:3000/auth/google/callback',
          scope: ['email', 'profile'],
        });
      }
    
      async validate(accessToken: string, refreshToken: string, profile: Profile): Promise<any> {
        const { name, emails, photos, id } = profile;
        const user = {
          userId: id,
          username: emails?.[0]?.value || name?.givenName,
          roles: ['user'],
          email: emails?.[0]?.value,
          firstName: name?.givenName,
          lastName: name?.familyName,
          picture: photos?.[0]?.value,
          accessToken,
        };
        // 在实际项目中，你可以在这里查找或创建用户
        return user;
      }
    }
    ```

4.  **创建 Google 登录路由**
    ```typescript
    // 在 AuthController 中
    @Get('google')
    @UseGuards(AuthGuard('google'))
    async googleAuth() {
      // 此处无需代码，Guard 会自动重定向到 Google 授权页面
    }
    
    @Get('google/callback')
    @UseGuards(AuthGuard('google'))
    googleAuthRedirect(@Request() req) {
      // Google 验证成功后，用户信息在 req.user
      return this.authService.login(req.user); // 返回 JWT
    }
    ```
    GitHub 等其他第三方登录实现方式与此类似。

#### 步骤 4：代码优化——全局守卫与公共路由

为了避免在每个接口上重复写 `@UseGuards`，我们可以设置一个全局守卫，并为公共接口（如登录、注册）创建特例。

1.  **创建 `@Public` 装饰器**
    ```typescript
    // src/auth/public.decorator.ts
    import { SetMetadata } from '@nestjs/common';
    export const IS_PUBLIC_KEY = 'isPublic';
    export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
    ```

2.  **增强 `JwtAuthGuard`**
    创建一个继承自 `AuthGuard('jwt')` 的守卫，并检查 `isPublic` 元数据。

    ```typescript
    // src/auth/jwt-auth.guard.ts
    import { ExecutionContext, Injectable } from '@nestjs/common';
    import { Reflector } from '@nestjs/core';
    import { AuthGuard } from '@nestjs/passport';
    import { IS_PUBLIC_KEY } from './public.decorator';
    
    @Injectable()
    export class JwtAuthGuard extends AuthGuard('jwt') {
      constructor(private reflector: Reflector) {
        super();
      }
    
      canActivate(context: ExecutionContext) {
        const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
          context.getHandler(),
          context.getClass(),
        ]);
        if (isPublic) {
          return true; // 如果是公共接口，直接放行
        }
        return super.canActivate(context); // 否则执行 JWT 验证
      }
    }
    ```

3.  **注册为全局守卫**
    ```typescript
    // main.ts 或 app.module.ts
    import { APP_GUARD } from '@nestjs/core';
    import { JwtAuthGuard } from './auth/jwt-auth.guard';
    
    // 在 AppModule 的 providers 中
    providers: [
      {
        provide: APP_GUARD,
        useClass: JwtAuthGuard,
      },
    ],
    ```

4.  **使用 `@Public`**
    现在，所有接口默认受 JWT 保护，只需为公共接口添加 `@Public()` 装饰器。

    ```typescript
    // AuthController
    @Public() // 标记为公共接口
    @UseGuards(AuthGuard('local'))
    @Post('login')
    async login(@Request() req) {
      return this.authService.login(req.user);
    }
    
    @Get('profile') // 此接口默认受 JWT 保护
    getProfile(@Request() req) {
      return req.user;
    }
    ```

---

## Part 4：精细化授权——实现 RBAC

认证解决了“你是谁”，而授权则回答“你能做什么”。RBAC (Role-Based Access Control) 是实现授权的经典模型。

### 4.1 什么是 RBAC？

RBAC 的核心思想是：不直接给用户分配权限，而是将权限分配给**角色**，再将角色分配给**用户**。

-   **用户 (User)**：系统中的操作实体。
-   **角色 (Role)**：一组权限的集合，如“管理员”、“普通用户”。
-   **权限 (Permission)**：具体的操作许可，如“创建文章”、“删除用户”。

关系：**用户 -> 角色 -> 权限**。这种方式使得权限管理变得极为高效，尤其是在用户和权限数量庞大时。

### 4.2 在 NestJS 中实现 RBAC

我们将基于 Part 3 的 JWT 认证系统，为其增加 RBAC 授权能力。

#### 步骤 1：数据库设计

使用 TypeORM 定义 User, Role, Permission 三个实体，它们之间是多对多关系。

-   **User Entity**:
    ```typescript
    @Entity()
    export class User {
      // ... 其他字段
      @ManyToMany(() => Role)
      @JoinTable({ name: 'user_role_relation' })
      roles: Role[];
    }
    ```
-   **Role Entity**:
    ```typescript
    @Entity()
    export class Role {
      // ... 其他字段
      @ManyToMany(() => Permission)
      @JoinTable({ name: 'role_permission_relation' })
      permissions: Permission[];
    }
    ```
-   **Permission Entity**:
    ```typescript
    @Entity()
    export class Permission {
      @PrimaryGeneratedColumn()
      id: number;
      @Column({ length: 50 })
      name: string; // e.g., 'post:create', 'user:delete'
      // ... 其他字段
    }
    ```

#### 步骤 2：将角色信息加入 JWT

在登录成功时，将用户的角色和权限信息编码到 JWT 的 Payload 中。

```typescript
// AuthService -> login 方法
async login(user: any) {
  // 查找用户的完整角色和权限
  const userWithRoles = await this.userService.findUserWithPermissions(user.userId);
  const payload = {
    username: user.username,
    sub: user.userId,
    roles: userWithRoles.roles.map(role => role.name),
    permissions: userWithRoles.roles.flatMap(role => role.permissions.map(p => p.name)),
  };
  return {
    access_token: this.jwtService.sign(payload),
  };
}
```

#### 步骤 3：创建权限守卫 (`PermissionGuard`)

这个守卫负责检查当前用户是否拥有访问接口所需的权限。

1.  **创建 `@RequirePermission` 装饰器**
    ```typescript
    // src/permission/require-permission.decorator.ts
    import { SetMetadata } from '@nestjs/common';
    export const PERMISSIONS_KEY = 'permissions';
    export const RequirePermission = (...permissions: string[]) => SetMetadata(PERMISSIONS_KEY, permissions);
    ```

2.  **实现 `PermissionGuard`**
    ```typescript
    // src/permission/permission.guard.ts
    import { CanActivate, ExecutionContext, Injectable, ForbiddenException } from '@nestjs/common';
    import { Reflector } from '@nestjs/core';
    import { PERMISSIONS_KEY } from './require-permission.decorator';
    
    @Injectable()
    export class PermissionGuard implements CanActivate {
      constructor(private reflector: Reflector) {}
    
      async canActivate(context: ExecutionContext): Promise<boolean> {
        const requiredPermissions = this.reflector.getAllAndOverride<string[]>(
          PERMISSIONS_KEY,
          [context.getHandler(), context.getClass()],
        );
    
        if (!requiredPermissions || requiredPermissions.length === 0) {
          return true; // 没有权限要求，直接放行
        }
    
        const { user } = context.switchToHttp().getRequest();
        if (!user || !user.permissions) {
          throw new ForbiddenException('您没有访问该接口的权限');
        }
    
        const hasPermission = requiredPermissions.every(p => user.permissions.includes(p));
    
        if (!hasPermission) {
          throw new ForbiddenException('您没有访问该接口的权限');
        }
    
        return true;
      }
    }
    ```

3.  **注册为全局守卫**
    在 `JwtAuthGuard` 之后注册 `PermissionGuard`。
    ```typescript
    // AppModule providers
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: PermissionGuard,
    },
    ```

#### 步骤 4：保护接口

现在，你可以用 `@RequirePermission` 来保护你的接口了。

```typescript
import { Controller, Post, Get } from '@nestjs/common';
import { RequirePermission } from '../permission/require-permission.decorator';

@Controller('posts')
export class PostController {
  @Get()
  @RequirePermission('post:list')
  findAll() {
    return 'This action returns all posts';
  }

  @Post()
  @RequirePermission('post:create')
  create() {
    return 'This action adds a new post';
  }
}
```

至此，我们已经构建了一个从认证到授权的完整闭环。

---

## Part 5：安全最佳实践与总结

1.  **密码安全**：始终使用 `bcrypt` 或 `argon2` 对密码进行哈希加盐处理。
2.  **密钥管理**：将所有敏感密钥（JWT Secret, OAuth Client Secret, 数据库密码）存储在环境变量或专用的密钥管理服务中，切勿硬编码。
3.  **HTTPS 强制**：生产环境中的所有通信都必须通过 HTTPS 加密，防止中间人攻击。
4.  **令牌有效期**：为 JWT 设置合理的、较短的过期时间（如 15 分钟到 1 小时），并配合 Refresh Token 机制实现长效登录，兼顾安全与体验。
5.  **输入验证**：对所有用户输入（特别是登录、注册接口）使用 `class-validator` 进行严格验证。
6.  **错误处理**：设计统一的、信息量适当的错误响应。避免泄露“用户不存在”或“密码错误”等具体信息，统一返回“用户名或密码无效”。
7.  **日志与监控**：记录所有认证尝试（尤其是失败的尝试），并设置速率限制，以防范暴力破解攻击。

通过本文的引导，你已经掌握了在 NestJS 中构建强大、安全且可扩展的认证与授权系统的完整知识。从简单的 Session/Cookie 到复杂的 JWT + RBAC，你可以根据项目需求，灵活选择并组合最适合的技术方案。
