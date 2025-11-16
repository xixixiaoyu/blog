## 引言：我们为什么需要可观测性？

想象一下，你是一位医生，而你的 NestJS 应用是你的病人。

*   **监控 (Monitoring)** 就像是给病人做常规体检：量体温、测血压、做心电图。它告诉你病人**当前的健康状态**（比如 CPU 使用率高不高、内存够不够、接口响应快不快、错误多不多）。它能帮你发现“症状”。
*   **追踪 (Tracing)** 则更像是做一次 CT 或核磁共振。当病人说某个地方不舒服时（比如一个请求特别慢），追踪能让你看到这个“不舒服”的请求在系统内部**完整的路径和过程**，经过了哪些服务、哪些函数，每一步耗时多久。它能帮你定位“病因”。
*   **日志 (Logging)** 是病人的详细病历，记录了在特定时间点发生的离散事件。

监控发现问题，追踪定位根源，日志提供详细上下文。这三者结合，构成了现代软件工程的**可观测性 (Observability)** 的三大支柱。

随着微服务架构的普及，一个用户请求可能会流经数十个服务。传统的监控和日志虽然有用，但缺少将离散事件串联起来的上下文。本文将带你深入探索如何为 NestJS 应用构建一个完整的可观测性体系，从使用 Prometheus 和 Grafana 进行宏观监控，到通过 Liveness 和 Readiness 探针实现自动化的健康检查，再到利用 OpenTelemetry 实现强大的分布式追踪能力。

---

## 第一部分：宏观监控 — 使用 Prometheus 与 Grafana 掌握系统脉搏

在生产环境中，仅仅知道应用“活着”是远远不够的。我们需要深入了解其内部运行状态、性能表现和资源消耗。Prometheus 和 Grafana 是当前最流行的开源监控组合：Prometheus 负责收集和存储时序数据（指标），而 Grafana 则负责将这些数据转化为直观的仪表盘。

### 1. 核心组件与工作流程

*   **NestJS 应用**: 通过 `prom-client` 库在 `/metrics` 端点暴露性能和业务指标。
*   **Prometheus 服务器**: 采用“拉取模型”（Pull Model），定期从应用的 `/metrics` 端点抓取指标数据，并使用其强大的查询语言 PromQL 进行分析。
*   **Grafana**: 连接到 Prometheus 作为数据源，通过高度可定制的仪表盘（Dashboard）来查询和可视化指标。

![工作流程](https://i.imgur.com/your-placeholder-image.png)  <!-- 你可以替换成一个真实的工作流图 -->

### 2. 在 NestJS 中集成 Prometheus

我们将使用 `prom-client` 来创建指标，并构建一个模块来暴露 `/metrics` 端点。

#### 步骤 1: 安装依赖

```bash
npm install prom-client
```

#### 步骤 2: 创建监控模块

为了更好地组织代码，我们创建一个 `metrics` 模块。

**`src/metrics/metrics.service.ts`**

这个服务将负责初始化和管理我们的自定义指标。

```typescript
import { Injectable } from '@nestjs/common';
import { Counter, Gauge, Histogram, register } from 'prom-client';

@Injectable()
export class MetricsService {
  public readonly httpRequestCounter: Counter;
  public readonly httpRequestDuration: Histogram;
  public readonly activeConnections: Gauge;

  constructor() {
    // 清理默认指标，确保只注册我们需要的
    register.clear(); 

    // 1. HTTP 请求总数 (Counter)
    this.httpRequestCounter = new Counter({
      name: 'http_requests_total',
      help: 'Total number of HTTP requests',
      labelNames: ['method', 'route', 'status_code'],
    });

    // 2. HTTP 请求延迟 (Histogram)
    this.httpRequestDuration = new Histogram({
      name: 'http_request_duration_seconds',
      help: 'Duration of HTTP requests in seconds',
      labelNames: ['method', 'route', 'status_code'],
      buckets: [0.1, 0.5, 1, 1.5, 2, 5], // 自定义延迟桶 (单位: 秒)
    });

    // 3. 活跃连接数 (Gauge)
    this.activeConnections = new Gauge({
      name: 'active_connections',
      help: 'Number of active connections',
    });

    // 注册我们创建的指标
    register.registerMetric(this.httpRequestCounter);
    register.registerMetric(this.httpRequestDuration);
    register.registerMetric(this.activeConnections);
  }
}
```

**`src/metrics/metrics.controller.ts`**

这个控制器负责暴露 `/metrics` 端点。

```typescript
import { Controller, Get, Res } from '@nestjs/common';
import { Response } from 'express';
import { register } from 'prom-client';

@Controller('metrics')
export class MetricsController {
  @Get()
  async getMetrics(@Res() res: Response) {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  }
}
```

**`src/metrics/metrics.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { MetricsController } from './metrics.controller';
import { MetricsService } from './metrics.service';

@Module({
  controllers: [MetricsController],
  providers: [MetricsService],
  exports: [MetricsService], // 导出服务，以便在其他地方使用
})
export class MetricsModule {}
```

#### 步骤 3: 使用中间件自动记录指标

创建一个中间件来自动记录所有 HTTP 请求的指标。

**`src/metrics/metrics.middleware.ts`**

```typescript
import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { MetricsService } from './metrics.service';

@Injectable()
export class MetricsMiddleware implements NestMiddleware {
  constructor(private readonly metricsService: MetricsService) {}

  use(req: Request, res: Response, next: NextFunction) {
    const end = this.metricsService.httpRequestDuration.startTimer();
    this.metricsService.activeConnections.inc(); // 活跃连接数 +1

    res.on('finish', () => {
      const labels = {
        method: req.method,
        route: req.route ? req.route.path : req.path,
        status_code: String(res.statusCode),
      };

      this.metricsService.httpRequestCounter.inc(labels);
      end(labels); // 记录请求耗时
      this.metricsService.activeConnections.dec(); // 活跃连接数 -1
    });

    next();
  }
}
```

#### 步骤 4: 应用中间件并导入模块

在 `app.module.ts` 中导入 `MetricsModule` 并对所有路由应用中间件。

```typescript
import { Module, MiddlewareConsumer, NestModule } from '@nestjs/common';
import { MetricsModule } from './metrics/metrics.module';
import { MetricsMiddleware } from './metrics/metrics.middleware';

@Module({
  imports: [MetricsModule, /* ...其他模块 */],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(MetricsMiddleware).forRoutes('*'); // 对所有路由生效
  }
}
```

现在，启动你的应用并访问 `http://localhost:3000/metrics`，你将看到 Prometheus 格式的指标输出。

### 3. 配置与可视化

#### Prometheus 服务器配置

创建一个 `prometheus.yml` 配置文件，告诉 Prometheus 从哪里抓取指标。

```yaml
global:
  scrape_interval: 15s # 每 15 秒抓取一次

scrape_configs:
  - job_name: 'nest-app'
    static_configs:
      - targets: ['host.docker.internal:3000'] # 你的 NestJS 应用地址 (在 Docker 中)
```

使用 Docker 运行 Prometheus：

```bash
docker run \
    -p 9090:9090 \
    -v /path/to/your/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus
```

#### Grafana 可视化数据

1.  **运行 Grafana**: `docker run -d -p 3001:3000 grafana/grafana`
2.  **添加数据源**: 访问 Grafana (`http://localhost:3001`)，进入 `Configuration > Data Sources`，添加一个 Prometheus 数据源，URL 指向 `http://prometheus:9090` 或 `http://localhost:9090`。
3.  **创建仪表盘**: 创建一个新的仪表盘和面板，使用下面的 PromQL 查询语句来展示指标。

#### 常用 PromQL 查询示例

*   **QPS (每秒请求数)**:
    ```promql
    sum(rate(http_requests_total[5m])) by (route)
    ```
*   **错误率 (状态码 >= 500)**:
    ```promql
    sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))
    ```
*   **P95 请求延迟 (95% 的请求耗时)**:
    ```promql
    histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, route))
    ```
*   **当前活跃连接数**:
    ```promql
    sum(active_connections)
    ```

---

## 第二部分：健康检查 — 赋予系统自愈能力

监控告诉我们系统是否“健康”，而健康检查则让容器编排系统（如 Kubernetes）能够根据应用的健康状况自动采取行动。健康检查分为两种：**Liveness (存活探针)** 和 **Readiness (就绪探针)**。

### 4. Liveness vs. Readiness：有什么区别？

| 特性 | Liveness Probe (存活探针) | Readiness Probe (就绪探针) |
| :--- | :--- | :--- |
| **目的** | 应用是否应被重启？ | 应用是否准备好接收流量？ |
| **核心问题** | “你还好吗？” | “你准备好了吗？” |
| **失败后果** | **重启容器** (kill & restart) | **从服务中移除**，停止接收流量 |
| **适用场景** | 检测死锁、内存耗尽等无法恢复的内部错误。 | 应用启动中、依赖项不可用、正在执行初始化任务等暂时无法服务的情况。 |

**原则**: 只有当重启是解决问题的唯一方法时，才让 Liveness 探针失败。当应用暂时无法处理请求，但预计未来可以恢复时，应让 Readiness 探针失败。

### 5. 在 NestJS 中实现健康检查

NestJS 官方提供了 `@nestjs/terminus` 模块，极大地简化了健康检查的实现。

#### 步骤 1: 安装依赖

```bash
npm install @nestjs/terminus @nestjs/axios axios
# 如果需要检查数据库，还需安装对应的驱动，如 @nestjs/typeorm
```

#### 步骤 2: 创建健康检查模块

**`src/health/health.controller.ts`**

```typescript
import { Controller, Get } from '@nestjs/common';
import {
  HealthCheck,
  HealthCheckService,
  HttpHealthIndicator,
  TypeOrmHealthIndicator,
  MemoryHealthIndicator,
  DiskHealthIndicator,
} from '@nestjs/terminus';

@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private http: HttpHealthIndicator,
    private db: TypeOrmHealthIndicator,
    private memory: MemoryHealthIndicator,
    private disk: DiskHealthIndicator,
  ) {}

  @Get()
  @HealthCheck()
  check() {
    // Readiness 探针应检查所有依赖项
    // Liveness 探针通常只检查应用本身是否响应
    // 这里我们创建一个通用的端点，可以同时服务于两者
    return this.health.check([
      // 1. 检查数据库连接
      () => this.db.pingCheck('database'),
      
      // 2. 检查外部依赖 (例如，一个外部 API)
      () => this.http.pingCheck('external-api', 'https://api.example.com'),

      // 3. 检查内存使用情况 (当堆内存超过 256MB 时标记为不健康)
      () => this.memory.checkHeap('memory_heap', 256 * 1024 * 1024),

      // 4. 检查磁盘空间 (当已用空间超过 90% 时标记为不健康)
      () =>
        this.disk.checkStorage('storage', {
          path: '/',
          thresholdPercent: 0.9,
        }),
    ]);
  }
}
```

**`src/health/health.module.ts`**

```typescript
import { Module } from '@nestjs/common';
import { TerminusModule } from '@nestjs/terminus';
import { HttpModule } from '@nestjs/axios';
import { HealthController } from './health.controller';

@Module({
  imports: [
    TerminusModule,
    HttpModule, // 如果需要检查外部 HTTP 端点
    // TypeOrmModule.forRoot(...) 应该在根模块导入
  ],
  controllers: [HealthController],
})
export class HealthModule {}
```

最后，在 `app.module.ts` 中导入 `HealthModule`。

### 6. 与 Kubernetes 集成

在你的 `deployment.yaml` 文件中，为容器添加 `livenessProbe` 和 `readinessProbe` 配置。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nest-app
spec:
  replicas: 3
  template:
    spec:
      containers:
        - name: my-nest-app-container
          image: your-docker-image
          ports:
            - containerPort: 3000
          
          # --- Liveness Probe ---
          # 如果应用无响应，重启它
          livenessProbe:
            httpGet:
              path: /health/liveness # 可以创建一个更简单的 liveness 端点
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
            failureThreshold: 3

          # --- Readiness Probe ---
          # 如果应用未就绪，停止向其发送流量
          readinessProbe:
            httpGet:
              path: /health # 指向我们包含所有检查的端点
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
            failureThreshold: 2
```

---

## 第三部分：分布式追踪 — 使用 OpenTelemetry 解密请求链路

当一个请求很慢，监控告诉我们“慢了”，但要回答“为什么慢”，我们就需要分布式追踪。OpenTelemetry (OTel) 是 CNCF 的一个开源项目，它旨在标准化遥测数据（Metrics, Traces, Logs）的生成、收集和导出。

### 7. 核心概念

*   **Span**: 追踪的基本工作单元，代表一个有开始和结束时间的操作（如一次 HTTP 请求、一个数据库查询）。Span 可以嵌套，形成父子关系。
*   **Trace**: 由一个或多个 Span 组成的树状结构，完整地描绘了一个请求的生命周期。
*   **Instrumentation**: 自动为常用库（如 Express, TypeORM, Axios）“插桩”的插件，无需修改代码即可自动创建 Span。
*   **Exporter**: 负责将收集到的追踪数据发送到指定的后端，如 Jaeger, Zipkin 或 OpenTelemetry Collector。

### 8. 在 NestJS 中集成 OpenTelemetry

我们将通过配置 OpenTelemetry Node.js SDK 并利用其自动插桩功能，为 NestJS 应用快速带来分布式追踪能力。

#### 步骤 1: 安装依赖

```bash
npm install @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node @opentelemetry/exporter-trace-otlp-http
```

#### 步骤 2: 创建并配置 OTel SDK

在项目的 `src` 目录下创建一个 `tracing.ts` 文件。这个文件将负责初始化和配置 OTel。

**`src/tracing.ts`**

```typescript
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { NodeSDK } from '@opentelemetry/sdk-node';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

// 配置 Trace Exporter
const traceExporter = new OTLPTraceExporter({
  // OTLP Collector 或 Jaeger/Zipkin 等后端的地址
  url: 'http://localhost:4318/v1/traces', 
});

const sdk = new NodeSDK({
  traceExporter,
  instrumentations: [getNodeAutoInstrumentations()],
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'my-nest-app',
  }),
});

// 优雅地关闭 SDK
process.on('SIGTERM', () => {
  sdk
    .shutdown()
    .then(() => console.log('Tracing terminated'))
    .catch((error) => console.log('Error terminating tracing', error))
    .finally(() => process.exit(0));
});

export default sdk;
```

#### 步骤 3: 在应用入口启动 OTel SDK

为了让 OTel 能够在所有其他模块加载之前开始工作，我们需要在 `main.ts` 的最顶端导入并启动 `tracing.ts`。

**`src/main.ts`**

```typescript
// 必须在所有其他导入之前首先导入和启动 tracing
import tracing from './tracing';
tracing.start();

import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  await app.listen(3000);
}
bootstrap();
```

**重要**: 确保 `import tracing from './tracing'` 是 `main.ts` 文件中的第一行可执行代码，这对于自动插桩的正常工作至关重要。

#### 步骤 4: 运行追踪后端 (例如 Jaeger)

你可以使用 Docker 快速启动一个 Jaeger 实例，它已经内置了 OTLP 接收器。

```bash
docker run -d --name jaeger \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 16686:16686 \
  -p 4318:4318 \
  jaegertracing/all-in-one:latest
```

现在，启动你的 NestJS 应用，并发送一些请求。然后访问 Jaeger UI `http://localhost:16686`，你应该能在服务列表中看到 `my-nest-app`，并能查看到完整的请求追踪链！

### 9. 手动创建自定义 Span

自动插桩非常强大，但有时你需要追踪特定的业务逻辑。

```typescript
import { Injectable } from '@nestjs/common';
import { trace, context } from '@opentelemetry/api';

@Injectable()
export class AppService {
  private readonly tracer = trace.getTracer('my-app-tracer');

  async processOrder(orderId: string): Promise<void> {
    // 创建一个新的子 Span，它会自动关联到当前活动的 Span (例如 HTTP 请求的 Span)
    await this.tracer.startActiveSpan('process-order', async (span) => {
      span.setAttribute('order.id', orderId);

      // 添加一个事件
      span.addEvent('Order validation started');
      // ... 模拟一些工作
      await new Promise(resolve => setTimeout(resolve, 100));
      span.addEvent('Order validation finished');

      // ...

      // Span 会在回调函数结束时自动关闭
      span.end();
    });
  }
}
```

---

## 总结：构建完整的可观测性体系

| 特性 | 监控 (Prometheus) | 健康检查 (Terminus) | 追踪 (OpenTelemetry) |
| :--- | :--- | :--- | :--- |
| **目标** | 回答“系统**是否**健康？” | 回答“应用**能否**服务？”并触发自愈 | 回答“请求**为什么**慢/失败？” |
| **粒度** | 聚合的、宏观的 | 单个实例的、状态性的 | 单个请求的、微观的 |
| **数据形式** | 时间序列指标 | 二元状态 (UP/DOWN) | 调用链图 (Traces/Spans) |
| **核心工具** | Prometheus, Grafana | Kubernetes, Terminus | OpenTelemetry, Jaeger, Zipkin |
| **NestJS 实现** | 中间件收集指标，暴露 `/metrics` 端点 | 控制器暴露 `/health` 端点 | 在入口文件启动 SDK，自动插桩 |

监控、健康检查和追踪共同构成了现代应用可观测性的基石。NestJS 凭借其优秀的模块化和 AOP（面向切面编程）设计，让我们能够非常优雅地将这些非业务功能集成进来，保持核心代码的纯净。

现在，我想留给你一个问题来思考：

**想象一下，你的一个关键业务接口响应时间突然从 50ms 上涨到 2s。你会如何利用今天我们讨论的知识，一步步地定位到问题的根源呢？**
