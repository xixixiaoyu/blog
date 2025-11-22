想象一下，你的公司正在开发一个复杂的产品矩阵：

- 一个面向用户的主站
- 一个管理后台
- 一个移动端 App
- 一个共享的组件库
- 一个共享的工具函数库

在传统的 **Multi-repo（多仓库）** 模式下，你会为它们各自创建一个独立的 Git 仓库：

```
project-main-website/
project-admin-panel/
project-mobile-app/
project-shared-ui-components/
project-shared-utils/
```

这看起来很清晰，但随着项目发展，痛点会逐渐暴露：

1. **代码共享困难**：如果 `project-shared-ui-components` 更新了一个 Button 组件，你需要如何通知其他项目去更新？是发邮件？还是在 IM 里喊话？这个过程极易出错和滞后。
2. **依赖版本不一致**：主站用了 React 18，后台用了 React 17。组件库为了兼容两者，可能需要做额外的工作，甚至无法兼容。这会导致“依赖地狱”。
3. **跨项目开发体验差**：修复一个需要同时涉及主站和组件库的 bug，你需要在两个仓库之间来回切换，提交两次 PR，流程繁琐。

**Monorepo（单仓库）** 就是为了解决这些问题而生的。

它的核心思想非常直观：**将多个相关的项目存放在一个单一的 Git 仓库中**。

```
my-monorepo/
├── packages/
│   ├── main-website/          # 主站
│   ├── admin-panel/           # 管理后台
│   ├── mobile-app/            # 移动端应用
│   ├── shared-ui-components/  # 共享组件库
│   └── shared-utils/          # 共享工具库
├── docs/                      # 项目文档
└── package.json               # 根级 package.json
```

`main-website` 可以直接 `import { Button } from '@my-org/shared-ui-components'`，就像引用一个普通的 npm 包一样。当组件库更新时，所有引用它的项目都能立刻感知到。

所有项目的依赖都由根目录统一管理。可以确保整个组织都使用相同版本的 React、TypeScript 或 ESLint，从根本上避免了版本冲突。依赖项可以被提升到根目录，避免重复安装，节省磁盘空间。

想给所有项目统一升级某个 API？或者重构一个被多处使用的工具函数？在 Monorepo 中，你可以在一个仓库内完成所有修改，IDE 的全局搜索和替换功能也能完美支持。

所有项目共享同一套构建脚本、代码规范（ESLint、Prettier）、测试配置。新成员上手任何一个项目，体验都是一致的。



但是所有代码都在一个仓库里，`git clone` 会变慢。但现代工具通过浅克隆和稀疏检出等技术可以缓解这个问题。

每次都把所有项目重新构建一遍，那将是灾难。因此，**增量构建** 和 **智能缓存** 变得至关重要。

你需要引入额外的工具来管理依赖、执行任务、发布版本等，这会增加一定的学习成本。

在 Multi-repo 中，可以轻松地为某个仓库设置访问权限。在 Monorepo 中，权限控制需要更精细的机制（比如使用 CODEOWNERS 文件或 Git 服务商提供的功能）。



通常采用 `packages` 或 `apps` 目录来存放各个子项目。每个子项目都是一个独立的 `npm package`，有自己的 `package.json`。

Workspace 是实现 Monorepo 的基石。

以 `pnpm` 为例，你只需在根目录的 `package.json` 中声明：

```json
{
  "name": "my-monorepo",
  "private": true,
  "workspaces": [
    "packages/*"
  ]
}
```

当你运行 `pnpm install` 时，pnpm 会：

1. 读取所有 `packages/*` 下的 `package.json`。
2. 分析它们的依赖关系。
3. 将所有依赖提升到根目录的 `node_modules`。
4. 对于内部包的引用（如 `@my-org/shared-ui-components`），pnpm 会在 `node_modules` 中创建一个**符号链接**，指向 `packages/shared-ui-components` 目录。

这样，代码中的 `import` 语句就能像引用普通 node_modules 包一样工作了，但引用的其实是本地的代码。



如何只构建被修改过的项目？如何缓存构建结果？这就是 **Turborepo** 和 **Nx** 这类工具大显身手的地方。

它们的工作流程大致如下：

1. **依赖图分析**：它们会分析各个包之间的依赖关系，构建一个依赖图。比如，`main-website` 依赖 `shared-ui-components`。
2. **变更检测**：通过 Git diff 找出自上次提交以来，哪些文件被修改了。
3. **智能任务调度**：根据依赖图和变更，只执行受影响的任务。例如，如果只修改了 `shared-utils`，那么只有依赖它的 `shared-ui-components` 和 `main-website` 需要重新测试或构建。
4. **全局缓存**：任务（如 `build`、`test`、`lint`）的输出会被缓存。下次执行相同任务时，如果输入文件没变，它会直接从缓存中读取结果，瞬间完成。



当共享组件库更新后，如何自动更新它的版本号并发布到 npm？**Changesets** 是一个为此设计的优秀工具。

它的核心工作流是：

1. 开发者完成一个功能或修复后，运行 `pnpm changeset` 命令。
2. 它会询问你这次变更是 `patch`（补丁）、`minor`（小版本）还是 `major`（大版本），并让你写下变更日志。
3. 这个信息会以 `.md` 文件的形式保存在 `.changeset` 目录下。
4. 当准备发布时，运行 `pnpm changeset version`。它会消费所有 `.changeset` 文件，自动更新所有相关包的 `package.json` 版本号，并生成 `CHANGELOG.md`。
5. 最后，运行 `pnpm changeset publish`，它会自动将所有需要发布的包发布到 npm。



一个现代的前端 Monorepo 项目，通常会组合使用以下工具：

- **包管理器**: **pnpm** (因其节省空间和严格的依赖管理而备受青睐)
- **任务编排/构建**: **Turborepo** (由 Vercel 出品，配置简单，缓存强大) 或 **Nx** (功能更全面，但学习曲线稍陡)
- **版本发布**: **Changesets** (灵活且强大)
- **代码规范**: ESLint, Prettier (通过 `@typescript-eslint/utils` 等工具可以轻松实现跨包共享配置)



### 总结与建议

Monorepo 并非万能药，但对于中大型项目、组件库驱动开发或追求极致工程化体验的团队来说，它带来的收益远大于其复杂性。

**我的建议是：**

- **如果你正在启动一个新项目，并且预见到未来会有多个应用或共享库**，大胆地采用 Monorepo 吧。从第一天起就享受它带来的便利。
- **如果你正在维护一个混乱的 Multi-repo 项目**，可以考虑逐步将关联最紧密的项目迁移到 Monorepo 中，不必追求一步到位。

