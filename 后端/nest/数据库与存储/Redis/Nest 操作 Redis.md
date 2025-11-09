## Node 中操作 Redis 简介
在 Node.js 中，我们通常使用 Redis 客户端库来与 Redis 数据库交互。以下是两种流行的 Redis Node 客户端：

1. redis：由官方提供的 npm 包。
2. ioredis：一个功能丰富的第三方 Redis 客户端。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687959580779-595fe57b-e852-4c12-aaab-e1b28c4f078b.png)

redis 还有很多的 [node 客户端的包](https://link.juejin.cn/?target=https%3A%2F%2Fredis.io%2Fresources%2Fclients%2F%23nodejs)。



## 使用 redis 包操作 Redis
创建项目：

```bash
mkdir redis-node-test
cd redis-node-test
npm init -y
npm install redis
```

使用 ES Module 和顶层 await，需要在 package.json 中添加 "type": "module"：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687961200340-ea3941f5-605c-4524-ac1c-7fe2774d637c.png)

创建 index.js 连接 redis 服务：

```typescript
import { createClient } from 'redis'

// 创建客户端实例
const client = createClient({
	socket: {
		host: 'localhost',
		port: 6379,
	},
})

// 监听错误事件
client.on('error', err => console.log('Redis Client Error', err))

// 连接 Redis 服务
await client.connect()

// 执行 keys 命令，获取所有键
const value = await client.keys('*')

console.log(value)

// 断开连接
await client.disconnect()
```

node 执行：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687962953767-b0c03e83-19d3-4064-9b1a-938c119f9b61.png)

用 RedisInsight 看下 key：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687962971849-1c5cc455-b665-4da5-b34d-793fc118042b.png)

没问题。

所有的 redis 命令都有对应的方法：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687963357775-14ee1bff-d537-42b7-bf5d-40afa128aa5e.png)

和我们在命令行客户端里操作一样。



## 使用 ioredis 包操作 Redis
安装 ioredis：

```bash
npm install ioredis
```

连接 redis 执行命令：

```typescript
import Redis from 'ioredis'

const redis = new Redis()

const res = await redis.keys('*')

console.log(res)
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687963458700-1934b7ef-4a5f-4031-b445-a5dd6b84286c.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687963638756-c4484fd9-dcc3-42bc-9318-df8f0a39d38f.png)



## 在 Nest 中操作 Redis
创建 nest 项目：

```bash
nest new nest-redis -p npm
```

安装 redis 的包：

```bash
npm install redis
```

在 AppModule 添加一个自定义的 provider：

```typescript
import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { createClient } from 'redis';

@Module({
  imports: [],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: 'REDIS_CLIENT', // 定义一个提供者的键
      async useFactory() { // 使用工厂模式创建 Redis 客户端
        const client = createClient({
          socket: {
            host: 'localhost', // Redis 服务器主机名
            port: 6379, // Redis 服务器端口
          },
        });
        await client.connect(); // 连接到 Redis 服务器
        return client; // 返回连接后的 Redis 客户端
      },
    },
  ],
})
export class AppModule {}
```

注入就可以使用了：

```typescript
import { Inject, Injectable } from '@nestjs/common';
import { RedisClientType } from 'redis';

@Injectable()
export class AppService {
  @Inject('REDIS_CLIENT')
  private redisClient: RedisClientType;

  async getHello() {
    const value = await this.redisClient.keys('*');
    console.log(value);

    return 'Hello World!';
  }
}
```

Controller 中也需要相应地使用 async/await：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687964680980-b45c11b2-804c-4c86-aa87-e7734408f40a.png)

运行项目，浏览器访问下：

```bash
nest start:dev
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687964757645-473f9735-4fdc-42e7-87f2-c8622c3fc656.png)

这样就能在 nest 里操作 redis 了。



## Nest 与 redis 缓存
Nest 的官方文档中推荐使用 cache-manager，但是它仅支持基础的 get 和 set 操作和基本缓存，不支持 list、hash、zset 等数据结构。

我们如上面一样封装 RedisService ，来实现 get、set 和其他操作更灵活。

至于缓存，我们也可以自己封装个拦截器。

创建一个 interceptor：

```bash
nest g interceptor my-cache --no-spec --flat
```

内容如下：

```typescript
import {
	CallHandler,
	ExecutionContext,
	Inject,
	Injectable,
	NestInterceptor,
} from '@nestjs/common';
import { HttpAdapterHost } from '@nestjs/core';
import { RedisClientType } from 'redis';
import { of } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class MyCacheInterceptor implements NestInterceptor {
	// 注入Redis客户端
	@Inject('REDIS_CLIENT')
	private redisClient: RedisClientType;

	// 注入HttpAdapterHost，用于访问HTTP请求信息
	@Inject(HttpAdapterHost)
	private httpAdapterHost: HttpAdapterHost;

	async intercept(context: ExecutionContext, next: CallHandler) {
		const request = context.switchToHttp().getRequest();

		// 生成缓存键，基于请求的URL
		const key = this.httpAdapterHost.httpAdapter.getRequestUrl(request);

		// 尝试从Redis获取缓存数据
		const value = await this.redisClient.get(key);

		// 如果缓存不存在，则处理请求并把结果缓存
		if (!value) {
			return next.handle().pipe(
				tap(res => {
					// 请求处理完成后，将结果缓存到Redis
					this.redisClient.set(key, res);
				})
			);
		} else {
			// 如果缓存存在，直接返回缓存数据
			return of(value);
		}
	}
}
```



## 总结
通过 redis 和 ioredis 等 npm 包，我们可以连接到 Redis 服务器并执行各种命令。

在 Nest.js 中，可以通过 useFactory 动态创建一个 Provider 来管理 Redis 客户端连接。

如果需要缓存接口，可以自己创建拦截器。
