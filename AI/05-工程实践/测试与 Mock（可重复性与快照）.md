# 写作提示 —— 为你的 AI 构建一个“飞行模拟器”

**核心类比**：将 AI 应用的测试过程，想象为为一架先进但行为复杂的“AI 飞行器”建造一个全功能的“飞行模拟器”。我们的目标是在它搭载真实“乘客”（用户）之前，确保其在各种预设“航线”和“极端天气”（边界情况）下的安全性、可靠性和可预测性。

**使用说明**：
- 本提示旨在生成一份关于 AI 应用测试与质量保障的权威指南。
- 你需要以“飞行模拟器建设手册”的口吻和结构，系统性地阐述如何解决 AI 的不确定性与可复现性挑战。

**生成目标**：
- **飞行脚本设计**：指导如何创建黄金测试用例（Golden Datasets），作为模拟器中必须通过的“核心飞行任务”。
- **虚拟环境搭建**：阐述如何通过 Mock/Stub 隔离外部依赖（如 API、数据库），为“AI 飞行器”创建一个完全受控的“虚拟驾驶舱”。
- **飞行记录仪安装**：解释如何利用快照测试（Snapshot Testing）来记录和比对“飞行数据”（LLM 输出），以及如何用结构化校验（如 Zod）确保“仪表盘读数”（数据格式）的精确性。
- **天气系统控制**：说明如何通过控制采样参数（`temperature`）和固定随机种子（`seed`），创造一个“风和日丽”的确定性环境，以进行可复现的“基础飞行测试”。
- **飞行员认证流程**：规划如何将整个“飞行模拟器”集成到 CI/CD 流程中，建立一套自动化的“飞行员认证”体系，确保每个新版本的“飞行器”都经过严格测试才能“首飞”。

**大纲建议：《AI 飞行模拟器建设手册》**

1.  **第一章：模拟的哲学 —— 为何要为 AI 建立模拟器？**
    *   引入“AI 飞行器”与“飞行模拟器”的核心类比。
    *   论证在非确定性系统中，测试的重点从“预测精确结果”转向“验证行为边界、能力和安全性”。

2.  **第二章：设计飞行脚本 —— 打造你的黄金测试集**
    *   定义“飞行任务”：如何根据产品需求，设计核心的测试场景。
    *   编写“飞行计划”：创建包含输入（Prompt）和期望输出（或评估标准）的黄金数据集。
    *   案例：用户意图识别、RAG 准确性、函数调用正确性等场景的测试集设计。

3.  **第三章：构建虚拟世界 —— 精通 Mock 与 Stub**
    *   “与世隔绝”的驾驶舱：Mock 所有外部 API、数据库、函数调用，确保测试的独立性、速度和确定性。
    *   提供 Mock 实现，覆盖正常路径和“引擎故障”（错误处理）路径。
    *   代码示例：使用 Jest Mock 注入一个伪造的 `OpenAIService`。

4.  **第四章：安装飞行记录仪 —— 快照与结构化校验**
    *   “黑匣子”的重要性：使用快照测试（`toMatchSnapshot`）来捕捉和回归测试 LLM 的关键输出。
    *   “仪表盘”的精确性：使用 Zod 或 JSON Schema 对模型的结构化输出（如 JSON）进行严格的格式和内容校验。
    *   讨论快照测试在 LLM 场景下的脆弱性与管理策略。

5.  **第五章：控制天气 —— 驯服随机性**
    *   “风和日丽”的测试环境：在测试中将 `temperature` 设为 0，并尽可能使用 `seed`，以获得可复现的输出，专注于测试核心逻辑。
    *   解释这与生产环境的高创造性设置有何不同，以及为何这种控制在测试中是必要的。

6.  **第六章：飞行员认证流程 —— CI/CD 与质量门禁**
    *   自动化“模拟飞行”：将所有测试（单元、集成、E2E）集成到 CI 流程中（如 GitHub Actions）。
    *   设立“认证标准”：在 PR 中自动运行测试，失败则阻止合并。
    *   集成评估框架（如 LangSmith, Ragas）的报告，设定“通过认证”的质量阈值（如准确率 > 95%）。

7.  **第七章：高级模拟 —— 应对复杂飞行器（流式响应测试）**
    *   为需要实时响应的“喷气式飞机”（如 SSE, WebSocket）设计专门的测试方案。
    *   提供测试流式响应的客户端辅助工具代码和测试策略。

**质量检查清单（飞行前检查）**：
- **模拟环境完整吗？**：Mock 是否覆盖了所有关键的外部依赖和错误路径？
- **飞行脚本真实吗？**：黄金测试集是否能代表核心用户场景和潜在风险？
- **记录仪可靠吗？**：快照和结构化校验是否足够健壮，既能发现问题又不过于脆弱？
- **天气可控吗？**：随机性是否在测试中被有效管理，以确保结果的可复现性？
- **认证流程自动化了吗？**：CI/CD 是否能自动执行所有测试并有效阻止不合格的“飞行器”进入下一阶段？

---
*保留并重构原有代码示例，将其嵌入到新的章节结构中，作为每个“建设步骤”的具体实现。*
---

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
