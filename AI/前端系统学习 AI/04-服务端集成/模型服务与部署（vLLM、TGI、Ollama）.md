# 写作提示 —— 模型服务与部署（vLLM、TGI、Ollama）

使用说明：
- 面向后端/平台工程与前端协作，生成“如何部署与运维推理服务”的落地指南。
- 聚焦主流推理服务：vLLM、TGI（Text Generation Inference）、Ollama，以及私有化/本地化部署。

生成目标：
- 比较不同推理服务的能力、资源需求、性能与生态（API 兼容、扩展性）。
- 给出部署与配置步骤（容器、GPU/CPU、显存规划、量化策略、并发参数）。
- 总结扩缩容、负载均衡、滚动升级、A/B 测试与回滚策略。
- 提供多云/多供应商的路由与降级方案，保证稳定性与成本可控。

大纲建议：
1. 选型维度（模型支持、性能、易用性、生态与社区）
2. 环境与资源规划（GPU/CPU、显存与内存、网络带宽）
3. 部署与配置（容器镜像、参数、量化、并发与队列）
4. 路由与扩缩容（负载均衡、自动化伸缩、优先级调度）
5. 升级与回滚（版本管理、兼容策略、灰度发布）
6. 观测与运维（日志、指标、Tracing、告警）
7. 安全与合规（访问控制、隔离、清理与审计）

输出格式要求：
- Markdown；附示例部署命令/配置片段（Docker/K8s）与参数解释。
- 给出性能/成本对比的文字表或清单（QPS、延迟、显存占用）。

质量检查清单：
- 步骤可执行；参数含义明确，能复现性能指标。
- 有升级与回滚策略；不影响线上服务稳定性。
- 兼顾安全与合规；权限与访问控制清晰。


默认技术栈（网关与粘合层）：TypeScript + NestJS

最小部署示例（容器）
- vLLM（OpenAI 兼容 REST）：
  - Docker（GPU）：
    ```bash
    docker run --rm -it \
      --gpus all -p 8000:8000 \
      -v /models:/models \
      vllm/vllm-openai:latest \
      --model /models/Qwen2.5-7B-Instruct \
      --gpu-memory-utilization 0.90 \
      --max-model-len 32768
    ```
  - 说明：暴露 OpenAI 风格的 `/v1/chat/completions`，支持 `stream: true`。
- TGI（Text Generation Inference）：
  - Docker（GPU）：
    ```bash
    docker run --rm -it \
      --gpus all -p 8080:80 \
      ghcr.io/huggingface/text-generation-inference:2.1 \
      --model-id meta-llama/Llama-3-8b-instruct
    ```
  - 说明：支持 SSE 流式接口（`/generate_stream`）。
- Ollama（本地推理）：
  - macOS：`brew install ollama && ollama serve && ollama pull llama3`
  - REST：`POST /api/chat`，通过 `stream: true` 获取增量输出。

NestJS 网关 → 统一 SSE 输出（对接 OpenAI/vLLM/TGI/Ollama）

依赖：`npm i openai rxjs @nestjs/common`

```ts
// src/model-gateway.controller.ts
import { Controller, Sse, MessageEvent, Query } from '@nestjs/common';
import { Subject } from 'rxjs';
import OpenAI from 'openai';

type Provider = 'openai' | 'vllm' | 'tgi' | 'ollama';

@Controller('model')
export class ModelGatewayController {
  private openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY! });

  @Sse('chat')
  async chat(
    @Query('provider') provider: Provider = 'openai',
    @Query('prompt') prompt = 'hello',
  ): Promise<Subject<MessageEvent>> {
    const out$ = new Subject<MessageEvent>();

    const push = (payload: any) => out$.next({ data: payload });
    const done = () => out$.complete();
    const fail = (e: any) => out$.error(e);

    (async () => {
      try {
        if (provider === 'openai') {
          const stream = await this.openai.chat.completions.create({
            model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
            messages: [{ role: 'user', content: prompt }],
            stream: true,
          });
          for await (const chunk of stream) {
            const delta = chunk.choices?.[0]?.delta?.content;
            if (delta) push({ type: 'delta', data: delta });
          }
          push({ type: 'complete' });
          return done();
        }

        if (provider === 'vllm') {
          // vLLM: OpenAI 兼容 API（示例使用 fetch）
          const res = await fetch('http://localhost:8000/v1/chat/completions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              model: process.env.VLLM_MODEL || 'Qwen2.5-7B-Instruct',
              messages: [{ role: 'user', content: prompt }],
              stream: true,
            }),
          });
          const reader = res.body!.getReader();
          const decoder = new TextDecoder();
          let buf = '';
          while (true) {
            const { value, done: d } = await reader.read();
            if (d) break;
            buf += decoder.decode(value, { stream: true });
            // 简单解析 SSE 行（生产建议使用 eventsource-parser）
            for (const line of buf.split('\n')) {
              if (line.startsWith('data: ')) {
                const payload = line.slice(6).trim();
                if (payload === '[DONE]') continue;
                try {
                  const json = JSON.parse(payload);
                  const delta = json?.choices?.[0]?.delta?.content;
                  if (delta) push({ type: 'delta', data: delta });
                } catch {}
              }
            }
            buf = '';
          }
          push({ type: 'complete' });
          return done();
        }

        if (provider === 'tgi') {
          const res = await fetch('http://localhost:8080/generate_stream', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              inputs: prompt,
              parameters: { temperature: 0.7 },
            }),
          });
          const reader = res.body!.getReader();
          const decoder = new TextDecoder();
          while (true) {
            const { value, done: d } = await reader.read();
            if (d) break;
            const text = decoder.decode(value);
            // TGI 返回逐步文本块
            push({ type: 'delta', data: text });
          }
          push({ type: 'complete' });
          return done();
        }

        if (provider === 'ollama') {
          const res = await fetch('http://localhost:11434/api/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              model: process.env.OLLAMA_MODEL || 'llama3',
              messages: [{ role: 'user', content: prompt }],
              stream: true,
            }),
          });
          const reader = res.body!.getReader();
          const decoder = new TextDecoder();
          while (true) {
            const { value, done: d } = await reader.read();
            if (d) break;
            const lines = decoder.decode(value).trim().split('\n');
            for (const line of lines) {
              try {
                const json = JSON.parse(line);
                const delta = json?.message?.content || json?.response;
                if (delta) push({ type: 'delta', data: delta });
              } catch {}
            }
          }
          push({ type: 'complete' });
          return done();
        }
      } catch (e) {
        fail({ type: 'error', message: (e as Error).message });
      }
    })();

    return out$;
  }
}
```

路由与降级（示例策略）：
- 首选高质量模型（OpenAI/Anthropic）；若失败或超时回退本地 vLLM/Ollama。
- 依据上下文长度与成本选择模型；超过上限自动截断或摘要。
- 按租户/场景配置权重与优先级，暴露动态配置（环境变量/配置中心）。

配置建议（文字版）：
- 并发参数：`max_concurrent_requests` 控制队列长度；适当的 `gpu-memory-utilization` 防止 OOM。
- 量化策略：优先尝试 `AWQ/GGUF` 以降低显存；对质量敏感场景保留 FP16。
- 超时与重试：流式请求整体超时（如 30s），短重试（1-2 次），指数退避；出现 429/503 时切换提供商。
- 监控：记录延迟、吞吐、错误率；按模型维度打点，支持 A/B 对比与回滚。
