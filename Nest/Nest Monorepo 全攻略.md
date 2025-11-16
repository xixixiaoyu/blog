# NestJS Monorepo 全攻略：从独立应用到企业级架构

随着业务复杂度的提升和微服务架构的普及，管理数十个分散的 Git 仓库成了一项艰巨的任务。代码复用困难、依赖版本不一致、项目间协作成本高等问题日益凸显。此时，Monorepo（单一代码库）模式便成为解决这些挑战的优雅方案。

本文将带你深入理解 NestJS 中的 Monorepo 架构，从它的必要性讲起，一步步教你如何创建、管理和维护一个企业级的 Monorepo 项目，并结合独立应用（Standalone Application）的场景，让你全面掌握 NestJS 的强大能力。

## 一、为什么需要 Monorepo？

当你的团队维护多个 NestJS 服务时，很可能会遇到以下场景：

![多个独立仓库](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1710043137870-fd2a1d19-c42c-4aeb-8b6d-1cc3939714d5.jpeg)

每个项目都是一个独立的 Git 仓库，这带来了诸多不便：

*   **代码共享困难**：通用的认证逻辑、数据库模块、工具函数需要在不同仓库间复制粘贴或发布为私有 NPM 包，维护成本极高。
*   **依赖管理混乱**：每个项目都有自己的 `package.json`，很容易出现依赖版本冲突。
*   **原子提交缺失**：一个功能的修改可能涉及多个服务，需要跨仓库提交，难以保证版本一致性和原子性。

Monorepo 模式将所有相关项目都放在一个 Git 仓库中进行管理，从根本上解决了这些问题。

![Monorepo 结构](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1710043309038-0369d007-3129-4729-9f84-148279ceda79.jpeg)

这种方式简化了代码共享和依赖管理，特别适合管理多个相关的微服务。

## 二、项目架构的进化：从标准模式到 Monorepo

NestJS 项目主要有两种模式：

*   **标准模式 (Standard Mode)**：通过 `nest new my-project` 创建的项目，相当于一栋“独立别墅”。它有自己的 `package.json`、配置文件，适合小型独立项目。
*   **Monorepo 模式 (Monorepo Mode)**：像一个“社区”，多个项目（应用和库）共享同一个代码仓库，统一管理依赖和配置，极大提升代码复用和协作效率。

### 无痛升级到 Monorepo

如果你已经有一个标准模式的项目，升级到 Monorepo 非常简单。假设你的项目名为 `monorepo-test`：

1.  **创建或进入项目目录**：
    ```bash
    nest new monorepo-test
    cd monorepo-test
    ```

2.  **生成一个新应用**：
    ```bash
    nest g app app2
    ```

执行完第二步后，Nest CLI 会自动将你的项目结构从标准模式转换为 Monorepo 模式。

### Monorepo 结构解析

转换后，你的目录结构会发生如下变化：

*   原有的 `src` 和 `test` 目录被移除。
*   新增一个 `apps` 目录，你原有的项目 `monorepo-test` 和新创建的 `app2` 都会被移动到这里。
*   根目录会有一个顶层的 `package.json` 和 `tsconfig.json`。

```plain
monorepo-test/
├── apps/
│   ├── monorepo-test/  # 原有项目
│   │   ├── src/
│   │   └── main.ts
│   └── app2/           # 新增应用
│       ├── src/
│       └── main.ts
├── libs/               # 共享库（初始为空）
├── package.json        # 顶层依赖管理
├── nest-cli.json       # Monorepo 配置文件
└── tsconfig.json       # 顶层 TypeScript 配置
```

`nest-cli.json` 文件也随之更新，成为了管理整个 Monorepo 的核心：

![nest-cli.json 变化](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693745248719-145beee9-18f8-433c-acf5-347a3aa7f7dd.png)

`projects` 字段下记录了所有应用（application）和库（library）的元信息，如根目录、源码路径、配置文件等。`sourceRoot` 和 `root` 则指向默认项目。

### 运行和构建 Monorepo 中的应用

*   **运行默认应用**：
    ```bash
    npm run start:dev
    ```
    这会启动 `nest-cli.json` 中 `root` 字段指定的默认项目。

*   **运行指定应用**：
    ```bash
    npm run start:dev app2
    ```
    Nest CLI 会根据你提供的应用名称 (`app2`)，找到对应的配置并启动它。

*   **构建应用**：
    ```bash
    # 构建默认应用
    npm run build

    # 构建指定应用
    npm run build app2
    ```

## 三、Monorepo 的核心：共享库 (Library)

Monorepo 的最大价值在于代码共享，而这正是通过库（Library）实现的。库是可复用的模块，不能独立运行，专为代码共享而设计。

### 1. 创建共享库

假设我们要创建一个名为 `lib1` 的共享库：

```bash
nest g lib lib1
```

CLI 默认使用 `@app` 作为路径别名前缀，并在 `tsconfig.json` 中写入 `paths` 映射。这个前缀将用于在应用中导入库。

创建成功后，`libs` 目录下会生成 `lib1` 的代码结构，并且 `nest-cli.json` 和 `tsconfig.json` 会自动更新。

`tsconfig.json` 中会增加一条 `paths` 映射：

![tsconfig.json paths](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693745540453-18379d6c-c6de-45c7-bbbc-fd69bb3735a7.png)

这使得你可以用 `@app/lib1` 这样清晰的路径来导入库中的模块，而无需使用繁琐的相对路径 `../../libs/lib1/src`。

### 2. 在应用中使用共享库

现在，我们可以在 `monorepo-test` 和 `app2` 这两个应用中同时使用 `lib1`。

首先，在 `lib1` 的 service (`libs/lib1/src/lib1.service.ts`) 中添加一个方法：

```typescript
import { Injectable } from '@nestjs/common';

@Injectable()
export class Lib1Service {
  getMessage(): string {
    return 'This is a shared method from lib1!';
  }
}
```

然后，在 `monorepo-test` 应用中导入并使用它：

1.  **注册 `Lib1Module`**：
    在 `apps/monorepo-test/src/app.module.ts` 中导入 `Lib1Module`。

    ```typescript
    import { Module } from '@nestjs/common';
    import { AppController } from './app.controller';
    import { AppService } from './app.service';
    import { Lib1Module } from '@app/lib1'; // <-- 导入共享库

    @Module({
      imports: [Lib1Module], // <-- 注册
      controllers: [AppController],
      providers: [AppService],
    })
    export class AppModule {}
    ```

2.  **注入 `Lib1Service`**：
    在 `apps/monorepo-test/src/app.controller.ts` 中注入 `Lib1Service` 并调用其方法。

    ```typescript
    import { Controller, Get } from '@nestjs/common';
    import { Lib1Service } from '@app/lib1'; // <-- 导入 Service

    @Controller()
    export class AppController {
      constructor(private readonly lib1Service: Lib1Service) {} // <-- 注入

  @Get()
  getHello(): string {
    return this.lib1Service.getMessage(); // <-- 调用
  }
}
    ```

同样的操作也可以在 `app2` 中重复一遍。这样，`lib1` 中的逻辑就被两个应用轻松复用了。

### 3. 并行构建

当项目增多时，可以使用 `npm-run-all` 这样的工具来并行构建所有应用和库，提升效率。

```json
// package.json
{
  "scripts": {
    "build": "npm-run-all --parallel build:*",
    "build:main": "nest build monorepo-test",
    "build:app2": "nest build app2",
    "build:lib1": "nest build lib1"
  }
}
```

## 四、NestJS 的另一面：独立应用 (Standalone Application)

除了标准的 Web 服务，NestJS 还支持一种特殊的应用形态——独立应用。

### 1. 什么是独立应用？

想象一个场景：你需要写一个脚本，每天凌晨自动清理数据库中的过期数据；或者在项目上线前，跑一个数据迁移脚本。这些任务不需要监听网络端口，也不处理 HTTP 请求，但你又想复用 NestJS 的模块化组织、依赖注入等强大特性。这时候，独立应用就派上用场了。

独立应用就像一辆没有“车门”的汽车：引擎（Nest 的核心 IoC 容器）照常运转，内部组件（服务、模块等）一应俱全，但它不对外开放网络接口。你可以直接调用内部的服务逻辑，完成特定任务。

### 2. 快速上手独立应用

创建独立应用非常简单，只需将 `NestFactory.create()` 换成 `NestFactory.createApplicationContext()`：

```typescript
// a-script.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { TasksService } from './tasks.service';

async function runScript() {
  // 1. 创建应用上下文，而不是 HTTP 服务
  const app = await NestFactory.createApplicationContext(AppModule);
  
  // 2. 获取服务实例
  const tasksService = app.get(TasksService);
  
  // 3. 调用服务方法
  await tasksService.runDailyTask();
  
  // 4. 优雅退出
  await app.close();
}

runScript();
```

`createApplicationContext` 创建了一个 Nest 的 IoC 容器，加载了 `AppModule` 及其所有依赖。你可以用 `app.get()` 直接获取任何注册在模块中的服务实例。

**注意事项**：

*   **无 HTTP 特性**：独立应用没有网络环境，所以像中间件（Middleware）、守卫（Guards）、拦截器（Interceptors）这些依赖 HTTP 请求的功能都不可用。
*   **优雅退出**：任务完成后，务必调用 `app.close()`。这会触发 Nest 的生命周期钩子（如 `onModuleDestroy`），确保数据库连接等资源被正确清理。

## 五、总结与最佳实践

从一个简单的 `nest new` 到一个容纳多个应用和库的代码王国，NestJS 提供了一套优雅且高效的解决方案。

*   **Monorepo 模式**通过共享库和统一配置，完美解决了多项目开发的痛点，是构建企业级微服务架构的理想选择。
*   **独立应用**则让你能够复用 Nest 的模块化和依赖注入特性，轻松编写各类脚本和定时任务。

**最佳实践建议**：

*   **按功能划分库**：比如 `libs/auth`、`libs/database`、`libs/common`。
*   **保持应用独立**：每个 `apps/` 下的应用都应该是可独立部署的单元。
*   **统一配置**：在根目录管理共享的 `eslint`、`prettier`、`tsconfig` 等配置，确保代码风格一致。
*   **善用 CLI**：`nest g resource` 等命令能帮你快速生成包含 CRUD 的全套代码，极大提升开发效率。

掌握了 Monorepo 和独立应用，你将能更从容地应对从小型项目到大型企业级应用的各种复杂需求。
