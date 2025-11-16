## 为什么需要 API 版本管理？

想象一下，你发布了一个 API，许多客户端应用都在使用它。随着业务发展，你需要对接口进行升级，比如将 `userName` 字段改名为 `fullName`。如果直接在现有接口上修改，所有依赖旧 `userName` 字段的客户端都会立刻出错。这就是所谓的“破坏性变更”。

API 版本管理的核心目的，就是在不破坏现有客户端的前提下，让 API 能够平滑地演进和迭代。它允许我们同时支持多个版本的 API，引导开发者逐步迁移到新版本，最终再安全地废弃旧版本，从而确保了业务的连续性和稳定性。

## 在 NestJS 中开启版本控制

NestJS 提供了开箱即用的版本控制支持，开启方式非常简单。在 `main.ts` 文件中，通过 `app.enableVersioning()` 方法即可启用。

```typescript
// src/main.ts
import { NestFactory } from '@nestjs/core';
import { VersioningType } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 全局启用版本控制
  app.enableVersioning({
    // 使用 URI 路径作为版本标识，这是最常见和直观的方式
    type: VersioningType.URI,
    // 默认版本，当请求未指定版本时使用
    defaultVersion: '1',
  });

  await app.listen(3000);
}
bootstrap();
```

只需几行代码，NestJS 就具备了版本控制能力。`defaultVersion` 配置非常重要，它为那些尚未适配新版本的旧客户端或简单的测试请求提供了一个兜底方案，保证了向后兼容性。

## 四种核心版本控制策略

NestJS 提供了四种主流的版本控制方式，每种都有其独特的适用场景。

### 1. URI 版本控制（推荐）

这是最直观、最常见的版本控制策略。版本号直接体现在 URL 路径中，例如 `/v1/users`。

**实现方式：**

在控制器中通过 `version` 属性指定版本。

```typescript
// V1 控制器
@Controller({ path: 'users', version: '1' })
export class UsersV1Controller {
  @Get()
  findAll(): string {
    return 'V1 版本的用户列表';
  }
}

// V2 控制器
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

**优缺点分析：**

*   **优点**：简单直观，版本号一目了然，非常便于调试和分享。
*   **缺点**：URL 中包含了版本信息，有人认为这“污染”了资源的统一定位符（URL）。

### 2. 请求头版本控制

通过自定义请求头（如 `X-API-Version`）来传递版本信息，URL 保持不变。

**实现方式：**

在 `main.ts` 中修改版本控制类型，并指定 `header` 名称。

```typescript
app.enableVersioning({
  type: VersioningType.HEADER,
  header: 'X-API-Version',
});
```

控制器代码与 URI 方式相同，只需声明 `version`。

**客户端请求：**

```plain
GET /users
X-API-Version: 1
```

**优缺点分析：**

*   **优点**：URL 简洁，更符合 RESTful 对资源唯一标识的纯粹主义。
*   **缺点**：客户端需要额外配置请求头，调试起来稍显不便，且无法在浏览器地址栏中直接测试特定版本。

### 3. 媒体类型版本控制

将版本信息嵌入 `Accept` 请求头中，与媒体类型（如 `application/json`）结合。

**实现方式：**

在 `main.ts` 中配置 `MEDIA_TYPE` 和用于提取版本的 `key`。

```typescript
app.enableVersioning({
  type: VersioningType.MEDIA_TYPE,
  key: 'v', // 媒体类型参数名
});
```

**客户端请求：**

```plain
GET /users
Accept: application/json;v=1
```

**优缺点分析：**

*   **优点**：严格遵循 RESTful 设计理念，利用了标准的 HTTP 头。
*   **缺点**：客户端调用稍显复杂，需要正确构造 `Accept` 头。

### 4. 自定义版本控制

如果以上策略都无法满足需求，NestJS 允许你实现自定义的版本提取逻辑，例如从查询参数中获取。

**实现方式：**

在 `main.ts` 中提供一个 `extractor` 函数。

```typescript
app.enableVersioning({
  type: VersioningType.CUSTOM,
  extractor: (request) => request.query.version || '1', // 从查询参数 'version' 中提取
});
```

**客户端请求：**

```plain
GET /users?version=1
```

## 灵活的版本指定方式

NestJS 提供了多种粒度来为控制器或路由指定版本。

### 控制器级别版本

为整个控制器指定版本，其下所有路由都将继承此版本。

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

使用 `@Version()` 装饰器为单个路由指定版本，这会覆盖控制器级别的设置。

```typescript
@Controller({ path: 'cats', version: '1' })
export class CatsController {
  @Get()
  findAllV1(): string {
    return 'V1 版本的猫咪列表';
  }

  @Get()
  @Version('2') // 此路由属于 V2
  findAllV2(): string {
    return 'V2 版本的猫咪列表';
  }
}
```

### 多版本支持

一个接口可以同时支持多个版本，以减少代码重复。

```typescript
@Controller({ path: 'dogs' })
export class DogsController {
  @Get()
  @Version(['1', '2']) // 同时支持 V1 和 V2
  findAll(): string {
    return '兼容 V1 和 V2 版本的狗狗列表';
  }
}
```

### 版本中立

对于某些通用接口（如健康检查），可以将其设置为版本中立，使其不受版本控制影响。

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

任何版本的请求路径（或不含版本路径）都可以访问到 `/health`。

## 中间件的版本控制

NestJS 甚至支持为中间件绑定特定版本，实现更精细的控制。例如，可以只对 V2 版本的请求应用某个中间件。

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
        version: '2', // 只对 V2 的 GET /cats 请求应用此中间件
      });
  }
}
```

## 最佳实践与建议

1.  **谨慎引入破坏性变更**：只有当必须进行不兼容的修改时（如删除字段、改变数据类型）才引入新版本。单纯增加字段或新增接口通常不需要升级版本。
2.  **合理组织代码结构**：为不同版本创建独立的控制器文件（如 `users-v1.controller.ts`），或在同一控制器内使用 `@Version()` 装饰器进行细粒度控制，保持代码清晰。
3.  **明确的弃用策略**：当旧版本准备废弃时，不要立即删除。应通过文档、响应头（如 `Deprecation: true`）或 API 响应中的警告信息，提前通知开发者，并给出明确的迁移时间表。
4.  **版本命名规范**：推荐使用简单的整数版本号，如 `v1`, `v2`。这比语义化版本（`v1.0.1`）更适合 API 的重大兼容性变更。
5.  **文档先行**：每次发布新版本时，务必更新 API 文档（如 Swagger），清晰说明新旧版本之间的差异、支持状态和迁移指南。
6.  **监控与日志**：为不同版本的接口添加独立的监控和日志，跟踪其使用情况。这有助于判断哪些版本仍在活跃使用，何时可以安全下线。
7.  **自动化测试**：为每个版本的 API 都编写自动化测试用例，确保新功能的迭代不会意外破坏旧版本的兼容性。

## 总结

API 版本管理是构建健壮、可维护的长期服务的基石。NestJS 提供了灵活且强大的工具集，帮助开发者轻松实现多版本共存。通过选择合适的版本策略、合理组织代码并遵循最佳实践，你可以在保证 API 平滑演进的同时，维持代码库的整洁与高效。
