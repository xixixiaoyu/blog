# 写作提示 —— 常用 AI API

使用说明：
- 生成主流 AI API 的工程对比与入门指南，帮助选型与快速集成。

生成目标：
- 介绍常见提供商（如 OpenAI、Anthropic、Google、Azure、国内平台、本地/私有化方案）。
- 对比能力、价格、速率限制、稳定性与生态。
- 提供统一调用示例（REST/WebSocket/SSE）、流式输出与函数调用示例。

大纲建议：
1. 选型维度与优先级（能力、成本、稳定性、合规）
2. 调用模式（REST、SSE、WebSocket）、流式与非流式差异
3. 函数调用/工具使用（参数校验、错误处理）
4. 本地/私有化方案与代理层（网关、负载均衡、降级）
5. 常见坑与并发注意事项（速率、重试、退避）
6. 版本与兼容策略（API 变更、SDK 更新）

输出格式要求：
- Markdown；给出统一的最小调用示例与依赖版本。
- 以表格或清单形式总结对比结论（文字版）。

质量检查清单：
- 示例完整可运行或易于运行；包含流式与函数调用。
- 选型标准明确，有具体场景建议。
- 考虑本地化/私有化与代理层的工程现实。

默认技术栈（示例代码）：TypeScript + NestJS

OpenAI（Chat Completions）最小调用与流式示例：

依赖：`npm i openai`

```ts
// src/openai.service.ts
import { Injectable } from '@nestjs/common';
import OpenAI from 'openai';

@Injectable()
export class OpenAIService {
  private client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY! });

  async nonStream(prompt: string) {
    const r = await this.client.chat.completions.create({
      model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
    });
    return r.choices[0]?.message?.content ?? '';
  }

  async *stream(prompt: string) {
    const s = await this.client.chat.completions.create({
      model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      stream: true,
    });
    for await (const chunk of s) {
      const delta = chunk.choices?.[0]?.delta?.content;
      if (delta) yield delta;
    }
  }
}
```

Anthropic（Messages API）最小调用示例：

依赖：`npm i @anthropic-ai/sdk`

```ts
// src/anthropic.service.ts
import { Injectable } from '@nestjs/common';
import Anthropic from '@anthropic-ai/sdk';

@Injectable()
export class AnthropicService {
  private client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY! });

  async nonStream(prompt: string) {
    const r = await this.client.messages.create({
      model: process.env.ANTHROPIC_MODEL || 'claude-3-5-sonnet-20240620',
      max_tokens: 1024,
      messages: [{ role: 'user', content: prompt }],
    });
    return r.content?.[0]?.type === 'text' ? r.content[0].text : '';
  }
}
```

函数调用示例（统一参数校验）：

依赖：`npm i zod`

```ts
// src/tools.service.ts
import { Injectable } from '@nestjs/common';
import { z } from 'zod';

const WeatherInput = z.object({ city: z.string(), date: z.string().optional() });

@Injectable()
export class ToolsService {
  async callWeather(args: unknown) {
    const input = WeatherInput.parse(args); // 参数校验
    // 执行工具逻辑（伪代码）
    return { tempC: 26, city: input.city, date: input.date ?? 'today' };
  }
}
```

选型建议（文字版）：
- OpenAI：功能全面、生态成熟；成本与合规需评估。
- Anthropic：长上下文与安全对齐较强；适合复杂推理与长文档。
- vLLM/TGI/Ollama：私有化与成本可控；需考虑部署与维护成本、模型效果差异。
- 国内平台：注意接口稳定性、速率限制与合规（数据出境、隐私）。

并发与常见坑：
- 速率限制：遵循官方速率并使用代理层限流与队列；对 429/503 加入退避重试。
- JSON 与函数调用：严格使用 Schema 校验，避免幻觉参数；失败回退到纯文本回答。
- 流式渲染：统一事件格式；前端按片段合并与代码块处理，避免闪烁。
