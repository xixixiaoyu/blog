在开发 Web 应用时，身份认证是不可或缺的一环。无论是传统的用户名密码登录，还是便捷的第三方 OAuth 登录，一个安全、可靠且易于扩展的认证系统能极大提升用户体验和开发效率。本文将带你一步步使用 **NestJS** 和 **Passport**，从零构建一个功能完备的认证系统，覆盖以下核心内容：

1. **用户名密码登录**：实现经典的本地认证。
2. **JWT 无状态认证**：通过 JSON Web Token 确保安全访问。
3. **第三方登录**：集成 Google 和 GitHub 授权登录。
4. **进阶优化**：使用全局守卫和装饰器提升代码优雅度。

---

### 为什么选择 NestJS 和 Passport？
**Passport** 是 Node.js 生态中最流行的认证中间件，核心在于它的**策略模式**。无论是验证用户名密码、JWT，还是处理第三方 OAuth，Passport 都通过“策略”将认证逻辑抽象为统一的流程：获取凭证 -> 验证凭证 -> 返回用户信息。这种设计让扩展新认证方式变得异常简单。

**NestJS** 则以模块化、依赖注入和装饰器为核心，完美适配 Passport。通过 `@nestjs/passport` 模块，我们可以用声明式的方式集成认证逻辑，代码结构清晰且易于维护。两者结合，让你能快速构建生产级别的认证系统。

---

### 实战一：实现用户名密码登录
我们先从最常见的用户名密码登录开始，搭建认证系统的基本框架。

#### 项目初始化
创建一个新的 NestJS 项目，并安装必要依赖：

```bash
# 创建项目
nest new nest-passport-app
cd nest-passport-app

# 安装认证相关依赖
npm install --save @nestjs/passport passport passport-local @nestjs/jwt passport-jwt
npm install --save-dev @types/passport-local @types/passport-jwt
```

#### 创建用户服务
为了简化演示，我们用一个简单的 `UserService` 模拟用户数据。在实际项目中，建议使用数据库（如 PostgreSQL 或 MongoDB）存储用户。

```typescript
// src/user/user.service.ts
import { Injectable } from '@nestjs/common';

@Injectable()
export class UserService {
  // 模拟数据库中的用户数据
  private readonly users = [
    { userId: 1, username: 'admin', password: 'password123' },
    { userId: 2, username: 'user', password: 'password456' },
  ];

  async findOne(username: string) {
    return this.users.find(user => user.username === username);
  }
}
```

> **重要提示**：生产环境中，**绝不能明文存储密码**！请使用 `bcrypt` 或其他加密库对密码进行哈希处理。
>

创建 `UserModule` 并导出 `UserService`：

```typescript
// src/user/user.module.ts
import { Module } from '@nestjs/common';
import { UserService } from './user.service';

@Module({
  providers: [UserService],
  exports: [UserService],
})
export class UserModule {}
```

#### 实现本地认证策略
使用 Passport 的本地策略（`passport-local`）来验证用户名和密码：

```typescript
// src/auth/local.strategy.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-local';
import { AuthService } from './auth.service';

@Injectable()
export class LocalStrategy extends PassportStrategy(Strategy) {
  constructor(private authService: AuthService) {
    super({ usernameField: 'username', passwordField: 'password' });
  }

  async validate(username: string, password: string): Promise<any> {
    const user = await this.authService.validateUser(username, password);
    if (!user) {
      throw new UnauthorizedException('用户名或密码错误');
    }
    return user; // 返回用户对象，挂载到 req.user
  }
}
```

`validate` 方法是核心，负责调用 `AuthService` 验证用户凭证。

#### 创建认证服务
`AuthService` 封装认证逻辑，负责验证用户并返回结果：

```typescript
// src/auth/auth.service.ts
import { Injectable } from '@nestjs/common';
import { UserService } from '../user/user.service';

@Injectable()
export class AuthService {
  constructor(private userService: UserService) {}

  async validateUser(username: string, password: string): Promise<any> {
    const user = await this.userService.findOne(username);
    if (user && user.password === password) {
      const { password, ...result } = user; // 剔除密码
      return result;
    }
    return null;
  }
}
```

#### 配置认证模块
将认证相关的逻辑组织在 `AuthModule` 中：

```typescript
// src/auth/auth.module.ts
import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { UserModule } from '../user/user.module';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { LocalStrategy } from './local.strategy';

@Module({
  imports: [UserModule, PassportModule],
  controllers: [AuthController],
  providers: [AuthService, LocalStrategy],
  exports: [AuthService],
})
export class AuthModule {}
```

#### 创建登录接口
在控制器中添加登录接口，使用 `AuthGuard('local')` 激活本地策略：

```typescript
// src/auth/auth.controller.ts
import { Controller, Post, Request, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Controller('auth')
export class AuthController {
  @UseGuards(AuthGuard('local'))
  @Post('login')
  async login(@Request() req) {
    return req.user; // 返回验证后的用户信息
  }
}
```

#### 根模块注册
```typescript
import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AuthModule } from './auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

```

启动项目：

```bash
pnpm run start:dev
```

使用 Postman 或 cURL 测试 `POST /auth/login`：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1753019718507-e5404f40-2045-498f-a479-561416ca1d22.png)

发送 `{ "username": "admin", "password": "password123" }`，应返回用户信息（如 `{ userId: 1, username: "admin" }`）。

---

### 实战二：集成 JWT 实现无状态认证
为了避免每次请求都重新输入密码，我们使用 JWT（JSON Web Token）实现无状态认证。登录成功后，服务器签发 Token，客户端在后续请求中携带它以证明身份。

#### 1. 配置 JWT 模块
在 `AuthModule` 中注册 `JwtModule`：

```typescript
// src/auth/auth.module.ts
import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { JwtModule } from '@nestjs/jwt';
import { UserModule } from '../user/user.module';
import { AuthService } from './auth.service';
import { LocalStrategy } from './local.strategy';
import { JwtStrategy } from './jwt.strategy';

@Module({
  imports: [
    UserModule,
    PassportModule,
    JwtModule.register({
      secret: 'YOUR_SECRET_KEY', // 生产环境中使用环境变量
      signOptions: { expiresIn: '1h' },
    }),
  ],
  providers: [AuthService, LocalStrategy, JwtStrategy],
  exports: [AuthService],
})
export class AuthModule {}
```

> **安全提示**：切勿将密钥硬编码在代码中，建议使用环境变量（如 `process.env.JWT_SECRET`）管理。
>

#### 2. 生成 JWT
在 `AuthService` 中添加方法，用于生成 JWT：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1753020313743-2dc1b68a-9f55-4af1-904d-e1a9f08509f2.png)

```typescript
async login(user: any) {
    const payload = { username: user.username, sub: user.userId };
    return {
      access_token: this.jwtService.sign(payload),
    };
  }
}
```

更新登录接口，返回 JWT：

```typescript
// src/auth/auth.controller.ts
import { Controller, Post, Request, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @UseGuards(AuthGuard('local'))
  @Post('login')
  async login(@Request() req) {
    return this.authService.login(req.user); // 返回 JWT
  }
}
```

#### 3. 验证 JWT
创建 `JwtStrategy` 用于验证客户端发送的 Token：

```typescript
// src/auth/jwt.strategy.ts
import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      // 从请求头的 Authorization 中提取 Bearer Token
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      // 不忽略 token 过期时间，过期后认证失败
      ignoreExpiration: false,
      // 用于验证 token 的密钥，需替换为实际的密钥字符串
      secretOrKey: 'YOUR_SECRET_KEY',
    });
  }

  async validate(payload: any) {
    return { userId: payload.sub, username: payload.username };
  }
}
```

#### 4. 保护路由
使用 `AuthGuard('jwt')` 保护需要认证的接口：

```typescript
// src/auth/auth.controller.ts
import { Controller, Get, Post, Request, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @UseGuards(AuthGuard('local'))
  @Post('login')
  async login(@Request() req) {
    return this.authService.login(req.user);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('profile')
  getProfile(@Request() req) {
    return req.user; // 返回用户信息
  }
}
```

测试时，先调用 `/auth/login` 获取 Token：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1753021938034-92af751b-d252-44b1-8d71-265a795ec43a.png)

然后在请求 `/auth/profile` 时，在请求头添加 `Authorization: Bearer <your_token>`：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1753021905223-4b88133f-c3bd-4faf-9e0c-be2bcba9f8d5.png)

如果没有正确添加：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1753021013324-d8e70cef-354b-467c-b7f3-5863e1dc728a.png)

---

### 实战三：实现 Google 第三方登录
第三方登录（如 Google 或 GitHub）通过 OAuth 2.0 协议，可以让用户使用已有账号快速登录，提升体验。我们以 Google 登录为例。

#### 1. 配置 Google 应用
1. 访问 [Google Cloud Console](https://console.cloud.google.com/)，创建项目。
2. 在 "OAuth consent screen" 配置应用信息。
3. 在 "Credentials" 创建 OAuth 2.0 Client ID，类型为 "Web application"。
4. 设置回调地址为 `http://localhost:3000/auth/google/callback`。
5. 获取 `Client ID` 和 `Client Secret`。

#### 2. 安装 Google 策略
```bash
npm install --save passport-google-oauth20
npm install --save-dev @types/passport-google-oauth20
```

#### 3. 创建 Google 策略
```typescript
// src/auth/google.strategy.ts
import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Profile, Strategy } from 'passport-google-oauth20';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor() {
    super({
      clientID: 'YOUR_GOOGLE_CLIENT_ID',
      clientSecret: 'YOUR_GOOGLE_CLIENT_SECRET',
      callbackURL: 'http://localhost:3000/auth/google/callback',
      scope: ['email', 'profile'],
    });
  }

  async validate(accessToken: string, refreshToken: string, profile: Profile): Promise<any> {
    const { name, emails, photos } = profile;
    const user = {
      email: emails[0].value,
      firstName: name.givenName,
      lastName: name.familyName,
      picture: photos[0].value,
      accessToken,
    };
    return user; // 实际项目中应查询或创建用户
  }
}
```

在 `AuthModule` 的 `providers` 中添加 `GoogleStrategy`。

#### 4. 创建 Google 登录路由
```typescript
// src/auth/auth.controller.ts
import { Controller, Get, Post, Request, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @UseGuards(AuthGuard('local'))
  @Post('login')
  async login(@Request() req) {
    return this.authService.login(req.user);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('profile')
  getProfile(@Request() req) {
    return req.user;
  }

  @Get('google')
  @UseGuards(AuthGuard('google'))
  async googleAuth() {
    // 重定向到 Google 授权页面
  }

  @Get('google/callback')
  @UseGuards(AuthGuard('google'))
  async googleAuthRedirect(@Request() req) {
    return this.authService.login(req.user); // 返回 JWT
  }
}
```

访问 `http://localhost:3000/auth/google`，会跳转到 Google 登录页面，授权后回调到 `/auth/google/callback` 并返回 JWT。GitHub 登录实现方式类似，只需更换策略和密钥。

---

### 进阶：全局守卫与公开路由
为避免在每个路由上重复添加 `@UseGuards(AuthGuard('jwt'))`，我们可以通过全局守卫默认保护所有接口，并用自定义装饰器标记公开路由。

#### 1. 创建公开路由装饰器
```typescript
// src/auth/public.decorator.ts
import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
```

#### 2. 自定义全局守卫
```typescript
// src/auth/jwt-auth.guard.ts
import { Injectable, ExecutionContext } from '@nestjs/common';
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
      return true;
    }
    return super.canActivate(context);
  }
}
```

#### 3. 注册全局守卫
在 `AppModule` 中注册：

```typescript
// src/app.module.ts
import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { AuthModule } from './auth/auth.module';
import { UserModule } from './user/user.module';
import { JwtAuthGuard } from './auth/jwt-auth.guard';

@Module({
  imports: [AuthModule, UserModule],
  providers: [
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
  ],
})
export class AppModule {}
```

#### 4. 使用公开装饰器
将登录接口标记为公开：

```typescript
// src/auth/auth.controller.ts
import { Controller, Get, Post, Request, UseGuards } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { Public } from './public.decorator';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Public()
  @UseGuards(AuthGuard('local'))
  @Post('login')
  async login(@Request() req) {
    return this.authService.login(req.user);
  }

  @Get('profile')
  getProfile(@Request() req) {
    return req.user;
  }

  @Public()
  @Get('google')
  @UseGuards(AuthGuard('google'))
  async googleAuth() {}

  @Public()
  @Get('google/callback')
  @UseGuards(AuthGuard('google'))
  async googleAuthRedirect(@Request() req) {
    return this.authService.login(req.user);
  }
}
```

现在，所有接口默认需要 JWT 验证，带有 `@Public()` 的接口（如登录、Google 回调）无需认证。

---

### 实战四：实现 GitHub 第三方登录
GitHub 登录与 Google 登录类似，同样基于 OAuth 2.0 协议。我们将实现用户通过 GitHub 账号登录，并返回 JWT。

#### 1. 配置 GitHub 应用
1. 访问 [GitHub Developer Settings](https://github.com/settings/developers)，点击 "New OAuth App" 创建应用。
2. 填写应用名称、Homepage URL（如 `http://localhost:3000`）和 Authorization callback URL（如 `http://localhost:3000/auth/github/callback`）。
3. 保存后获取 `Client ID` 和 `Client Secret`。

#### 2. 安装 GitHub 策略
安装 `passport-github2` 策略：

```typescript
npm install --save passport-github2
npm install --save-dev @types/passport-github2
```

#### 3. 创建 GitHub 策略
创建 `GithubStrategy` 来处理 GitHub 登录逻辑：

```typescript
// src/auth/github.strategy.ts
import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy, Profile } from 'passport-github2';

@Injectable()
export class GithubStrategy extends PassportStrategy(Strategy, 'github') {
  constructor() {
    super({
      clientID: 'YOUR_GITHUB_CLIENT_ID',
      clientSecret: 'YOUR_GITHUB_CLIENT_SECRET',
      callbackURL: 'http://localhost:3000/auth/github/callback',
      scope: ['user:email'], // 请求获取用户邮箱
    });
  }

  async validate(accessToken: string, refreshToken: string, profile: Profile): Promise<any> {
    const { username, emails, photos } = profile;
    const user = {
      email: emails && emails[0]?.value, // GitHub 可能不返回邮箱，需处理
      username: username || profile.displayName,
      picture: photos && photos[0]?.value,
      accessToken,
    };
    // 实际项目中应查询或创建用户
    return user;
  }
}
```

> **注意**：GitHub 的用户邮箱可能需要额外权限或用户设置公开才能获取。如果 `emails` 为空，需根据业务逻辑处理（如使用 `username` 作为唯一标识）。
>

#### 4. 创建 GitHub 登录路由
GitHub 登录路由已在 `AuthController` 中添加，访问 `http://localhost:3000/auth/github` 会跳转到 GitHub 授权页面，授权后回调到 `/auth/github/callback` 并返回 JWT。

### 总结与生产环境实践
通过以上步骤，我们构建了一个支持用户名密码登录、JWT 认证和 Google 第三方登录的认证系统。关键点总结：

+ **Passport 策略**：通过策略模式解耦认证逻辑，扩展性极强。
+ **NestJS 模块化**：将认证逻辑封装在模块中，代码清晰且易于维护。
+ **全局守卫**：通过装饰器和守卫简化认证管理，提升开发效率。

**生产环境最佳实践**：

1. **密码安全**：使用 `bcrypt` 对密码进行哈希存储，避免明文泄露。
2. **密钥管理**：将 JWT 密钥、数据库凭证和第三方 `Client Secret` 存储在环境变量中。
3. **Refresh Token**：实现 Refresh Token 机制，延长用户会话时长，提升体验。
4. **数据库集成**：使用 TypeORM 或 Mongoose 管理用户数据，确保持久化存储。
5. **错误处理**：添加全局异常过滤器，统一处理认证失败等错误，返回友好的提示信息。

