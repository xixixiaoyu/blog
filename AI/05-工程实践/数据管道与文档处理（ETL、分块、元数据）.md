# 写作提示 —— 数据管道与文档处理（ETL、分块、元数据）

使用说明：
- 生成面向 RAG 的数据管道文章，覆盖采集、清洗、分块、元数据与入库。

生成目标：
- 设计从文档来源到向量库的流水线：抽取、清洗、分块、元数据标注、入库与回填。
- 介绍增量构建、重复检测、版本化与回放机制。
- 提供批处理与实时（事件驱动）的实现建议与工具链。

大纲建议：
1. 文档来源与抽取（网页、PDF、Markdown、API）
2. 清洗与规范化（格式统一、噪声处理、编码）
3. 分块策略与元数据（大小、重叠、层级、标签）
4. 入库与回填（向量库、关系库、对象存储）
5. 增量与版本化（变更检测、去重、回放）
6. 批处理与实时（任务队列、事件流、失败重试）
7. 监控与治理（数据质量、覆盖率、审计）

输出格式要求：
- Markdown；附最小管道代码片段或伪代码与配置建议。
- 给出数据质量与覆盖率的评估方法。

质量检查清单：
- 流水线可运行或易于运行；数据质量治理到位。
- 有版本化与回放机制，支持可追溯。
- 兼顾成本与性能，避免重复计算。

默认技术栈：
- 管道与索引：Python + FastAPI（文档解析、分块、Embedding/索引）
- 网关与消费：TypeScript + NestJS（调用管道 API，融合到 RAG 回答）

FastAPI 最小管道示例（伪代码，可运行化）

依赖：`pip install fastapi uvicorn pydantic`

```py
# app.py
from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict

app = FastAPI()

class IngestItem(BaseModel):
    id: str
    text: str
    meta: Dict[str, str] = {}

DB: Dict[str, IngestItem] = {}

@app.post('/ingest')
def ingest(items: List[IngestItem]):
    for it in items:
        DB[it.id] = it
    return { 'count': len(items) }

@app.post('/index')
def index():
    # TODO: 解析/分块/embedding/入库（省略，演示用）
    return { 'ok': True }

class SearchReq(BaseModel):
    query: str
    topK: int = 5

@app.post('/search')
def search(req: SearchReq):
    # 伪检索：返回包含 query 的文本
    matches = [
        { 'id': id, 'score': 0.5, 'text': item.text, 'meta': item.meta }
        for id, item in DB.items() if req.query.lower() in item.text.lower()
    ][:req.topK]
    return { 'matches': matches }

# 启动：uvicorn app:app --host 0.0.0.0 --port 8001
```

NestJS 接口契约与调用示例：

```ts
// src/pipeline.service.ts
import { Injectable } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class PipelineService {
  constructor(private readonly http: HttpService) {}

  async ingest(items: Array<{ id: string; text: string; meta?: Record<string, string> }>) {
    const res$ = this.http.post('http://localhost:8001/ingest', items);
    return (await firstValueFrom(res$)).data;
  }

  async index() {
    const res$ = this.http.post('http://localhost:8001/index', {});
    return (await firstValueFrom(res$)).data;
  }

  async search(query: string, topK = 5) {
    const res$ = this.http.post('http://localhost:8001/search', { query, topK });
    return (await firstValueFrom(res$)).data.matches as Array<{ id: string; score: number; text: string; meta: any }>;
  }
}
```

分块与元数据建议（文字版）：
- 分块大小：普通文本 500-1000 tokens；代码/表格适当缩小；保持 10-20% 重叠；
- 层级：文档 → 章节 → 段落 → 片段；存储层保持层级与来源引用；
- 元数据：`source`、`title`、`section`、`tags`、`lang`、`updatedAt`；为检索过滤与引用渲染服务。

增量与版本化：
- 变更检测：基于哈希/ETag；只更新变更片段；
- 去重：按 `source+hash` 唯一键；维护 `version` 与 `status`（active/deleted）
- 回放：保留历史版本用于评估回归与解释。

监控与治理（字段建议）：
- `docCount`、`chunkCount`、`avgChunkSize`、`embedLatencyMs`、`indexLatencyMs`、`errorRate`；
- 数据质量抽样：随机抽查片段覆盖率与相关性；
- 失败重试：指数退避与死信队列；记录失败原因与次数。
