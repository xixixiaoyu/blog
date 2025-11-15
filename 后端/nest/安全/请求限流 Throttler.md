## 速率限制：保护 API 免受滥用

### 为什么需要速率限制？
没有速率限制的 API 容易被恶意用户攻击，比如：

- 暴力破解：尝试大量密码组合。
- DDoS 攻击：通过高频请求瘫痪服务器。
- 资源滥用：恶意爬取数据或占用服务器资源。

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
import { Controller, Get } from '@nestjs/common';
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
    const xff = req.get('X-Forwarded-For');
    req['realIp'] = xff ? xff.split(',')[0].trim() : req.ip;
    next();
  });
  await app.listen(3000);
}
bootstrap();
```

### 最佳实践
- 区分环境：开发环境使用宽松限制，生产环境收紧策略。
- 监控超限请求：记录超出限制的请求，分析潜在攻击。
- 多层防护：结合身份验证、防火墙等，形成全面防御。
