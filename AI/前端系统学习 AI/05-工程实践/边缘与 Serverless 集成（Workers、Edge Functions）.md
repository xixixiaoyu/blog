# 写作提示 —— 边缘与 Serverless 集成（Workers、Edge Functions）

使用说明：
- 生成在边缘/Serverless 环境集成 AI 的实践指南，处理冷启动与并发限制。

生成目标：
- 比较 Cloudflare Workers、Vercel Edge、Netlify Functions 等的能力与限制。
- 设计流式响应、超时与取消、速率限制与重试策略。
- 管理 Secrets 与配置；处理冷启动与资源配额。

大纲建议：
1. 环境差异与限制（运行时、内存、超时、并发）
2. 流式实现（SSE/WS）与兼容性
3. 冷启动与性能优化（预热、分层路由、缓存）
4. 速率限制与重试（队列与退避）
5. Secrets 与配置管理（KV、环境变量、密钥轮换）
6. 观测与告警（日志、指标、Tracing）

输出格式要求：
- Markdown；附最小边缘函数示例与参数建议。
- 标注兼容性与限制说明，给出降级方案。

质量检查清单：
- 流式效果稳定；冷启动与超时可控。
- 有速率限制与重试，避免请求风暴。
- 管理 Secrets 安全可审计。

默认技术栈：TypeScript（Cloudflare Workers / Vercel Edge）+ 后端网关（NestJS）

Cloudflare Workers —— 转发 SSE 到 NestJS 网关：

```ts
// worker.ts
export default {
  async fetch(req: Request, env: Env) {
    const url = new URL(req.url);
    if (url.pathname === '/chat') {
      // 转发到后端 NestJS SSE（统一事件格式）
      const upstream = await fetch(env.NEST_BASE + '/model/chat?provider=openai&prompt=' + url.searchParams.get('q'));
      const { readable, writable } = new TransformStream();
      const writer = writable.getWriter();
      const encoder = new TextEncoder();
      const reader = upstream.body!.getReader();
      // 直接透传 SSE 文本
      writer.write(encoder.encode(':' + 'worker-bridge\n\n')); // 注释心跳（可选）
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        await writer.write(value);
      }
      await writer.close();
      return new Response(readable, { headers: { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache' } });
    }
    return new Response('ok');
  },
} satisfies ExportedHandler<Env>;
```

Vercel Edge Function —— 统一 SSE 输出（转发 NestJS）：

```ts
// vercel/edge.ts
import { NextRequest } from 'next/server';

export const config = { runtime: 'edge' };

export default async function handler(req: NextRequest) {
  const prompt = req.nextUrl.searchParams.get('q') ?? 'hello';
  const upstream = await fetch(process.env.NEST_BASE + `/model/chat?provider=openai&prompt=${encodeURIComponent(prompt)}`);
  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();
  const reader = upstream.body!.getReader();
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    await writer.write(value);
  }
  await writer.close();
  return new Response(readable, { headers: { 'Content-Type': 'text/event-stream' } });
}
```

速率限制与重试（文字版）：
- Workers/Edge 层实施简单速率限制（按 IP/租户），重试采用指数退避；
- 对后端返回 429/503，边缘层降速并提示用户；

Secrets 管理：
- Workers：`wrangler.toml` 的 `vars` 与 `secrets`；Vercel：环境变量与 Secret 管理；
- 不在边缘层保存供应商密钥，仅保存后端网关地址与短期令牌；

冷启动与优化：
- 预热：保持 Workers 常用路由活跃（定时心跳请求）；Edge 函数可用轻量初始化；
- 缓存：静态资源与公共上下文缓存；对不可缓存的 SSE 路径避免 CDN 干预；

兼容性与降级：
- 若边缘运行时无法处理复杂解析（如 eventsource-parser），直接透传 SSE 文本；
- 上游不支持流式时，边缘层模拟分片（150ms）输出，改善前端体验；
