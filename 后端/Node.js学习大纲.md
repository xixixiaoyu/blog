# 新版 Node.js 学习大纲 (优化版)

## 第一部分：Node.js 核心与基础 (The Core)

*   **第 1 章：基础入门与环境搭建**
    *   1-1. Node.js 是什么？（单线程、非阻塞 I/O、事件循环）
    *   1-2. 安装与版本管理（Node.js, nvm）
    *   1-3. 运行 `.js` 文件与 REPL 环境
    *   1-4.【核心】理解 `async/await` 与 Promise（宏任务与微任务）

*   **第 2 章：深入理解核心模块**
    *   2-1.【核心】深入事件循环 (Event Loop)
    *   2-2. 模块系统：CommonJS 与 ES Modules 的差异与实践
    *   2-3. 文件系统 `fs` 模块（同步/异步、读写、目录操作）
    *   2-4. 路径 `path` 模块
    *   2-5. 缓冲区 `Buffer`
    *   2-6.【核心】流 `Stream`（可读流、可写流、管道）
    *   2-7. 事件 `EventEmitter`

*   **第 3 章：构建原生 HTTP 服务器**
    *   3-1. `http` 模块：创建 Web 服务器
    *   3-2. 处理不同请求方法（GET, POST）
    *   3-3. 处理 URL 与查询参数
    *   3-4. 响应不同数据类型（HTML, JSON）
    *   3-5. 原生服务器的模块化拆分

## 第二部分：现代化工程实践 (The Ecosystem)

*   **第 4 章：包管理与项目构建**
    *   4-1. `npm` 深度指南 (`package.json`, `scripts`, `dependencies`, `npx`)
    *   4-2. `package-lock.json` 与依赖管理
    *   4-3. (选修) `yarn` 与 `pnpm` 简介

*   **第 5 章：TypeScript 在 Node.js 中的应用**
    *   5-1. 为什么需要 TypeScript？
    *   5-2. `tsconfig.json` 配置详解
    *   5-3. 在 Node.js 项目中集成 TypeScript
    *   5-4. 常用类型与接口定义

*   **第 6 章：测试与质量保证**
    *   6-1. 测试的重要性与 TDD/BDD 理念
    *   6-2. 使用 Jest/Vitest 进行单元测试
    *   6-3. 异步代码的测试
    *   6-4. Mocking 与 Spying
    *   6-5. (选修) 端到端测试 (E2E Testing) 简介

## 第三部分：Web 框架与数据持久化 (The Framework)

*   **第 7 章：Express.js 深度实践 (或 Nest.js)**
    *   7-1. 框架介绍与项目初始化
    *   7-2. 路由（Routing）设计
    *   7-3.【核心】中间件 (Middleware) 的概念与实践
    *   7-4. 静态文件服务
    *   7-5. 错误处理中间件
    *   7-6. 构建 RESTful API
    *   7-7. (对比) Koa 的中间件模型 (洋葱模型)

*   **第 8 章：数据持久化与 MongoDB**
    *   8-1. 数据库选型（SQL vs NoSQL）
    *   8-2. MongoDB 核心概念与 Shell 操作
    *   8-3. 使用 Mongoose 连接与操作 MongoDB
    *   8-4. Schema 与 Model 设计
    *   8-5. 实现完整的 CRUD API
    *   8-6. (选修) 使用 Prisma 操作 SQL 数据库

*   **第 9 章：用户认证与授权**
    *   9-1. 认证 (Authentication) vs 授权 (Authorization)
    *   9-2. Cookie 与 Session
    *   9-3. JWT (JSON Web Token) 认证流程详解
    *   9-4. 使用 `jsonwebtoken` 或 `passport.js` 实现认证
    *   9-5. 密码安全：哈希与加盐

## 第四部分：高级主题与性能优化 (The Advanced)

*   **第 10 章：实战项目：开发一个自己的 CLI 脚手架**
    *   10-1. `commander.js` 处理命令行参数
    *   10-2. `inquirer.js` 实现命令行交互
    *   10-3. 下载远程模板
    *   10-4. 命令行美化 (`chalk`, `ora`)
    *   10-5. 发布到 npm

*   **第 11 章：文件上传与处理**
    *   11-1. `multer` 中间件处理 `multipart/form-data`
    *   11-2. 文件上传到服务器本地
    *   11-3. (进阶) 上传到云存储（如 AWS S3, 阿里云 OSS）

*   **第 12 章：性能与扩展**
    *   12-1. 使用 Redis 实现缓存与 Session 存储
    *   12-2. `cluster` 模块与 `child_process`
    *   12-3. 使用 PM2 进行进程管理与负载均衡
    *   12-4. (选修) WebSocket 与实时通信

*   **第 13 章：安全**
    *   13-1. 常见 Web 攻击（XSS, CSRF, SQL 注入）及其防范
    *   13-2. 使用 `helmet` 保护 Express 应用
    *   13-3. 数据验证的重要性 (`joi`, `class-validator`)

## 第五部分：生产环境部署 (The Deployment)

*   **第 14 章：使用 Docker 容器化**
    *   14-1. Docker 核心概念（Image, Container, Dockerfile）
    *   14-2. 为 Node.js 应用编写 `Dockerfile`
    *   14-3. 使用 `docker-compose` 编排应用与数据库

*   **第 15 章：云服务器部署**
    *   15-1. 云服务器选购与基础配置
    *   15-2. Nginx 介绍与核心配置
    *   15-3. 使用 Nginx 作为反向代理
    *   15-4. 配置 HTTPS (Let's Encrypt)
    *   15-5. (选修) 自动化部署与 CI/CD 简介

*   **第 16 章：课程总结与未来学习方向**
    *   16-1. 知识体系回顾
    *   16-2. 探索方向：微服务、Serverless、GraphQL
