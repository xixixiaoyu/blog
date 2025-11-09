# OpenTelemetry Node.js 入门

目标
- 为 Node 应用添加分布式追踪，快速查看请求的 Trace/Span。

依赖安装
```bash
npm i @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node
npm i -D tsx typescript
```

初始化 SDK：otel.ts
```ts
import { NodeSDK } from '@opentelemetry/sdk-node';
import { ConsoleSpanExporter } from '@opentelemetry/sdk-trace-base';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';

const sdk = new NodeSDK({
  // 简单导出到控制台，生产环境可替换为 OTLP 导出到可视化平台
  traceExporter: new ConsoleSpanExporter(),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start().then(() => {
  console.log('OpenTelemetry SDK started');
}).catch(err => {
  console.error('Error starting OTel SDK', err);
});

// 可选：在进程退出时优雅关闭
process.on('SIGTERM', async () => {
  await sdk.shutdown();
  process.exit(0);
});
```

示例服务：server.ts
```ts
import './otel'; // 必须在其他导入前初始化 SDK
import http from 'http';

const server = http.createServer((_req, res) => {
  res.writeHead(200, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ ok: true }));
});

server.listen(3000, () => console.log('http://localhost:3000'));
```

运行
```bash
npx tsx server.ts
# 控制台可看到 Span 导出
```

要点
- 自动探针会为 http、fs、DNS 等常用模块生成 Span。
- 生产建议使用 OTLP 导出到 Jaeger/Tempo/Zipkin 等。
- 与日志（Pino）结合时，可在日志里输出 TraceID 以便串联。

