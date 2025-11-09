# 写作提示 —— 测试与 Mock（可重复性与快照）

使用说明：
- 生成面向 LLM 应用的测试与 Mock 指南，解决不确定性与可复现问题。

生成目标：
- 设计黄金样例与快照测试（输出对齐、结构化校验）。
- 为 LLM 调用提供 Mock/Stub；控制采样（温度、Top-p）与随机性（seed）。
- 提供函数调用的契约测试与错误场景覆盖。

大纲建议：
1. 测试金样与数据集（任务定义、期望输出）
2. Mock/Stub 方案（离线/在线；跨供应商）
3. 快照与结构化校验（JSON Schema/Grammar）
4. 函数调用契约测试（参数校验、错误路径）
5. 随机性控制（seed、采样参数）
6. CI 集成与门控（失败重现、阈值）

输出格式要求：
- Markdown；附最小测试/Mock 代码片段与配置建议。
- 标注与评估框架/CI 的集成方式。

质量检查清单：
- 测试可重复；快照与结构化校验可靠。
- Mock 覆盖主路径与错误路径；避免脆弱性。
- 与 CI 与评估闭环集成。

默认技术栈：TypeScript + NestJS + Jest + Supertest

最小 e2e 测试（HTTP 非流式）：

依赖：`npm i -D jest @types/jest supertest ts-jest`

```ts
// test/llm.e2e-spec.ts
import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('LLM (e2e)', () => {
  let app: INestApplication;
  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    app = moduleRef.createNestApplication();
    await app.init();
  });
  afterAll(async () => { await app.close(); });

  it('should return text', async () => {
    const res = await request(app.getHttpServer()).post('/llm/chat').send({ prompt: 'hello' });
    expect(res.status).toBe(201); // 或 200，视实现而定
    expect(res.body.text).toBeDefined();
  });
});
```

SSE 的测试思路（伪代码）：
- 使用 `node-fetch` 与 `eventsource-parser` 读取增量，将其聚合后断言；或提供一个本地 `SSEClient` 辅助类。

```ts
// test/sse.client.ts（示例思路）
import fetch from 'node-fetch';
import { createParser } from 'eventsource-parser';

export async function readSse(url: string): Promise<string> {
  const res = await fetch(url);
  const reader = res.body!.getReader();
  const decoder = new TextDecoder();
  let result = '';
  const parser = createParser((event) => {
    if (event.type === 'event') {
      try {
        const json = JSON.parse(event.data);
        if (json.type === 'delta') result += json.data;
      } catch {}
    }
  });
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    parser.feed(decoder.decode(value));
  }
  return result;
}
```

WebSocket 的测试（socket.io-client）：

依赖：`npm i -D socket.io-client`

```ts
// test/ws.spec.ts
import { io } from 'socket.io-client';

it('ws stream should send deltas', (done) => {
  const socket = io('http://localhost:3000');
  const chunks: string[] = [];
  socket.on('delta', (ev: any) => chunks.push(ev.data));
  socket.on('complete', () => {
    expect(chunks.length).toBeGreaterThan(0);
    socket.disconnect();
    done();
  });
  socket.emit('start', { prompt: 'hello' });
});
```

Mock/Stub 上游调用（OpenAI 示例）：

```ts
// src/openai.service.ts（在测试环境中注入 mock 实现）
export class OpenAIService {
  async nonStream(prompt: string) { return `Echo: ${prompt}`; }
  async *stream(prompt: string) { yield `Echo: ${prompt}`; }
}
```

结构化校验与快照：
- 使用 Zod/JSON Schema 校验函数调用输入输出；
- 对关键输出进行快照测试（`expect(text).toMatchSnapshot()`）；
- 控制随机性：固定 temperature/top-p，使用固定 seed（供应商支持时）。

CI 集成与门控：
- 在 CI 上运行 e2e 与快照；对失败进行日志收集与重试（一次）；
- 评估框架（LangSmith/Ragas/DeepEval）在 PR 中生成报表；设定阈值门槛（质量/回归）。
