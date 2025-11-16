# NestJS 生产级部署完全指南

### 核心思想：从开发到生产，究竟改变了什么？

想象一下，你在本地开发 NestJS 应用，就像在自己的工作室里精心制作一件产品。而部署，则是把这件产品搬到繁华的商业街上，开一家正式的店铺，迎接成千上万的顾客。

这个过程的核心变化是什么？

1.  **环境变了**：从你可控的个人电脑，变成了一个远程、共享的服务器。
2.  **目标变了**：从方便调试、快速迭代，变成了稳定、高效、安全地运行。
3.  **用户变了**：从只有你自己，变成了真实的、不可预测的互联网用户。

想清楚这几点，我们就能理解部署中每一步操作背后的“为什么”了。

---

### 一、部署前的必备准备

在动手部署之前，一份清晰的清单能让你事半功倍。

1.  **一个测试通过的应用**：确保你的 Nest 应用功能完整，经过充分的单元测试和集成测试。没人希望上线后才发现代码里藏着 Bug。
2.  **选择一个托管平台**：为你的应用找个“家”。可以是 AWS、Azure 等云平台，也可以是 DigitalOcean、Linode 等 VPS（虚拟专用服务器）。
3.  **依赖服务就绪**：确保你的应用所依赖的数据库（PostgreSQL、MongoDB）、缓存（Redis）等服务已经部署好且连接正常。
4.  **Node.js 环境**：部署的服务器需要安装 Node.js 的长期支持版（LTS），建议使用 `nvm` 来管理版本。
5.  **配置环境变量**：这是部署准备中的重中之重。

**第一性原理：配置与代码分离**

一个应用的行为应该由外部配置来决定，而不是硬编码在代码里。这样做的好处是：

*   **安全**：敏感信息（如数据库密码、API 密钥）不会暴露在代码仓库中。
*   **灵活**：同一份代码，可以根据不同的环境（开发、测试、生产）加载不同的配置，轻松切换。

**如何操作（官方推荐）**：

NestJS 官方推荐使用 `@nestjs/config` 包来管理环境变量。

1.  **安装依赖**：
    ```bash
    npm install @nestjs/config
    ```

2.  **创建 `.env` 文件**：在项目根目录下创建此文件（并确保已将其加入 `.gitignore`）。
    ```env
    # .env
    NODE_ENV=development
    DATABASE_HOST=localhost
    DATABASE_PORT=5432
    DATABASE_USER=my_user
    DATABASE_PASSWORD=my_password
    ```

3.  **在应用中全局加载**：在根模块 `app.module.ts` 中加载配置。
    ```typescript
    // src/app.module.ts
    import { Module } from '@nestjs/common';
    import { ConfigModule } from '@nestjs/config';

    @Module({
      imports: [
        // forRoot() 在应用启动时一次性加载所有配置
        // isGlobal: true 让我们在任何地方都能直接注入 ConfigService
        ConfigModule.forRoot({
          isGlobal: true,
          envFilePath: `.env.${process.env.NODE_ENV || 'development'}`, // 根据环境加载不同配置文件
        }),
        // ... 其他模块
      ],
    })
    export class AppModule {}
    ```

4.  **在服务中使用**：
    ```typescript
    // src/some.service.ts
    import { Injectable } from '@nestjs/common';
    import { ConfigService } from '@nestjs/config';

    @Injectable()
    export class SomeService {
      constructor(private configService: ConfigService) {}

      getDatabaseHost(): string {
        // 使用 get 方法获取变量，第二个参数是默认值，非常安全
        return this.configService.get<string>('DATABASE_HOST', 'localhost');
      }
    }
    ```

---

### 二、部署的四大关键步骤

一个标准的、稳健的 NestJS 部署流程，通常包含以下四个核心环节。

#### 1. 构建应用：从 TypeScript 到 JavaScript

**启发式提问**：为什么我们本地开发用 `npm run start:dev`，但部署时却不行？

**第一性原理**：Node.js 本身只认识 JavaScript (`.js`)。`start:dev` 命令背后的 `ts-node` 会实时监听和编译，这在开发时很方便，但会消耗额外性能，不适合追求极致性能的生产环境。

因此，部署的第一步就是将所有 `.ts` 代码“翻译”成高度优化的 `.js` 代码。

**如何操作**：

```bash
npm run build
```

这个命令会执行 `nest build`，将 `src` 目录下的所有 TypeScript 代码编译到 `dist` 目录下。现在，`dist/main.js` 就是我们应用的最终入口文件。

#### 2. 进程管理：确保应用持续在线

**启发式提问**：如果直接用 `node dist/main.js` 启动应用，然后关掉 SSH 窗口，应用还会运行吗？如果应用崩溃了，谁来重启它？

**第一性原理**：生产环境的应用必须具备**高可用性**和**自愈能力**。我们需要一个“管家”来守护 Node.js 进程，这个管家就是**进程管理器**，最常用的选择是 **PM2**。

**如何操作**：

1.  **全局安装 PM2**：
    ```bash
    npm install pm2 -g
    ```

2.  **启动应用**：
    ```bash
    # --name 给应用起个名字，方便管理
    # -i max 利用所有 CPU 核心开启集群模式，充分利用服务器资源
    pm2 start dist/main.js --name my-nest-app -i max
    ```

3.  **最佳实践：使用配置文件**：
    在项目根目录创建 `ecosystem.config.js` 文件，比命令行参数更清晰、可维护。

    ```javascript
    // ecosystem.config.js
    module.exports = {
      apps: [{
        name: 'my-nest-app',
        script: 'dist/main.js',
        // instances: 'max' 能充分利用多核 CPU，实现负载均衡
        instances: 'max',
        exec_mode: 'cluster',
        // watch 在生产环境通常关闭，以保证稳定性
        watch: false,
        // max_memory_restart 防止内存泄漏导致应用崩溃，自动重启
        max_memory_restart: '1G',
        env_production: {
          NODE_ENV: 'production',
          // 这里可以覆盖 .env 中的变量
        },
      }],
    };
    ```
    然后用 `pm2 start ecosystem.config.js --env production` 启动。

#### 3. 反向代理：应用的“门面”

**启发式提问**：我们的 NestJS 应用监听 3000 端口，用户访问 `http://your-domain.com:3000` 既不美观也不安全。怎么办？

**第一性原理**：我们需要一个统一的入口来处理所有进入服务器的请求，并根据规则分发。这个入口就是**反向代理**，最常用的工具是 **Nginx**。

Nginx 就像店铺的迎宾和前台，它负责：

*   **端口转发**：让用户通过默认的 80 (HTTP) 或 443 (HTTPS) 端口访问。
*   **负载均衡**：如果你用 PM2 开了多个实例，Nginx 可以把请求平均分发给它们。
*   **处理静态文件**：高效地提供图片、CSS 等静态资源，减轻 Node.js 的压力。
*   **SSL 终止**：集中处理 HTTPS 证书，简化应用逻辑。
*   **安全防护**：提供基础的防火墙、限流等功能。

**如何操作**（一个简化的 Nginx 配置示例）：

```nginx
# /etc/nginx/sites-available/my-nest-app
server {
  listen 80;
  server_name your-domain.com;

  location / {
    # 将所有请求代理到本地 3000 端口
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
  }
}
```

---

### 三、进阶之路：容器化部署

当你希望“在我的电脑上能跑，在任何地方都能跑”，那么就该了解 **Docker** 容器化了。

**第一性原理：环境标准化**。Docker 将你的应用、所有依赖、甚至运行时环境都打包到一个轻量、可移植的“容器”中，彻底解决了环境不一致的问题。

1.  **创建 `Dockerfile`**：
    ```dockerfile
    # ====== 构建阶段 ======
    FROM node:20-alpine AS builder
    WORKDIR /usr/src/app
    COPY package*.json ./
    # 使用 npm ci 保证可重复构建，且安装开发依赖以完成编译
    RUN npm ci
    COPY . .
    RUN npm run build

    # ====== 运行阶段 ======
    FROM node:20-alpine AS runtime
    WORKDIR /usr/src/app
    COPY package*.json ./
    # 仅安装生产依赖，减小镜像体积
    RUN npm ci --only=production
    # 仅复制编译产物到运行镜像
    COPY --from=builder /usr/src/app/dist ./dist
    EXPOSE 3000
    CMD ["node", "dist/main.js"]
    ```

2.  **创建 `.dockerignore`**：
    ```
    node_modules
    dist
    *.log
    .git
    ```

3.  **构建与运行**：
    ```bash
    # 构建镜像
    docker build -t my-nestjs-app .

    # 运行容器
    docker run -p 3000:3000 -d --name my-app-container my-nestjs-app
    ```

---

### 四、部署后的最佳实践

上线只是开始，要让应用长期稳定运行，离不开以下“养护”工作。

1.  **健康检查**：
    使用 `@nestjs/terminus` 包，轻松实现 `/health` 接口，让监控工具（如 AWS CloudWatch）可以定期“体检”。
    ```typescript
    // src/health/health.controller.ts
    import { Controller, Get } from '@nestjs/common';
    import { HealthCheck, HealthCheckService, TypeOrmHealthIndicator } from '@nestjs/terminus';

    @Controller('health')
    export class HealthController {
      constructor(
        private health: HealthCheckService,
        private db: TypeOrmHealthIndicator,
      ) {}

      @Get()
      @HealthCheck()
      check() {
        return this.health.check([
          () => this.db.pingCheck('database', { timeout: 1500 }),
        ]);
      }
    }
    ```

2.  **日志管理**：
    日志是排查问题的“黑匣子”。推荐使用 `pino` 或 `winston` 等库，将日志输出为 JSON 格式，并发送到 ElasticSearch 或 Datadog 等集中化日志平台进行分析。

3.  **扩展能力**：
    当用户量增加时，通过**水平扩展**（增加服务器实例并使用负载均衡器）来应对，这是云时代的主流方案。

4.  **安全防护**：
    *   使用 `helmet` 中间件来防御常见的 Web 漏洞。
    *   使用 `@nestjs/throttler` 或 `express-rate-limit` 配置请求限流，防止 DDoS 攻击。
    *   定期使用 `npm audit` 检查并修复依赖漏洞。

5.  **持续监控与自动化 (CI/CD)**：
    *   使用 Prometheus 或 New Relic 监控 CPU、内存、响应时间等关键指标。
    *   配置 GitHub Actions 或 Jenkins 等工具，实现代码提交后自动测试、构建和部署。

---

### 总结与展望

我们来回顾一下部署的“心法”：

1.  **构建**：将 TS 编译为优化的 JS，为了**性能**。
2.  **环境变量**：分离配置与代码，为了**安全与灵活**。
3.  **进程管理**：使用 PM2 等工具，为了**稳定与自愈**。
4.  **反向代理**：使用 Nginx，为了**统一入口与负载均衡**。
5.  **容器化**：使用 Docker，为了**环境标准化**。

这几步构成了一个坚实可靠的部署基础。部署是一个实践性很强的领域，理论讲得再多，不如亲手在服务器上操作一遍。当你熟练掌握后，再去探索 CI/CD 自动化流程，那将是现代开发的终极形态。
