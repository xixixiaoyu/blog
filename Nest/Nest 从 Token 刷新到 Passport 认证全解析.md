## Part 1: 深入解析 Token 刷新机制

Token 是目前最流行的无状态认证方案，但 Token 的有效期管理是一个关键问题。有效期太长会带来安全风险，太短则会频繁要求用户重新登录。如何实现“无感刷新”，在安全和体验之间找到平衡点？我们来探讨两种主流方案。

### 方案一：单 Token 自动续期

这是最简单直接的方案，其原理是：

1.  用户登录成功，服务端返回一个具备有效期的 JWT。
2.  前端在后续的每次请求中都携带此 JWT。
3.  服务端在每次验证通过后，都返回一个新的 JWT，替换掉旧的。
4.  前端通过响应头获取新 Token，并更新本地存储。

只要用户在 Token 过期前（例如 7 天内）有任意一次操作，登录状态就会被延续，从而实现“无感刷新”。

#### 后端实现

首先，我们需要一个登录接口和用于验证的 `Guard`。

**1. 登录接口**

我们创建一个 `user` 模块，并提供一个 `login` 接口。为了简化，我们在这里硬编码用户名和密码。

```typescript
// src/user/user.controller.ts
import { BadRequestException, Body, Controller, Inject, Post } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { LoginUserDto } from './dto/login-user.dto';

@Controller('user')
export class UserController {
  @Inject(JwtService)
  private jwtService: JwtService;

  @Post('login')
  async login(@Body() loginDto: LoginUserDto) {
    if(loginDto.username !== 'guang' || loginDto.password !== '123456') {
      throw new BadRequestException('用户名或密码错误');
    }
    const token = this.jwtService.sign({
      username: loginDto.username
    }, {
      expiresIn: '7d' // 7天有效期
    });
    return { token };
  }
}
```

**2. 刷新 Token 的 Guard**

关键在于 `Guard`。在验证 Token 成功后，我们利用 `response` 对象在响应头里设置一个新的 Token。

```typescript
// src/login.guard.ts
import { JwtService } from '@nestjs/jwt';
import { CanActivate, ExecutionContext, Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { Request, Response } from 'express';

@Injectable()
export class LoginGuard implements CanActivate {
  @Inject(JwtService)
  private jwtService: JwtService;

  canActivate(context: ExecutionContext): boolean {
    const request: Request = context.switchToHttp().getRequest();
    const response: Response = context.switchToHttp().getResponse();
    const authorization = request.headers.authorization;

    if (!authorization) {
      throw new UnauthorizedException('用户未登录');
    }

    try {
      const token = authorization.split(' ')[1];
      const data = this.jwtService.verify(token);

      // 生成新 Token
      const newToken = this.jwtService.sign({
        username: data.username
      }, {
        expiresIn: '7d'
      });

      // 在响应头中返回新 Token
      response.setHeader('Authorization', `Bearer ${newToken}`);
      
      // 将用户信息附加到请求对象，方便后续处理
      request.user = data;

      return true;
    } catch (e) {
      throw new UnauthorizedException('Token 已失效，请重新登录');
    }
  }
}
```

#### 前端实现

前端的核心是使用 `axios` 的拦截器来统一处理 Token 的获取和更新。

**1. 请求拦截器**

在每次请求前，从 `localStorage` 读取 Token 并添加到请求头中。

```javascript
import axios from 'axios';

axios.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

**2. 响应拦截器**

在收到响应后，检查响应头中是否有新的 `Authorization`，如果有，则更新本地存储的 Token。

```javascript
axios.interceptors.response.use(
  (response) => {
    const newToken = response.headers['authorization'];
    if (newToken) {
      localStorage.setItem('token', newToken.split(' ')[1]);
    }
    return response;
  },
  (error) => {
    // 处理错误
    return Promise.reject(error);
  }
);
```

**注意：跨域问题**

默认情况下，前端 JavaScript 无法访问非标准的响应头。你需要让后端在 CORS 配置中显式暴露 `Authorization` 头。

```typescript
// main.ts
app.enableCors({
  // ... 其他配置
  exposedHeaders: ['Authorization'],
});
```

#### 方案评价

*   **优点**：实现极其简单，后端逻辑集中在 `Guard`，前端逻辑集中在拦截器。
*   **缺点**：
    *   每次请求都刷新 Token，会带来轻微的性能开销。
    *   如果 Token 被盗用，攻击者可以无限制地续期。
    *   更合理的做法应该是在 Token 即将过期时才进行刷新，但这会增加逻辑的复杂性。

### 方案二：双 Token 无感刷新

这是一种更安全、更工业化的标准方案。它引入了两种类型的 Token：

*   `access_token`：访问令牌，用于API请求的身份验证，有效期很短（如 30 分钟）。
*   `refresh_token`：刷新令牌，专门用于获取新的 `access_token`，有效期很长（如 7 天）。

**工作流程：**

1.  登录时，服务端返回 `access_token` 和 `refresh_token`。
2.  前端请求 API 时只携带 `access_token`。
3.  当 `access_token` 过期时（通常API返回 401 错误），前端使用 `refresh_token` 去调用一个专门的刷新接口。
4.  刷新接口验证 `refresh_token`，成功后返回一对全新的 `access_token` 和 `refresh_token`。
5.  前端更新本地存储的两个 Token，并重新发起刚才失败的 API 请求。
6.  如果 `refresh_token` 也过期了，则用户必须重新登录。

#### 后端实现

**1. 登录接口返回双 Token**

```typescript
// src/user/user.controller.ts
@Post('login')
async login(@Body() loginUser: LoginUserDto) {
  const user = await this.userService.login(loginUser); // 假设 userService.login 验证用户

  const payload = { userId: user.id, username: user.username };

  const access_token = this.jwtService.sign(payload, { expiresIn: '30m' });
  const refresh_token = this.jwtService.sign({ userId: user.id }, { expiresIn: '7d' });

  return { access_token, refresh_token };
}
```

**2. 刷新 Token 接口**

```typescript
// src/user/user.controller.ts
@Post('refresh')
async refresh(@Body('refresh_token') refreshToken: string) {
  try {
    const data = this.jwtService.verify(refreshToken);
    const user = await this.userService.findUserById(data.userId);

    const payload = { userId: user.id, username: user.username };

    const access_token = this.jwtService.sign(payload, { expiresIn: '30m' });
    const new_refresh_token = this.jwtService.sign({ userId: user.id }, { expiresIn: '7d' });

    return { access_token, refresh_token: new_refresh_token };
  } catch (e) {
    throw new UnauthorizedException('Token 已失效，请重新登录');
  }
}
```

**3. 登录守卫**

这个守卫只验证 `access_token`。

```typescript
// src/login.guard.ts
// ...
try {
  const token = authorization.split(' ')[1];
  const data = this.jwtService.verify(token); // 默认验证 access_token
  request.user = data;
  return true;
} catch (e) {
  // 这里不再直接抛出异常，而是让前端判断
  throw new UnauthorizedException('access_token 已失效');
}
// ...
```

#### 前端实现

前端的 `axios` 响应拦截器是实现无感刷新的关键，它需要处理并发请求和刷新逻辑。

```javascript
import axios from 'axios';

let isRefreshing = false; // 标记是否正在刷新 Token
let requestQueue = []; // 请求队列，用于存储在刷新期间到来的请求

// 请求拦截器：为双 Token 场景统一附加 access_token
axios.interceptors.request.use((config) => {
  const accessToken = localStorage.getItem('access_token');
  if (accessToken) {
    config.headers.Authorization = `Bearer ${accessToken}`;
  }
  return config;
});

// 响应拦截器
axios.interceptors.response.use(
  response => response,
  async (error) => {
    const { config, response } = error;

    // 如果是 401 错误且不是刷新接口本身
    if (response && response.status === 401 && !config.url.includes('/refresh')) {
      if (!isRefreshing) {
        isRefreshing = true;
        try {
          const refreshToken = localStorage.getItem('refresh_token');
          const { data } = await axios.post('http://localhost:3000/user/refresh', { refresh_token: refreshToken });
          
          // 更新 Token
          localStorage.setItem('access_token', data.access_token);
          localStorage.setItem('refresh_token', data.refresh_token);

          // 重新执行队列中的请求
          requestQueue.forEach(cb => cb(data.access_token));
          requestQueue = []; // 清空队列

          // 重新执行当前失败的请求
          config.headers.Authorization = `Bearer ${data.access_token}`;
          return axios(config);
        } catch (e) {
          // 刷新失败，跳转到登录页
          console.error('Refresh token failed, redirect to login.');
          window.location.href = '/login';
          return Promise.reject(error);
        } finally {
          isRefreshing = false;
        }
      } else {
        // 如果正在刷新，将当前请求加入队列
        return new Promise((resolve) => {
          requestQueue.push((token) => {
            config.headers.Authorization = `Bearer ${token}`;
            resolve(axios(config));
          });
        });
      }
    }
    return Promise.reject(error);
  }
);
```

#### 方案评价

*   **优点**：安全性高，职责分离。`access_token` 即使泄露，生命周期也很短。刷新 `refresh_token` 的操作可以被监控。
*   **缺点**：实现逻辑相对复杂，尤其是在前端需要处理好并发请求的队列，防止多次重复刷新。

## Part 2: 使用 Passport.js 构建模块化认证系统

虽然我们可以手动实现认证逻辑，但随着认证方式的增多（如用户名密码、JWT、社交登录等），代码会变得越来越难以维护。`Passport.js` 正是为此而生，它是 Node.js 中最流行的认证中间件，通过“策略”（Strategy）模式，将各种认证逻辑解耦，使代码更加清晰和模块化。

### 拥抱 Passport：认证策略的抽象

Passport 的核心思想是：

1.  **策略 (Strategy)**：每一种认证方式（`local`, `jwt`, `github`）都是一个独立的策略。
2.  **守卫 (Guard)**：NestJS 提供了 `@UseGuards(AuthGuard('策略名'))` 来应用某个策略。
3.  **验证 (Validate)**：每个策略的核心是一个 `validate` 方法，你只需要在这个方法里实现你的验证逻辑（如查询数据库、验证密码）。
4.  **用户信息注入**：验证成功后，Passport 会自动将 `validate` 方法返回的用户信息附加到 `request.user` 上。

让我们用 Passport 来重构和增强我们的认证系统。

**安装依赖：**

```bash
npm install --save @nestjs/passport passport @nestjs/jwt passport-local passport-jwt
npm install --save-dev @types/passport-local @types/passport-jwt
```

### 本地认证：`passport-local` 策略

`passport-local` 策略用于处理最常见的用户名和密码登录。

**1. 创建 LocalStrategy**

```typescript
// src/auth/local.strategy.ts
import { Strategy } from 'passport-local';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { AuthService } from './auth.service';

@Injectable()
export class LocalStrategy extends PassportStrategy(Strategy) {
  constructor(private authService: AuthService) {
    // 你可以在这里配置 passport-local，例如重命名字段
    super({ usernameField: 'username', passwordField: 'password' });
  }

  // Passport 会自动调用这个方法
  async validate(username: string, password: string): Promise<any> {
    const user = await this.authService.validateUser(username, password);
    if (!user) {
      throw new UnauthorizedException('用户名或密码错误');
    }
    return user; // 返回值会被注入到 request.user
  }
}
```

**2. 创建 AuthService**

`AuthService` 封装了具体的验证逻辑。

```typescript
// src/auth/auth.service.ts
@Injectable()
export class AuthService {
  // 假设 userService 负责数据库交互
  constructor(private userService: UserService) {}

  async validateUser(username: string, pass: string): Promise<any> {
    const user = await this.userService.findOne(username);
    if (user && user.password === pass) {
      const { password, ...result } = user;
      return result;
    }
    return null;
  }
}
```

**3. 应用于登录接口**

现在，登录接口变得异常简洁。

```typescript
// src/app.controller.ts
import { Controller, Post, UseGuards, Request, Inject } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { JwtService } from '@nestjs/jwt';

@Controller()
export class AppController {
  @Inject(JwtService)
  private jwtService: JwtService;

  @UseGuards(AuthGuard('local')) // 应用 local 策略
  @Post('login')
  async login(@Request() req) {
    // local 策略验证成功后，用户信息在 req.user 中
    // 接下来可以签发 JWT
    const payload = { userId: req.user.id, username: req.user.username };
    return {
      access_token: this.jwtService.sign(payload),
    };
  }
}
```

### JWT 认证：`passport-jwt` 策略

`passport-jwt` 策略用于保护我们的 API 端点，验证请求头中的 JWT。

**1. 创建 JwtStrategy**

```typescript
// src/auth/jwt.strategy.ts
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable } from '@nestjs/common';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(), // 从 Authorization 头提取 Token
      ignoreExpiration: false, // 不忽略过期
      secretOrKey: process.env.JWT_SECRET, // 使用环境变量中的密钥，需与 JwtModule 保持一致
    });
  }

  // Passport 解码 Token 后会调用此方法
  async validate(payload: any) {
    // payload 就是解码后的用户信息
    return { userId: payload.userId, username: payload.username };
  }
}
```

**2. 应用于受保护的接口**

```typescript
// src/app.controller.ts
@UseGuards(AuthGuard('jwt')) // 应用 jwt 策略
@Get('profile')
getProfile(@Request() req) {
  return req.user; // 返回用户信息
}
```

### 全局守卫：实现公共路由

在实际应用中，我们希望大部分接口默认需要认证，只有少数接口（如登录、注册）是公开的。我们可以通过创建一个全局 `Guard` 和一个自定义装饰器 `@IsPublic()` 来优雅地实现这一点。

**1. 创建 `@IsPublic` 装饰器**

```typescript
// src/auth/is-public.decorator.ts
import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';
export const IsPublic = () => SetMetadata(IS_PUBLIC_KEY, true);
```

**2. 创建自定义的全局 JWT 守卫**

这个守卫继承自 `AuthGuard('jwt')`，并添加了检查 `@IsPublic` 元数据的逻辑。

```typescript
// src/auth/jwt-auth.guard.ts
import { ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { IS_PUBLIC_KEY } from './is-public.decorator';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private reflector: Reflector) {
    super();
  }

  canActivate(context: ExecutionContext) {
    // 检查是否有 @IsPublic() 装饰器
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true; // 如果是公共接口，直接放行
    }
    // 否则，执行 JWT 认证
    return super.canActivate(context);
  }
}
```

**3. 全局注册 Guard**

在 `app.module.ts` 中将其注册为全局 `Guard`。

```typescript
// src/app.module.ts
import { APP_GUARD } from '@nestjs/core';
import { JwtAuthGuard } from './auth/jwt-auth.guard';

@Module({
  // ...
  providers: [
    // ...
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
```

**4. 使用**

现在，所有接口默认受 JWT 保护。要将某个接口设为公开，只需添加 `@IsPublic()` 装饰器。

```typescript
// src/app.controller.ts

// 这个接口是公开的
@IsPublic()
@Post('login')
// ...

// 这个接口需要 JWT 认证
@Get('profile')
// ...
```

## Part 3: 集成第三方 OAuth 登录

Passport 的强大之处还在于其丰富的第三方策略生态。我们可以轻松地为应用添加“使用 GitHub/Google 登录”等功能。

### GitHub 登录：`passport-github2` 策略

**1. 安装依赖**

```bash
npm install --save passport-github2
npm install --save-dev @types/passport-github2
```

**2. 在 GitHub 创建 OAuth App**

前往 GitHub 的 `Settings > Developer settings > OAuth Apps`，创建一个新的 OAuth App。你需要提供应用名称、主页 URL 和一个关键的 **Authorization callback URL**（例如 `http://localhost:3000/auth/github/callback`）。创建后，你将获得一个 `Client ID` 和一个 `Client Secret`。

**3. 创建 GithubStrategy**

```typescript
// src/auth/github.strategy.ts
import { PassportStrategy } from '@nestjs/passport';
import { Injectable } from '@nestjs/common';
import { Strategy, Profile } from 'passport-github2';

@Injectable()
export class GithubStrategy extends PassportStrategy(Strategy, 'github') {
  constructor() {
    super({
      clientID: 'YOUR_GITHUB_CLIENT_ID',
      clientSecret: 'YOUR_GITHUB_CLIENT_SECRET',
      callbackURL: 'http://localhost:3000/auth/github/callback',
      scope: ['read:user', 'user:email'],
    });
  }

  async validate(accessToken: string, refreshToken: string, profile: Profile) {
    // 在这里，你可以将 GitHub profile 信息保存到数据库
    // 或者根据 profile.id 查找关联的本地用户
    const user = {
      githubId: profile.id,
      username: profile.username,
      avatar: profile._json.avatar_url,
    };
    return user; // 返回的用户信息将注入 req.user
  }
}
```

**4. 创建认证路由**

你需要两个路由：一个用于发起登录请求，一个用于处理回调。

```typescript
// src/auth/auth.controller.ts
import { Controller, Get, UseGuards, Request } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Controller('auth')
export class AuthController {
  // 1. 发起登录，会重定向到 GitHub 授权页
  @Get('github')
  @UseGuards(AuthGuard('github'))
  async githubLogin() {
    // Passport 会自动处理重定向
  }

  // 2. GitHub 授权后回调此接口
  @Get('github/callback')
  @UseGuards(AuthGuard('github'))
  githubLoginCallback(@Request() req) {
    // Passport 处理完回调后，用户信息在 req.user 中
    // 在这里，你可以签发自己的 JWT，然后重定向到前端页面
    return req.user;
  }
}
```

### Google 登录：`passport-google-oauth20` 策略

实现 Google 登录的流程与 GitHub 非常相似。

1.  **安装依赖**：`npm install --save passport-google-oauth20` 和 `@types/passport-google-oauth20`。
2.  **创建凭证**：在 [Google Cloud Console](https://console.cloud.google.com/) 创建一个项目，然后在 "APIs & Services > Credentials" 中创建一个 "OAuth 2.0 Client ID"，获取 `Client ID` 和 `Client Secret`。
3.  **创建 GoogleStrategy**：与 `GithubStrategy` 类似，只是 `Strategy` 来自 `passport-google-oauth20`，并配置 Google 提供的凭证和回调 URL。
4.  **创建路由**：同样需要一个发起路由和一个回调路由，并使用 `@UseGuards(AuthGuard('google'))`。

## 总结

我们从最基础的单 Token 刷新方案出发，逐步过渡到更安全的双 Token 机制，最终拥抱了 Passport.js 这个强大的认证框架。通过本文的实践，你应该掌握了：

*   **两种 Token 刷新机制**的原理和实现，并能根据场景权衡利弊。
*   **Passport.js 的核心思想**——策略模式，以及如何用它来解耦和组织认证代码。
*   **如何实现本地认证 (`local`) 和 JWT 认证 (`jwt`)**，并构建一个可扩展的认证系统。
*   **如何通过全局 `Guard` 和自定义装饰器**来优雅地管理应用的公共和私有路由。
*   **如何集成第三方 OAuth 登录**（如 GitHub 和 Google），为用户提供便捷的登录选项。

身份认证是构建健壮应用的基石。希望这篇文章能为你提供一个清晰的路线图，帮助你在 NestJS 项目中自信地处理各种复杂的认证需求。
