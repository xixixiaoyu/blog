## 为什么需要分布式 Session？
Session 的核心逻辑很简单：用户登录时，服务端生成一个唯一标识（Session ID），把用户数据（比如 ID、权限、购物车等）存在服务器内存里，Session ID 则通过 Cookie 发给客户端。客户端后续请求会带上这个 ID，服务端根据它找到对应的用户数据。

但问题来了：如果你的应用部署在多台服务器上，负载均衡可能会把用户的请求分配到不同服务器。比如，用户第一次访问服务器 A，Session 数据存在 A 上，但下次请求被分到服务器 B，B 并不知道这个 Session ID，用户的登录状态就丢了。

相比之下，JWT（JSON Web Token）把所有数据都加密后存在客户端，服务端无需存储，天然适合分布式环境。但 JWT 的缺点是数据全在客户端，服务端难以主动失效或更新数据。而 Session 存储在服务端，控制更灵活，安全性更高。能不能让 Session 也支持分布式呢？答案是肯定的 —— 用 Redis 做“中央存储”就能完美解决。

## 实现思路
我们要把 Session 数据从单台服务器的内存搬到一个所有服务器都能访问的“中央存储”里，Redis 是个绝佳选择。它的速度快、支持多种数据结构，还能设置过期时间，非常适合存 Session 数据。具体步骤如下：

1. 用户请求时，生成一个唯一的 Session ID（简称 `sid`）。
2. 把用户数据以键值对形式存入 Redis，键是 `sid`，值是用户数据。
3. 通过 Cookie 把 `sid` 发给客户端。
4. 客户端后续请求带上 `sid`，服务端根据它从 Redis 读取或更新数据。
5. 如果数据有变化，更新 Redis 记录，确保所有服务器都能拿到最新状态。

接下来，我们用 NestJS 一步步实现这个分布式 Session 系统。

## 动手实践
### 第一步：搭建 Redis 服务
要让 NestJS 和 Redis 通信，我们需要安装 Redis 客户端并封装一个模块。

1. **初始化项目并安装依赖**

```bash
# 创建 NestJS 项目
nest new redis-session-test -p npm
cd redis-session-test
# 安装 Redis 客户端
npm install --save redis
```

2. **创建 Redis 模块和服务**  
用 NestJS 的 CLI 生成模块和服务，保持代码结构清晰：

```bash
nest g module redis
nest g service redis
```

在 `RedisModule` 中配置 Redis 连接，并设为全局模块，方便其他模块直接使用：

```typescript
// src/redis/redis.module.ts
import { Global, Module } from '@nestjs/common';
import { createClient } from 'redis';
import { RedisService } from './redis.service';

@Global()
@Module({
  providers: [
    RedisService,
    {
      provide: 'REDIS_CLIENT',
      async useFactory() {
        const client = createClient({
          socket: {
            host: 'localhost', // Redis 地址，生产环境需替换
            port: 6379,       // Redis 端口
          },
        });
        await client.connect();
        return client;
      },
    },
  ],
  exports: [RedisService],
})
export class RedisModule {}
```

3. **封装 Redis 操作**  
Session 数据通常是键值对形式，Redis 的 Hash 结构很适合存储。我们在 `RedisService` 中封装两个方法：`hashSet` 存数据，`hashGet` 取数据。

```typescript
// src/redis/redis.service.ts
import { Inject, Injectable } from '@nestjs/common';
import { RedisClientType } from 'redis';

@Injectable()
export class RedisService {
  // 注入 Redis 客户端实例
  @Inject('REDIS_CLIENT')
  private redisClient: RedisClientType;

  // 获取指定 key 的所有哈希字段和值
  async hashGet(key: string) {
    return await this.redisClient.hGetAll(key);
  }

  // 设置指定 key 的哈希字段和值，并可选设置过期时间
  async hashSet(key: string, obj: Record<string, any>, ttl?: number) {
    // 遍历对象，将每个字段和值存入 Redis 哈希
    for (const name in obj) {
      await this.redisClient.hSet(key, name, obj[name]);
    }
    // 如果提供了 ttl 参数，设置 key 的过期时间（单位：秒）
    if (ttl) {
      await this.redisClient.expire(key, ttl);
    }
  }
}
```

**提示**：Redis 会把所有值转为字符串存储，所以存复杂对象时需要注意类型转换，必要时可以用 JSON 序列化。

### 第二步：实现 Session 服务
接下来，基于 `RedisService` 创建一个专门管理 Session 的服务。

1. **创建 Session 模块和服务**

```bash
nest g module session
nest g service session --no-spec
```

将 `SessionModule` 设为全局模块：

```typescript
// src/session/session.module.ts
import { Global, Module } from '@nestjs/common';
import { SessionService } from './session.service';

@Global()
@Module({
  providers: [SessionService],
  exports: [SessionService],
})
export class SessionModule {}
```

2. **实现 Session 核心逻辑**  
`SessionService` 负责生成 `sid`、存取 Session 数据。我们用 TypeScript 的泛型让代码更灵活：

```typescript
// src/session/session.service.ts
import { Inject, Injectable } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';

// 标记为可注入的服务类，用于管理用户会话
@Injectable()
export class SessionService {
  // 注入 Redis 服务，用于存储和操作会话数据
  @Inject(RedisService)
  private redisService: RedisService;

  // 获取指定会话 ID 的会话数据
  async getSession<SessionType extends Record<string, any>>(
    sid: string, // 会话 ID
  ): Promise<SessionType | null> {
    // 从 Redis 中获取会话数据
    const sessionData = await this.redisService.hashGet(`sid_${sid}`);
    // 如果数据为空，返回 null
    if (Object.keys(sessionData).length === 0) {
      return null;
    }
    // 返回类型转换后的会话数据
    return sessionData as SessionType;
  }

  // 设置或更新会话数据
  async setSession(
    sid: string, // 会话 ID
    value: Record<string, any>, // 会话数据
    ttl: number = 30 * 60, // 过期时间（秒），默认 30 分钟
  ) {
    // 如果未提供会话 ID，生成一个新的
    if (!sid) {
      sid = this.generateSid();
    }
    // 将会话数据存储到 Redis 中，并设置过期时间
    await this.redisService.hashSet(`sid_${sid}`, value, ttl);
    // 返回会话 ID
    return sid;
  }

  // 生成唯一的会话 ID
  private generateSid() {
    // 使用随机数生成简单唯一 ID，去掉前缀 "0."
    return Math.random().toString(36).slice(2);
  }
}
```

**说明**：`getSession` 使用泛型支持类型提示，方便开发者获取强类型的 Session 数据。`generateSid` 是个简单的实现，生产环境建议用 UUID 或更安全的随机算法。

### 第三步：在控制器中应用
我们写一个简单的计数器接口，测试 Session 功能。

1. **安装并启用 **`cookie-parser`  
Session ID 通过 Cookie 传递，需要 `cookie-parser` 中间件：

```bash
npm install --save cookie-parser
```

在 `main.ts` 中启用：

```typescript
// src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as cookieParser from 'cookie-parser';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.use(cookieParser());
  await app.listen(3000);
}
bootstrap();
```

2. **编写测试接口**  
在 `AppController` 中实现 `/count` 接口，每次访问计数加 1，并通过 Cookie 传递 `sid`：

```typescript
// src/app.controller.ts
import { Controller, Get, Inject, Req, Res } from '@nestjs/common';
import { Request, Response } from 'express';
import { SessionService } from './session/session.service';

@Controller()
export class AppController {
  @Inject(SessionService)
  private sessionService: SessionService;

  @Get('count')
  async count(@Req() req: Request, @Res({ passthrough: true }) res: Response) {
    // 从请求cookie中获取会话ID
    const sid = req.cookies?.sid;

    // 获取会话数据中的计数值
    const sessionData = await this.sessionService.getSession<{ count: string }>(
      sid,
    );

    // 计算新的计数值：如果存在则加1，不存在则初始化为1
    const currentCount = sessionData?.count
      ? parseInt(sessionData.count) + 1
      : 1;

    // 更新会话数据，保存新的计数值
    const newSid = await this.sessionService.setSession(sid, {
      count: currentCount,
    });

    // 设置新的会话ID到cookie，有效期30分钟
    res.cookie('sid', newSid, { maxAge: 1800 * 1000 }); // 30 分钟过期

    // 返回当前计数值
    return { count: currentCount };
  }
}
```

**关键点**：`@Res({ passthrough: true })` 让 NestJS 允许我们手动设置 Cookie，同时自动处理返回值。

### 第四步：运行与验证
1. 确保 Redis 服务已启动（默认 localhost:6379）。
2. 运行项目：`npm run start:dev`。
3. 用浏览器或 Postman 访问 `http://localhost:3000/count`：
    - 第一次访问，返回 `{"count": 1}`，浏览器会收到一个 `sid` Cookie。
    - 再次访问，返回 `{"count": 2}`，计数依次递增。
    - 这样多次访问后：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1753087599332-45a38f7e-b545-44be-9ef7-bd7754db90c9.png)

4. 用 Redis 客户端查看数据，会有类似 `sid_xxxxxxxx` 的 Hash 键，包含 `count` 字段。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1753087635487-6e994b53-0a89-47d2-a9a7-8068611a725e.png)

## 为什么这套方案好？
1. **分布式支持**：所有服务器都从 Redis 读取 Session 数据，完美适应负载均衡场景。
2. **安全性**：用户数据存储在服务端，服务端可以随时更新或失效 Session。
3. **灵活性**：Redis 支持设置过期时间（TTL），适合管理临时会话。
4. **可扩展**：可以用 Redis 的其他数据结构（如 List、Set）存储更复杂的 Session 数据。

## 小结与扩展
通过 Redis 和 NestJS，我们把传统的 Session 升级成了分布式 Session，解决了单机环境的局限。这种方案兼具 Session 的服务端控制能力和 JWT 的分布式特性，非常适合中大型项目。

想进一步优化？可以试试：

+ 用 UUID 替换简单的 `generateSid`，提高安全性。
+ 集成 Redis Cluster，支持更高的并发和容错。
+ 添加 Session 数据加密，防止敏感信息泄露。
+ 在生产环境中，配置 Redis 密码和 TLS 确保连接安全。

