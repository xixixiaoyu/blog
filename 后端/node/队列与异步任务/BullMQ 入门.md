# BullMQ 入门

目标
- 使用 BullMQ 与 Redis 构建任务队列与处理器。

依赖安装
```bash
npm i bullmq ioredis
```

示例：生产者 producer.ts
```ts
import { Queue } from 'bullmq';
const queue = new Queue('email', { connection: { host: '127.0.0.1', port: 6379 } });

await queue.add('send', { to: 'user@example.com', subject: 'Welcome' }, { attempts: 3, backoff: { type: 'exponential', delay: 1000 } });
console.log('Job queued');
```

示例：消费者 worker.ts
```ts
import { Worker } from 'bullmq';

const worker = new Worker('email', async job => {
  // 执行任务
  console.log('Processing', job.name, job.data);
}, { connection: { host: '127.0.0.1', port: 6379 } });

worker.on('completed', job => console.log('Completed', job.id));
worker.on('failed', (job, err) => console.error('Failed', job?.id, err));
```

要点
- 配置重试与退避，保障任务可靠性；必要时使用分布式锁防止重复处理。
- 延迟队列与并发设置可用于限速与容量管理。

