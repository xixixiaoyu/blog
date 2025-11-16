## 一、核心引擎：Nest CLI

无论是初始化项目、编译代码，还是在你改动文件时自动重新构建，这些都离不开 Nest CLI。Nest 把这些好用的功能都打包进了 `@nestjs/cli` 这个包里，提供了一个叫 `nest` 的命令行工具。

### CLI 的安装与使用

如果只是临时用一下，可以通过 `npx`：

```bash
npx @nestjs/cli new 项目名
```

但我更推荐全局安装，这样更方便：

```bash
npm install -g @nestjs/cli
# 如果需要更新
npm update -g @nestjs/cli
# mac 用户可能需要 sudo
sudo npm update -g @nestjs/cli
```

装好后就可以直接使用 `nest` 命令了：

```bash
nest new 项目名
```

### 常用 CLI 命令详解

我们可以通过 `nest -h` 查看所有可用的命令：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933380135-d639f986-3444-4cdc-91e7-869cb991049f.png)

它列出了一堆命令，如创建新项目的 `nest new`、生成代码的 `nest generate`、打包的 `nest build` 和开发模式的 `nest start` 等。我们来聊聊其中最常用的几个。

#### `nest new`：轻松创建新项目

这个命令就是用来从零开始搭建一个新的 Nest 项目。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933522991-be528b27-9be6-4208-a86b-46d9874dc73b.png)

它还提供了一些有用的选项：

*   `--skip-git`：如果你的项目不想用 Git 初始化。
*   `--package-manager` (或 `-p`)：创建项目时它会让你选 `npm`, `yarn`, `pnpm`。如果你提前想好了，比如就想用 `pnpm`，也不想 git 初始化：
    ```bash
    nest new 项目名 -p pnpm --skip-git
    ```
*   `--language`：可以指定用 `typescript` (默认) 还是 `javascript`。现在都 2025 年了，而且还是写后端，TS 是不二之选。
*   `--strict`：这是 TypeScript 的严格模式开关。默认是 `false`，如果你想一开始就让 TS 编译器对你的代码更严格（比如开启 `noImplicitAny`, `strictNullChecks` 等 5 个选项），可以设置为 `true`。这个后续在 `tsconfig.json` 里也能改，所以不用太纠结。

我们创建一个项目：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933562182-c0c989c5-cd75-4352-8782-98f27c37f2b1.png)

#### `nest generate` (或 `nest g`)：代码快速生成器

`nest` 命令除了生成整个项目，还允许你快速生成各种资源，比如 controllers、providers、modules 等。资源通常指的是与特定业务逻辑相关的模块。

使用 `nest generate <schematic> <name> [选项]`：

`<schematic>` 是文件类型，可以是以下选项之一：

*   **module**: 生成新的模块
*   **controller**: 生成新的控制器
*   **service**: 生成新的服务
*   **filter**: 生成新的过滤器
*   **middleware**: 生成新的中间件
*   **interceptor**: 生成新的拦截器
*   **guard**: 生成新的守卫
*   **decorator**: 生成新的装饰器
*   **pipe**: 生成新的管道
*   **resolver**: 生成新的解析器（GraphQL）
*   **resource**: 生成完整的资源（包含控制器、服务、模块等）
*   **class**: 生成普通类
*   **interface**: 生成接口
*   **gateway**: 生成 WebSocket 网关

`<name>` 是文件的名称。常用选项：

*   `--flat`: 默认不会创建文件夹。
*   `--no-spec`: 不生成 `.spec.ts` 的测试文件。
*   `--skip-import`：如果你不希望新生成的模块自动在 `AppModule` (或其他目标模块) 里被引入，可以用这个。
*   `--dry-run`: 预览将创建的文件而不实际写入。
*   `--project`：这个在玩 Monorepo (一个仓库管理多个项目) 的时候会用到，用来指定代码生成在哪个子项目里。

**生成一个模块 (Module)**：

```bash
nest generate module 模块名
# 或者简写
nest g module 模块名
```

模块名规范一般是小写，多个字母用 `-` 连接。它会生成 module 的代码，并在 `AppModule` 自动引入：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933614612-1e84df85-83f3-49c9-9f1e-36688d4f565e.png)

不过我们更常生成完整的模块代码，包含模块、控制器、服务，并且控制器里还带有一整套 CRUD (创建、读取、更新、删除) 的 RESTful API 接口：

```bash
nest g resource resource-name
```

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933696769-2173e144-a8e3-49b6-a510-ccf152dad667.png)

会先问资源要提供哪种 API，有常见的 `REST API` (HTTP)、`GraphQL`、`WebSockets` 等，一般选 `REST API` 就行。然后它会问你是否生成 CRUD 的入口点，我们选 yes，就会生成模块所需的所有基础文件：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933719728-a418b3b0-4bb4-44bb-ae1c-13ae97a892a0.png)

`book` 模块还会自动在 `AppModule` 中引入。这些代码模板都定义在 `@nestjs/schematics` 这个包里。

#### `nest build`：编译你的项目

代码开发完毕，我们需要编译成 JS 才能运行：

```bash
nest build
```

执行后，它会把编译好的代码输出到 `dist` 目录下。

它也有一些选项：

*   `--webpack` 和 `--tsc`：Nest 默认使用 `tsc` (TypeScript Compiler) 来编译。`tsc` 只是把 TS 文件转成 JS 文件，不会做打包。如果你想用 `webpack` 来编译和打包，可以加上 `--webpack`。
*   `--watch` (或 `-w`)：监听你文件的变动，一旦有修改，就自动重新编译。
*   `--watchAssets`：默认情况下，`--watch` 只监听代码文件。如果你的项目里还有一些其他类型的文件（比如 `.hbs` 模板、`.json` 配置文件）也想在变动时被复制到 `dist` 目录，那就要加上 `--watchAssets`。
*   `--path`：指定 `tsconfig.json` 文件的路径。
*   `--config`：指定 `nest-cli.json` 配置文件的路径。

#### `nest start`：启动开发服务器

使用 `nest start` 命令，它会先执行一次构建 (`nest build`)，然后用 `node` 把编译后的入口文件 (通常是 `dist/main.js`) 跑起来。

```bash
nest start
```

它最常用的选项就是 `--watch` (或 `-w`)：

```bash
nest start --watch
```

这样，当你保存了代码，它会重新编译并重启服务，你就能立刻看到改动后的效果。

其他选项：

*   `--debug`：如果你想进行调试，可以用这个选项。它会启动一个调试用的 WebSocket 服务，你可以配合 Chrome DevTools 或 VS Code 的调试器来使用。
*   `--exec`：默认是用 `node` 来运行编译后的代码，如果你想用其他的运行时 (比如 `nodemon`)，可以通过这个选项指定。
*   其余像 `--path`, `--config`, `--webpack` 等选项和 `nest build` 里的作用类似。

#### `nest info`：查看项目信息

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933815421-c394534b-b4c9-49e7-a505-d54ee55d4515.png)

显示当前项目的环境信息，包括你的操作系统、Node.js 版本、NPM/Yarn/PNPM 版本，以及项目中 NestJS 相关包的版本。排查环境问题或者提 issue 的时候会很有用。

### `nest-cli.json`：CLI 的大脑

其实很多你在命令行里用的选项，都可以在 `nest-cli.json` 文件里进行全局配置，这样就不用每次都敲一长串命令了。

打开你项目根目录下的 `nest-cli.json`：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933832482-1b95758c-c82b-40d1-be49-cb29b58b756b.png)

这个文件是 CLI 的大脑，其中几个核心配置项：

*   `collection`: 指定代码生成器的集合，默认是官方的 `@nestjs/schematics`。
*   `sourceRoot`: 源码根目录，默认是 `src`。
*   `compilerOptions`: 配置编译相关的选项。例如，`"deleteOutDir": true` 表示每次构建前清空 `dist` 目录。
*   `generateOptions`: 配置 `nest generate` 的默认行为。例如，设置 `"spec": false` 后，以后执行 `nest g` 就不会再生成测试文件了。
*   `assets`: 定义哪些非 TS/JS 文件或目录在构建时需要被复制到输出目录 (`dist`)，这对于模板文件、配置文件、i18n 文件等非常有用。
*   `projects`: 用于 Monorepo (单一代码仓库管理多个项目/应用) 模式的配置。

### Nest 项目的 npm 脚本

`nest new` 创建的项目 `package.json` 中会包含一套预设的 npm 脚本：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933890829-7af9ab46-4417-43a2-9541-511b95e0561e.png)

这些命令覆盖了从代码开发、格式化、打包、调试到测试的完整流程。

---

## 二、交互式利器：REPL 模式

### 什么是 REPL？

在开发 Nest.js 应用时，通常需要通过浏览器或 API 工具来测试模块、服务和控制器，这种方法虽然有效，但有时候会显得繁琐。

Nest.js 提供了 REPL (Read-Eval-Print Loop) 模式，它允许开发者在控制台中启动一个交互式环境，直接调用和测试应用中的任意模块或服务，而无需启动完整的 HTTP 服务器。

### 如何运行 REPL 模式

首先，我们需要创建一个专门用于启动 REPL 的入口文件，例如在 `src` 目录下创建 `repl.ts`：

```typescript
// src/repl.ts
import { repl } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  await repl(AppModule);
}
bootstrap();
```

然后，通过 `nest start` 命令并使用 `--entryFile` 选项来指定这个新的入口文件：

```bash
nest start --watch --entryFile repl
```

为了方便，可以将其配置到 `package.json` 的 `scripts` 中：

```json
"scripts": {
  "repl": "nest start --watch --entryFile repl"
}
```

之后就可以通过 `npm run repl` 来启动了。

### REPL 内置函数

进入 REPL 环境后，你可以使用一系列内置的辅助函数来与你的应用交互：

*   `get()` 或 `$()`: 获取一个提供者 (Service) 或控制器 (Controller) 的实例。
    ```typescript
    > const appService = get(AppService)
    > appService.getHello()
    'Hello World!'
    ```
*   `resolve()`: 与 `get()` 类似，但它会解析一个 provider 实例，并返回一个包含该实例的子树。
*   `debug()`: 打印出所有已注册的模块以及它们的控制器和提供者。
*   `methods()`: 查看某个提供者或控制器实例上的所有方法。
    ```typescript
    > methods(appService)
    ```
*   `help()`: 打印出所有可用的 REPL 函数及其说明。

**注意**：在 REPL 模式下直接调用方法，不会触发 Nest.js 的管道 (Pipes)、守卫 (Guards) 或拦截器 (Interceptors)。它主要用于单元测试和快速验证业务逻辑。

### 配置命令历史

为了在重启 REPL 后还能访问之前的命令历史，可以配置 `setupHistory`：

```typescript
// src/repl.ts
import { repl } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const replServer = await repl(AppModule);
  replServer.setupHistory('.nestjs_repl_history', (err) => {
    if (err) {
      console.error(err);
    }
  });
}
bootstrap();
```

这会在项目根目录创建一个 `.nestjs_repl_history` 文件来保存历史记录。

---

## 三、问题追踪器：调试 Node.js 与 Nest.js 应用

高效的调试是保证代码质量和开发效率的关键。VS Code 提供了强大的调试功能，可以与 Nest.js 无缝集成。

### 基础篇：调试单个 Node.js 文件

在深入 Nest.js 之前，我们先看一个简单的 Node.js 文件调试配置。

1.  点击 VS Code 左侧活动栏中的“运行和调试”图标，选择“创建 launch.json 文件”，并选择 “Node.js” 环境。
2.  VS Code 会在项目根目录创建 `.vscode/launch.json` 文件。
3.  使用以下配置来调试当前打开的文件：
    ```json
    {
      "version": "0.2.0",
      "configurations": [
        {
          "type": "node",
          "request": "launch",
          "name": "调试当前文件",
          "program": "${file}",
          "skipFiles": ["<node_internals>/**"]
        }
      ]
    }
    ```
    `${file}` 是一个 VS Code 变量，代表当前编辑器中活动的文件。

现在，你可以在任意 `.js` 文件中设置断点，然后按 `F5` (或点击调试面板的绿色播放按钮) 启动调试。

### 进阶篇：调试 Nest.js 项目

对于 Nest.js 项目，调试配置稍有不同，因为它需要通过 `npm` 脚本来启动。

1.  打开 `launch.json` 文件，添加一个新的调试配置：
    ```json
    {
      "version": "0.2.0",
      "configurations": [
        // ... 其他配置
        {
          "type": "node",
          "request": "launch",
          "name": "调试 Nest.js 应用",
          "runtimeExecutable": "npm",
          "runtimeArgs": ["run", "start:debug"],
          "skipFiles": ["<node_internals>/**"],
          "console": "integratedTerminal",
          "sourceMaps": true
        }
      ]
    }
    ```
    *   `runtimeExecutable`: "npm" 指定使用 `npm` 作为运行时。
    *   `runtimeArgs`: `["run", "start:debug"]` 相当于在终端执行 `npm run start:debug`。`start:debug` 是 Nest.js 项目 `package.json` 中预设的脚本，它以调试模式启动应用并开启 watch 功能。
    *   `console`: `"integratedTerminal"` 让程序输出显示在 VS Code 的集成终端里。
    *   `sourceMaps`: `true` 启用 source map 支持，这样你就可以在 TypeScript 源码 (`.ts` 文件) 中直接调试，而不是在编译后的 JavaScript 代码中。

2.  在你的控制器或服务中设置断点。
3.  在调试面板中选择 “调试 Nest.js 应用” 配置，然后按 `F5` 启动。
4.  当你的应用启动后，通过浏览器或 API 工具访问触发断点的路由。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746864737236-c7904d60-8dd6-4e09-b362-9cd32a7d0834.png)

代码会准确地停在你设置的断点处，此时你可以检查变量、查看调用堆栈，并使用调试工具栏进行单步调试。

**调试工具栏简介** (从左往右):
*   **继续 (Continue)**: 继续执行直到下一个断点。
*   **单步跳过 (Step Over)**: 执行当前行，不进入函数内部。
*   **单步调试 (Step Into)**: 如果当前行是函数调用，则进入函数内部。
*   **单步跳出 (Step Out)**: 执行完当前函数并返回到调用处。
*   **重启 (Restart)**: 重启调试会话。
*   **停止 (Stop)**: 终止调试。

---

## 总结

通过本文的整合，我们全面了解了 Nest.js 开发中的三大核心工具：

*   **Nest CLI**: 你的项目脚手架和代码生成器。使用 `nest new` 创建项目，`nest g` 高效生成模块、控制器、服务等，`nest build` 和 `nest start` 负责编译和运行。通过 `nest-cli.json` 可以实现高度定制化。
*   **REPL 模式**: 一个强大的交互式测试环境。它让你可以在不启动完整服务器的情况下，快速测试服务类的方法和业务逻辑，极大地提升了开发和调试效率。
*   **VS Code 调试**: 通过简单的 `launch.json` 配置，你可以轻松地在 TypeScript 源码中设置断点、检查变量和单步调试，是定位和解决问题的终极武器。

熟练掌握这三者，将使你的 Nest.js 开发流程更加顺畅、专业和高效。
