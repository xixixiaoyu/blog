# NestJS 全栈进阶学习大纲

---

## 第一部分：NestJS 核心基础

### 第 01 章：初识 NestJS
- 1-1 课程介绍与学习指南
- 1-2 为什么需要 NestJS？它解决了什么问题？
- 1-3 NestJS 核心思想与应用场景
- 1-4 主流 Node.js 框架对比 (Koa, Egg.js, Express)

### 第 02 章：开发环境搭建
- 2-1 高效开发环境概览 (Node.js, VSCode, Docker)
- 2-2 Node.js 版本管理 (nvm)
- 2-3 包管理工具的选择 (npm, cnpm, yarn, pnpm)
- 2-4 IDE 准备 (VSCode + 推荐插件)
- 2-5 数据库环境搭建 (Docker, docker-compose, MySQL/PostgreSQL)
- 2-6 Docker 环境配置与加速

### 第 03 章：第一个 NestJS 应用
- 3-1 安装与使用 NestJS CLI
- 3-2 RESTful API 设计理念与规范
- 3-3 创建你的第一个 NestJS 应用 (Hello World)
- 3-4 项目结构最佳实践与文件命名约定
- 3-5 使用 CLI 创建模块、控制器和服务

### 第 04 章：NestJS 核心概念与编程思想
- 4-1 SOLID 原则与面向对象编程 (OOP)
- 4-2 控制反转 (IoC) 与依赖注入 (DI)
- 4-3 切面编程 (AOP) 思想解读
- 4-4 NestJS 架构核心：模块 (Module)、控制器 (Controller)、服务 (Provider)
- 4-5 DTO, DAO 与 MVC/MVP 架构模式

### 第 05 章：深入理解 TypeScript (选修)
- 5-1 基础类型 & 引用类型
- 5-2 函数类型与函数重载
- 5-3 any, never, void, unknown
- 5-4 元组 (Tuple) 与枚举 (Enum)
- 5-5 接口 (Interface)
- 5-6 类 (Class)：修饰符、构造函数、继承与实现
- 5-7 泛型 (Generics)
- 5-8 声明文件 (`.d.ts`) 与 `tsconfig.json` 配置详解

---

## 第二部分：NestJS 核心功能详解

### 第 06 章：模块 (Modules)
- 6-1 使用模块组织代码
- 6-2 功能模块与共享模块
- 6-3 模块的导入与重新导出
- 6-4 全局模块 (`@Global()`)
- 6-5 动态模块 (`DynamicModule`) 的原理与实践
- 6-6 异步动态模块传参

### 第 07 章：控制器与路由 (Controllers & Routing)
- 7-1 路由配置与请求处理流程
- 7-2 参数装饰器详解 (`@Request`, `@Response`, `@Next`, `@Session`, `@Param`, `@Body`, `@Query`, `@Headers`)
- 7-3 获取请求参数与响应对象
- 7-4 自定义参数装饰器
- 7-5 路由排除

### 第 08 章：提供者 (Providers) 与依赖注入
- 8-1 Provider 详解：Service, Repository, Factory
- 8-2 依赖注入的实现与范围 (Scope)
- 8-3 自定义 Provider

### 第 09 章：中间件 (Middleware)
- 9-1 中间件的概念与使用
- 9-2 在中间件中实现依赖注入
- 9-3 全局中间件与函数式中间件

### 第 10 章：异常过滤器 (Exception Filters)
- 10-1 内置 HTTP 异常处理
- 10-2 创建自定义异常过滤器
- 10-3 全局异常过滤器 (`APP_FILTER`)
- 10-4 结合日志系统记录异常

### 第 11 章：管道 (Pipes)
- 11-1 管道的用途：转换与验证
- 11-2 内置管道的使用 (`ValidationPipe`, `ParseIntPipe`, etc.)
- 11-3 创建自定义管道
- 11-4 使用 `class-validator` 进行 DTO 验证
- 11-5 全局管道 (`APP_PIPE`)

### 第 12 章：守卫 (Guards)
- 12-1 守卫的角色：授权 (Authorization)
- 12-2 实现自定义守卫
- 12-3 全局守卫 (`APP_GUARD`)
- 12-4 守卫与角色权限控制 (RBAC)

### 第 13 章：拦截器 (Interceptors)
- 13-1 AOP 与拦截器的关系
- 13-2 拦截器的应用场景：响应转换、异常映射、缓存等
- 13-3 实现自定义拦截器
- 13-4 全局拦截器 (`APP_INTERCEPTOR`)
- 13-5 使用拦截器实现数据脱敏与序列化

---

## 第三部分：通用业务框架设计与实战

### 第 14 章：配置管理
- 14-1 多环境配置方案对比
- 14-2 使用官方 `@nestjs/config` 模块
- 14-3 集成 `yaml` 和 `.env` 文件
- 14-4 使用 `Joi` 或 `class-validator` 进行配置验证
- 14-5 命令行参数与配置模块结合

### 第 15 章：数据库与 ORM
- 15-1 ORM 介绍 (TypeORM, Prisma, Mongoose)
- 15-2 关系型数据库设计 (三大范式, ER 图)
- 15-3 **TypeORM 集成与实战**
    - 15-3-1 连接数据库与实体 (Entity) 创建
    - 15-3-2 实体关系：一对一, 一对多, 多对多
    - 15-3-3 数据库迁移 (Migration) 与数据同步
    - 15-3-4 实现 CURD 操作
    - 15-3-5 高级查询：QueryBuilder 与原生 SQL
    - 15-3-6 关联查询 (Join)
    - 15-3-7 从现有数据库生成实体
- 15-4 **Prisma 集成与实战**
    - 15-4-1 Prisma Client 与 NestJS 集成
    - 15-4-2 Prisma Schema 设计与数据库迁移
    - 15-4-3 使用 Prisma Client 进行数据操作
- 15-5 **Mongoose 集成与实战 (非关系型数据库)**
    - 15-5-1 连接 MongoDB
    - 15-5-2 Schema 与 Model
    - 15-5-3 数据操作

### 第 16 章：日志系统
- 16-1 日志的重要性与分类
- 16-2 使用内置 Logger
- 16-3 集成高性能日志库 (Pino, Winston)
- 16-4 日志滚动与持久化
- 16-5 全局异常过滤器与日志结合

### 第 17 章：文件上传与处理
- 17-1 单文件与多文件上传
- 17-2 文件流与缓冲区
- 17-3 图片压缩与处理
- 17-4 文件上传至对象存储 (COS/OSS)

### 第 18 章：任务调度与队列
- 18-1 使用 `@nestjs/schedule` 实现定时任务 (Cron)
- 18-2 集成 Bull 消息队列处理异步任务

### 第 19 章：事件驱动编程
- 19-1 使用 `@nestjs/event-emitter` 实现事件通知
- 19-2 解耦模块间的通信

---

## 第四部分：安全、认证与授权

### 第 20 章：用户认证 (Authentication)
- 20-1 认证与授权基础概念 (Session, Cookie, JWT)
- 20-2 API 接口安全基础 (HTTPS, 加密, 哈希)
- 20-3 **JWT 认证流程**
    - 20-3-1 Passport.js 策略模式
    - 20-3-2 集成 `@nestjs/jwt` 和 `passport`
    - 20-3-3 实现 `LocalStrategy` (用户名密码) 和 `JwtStrategy`
    - 20-3-4 签发与验证 JWT
- 20-4 **密码安全**
    - 20-4-1 哈希与加盐 (bcrypt, argon2)
    - 20-4-2 防止彩虹表攻击
- 20-5 **第三方登录**
    - 20-5-1 OAuth2.0 与 OpenID Connect
    - 20-5-2 实现微信/GitHub 扫码登录
- 20-6 **Token 刷新机制**
    - 20-6-1 Refresh Token 设计与实现
    - 20-6-2 无感刷新与并发处理
- 20-7 **会话管理**
    - 20-7-1 使用 Redis 存储会话

### 第 21 章：用户授权 (Authorization)
- 21-1 **基于角色的访问控制 (RBAC)**
    - 21-1-1 RBAC 模型分析与数据库设计
    - 21-1-2 创建角色、权限 CURD
    - 21-1-3 用户与角色关联
    - 21-1-4 实现 RBAC 守卫
- 21-2 **基于策略的访问控制 (CASL)**
    - 21-2-1 CASL 库介绍与核心概念
    - 21-2-2 定义能力 (Abilities) 和规则
    - 21-2-3 集成 CASL 实现复杂权限控制
    - 21-2-4 基于函数和条件的动态策略

---

## 第五部分：高级主题与企业级架构

### 第 22 章：多租户 (Multi-Tenancy) 架构
- 22-1 多租户概念与实现策略 (共享库、独立库)
- 22-2 TypeORM 动态连接多数据库
- 22-3 Prisma 多 Client 实践
- 22-4 抽象公共 Repository 与动态模块优化

### 第 23 章：微服务与异步通信
- 23-1 NestJS 微服务概览 (TCP, gRPC, Kafka, RabbitMQ)
- 23-2 构建第一个微服务
- 23-3 服务间通信模式

### 第 24 章：GraphQL
- 24-1 GraphQL vs REST
- 24-2 集成 `@nestjs/graphql`
- 24-3 Schema-first vs Code-first
- 24-4 实现 Query, Mutation, Subscription

### 第 25 章：测试 (Testing)
- 25-1 测试金字塔与测试策略
- 25-2 单元测试 (Unit Testing)
- 25-3 集成测试 (Integration Testing)
- 25-4 端到端测试 (E2E Testing)
- 25-5 Mocking 与 Spy

### 第 26 章：性能优化与监控
- 26-1 缓存策略 (In-Memory, Redis)
- 26-2 响应压缩与分页
- 26-3 性能监控与日志分析 (Prometheus, Grafana)
- 26-4 系统状态监控

### 第 27 章：前端集成与视图渲染
- 27-1 提供静态资源服务
- 27-2 集成模板引擎 (Handlebars, EJS)
- 27-3 与现代前端框架 (React, Vue, HTMX) 结合的最佳实践

### 第 28 章：部署与 DevOps
- 28-1 构建生产环境应用
- 28-2 使用 PM2 进行进程管理
- 28-3 Docker 容器化部署
- 28-4 CI/CD 流程简介

---

## 第六部分：全栈实战项目

### 第 29 章：实战项目：企业级后台管理系统
- 29-1 需求分析与技术选型
- 29-2 **后端开发**
    - 29-2-1 用户管理与权限系统 (RBAC + CASL)
    - 29-2-2 菜单与资源管理
    - 29-2-3 文章/内容管理 (富文本, 文件上传)
    - 29-2-4 数据报表与可视化
    - 29-2-5 系统设置与操作日志
- 29-3 **前端开发 (Vue/React/HTMX)**
    - 29-3-1 搭建前端项目与 UI 框架
    - 29-3-2 封装 HTTP Client (Axios)
    - 29-3-3 登录与 Token 管理
    - 29-3-4 动态路由与菜单权限
    - 29-3-5 实现各模块的 CURD 页面
- 29-4 **联调与测试**

### 第 30 章：实战项目：实时聊天室
- 30-1 WebSocket 与 Gateway
- 30-2 实现消息广播、私聊
- 30-3 用户状态管理
