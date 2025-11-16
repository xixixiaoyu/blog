# 深入 NestJS 核心：从执行上下文到依赖注入

在开发复杂的 NestJS 应用时，你会发现自己总是在处理两大核心问题：**“当前正在发生什么？”** 以及 **“我应该使用哪个工具（服务实例）来处理它？”**。

第一个问题由 **执行上下文（Execution Context）** 来解答。它为你提供了当前操作的全景视图，无论它是一个 HTTP 请求、一个 WebSocket 消息，还是一个微服务调用。

第二个问题则由 **依赖注入作用域（Dependency Injection Scopes）** 来管理。它决定了你的服务（Provider）实例是如何被创建、共享和销毁的，确保在正确的上下文中，你能拿到正确的实例。

这两个概念并非孤立存在，而是紧密相连、相辅相成的。理解它们如何协同工作，是掌握 NestJS 精髓、构建可扩展、高内聚应用的关键。本文将带你深入探索这两个核心机制，并揭示它们之间的联动关系。


## Part 1：管理“处理工具”—— 依赖注入作用域

不同的执行上下文，往往需要不同生命周期的服务实例。例如，一个全局缓存服务应该是单例的，而一个用于追踪单个请求信息的服务则应该随请求创建和销毁。这就是依赖注入作用域的用武之地。

NestJS 提供了三种作用域来精确控制 Provider 的生命周期。

### 1. `Scope.DEFAULT`（单例作用域）

这是默认行为，也是最高效的作用域。

*   **特点**：整个应用共享同一个 Provider 实例。
*   **生命周期**：从应用启动到关闭，与应用同生共死。
*   **适用场景**：无状态的服务、共享资源（如数据库连接池、配置服务、全局缓存）等。绝大多数服务都应该是单例。

```typescript
import { Injectable, Scope } from '@nestjs/common'

@Injectable({ scope: Scope.DEFAULT })
export class UsersService {
  constructor() {
    console.log('UsersService instance created ONCE!')
  }
}
```

### 2. `Scope.REQUEST`（请求作用域）

当需要为每个传入的请求创建一个独立的实例时，使用此作用域。

*   **特点**：每个请求（HTTP, GraphQL 等）都会创建一个全新的服务实例。
*   **生命周期**：仅存在于请求处理期间，请求结束后实例被垃圾回收。
*   **适用场景**：
    *   **请求追踪**：为每个请求生成唯一的追踪 ID。
    *   **按请求缓存**：在请求内部缓存数据，避免重复计算。
    *   **多租户应用**：根据请求头中的租户 ID，提供特定的数据库连接或服务。

```typescript
import { Injectable, Scope } from '@nestjs/common'

@Injectable({ scope: Scope.REQUEST })
export class RequestScopedService {
  private readonly requestData = {}

  constructor() {
    console.log('RequestScopedService instance created for a new request.')
  }
}
```

**注意**：`REQUEST` 作用域具有“传染性”。如果一个单例服务（`A`）注入了一个请求作用域的服务（`B`），那么服务 `A` 会被自动提升为请求作用域，以确保依赖注入的正确性。

### 3. `Scope.TRANSIENT`（瞬态作用域）

瞬态作用域提供了最细粒度的控制，每次注入都会创建一个新实例。

*   **特点**：每次被注入时，都会创建一个全新的、不被共享的实例。
*   **生命周期**：由注入它的消费者管理。如果两个不同的服务都注入了同一个瞬态 Provider，它们将各自获得一个独立的实例。
*   **适用场景**：需要完全隔离、无状态的工具类。

```typescript
import { Injectable, Scope } from '@nestjs/common'

@Injectable({ scope: Scope.TRANSIENT })
export class LoggerService {
  constructor() {
    console.log('A new LoggerService instance is created.')
  }

  log(message: string, context: string) {
    console.log(`[${context}] ${message}`)
  }
}
```

### 如何指定作用域？

你可以在 `@Injectable()` 或 `@Controller()` 装饰器中通过 `scope` 选项来指定作用域：

```typescript
import { Controller, Scope, Get } from '@nestjs/common'

@Controller({ path: 'cats', scope: Scope.REQUEST })
export class CatsController {
  constructor() {
    console.log('CatsController instance created for a new request!')
  }
}
```

对于自定义 Provider，也可以在模块的 `providers` 数组中配置：

```typescript
{
  provide: 'CACHE_MANAGER',
  useClass: CacheManager,
  scope: Scope.TRANSIENT,
}
```

---
## Part 2：理解“正在发生什么”—— 执行上下文与元数据

在编写通用功能（如权限守卫、日志拦截器、异常过滤器）时，你希望它们能跨越不同的应用场景（HTTP, RPC, WebSockets）工作。NestJS 的执行上下文机制正是为此而生。

### `ArgumentsHost`：参数的万能适配器

`ArgumentsHost` 是一个强大的工具，它对不同应用上下文的参数进行了统一封装。你可以在异常过滤器或自定义装饰器中获取到它。

它的核心能力是 **识别并切换上下文**：

```typescript
import { ArgumentsHost } from '@nestjs/common'
import { GqlContextType } from '@nestjs/graphql'

export function inspectContext(host: ArgumentsHost) {
  const contextType = host.getType()

  if (contextType === 'http') {
    const httpContext = host.switchToHttp()
    const request = httpContext.getRequest()
    console.log(`请求路径: ${request.url}`)
  } else if (contextType === 'rpc') {
    const rpcContext = host.switchToRpc()
    const data = rpcContext.getData()
    console.log('正在处理 RPC 调用')
  } else if (contextType === 'ws') {
    const wsContext = host.switchToWs()
    const client = wsContext.getClient()
    console.log('正在处理 WebSocket 消息')
  } else if (host.getType<GqlContextType>() === 'graphql') {
    console.log('正在处理 GraphQL 请求')
  }
}
```

### `ExecutionContext`：执行流程的全景视图

`ExecutionContext` 继承自 `ArgumentsHost`，并提供了更多关于 **当前执行流程** 的信息。它是在守卫（Guard）和拦截器（Interceptor）中最常用的工具。

它增加了两个关键方法：

*   `getClass()`: 返回当前请求正在处理的控制器类（例如 `CatsController`）。
*   `getHandler()`: 返回即将被调用的处理器方法（例如 `create` 方法）。

```typescript
import { ExecutionContext } from '@nestjs/common'

function logCurrentHandler(context: ExecutionContext) {
  const controllerClass = context.getClass()
  const handlerMethod = context.getHandler()

  console.log(`控制器: ${controllerClass.name}`)
  console.log(`处理方法: ${handlerMethod.name}`)
}
```

### 元数据：为上下文附加信息

获取控制器和处理器本身不是目的，真正的目的是读取附加在它们之上的 **元数据（Metadata）**。

**1. 创建元数据装饰器**

```typescript
// src/auth/roles.decorator.ts
import { Reflector } from '@nestjs/core'

export const Roles = Reflector.createDecorator<string[]>()
```

**2. 在控制器中使用**

```typescript
// src/cats/cats.controller.ts
import { Controller, Post } from '@nestjs/common'
import { Roles } from '../auth/roles.decorator'

@Controller('cats')
@Roles(['user'])
export class CatsController {
  @Post()
  @Roles(['admin'])
  async create() {}
}
```

**3. 在守卫中读取元数据**

```typescript
// src/auth/roles.guard.ts
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common'
import { Reflector } from '@nestjs/core'
import { Roles } from './roles.decorator'

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride(Roles, [
      context.getHandler(),
      context.getClass(),
    ])

    if (!requiredRoles) return true

    const { user } = context.switchToHttp().getRequest()
    return requiredRoles.some(role => user?.roles?.includes(role))
  }
}
```

---

## Part 3：强强联合 —— 上下文与作用域的协同工作

理解了执行上下文和作用域之后，我们来看看它们如何协同工作，发挥出 1+1>2 的效果。

### 场景一：在请求作用域服务中访问当前请求

这是最经典的联动场景。只有 `REQUEST` 作用域的 Provider 才能注入 `REQUEST` 令牌，从而访问到当前请求的详细信息。这背后正是执行上下文在发挥作用。

```typescript
import { Injectable, Scope, Inject } from '@nestjs/common';
import { REQUEST } from '@nestjs/core';
import { Request } from 'express';

@Injectable({ scope: Scope.REQUEST })
export class RequestTracerService {
  constructor(@Inject(REQUEST) private request: Request) {
    // 得益于执行上下文，NestJS 知道应该将哪个请求对象注入到这里
  }

  getTraceInfo() {
    return {
      userAgent: this.request.headers['user-agent'],
      userId: this.request.headers['x-user-id'],
      path: this.request.url,
    };
  }
}
```

在 GraphQL 应用中，你需要注入 `CONTEXT` 令牌来达到类似的效果。

### 场景二：在瞬态服务中识别调用者

对于 `TRANSIENT` 作用域的 Provider，有时我们想知道“是谁注入了我？”。通过注入 `INQUIRER` 令牌，你可以获取到消费当前实例的类（即调用者）的信息。

```typescript
import { Injectable, Scope, Inject } from '@nestjs/common';
import { INQUIRER } from '@nestjs/core';

@Injectable({ scope: Scope.TRANSIENT })
export class ContextualLogger {
  private readonly context: string;

  constructor(@Inject(INQUIRER) private parentClass: object) {
    this.context = parentClass?.constructor?.name || 'Unknown';
  }

  log(message: string) {
    console.log(`[${this.context}] ${message}`);
  }
}

// --- 在其他服务中使用 ---
@Injectable()
export class AppService {
  constructor(private logger: ContextualLogger) {}

  doSomething() {
    this.logger.log('Doing something important...'); // 输出: [AppService] Doing something important...
  }
}
```

这使得创建上下文感知的日志服务或工具类变得异常简单。

### 场景三：动态解析上下文感知的实例

在某些高级场景下，你可能不想通过构造函数注入依赖，而是希望在运行时动态地、按需地获取一个 Provider 实例。`ModuleRef` 工具类就是为此而生。

*   `moduleRef.get()`: 用于获取 **单例** 实例。速度快，但不能用于作用域化的 Provider。
*   `moduleRef.resolve()`: 用于获取 **作用域化**（`REQUEST` 或 `TRANSIENT`）的实例。它会为每次调用创建一个新的实例。

而 `resolve()` 最强大的地方在于它的第二个参数：`contextId`。通过传递一个由 `ContextIdFactory` 生成的上下文 ID，你可以精确地获取到 **属于特定请求上下文的那个实例**。

这完美地将执行上下文和依赖注入连接了起来：

```typescript
import { Injectable, Scope, Inject, ModuleRef } from '@nestjs/common';
import { REQUEST, ContextIdFactory } from '@nestjs/core';
import { Request } from 'express';

@Injectable({ scope: Scope.REQUEST })
export class CatsRepository { /* ... */ }

@Injectable()
export class CatsService {
  constructor(private moduleRef: ModuleRef) {}

  async getRepositoryForRequest(request: Request): Promise<CatsRepository> {
    // 1. 根据当前请求对象，创建一个唯一的上下文 ID
    const contextId = ContextIdFactory.getByRequest(request);

    // 2. 使用 ModuleRef 和上下文 ID 来解析出专属于这个请求的 CatsRepository 实例
    // 如果该请求的实例已存在，则返回现有实例；否则，创建一个新实例并缓存
    return await this.moduleRef.resolve(CatsRepository, contextId);
  }
}
```

在这个例子中，我们不再将 `CatsRepository` 直接注入到 `CatsService` 的构造函数中，而是通过 `ModuleRef` 在需要时动态解析。这给予了我们极大的灵活性，可以在一个单例服务中，根据不同的请求上下文，获取到对应的请求作用域实例。

---

## Part 4：性能考量与最佳实践

虽然作用域和上下文提供了巨大的灵活性，但也需要注意其带来的性能影响。

### `REQUEST` 作用域的性能开销

使用 `REQUEST` 作用域的 Provider 会对应用性能产生影响，因为每次请求都需要创建新的实例。官方文档指出，这可能会带来约 **5% 的延迟增加**，在高并发场景下影响可能更甚。因此，应遵循一个基本原则：**除非明确需要请求级别的隔离，否则始终优先使用 `DEFAULT`（单例）作用域**。

### 优化方案：持久化提供者（Durable Providers）

在某些场景下（如多租户应用），你既需要请求隔离，又无法接受高昂的实例创建开销。例如，你希望为每个租户（而不是每个请求）维护一个独立的数据库连接池。

这时，**持久化提供者（Durable Providers）** 就派上了用场。通过将 Provider 标记为 `durable: true`，并提供一个自定义的 `ContextIdStrategy`，你可以让 NestJS 在属于同一个“上下文标识”（如租户 ID）的多个请求之间复用实例。

**1. 定义上下文 ID 策略**

该策略告诉 NestJS 如何从请求中提取上下文标识（例如，从请求头中获取 `x-tenant-id`）。

```typescript
import { ContextIdFactory, ContextIdStrategy } from '@nestjs/core';
import { Request } from 'express';

export class TenantContextIdStrategy implements ContextIdStrategy {
  attach(contextId, request: Request) {
    const tenantId = request.headers['x-tenant-id'] as string;
    // 如果有租户 ID，则根据它创建或复用上下文
    if (tenantId) {
      return ContextIdFactory.createForKey(tenantId);
    }
    // 否则，走默认的请求作用域逻辑
    return contextId;
  }
}
```

**2. 注册策略并标记 Provider**

在应用启动时注册该策略，并将需要持久化的 Provider 标记为 `durable: true`。

```typescript
// main.ts
ContextIdFactory.apply(new TenantContextIdStrategy());

// tenant-specific.service.ts
@Injectable({ scope: Scope.REQUEST, durable: true })
export class TenantSpecificService {
  constructor() {
    // 对于同一个租户，这个构造函数只会被调用一次
    console.log('TenantSpecificService created for a specific tenant.');
  }
}
```

这样，来自同一个租户的请求将共享 `TenantSpecificService` 的同一个实例，极大地降低了开销。

## 总结与最佳实践

1.  **执行上下文是基础**：它是编写通用守卫、拦截器和过滤器的基石，通过 `ExecutionContext` 和 `Reflector` 可以读取请求信息和元数据，做出动态决策。

2.  **作用域决定生命周期**：根据业务需求选择合适的 Provider 作用域。
    *   **优先使用 `DEFAULT`**：为了最佳性能，尽可能使用单例服务。
    *   **谨慎使用 `REQUEST`**：仅在确实需要按请求隔离数据或行为时使用，并注意其“传染性”和性能开销。
    *   **`TRANSIENT` 用于特殊工具**：当你需要一个完全独立、无共享状态的实例时（如上下文日志记录器），它是完美的选择。

3.  **善用上下文与作用域的联动**：
    *   在 `REQUEST` 作用域的服务中注入 `REQUEST` 对象来获取请求信息。
    *   在 `TRANSIENT` 作用域的服务中注入 `INQUIRER` 来识别调用者。

4.  **`ModuleRef` 提供终极灵活性**：当你需要在运行时动态解析依赖，或在一个单例服务中处理请求作用域的实例时，使用 `ModuleRef.resolve()` 配合 `ContextIdFactory` 是最强大的模式。

5.  **性能优化永记心中**：对于高频使用的请求作用域服务，考虑使用 `durable: true` 和自定义上下文策略来优化性能，实现实例在特定范围内的复用。

通过将执行上下文的“全景感知能力”与依赖注入作用域的“精细化实例管理”相结合，你可以构建出真正优雅、健壮且可维护的 NestJS 应用程序。

 

 

 

---

 
