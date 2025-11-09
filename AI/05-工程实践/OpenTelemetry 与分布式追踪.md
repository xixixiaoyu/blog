# 写作提示 —— OpenTelemetry 与分布式追踪

使用说明：
- 生成跨前后端的分布式追踪方案，串联一次会话的端到端链路。

生成目标：
- 设计 Trace/Span 与上下文传播（前端 → 代理层 → 模型服务 → 向量库）。
- 在流式响应中记录事件与耗时；关联日志与指标。
- 提供可视化与报表实践（仪表板、告警、根因分析）。

大纲建议：
1. 追踪模型与上下文传播（Trace/Span/ID）
2. 前端埋点与链路起点（会话/消息 ID）
3. 代理层与后端追踪（SSE/WS/gRPC 的 span 切分）
4. 模型与检索层追踪（耗时与错误）
5. 日志与指标的关联（统一 ID、采样率）
6. 可视化、告警与根因分析（仪表板）

输出格式要求：
- Markdown；附最小追踪集成示例与字段约定。
- 给出采样率与性能影响的建议。

质量检查清单：
- 链路可串联；跨层标识统一，便于定位问题。
- 采样与性能权衡合理；可视化清晰。
- 与日志与评估形成闭环。

默认技术栈：TypeScript + NestJS；OTLP（HTTP/GRPC）导出到可视化平台（Grafana Tempo/Jaeger）

最小集成（Node/OpenTelemetry SDK）

依赖：`npm i @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node @opentelemetry/exporter-trace-otlp-http`

```ts
// src/otel.ts
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({ url: process.env.OTLP_HTTP_URL || 'http://localhost:4318/v1/traces' }),
  instrumentations: [getNodeAutoInstrumentations()],
});

export async function startOtel() {
  await sdk.start();
  console.log('OTel started');
}
export async function stopOtel() { await sdk.shutdown(); }
```

在应用入口启动 OTel：

```ts
// src/main.ts
import { startOtel } from './otel';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  await startOtel();
  const app = await NestFactory.create(AppModule);
  await app.listen(3000);
}
bootstrap();
```

上下文传播与标识约定：
- 使用 W3C Trace Context：`traceparent`/`tracestate`；在 HTTP/SSE 响应头中返回 `traceparent`。
- 自定义字段：`x-trace-id`、`x-session-id`、`x-message-id`；前端保存并在后续请求中携带。

SSE/WS 的 Span 切分示例：

```ts
// 在 SSE 控制器中手动创建 span 并记录事件
import { context, trace } from '@opentelemetry/api';

const tracer = trace.getTracer('gateway');
// 伪代码：每次连接一个 span
const span = tracer.startSpan('sse_stream', undefined, context.active());
span.setAttribute('model', 'gpt-4o-mini');
span.addEvent('stream_start');
// 在每个 delta 推送时（采样）记录事件与字节数
span.addEvent('delta', { bytes: 64 });
// 完成或取消时结束 span
span.addEvent('stream_complete');
span.end();
```

前端埋点与链路起点（文字版）：
- 生成 `sessionId` 与 `messageId`；在首次请求时记录 `traceparent` 与这些 ID；
- 在 SSE/WS 建立连接时，将 `sessionId/messageId` 作为查询参数或头部传递；
- 渲染端记录片段耗时、撤销/取消事件；与后端统一 ID 关联。

可视化与告警建议：
- Tempo/Jaeger：查看端到端 Span（前端 → 网关 → 模型服务 → 检索服务）
- 指标关联：将 Span 属性映射到指标（如模型、租户、延迟）；对错误率与超时进行告警；
- 采样率：默认 1-10% 采样，故障时提升采样以便根因分析。
