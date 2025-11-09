# 写作提示 —— 流式协议细节与粘合层（SSE、WS、gRPC）

使用说明：
- 生成统一流式事件格式与适配层的工程实践，提升跨供应商与跨协议的可维护性。

生成目标：
- 总结 SSE、WebSocket、gRPC 的流式差异、事件模型与兼容性问题。
- 定义统一的 delta 事件格式（文本增量、函数调用事件、错误事件）。
- 处理 Back-pressure、取消/超时、重连、心跳、网络抖动与代理中间层问题。

大纲建议：
1. 协议对比（握手、事件、可靠性与兼容性）
2. 统一事件格式（delta、完成、错误、心跳、meta）
3. 取消/超时与资源控制（中止信号、优雅结束）
4. 重连与断点续传策略（游标/偏移）
5. Markdown/代码块增量渲染与粘合层处理
6. 代理/网关层的适配（多供应商事件桥接与转译）
7. 观测与调试（事件日志、指标、追踪）

输出格式要求：
- Markdown；附最小适配层代码片段与前端消费示例。
- 给出取消、重连与心跳的实现方案与参数建议。

质量检查清单：
- 粘合层设计可复用；覆盖主流协议与供应商差异。
- 流式渲染稳定，错误与中止处理明确。
- 有观测与调试手段，便于定位问题。


默认技术栈（服务端）：TypeScript + NestJS（SSE、WebSocket 原生支持）

统一事件格式约定（供前后端复用）：
- delta：增量文本或结构化片段，如 `{ type: 'delta', data: '...text...' }`
- tool_call：函数调用/工具步骤事件，如 `{ type: 'tool_call', name, args }`
- error：错误事件，如 `{ type: 'error', code, message }`
- complete：完成事件，如 `{ type: 'complete' }`
- ping/heartbeat：心跳事件，如 `{ type: 'ping', ts }`

最小可运行示例（NestJS SSE 粘合层）

依赖：`npm i @nestjs/common rxjs`

```ts
// src/stream.controller.ts
import { Controller, Sse, MessageEvent, Req } from '@nestjs/common';
import type { Request } from 'express';
import { Observable, interval, fromEvent } from 'rxjs';
import { map, take, takeUntil } from 'rxjs/operators';

@Controller('stream')
export class StreamController {
  // 输出统一事件格式：{ type, data }
  @Sse('sse')
  sse(@Req() req: Request): Observable<MessageEvent> {
    const close$ = fromEvent(req, 'close');
    const source$ = interval(150).pipe(
      take(20),
      map((i) => ({ data: { type: 'delta', data: `chunk-${i}` } })),
      takeUntil(close$),
    );
    return source$;
  }
}
```

前端消费（SSE）与取消：

```ts
// 浏览器端
const es = new EventSource('/stream/sse');
es.onmessage = (e) => {
  const ev = JSON.parse(e.data);
  if (ev.type === 'delta') {
    renderAppend(ev.data);
  } else if (ev.type === 'complete') {
    finalize();
    es.close();
  }
};
es.onerror = (err) => {
  console.error('SSE error', err);
  es.close();
};
// 用户取消
// es.close();
```

最小可运行示例（NestJS WebSocket 粘合层）

依赖：`npm i @nestjs/websockets socket.io`

```ts
// src/chat.gateway.ts
import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({ cors: { origin: '*' } })
export class ChatGateway {
  @WebSocketServer() server: Server;

  @SubscribeMessage('start')
  handleStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { prompt: string },
  ) {
    let i = 0;
    const timer = setInterval(() => {
      i++;
      client.emit('delta', { type: 'delta', data: `chunk-${i}` });
      if (i >= 20) {
        client.emit('complete', { type: 'complete' });
        clearInterval(timer);
      }
    }, 150);

    client.on('cancel', () => {
      client.emit('error', { type: 'error', message: 'client cancelled' });
      clearInterval(timer);
    });

    client.on('disconnect', () => clearInterval(timer));
  }
}
```

前端消费（WebSocket）与取消：

```ts
import { io } from 'socket.io-client';
const socket = io('/');
socket.emit('start', { prompt: 'hello' });
socket.on('delta', (ev) => renderAppend(ev.data));
socket.on('complete', () => finalize());
socket.on('error', (e) => console.error(e));
// 用户取消
socket.emit('cancel');
socket.disconnect();
```

供应商 SSE → 统一事件桥接（示例思路）：
- 使用 `eventsource-parser` 解析上游 SSE，提取增量字段，转译为统一的 `{ type: 'delta', data }`。
- 对 OpenAI（Chat Completions stream）、vLLM（OpenAI 兼容 API）、TGI（SSE）均可采用相同思路。
- 在 NestJS 中将解析得到的增量推送到 SSE/WS 客户端，并在连接关闭时清理资源。

取消/超时与 Back-pressure：
- 服务端：监听 `req` 的 `close` 事件，触发 `takeUntil` 中止上游流；对 WS 监听 `disconnect/cancel`。
- 客户端：SSE 使用 `EventSource.close()`；WS 使用 `socket.emit('cancel')` 或 `socket.close()`。
- Back-pressure：对上游速率设定节流/分批（例如 150ms 间隔），或缓存队列 + 丢弃策略；必要时改用优先级队列。

心跳与重连：
- 定期发送 `{ type: 'ping', ts }`。
- 客户端重连策略：指数退避（500ms, 1s, 2s, 5s...），携带游标/偏移（消息 token 累计）进行断点续传。

观测与调试：
- 在粘合层记录事件日志（delta 计数、错误、完成、取消），采样写入。
- 暴露指标：连接数、事件速率、平均片段大小、取消/断连率、重连成功率。
- 结合 OpenTelemetry：在 SSE/WS 路径中传播 trace id，便于端到端追踪。
