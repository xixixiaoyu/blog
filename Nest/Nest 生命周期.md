先思考一下：一个应用的生命周期，本质上是什么？

你可以把它想象成一个“人”的一生：**诞生 -> 成长 -> 运行 -> 落幕**。NestJS 应用也是如此，它有一套精心设计的机制来管理这个过程，而“生命周期钩子”就是让我们在这些关键时刻介入的“接口”。

---

### 应用的三个生命阶段

一个 NestJS 应用的生命周期主要分为三个阶段：

1.  **初始化阶段 (Initializing)**：这是应用的"婴儿期"。Nest 开始启动时，会依次加载你定义的各个模块，解析它们之间的依赖关系，并完成运行前的各种准备工作。就像搭积木一样，每个模块都需要找到自己的位置，确保所有依赖都能正确连接。

2.  **运行阶段 (Running)**：所有准备工作完成后，应用开始监听指定端口，接收并处理来自客户端的请求。这是应用真正发挥价值的时间，也是我们最关心的业务逻辑执行阶段。

3.  **终止阶段 (Terminating)**：当应用收到关闭信号时（比如你按下 `Ctrl+C`，或者 Docker 容器收到 `SIGTERM` 信号），它会进入"退休"状态。这时需要优雅地处理正在进行的请求，关闭数据库连接，释放占用的资源，然后彻底退出。

我们主要关注的是 **初始化** 和 **终止** 这两个阶段，因为 NestJS 提供了明确的钩子让我们执行代码。

---

### 核心生命周期钩子详解

NestJS 提供了几个关键的接口，我们称之为“生命周期钩子接口”。当你的类（通常是 `Provider`、`Controller` 或 `Module`）实现这些接口时，NestJS 会在相应的时机自动调用你定义的方法。

让我们按执行顺序来看看它们：

#### 1. `OnModuleInit`

这个接口有一个方法：`onModuleInit()`。

*   **触发时机**：在所有模块的依赖注入都完成之后，但在应用开始监听外部请求之前。
*   **核心用途**：执行那些需要依赖其他服务的初始化逻辑。比如，连接数据库、预热缓存、读取配置文件等。此时，你可以确保所有通过 `constructor` 注入的依赖都已准备就绪。

#### 2. `OnApplicationBootstrap`

这个接口有一个方法：`onApplicationBootstrap()`。

*   **触发时机**：在所有模块的 `onModuleInit` 都执行完成，但在应用真正开始监听端口之前。这是整个应用层面的"万事俱备"时刻。
*   **核心用途**：执行那些需要整个应用完全就绪后才能进行的操作。比如，启动一个定时任务、或者发布一个“服务已就绪”的事件。

> **启发式提问**：你可能会问，`OnModuleInit` 和 `OnApplicationBootstrap` 看起来很相似，它们到底有什么区别呢？
>
> 想象一下：`OnModuleInit` 就像是“每个班级（模块）的老师在上课前，检查一下自己的学生（依赖）都到齐了没”。而 `OnApplicationBootstrap` 则像是“全校（整个应用）的广播，通知所有人‘开学典礼现在开始’”。前者是模块级别的就绪确认，后者是应用级别的就绪确认。

#### 3. `OnModuleDestroy`

这个接口有一个方法：`onModuleDestroy()`。

*   **触发时机**：在应用接收到关闭信号（例如 `SIGTERM`）后，在依赖注入容器被销毁之前。
*   **核心用途**：执行模块级别的清理工作。比如，关闭数据库连接、停止某个正在运行的后台任务。这是你清理模块特定资源的第一个机会。

#### 4. `BeforeApplicationShutdown`

这个接口有一个方法：`beforeApplicationShutdown(signal?: string)`。

*   **触发时机**：在所有模块的 `onModuleDestroy` 执行完毕后。这个方法会接收一个 `signal` 参数（如 `'SIGTERM'`），让你知道是什么信号触发了关闭。
*   **核心用途**：执行一些应用级别的、需要最后处理的清理逻辑。比如，向监控系统发送“应用下线”通知。执行完成后，Nest 会开始关闭所有现有的网络连接。

#### 5. `OnApplicationShutdown`

这个接口有一个方法：`onApplicationShutdown(signal?: string)`。

*   **触发时机**：当所有网络连接都成功关闭后 (`beforeApplicationShutdown` 完成后)。
*   **核心用途**：这是进行最后清理工作的地方。

#### 总结

| 钩子接口 | 触发时机 | 典型用途 |
| :--- | :--- | :--- |
| `OnModuleInit` | 依赖注入完成后，`app.listen()` 前 | 初始化模块内部依赖（如数据库连接） |
| `OnApplicationBootstrap` | 所有 `OnModuleInit` 完成后，`app.listen()` 前 | 启动需要整个应用就绪的任务（如定时任务） |
| `OnModuleDestroy` | 收到关闭信号后，DI 容器销毁前 | 清理模块级别的资源（如断开连接） |
| `BeforeApplicationShutdown` | `OnModuleDestroy` 之后，网络连接关闭前 | 执行应用级别的最后清理（如发送下线通知） |
| `OnApplicationShutdown` | 所有网络连接关闭后 | 执行最终的、无网络依赖的清理工作 |

---

### 异步操作与执行顺序

生命周期钩子完全支持异步操作。如果你的初始化或清理工作需要时间（比如从数据库加载配置），可以使用 `async/await` 或返回 `Promise`。Nest 会耐心等待所有异步操作完成，然后再继续执行后续的生命周期步骤。

```typescript
import { Injectable, OnModuleInit } from '@nestjs/common';

@Injectable()
export class CacheService implements OnModuleInit {
  async onModuleInit(): Promise<void> {
    console.log('开始预热缓存...');
    await this.preloadCache();
    console.log('缓存预热完成！');
  }

  private async preloadCache(): Promise<void> {
    // 模拟异步加载数据
    return new Promise(resolve => {
      setTimeout(() => {
        console.log('缓存数据加载完成');
        resolve();
      }, 1000);
    });
  }
}
```

#### 完整执行流程

生命周期钩子的执行顺序是固定的：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1686403694240-afb57f64-8f8e-43b8-a39e-20609056ca8e.png)

1.  **启动时**：`onModuleInit` → `onApplicationBootstrap`
2.  **关闭时**：`onModuleDestroy` → `beforeApplicationShutdown` → `onApplicationShutdown`

---

### 实现优雅关闭 (Graceful Shutdown)

在现代部署环境中，优雅关闭是一个重要特性。当平台需要停止或重启应用时，它们会发送关闭信号，给应用一个"收拾行李"的机会。

#### 启用关闭钩子监听

默认情况下，Nest 不会监听系统关闭信号。你需要在 `main.ts` 中手动开启：

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 开启对系统关闭信号的监听
  app.enableShutdownHooks();

  await app.listen(process.env.PORT ?? 3000);
  console.log(`应用已启动，运行在: ${await app.getUrl()}`);
}
bootstrap();
```

启用后，当应用收到 `SIGINT` (Ctrl+C), `SIGTERM` 等信号时，就会依次触发 `OnModuleDestroy`, `BeforeApplicationShutdown`, `OnApplicationShutdown` 这些关闭钩子。

---

### 一个完整的例子

为了让你更直观地感受这个流程，我们来创建一个简单的例子，包含一个模块、一个服务和一个控制器，并让它们都实现这些钩子。

**`app.module.ts`**

```typescript
import { Module, OnModuleInit, OnApplicationBootstrap, OnModuleDestroy, BeforeApplicationShutdown, OnApplicationShutdown } from '@nestjs/common'
import { AppController } from './app.controller'
import { AppService } from './app.service'

@Module({
  imports: [],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule implements OnModuleInit, OnApplicationBootstrap, OnModuleDestroy, BeforeApplicationShutdown, OnApplicationShutdown {
  onModuleInit() {
    console.log('[AppModule] OnModuleInit: 模块初始化')
  }

  onApplicationBootstrap() {
    console.log('[AppModule] OnApplicationBootstrap: 应用已就绪')
  }

  onModuleDestroy() {
    console.log('[AppModule] OnModuleDestroy: 模块即将被销毁')
  }

  beforeApplicationShutdown(signal: string) {
    console.log(`[AppModule] BeforeApplicationShutdown: 应用即将关闭 (信号: ${signal})`)
  }
  
  onApplicationShutdown(signal: string) {
    console.log(`[AppModule] OnApplicationShutdown: 应用已关闭 (信号: ${signal})`)
  }
}
```

**`app.service.ts`**

```typescript
import { Injectable, OnModuleInit, OnApplicationBootstrap, OnModuleDestroy, BeforeApplicationShutdown } from '@nestjs/common'

@Injectable()
export class AppService implements OnModuleInit, OnApplicationBootstrap, OnModuleDestroy, BeforeApplicationShutdown {
  constructor() {
    console.log('[AppService] Constructor: 服务实例化')
  }

  onModuleInit() {
    console.log('[AppService] OnModuleInit: 服务初始化')
  }

  onApplicationBootstrap() {
    console.log('[AppService] OnApplicationBootstrap: 服务已就绪')
  }

  onModuleDestroy() {
    console.log('[AppService] OnModuleDestroy: 服务销毁')
  }

  beforeApplicationShutdown(signal: string) {
    console.log(`[AppService] BeforeApplicationShutdown: 服务即将关闭 (信号: ${signal})`)
  }
}
```

**`app.controller.ts`**

```typescript
import { Controller, Get, OnModuleInit, OnApplicationBootstrap, OnModuleDestroy, BeforeApplicationShutdown } from '@nestjs/common'

@Controller()
export class AppController implements OnModuleInit, OnApplicationBootstrap, OnModuleDestroy, BeforeApplicationShutdown {
  constructor() {
    console.log('[AppController] Constructor: 控制器实例化')
  }

  onModuleInit() {
    console.log('[AppController] OnModuleInit: 控制器初始化')
  }

  onApplicationBootstrap() {
    console.log('[AppController] OnApplicationBootstrap: 控制器已就绪')
  }

  onModuleDestroy() {
    console.log('[AppController] OnModuleDestroy: 控制器销毁')
  }

  beforeApplicationShutdown(signal: string) {
    console.log(`[AppController] BeforeApplicationShutdown: 控制器即将关闭 (信号: ${signal})`)
  }

  @Get()
  getHello(): string {
    return 'Hello World!'
  }
}
```

现在，当你运行 `npm run start:dev` 然后按下 `Ctrl+C` 时，你会看到如下的日志输出：

**启动时：**

```
[AppService] Constructor: 服务实例化
[AppController] Constructor: 控制器实例化
[AppService] OnModuleInit: 服务初始化
[AppController] OnModuleInit: 控制器初始化
[AppModule] OnModuleInit: 模块初始化
[AppService] OnApplicationBootstrap: 服务已就绪
[AppController] OnApplicationBootstrap: 控制器已就绪
[AppModule] OnApplicationBootstrap: 应用已就绪
[Nest] INFO ...
Application is running on: http://localhost:3000
```

**关闭时 (`Ctrl+C`)：**

```
[AppModule] BeforeApplicationShutdown: 应用即将关闭 (信号: SIGINT)
[AppService] BeforeApplicationShutdown: 服务即将关闭 (信号: SIGINT)
[AppController] BeforeApplicationShutdown: 控制器即将关闭 (信号: SIGINT)
[AppModule] OnModuleDestroy: 模块即将被销毁
[AppService] OnModuleDestroy: 服务销毁
[AppController] OnModuleDestroy: 控制器销毁
[AppModule] OnApplicationShutdown: 应用已关闭 (信号: SIGINT)
```

---

### 实际应用场景

#### 数据库连接管理

```typescript
import { Injectable, OnModuleInit, OnApplicationShutdown } from '@nestjs/common';

@Injectable()
export class DatabaseService implements OnModuleInit, OnApplicationShutdown {
  private connection: any;

  async onModuleInit() {
    // this.connection = await createDatabaseConnection();
    console.log('数据库连接已建立');
  }

  async onApplicationShutdown() {
    if (this.connection) {
      // await this.connection.close();
      console.log('数据库连接已关闭');
    }
  }
}
```

#### 缓存预热

```typescript
import { Injectable, OnModuleInit } from '@nestjs/common';

@Injectable()
export class CacheService implements OnModuleInit {
  private cache = new Map();

  async onModuleInit() {
    await this.preloadFrequentlyUsedData();
    console.log('缓存预热完成');
  }

  private async preloadFrequentlyUsedData() {
    // 从数据库加载常用数据到缓存
    // const data = await this.fetchFrequentData();
    // data.forEach(item => {
    //   this.cache.set(item.key, item.value);
    // });
  }
}
```

---

### 注意事项和最佳实践

*   **请求范围的限制**：这些生命周期钩子在请求范围（request-scoped）的类上是有效的，但行为与单例作用域不同：请求范围的类会在每次请求创建实例时执行其生命周期方法（例如 `onModuleInit` 在该实例被创建时触发），而不是在应用启动时统一触发。请求结束后，请求范围实例随即被销毁，拥有独立的生命周期。
*   **平台兼容性**：Windows 系统对信号的支持有限。`SIGINT`（Ctrl+C）通常没问题，但 `SIGTERM` 可能无法被正确捕获。这是操作系统的限制，在部署时需要考虑。
*   **资源管理**：`enableShutdownHooks()` 会启动额外的监听器，消耗少量系统资源。如果在同一个进程中运行多个 Nest 应用实例（比如测试环境），可能会遇到监听器数量警告。

掌握这些生命周期钩子，就如同掌握了应用的“呼吸”与“心跳”。你可以在最恰当的时机，做最恰当的事，让你的 NestJS 应用运行得更加优雅和稳定。
