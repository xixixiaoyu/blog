在开发 API 时，随着业务需求变化和技术进步，接口版本的更新不可避免。新版本可能会引入不兼容的改动，但老版本的接口又不能直接下线，因为还有用户和客户端依赖它们。如何在不增加过多维护成本的情况下，让新老版本的接口和谐共存？这就需要一套高效的 API 版本管理策略。

## 为什么需要 API 版本管理？
想象一下，你的应用上线了第一个版本（V1），运行得非常顺利。但随着时间推移，业务需求变化，可能需要调整接口逻辑、数据结构，甚至完全重构某些功能。如果直接修改现有接口，老用户可能会遇到问题，比如客户端崩溃或数据解析错误。而维护多套独立的服务又会大幅增加开发和部署成本。

API 版本管理就像一座桥梁，让同一个应用能够同时支持多个版本的接口，既满足新用户的需求，又保证老用户的体验。它通过在代码中明确区分版本，确保不同版本的逻辑互不干扰，同时保持代码的可维护性。

## 在 NestJS 中开启版本控制
NestJS 提供了开箱即用的版本控制支持，开启方式非常简单。在 `main.ts` 文件中，通过 `enableVersioning` 方法即可启用：

```typescript
import { NestFactory } from '@nestjs/core';
import { VersioningType } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableVersioning({
    type: VersioningType.URI, // 使用 URI 版本控制
  });
  await app.listen(3000);
}
bootstrap();
```

只需这一行代码，NestJS 就支持了版本控制，接下来可以根据需求选择合适的版本控制策略。

## 四种版本控制策略
NestJS 提供了四种主流的版本控制方式，每种都有自己的适用场景。以下是它们的详细介绍：

### 1. URI 版本控制（推荐）
这是最直观的方式，也是 NestJS 默认的版本控制策略。版本号直接体现在 URL 路径中，比如 `/v1/users` 表示 V1 版本的接口，`/v2/users` 表示 V2 版本。

**实现方式：**

在控制器中指定版本：

```typescript
import { Controller, Get, Version } from '@nestjs/common';

@Controller({ path: 'users', version: '1' })
export class UsersV1Controller {
  @Get()
  findAll(): string {
    return 'V1 版本的用户列表';
  }
}

@Controller({ path: 'users', version: '2' })
export class UsersV2Controller {
  @Get()
  findAll(): string {
    return 'V2 版本的用户列表，增加了新字段';
  }
}
```

**客户端请求：**

```plain
GET /v1/users  // 返回 V1 版本的数据
GET /v2/users  // 返回 V2 版本的数据
```

**优点：**

+ 简单直观，版本号一目了然。
+ 客户端无需额外配置，URL 即表明版本。

**适用场景：**

+ 面向外部开发者的公开 API。
+ 需要清晰区分版本的场景。

### 2. 请求头版本控制
通过自定义请求头传递版本信息，URL 保持不变。这种方式适合希望 URL 简洁的场景。

**实现方式：**

在 `main.ts` 中启用请求头版本控制：

```typescript
app.enableVersioning({
  type: VersioningType.HEADER,
  header: 'X-API-Version',
});
```

控制器代码与 URI 版本控制类似，只需指定版本号：

```typescript
@Controller({ path: 'users', version: '1' })
export class UsersV1Controller {
  @Get()
  findAll(): string {
    return 'V1 版本的用户列表';
  }
}
```

**客户端请求：**

```plain
GET /users
X-API-Version: 1
```

**优点：**

+ URL 简洁，不因版本变化而改变。
+ 适合内部系统或对 URL 美观度有要求的场景。

**缺点：**

+ 客户端需要额外设置请求头，增加了调用复杂度。

### 3. 媒体类型版本控制
将版本信息嵌入到 `Accept` 请求头中，通常与媒体类型（如 JSON）结合使用。

**实现方式：**

在 `main.ts` 中启用：

```typescript
app.enableVersioning({
  type: VersioningType.MEDIA_TYPE,
  key: 'v=',
});
```

**客户端请求：**

```plain
GET /users
Accept: application/json;v=1
```

**优点：**

+ 符合 RESTful 设计理念，利用标准的 HTTP 头。
+ URL 保持简洁。

**缺点：**

+ 客户端需要了解媒体类型版本的格式，调用稍复杂。

### 4. 自定义版本控制
如果以上方式都无法满足需求，NestJS 允许自定义版本提取逻辑。例如，可以从查询参数或其他请求元数据中提取版本号。

**实现方式：**

在 `main.ts` 中定义自定义提取逻辑：

```typescript
app.enableVersioning({
  type: VersioningType.CUSTOM,
  extractor: (request) => request.query.version || '1',
});
```

**客户端请求：**

```plain
GET /users?version=1
```

**适用场景：**

+ 特殊场景，比如版本信息需要从非标准位置提取。

## 灵活的版本指定方式
NestJS 提供了多种方式为控制器或路由指定版本，满足不同粒度的需求。

### 控制器级别版本
为整个控制器指定版本，所有路由共享同一版本：

```typescript
@Controller({ path: 'cats', version: '1' })
export class CatsV1Controller {
  @Get()
  findAll(): string {
    return 'V1 版本的猫咪列表';
  }
}
```

### 路由级别版本
为单个路由指定版本，覆盖控制器级别的设置：

```typescript
@Controller({ path: 'cats', version: '1' })
export class CatsController {
  @Get()
  @Version('2') // 覆盖控制器版本
  findAll(): string {
    return 'V2 版本的猫咪列表';
  }
}
```

**客户端请求：**

```plain
GET /v2/cats  // 返回 V2 版本数据
GET /v1/cats  // 返回 V1 版本数据（如果有其他路由）
```

### 多版本支持
一个接口可以同时支持多个版本，减少重复代码：

```typescript
@Controller({ path: 'cats', version: ['1', '2'] })
export class CatsController {
  @Get()
  findAll(): string {
    return '兼容 V1 和 V2 版本的接口';
  }
}
```

**客户端请求：**

```plain
GET /v1/cats  // 有效
GET /v2/cats  // 有效
```

### 版本中立
某些接口（如健康检查）无需区分版本，可以使用 `VERSION_NEUTRAL`：

```typescript
import { Controller, Get, VERSION_NEUTRAL } from '@nestjs/common';

@Controller({ path: 'health', version: VERSION_NEUTRAL })
export class HealthController {
  @Get()
  check(): string {
    return '健康检查接口，不区分版本';
  }
}
```

**客户端请求：**

```plain
GET /health  // 任何版本都有效
```

## 设置全局默认版本
为了避免为每个控制器重复指定版本，可以设置全局默认版本：

```typescript
app.enableVersioning({
  type: VersioningType.URI,
  defaultVersion: '1',
});
```

未指定版本的控制器将默认使用 V1 版本：

```typescript
@Controller('dogs')
export class DogsController {
  @Get()
  findAll(): string {
    return '默认 V1 版本的狗狗列表';
  }
}
```

**客户端请求：**

```plain
GET /v1/dogs  // 默认版本
```

## 中间件的版本控制
NestJS 甚至支持为中间件指定版本，实现更精细的控制。例如，只对 V2 版本的请求应用日志中间件：

```typescript
import { Module, NestModule, MiddlewareConsumer, RequestMethod } from '@nestjs/common';
import { LoggerMiddleware } from './logger.middleware';

@Module({})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(LoggerMiddleware)
      .forRoutes({ 
        path: 'cats', 
        method: RequestMethod.GET, 
        version: '2',
      });
  }
}
```

**效果：**  
只有 `GET /v2/cats` 的请求会触发 `LoggerMiddleware`。

## 实践建议
以下是一些在实际开发中实施 API 版本管理的建议，帮助你更高效地管理多版本接口：

1. **选择合适的版本控制策略**  
    - URI 版本控制最直观，适合公开 API 和大多数场景。  
    - 请求头版本控制适合需要保持 URL 简洁的内部系统。  
    - 媒体类型版本控制适合严格遵循 RESTful 规范的项目。  
    - 自定义版本控制适合特殊需求，但尽量避免过于复杂的设计。
2. **合理组织代码结构**  
为不同版本创建独立的控制器文件，例如 `cats-v1.controller.ts` 和 `cats-v2.controller.ts`。这不仅让代码更清晰，还便于维护和调试。
3. **善用版本中立**  
将不随版本变化的通用逻辑（如健康检查、静态资源）放在 `VERSION_NEUTRAL` 控制器中，减少重复代码。
4. **渐进式迁移**  
新版本发布后，保留旧版本一段时间，给用户充分的迁移时间。可以通过文档或通知引导用户升级。
5. **文档同步**  
确保 API 文档清晰标注每个版本的接口差异、支持状态和废弃计划。可以使用工具如 Swagger（@nestjs/swagger）自动生成版本化的文档。
6. **监控和日志**  
为不同版本的接口添加监控和日志，跟踪使用情况。这有助于了解哪些版本仍在活跃使用，哪些可以安全下线。
7. **自动化测试**  
为每个版本的接口编写自动化测试用例，确保新版本上线不会破坏旧版本的兼容性。

## 总结
API 版本管理是现代应用开发中不可或缺的一部分。NestJS 提供了灵活且强大的工具，帮助开发者轻松实现多版本共存。通过选择合适的版本控制策略、合理组织代码、善用版本中立和全局默认版本，你可以在保持代码简洁的同时，满足不同用户的需求。

