## 引言
MySQL 是一种关系型数据库，通过表和字段来存储信息，表与表之间通过 ID 关联。它使用 SQL 语言进行数据的增删改查操作。

由于 MySQL 基于硬盘存储，并且需要解析执行 SQL 语句，这在某些高并发场景下可能会导致性能瓶颈。通常情况下，服务端执行计算的速度很快，但等待数据库查询结果的过程却较为缓慢。

为了解决这个问题，性能优化的常见策略之一是使用缓存（Cache）。考虑到内存与硬盘速度的显著差异，我们通常会采用像 Redis 这样的内存数据库作为缓存层，以显著提高数据访问速度。

## Redis 简介
Redis (Remote Dictionary Server) 是一个开源的、使用 C 语言编写的、支持网络、可基于内存亦可持久化的日志型、Key-Value 数据库。它通常用作数据库、缓存或消息传递中间件。

Redis 以键值对（key-value pair）的形式设计，其独特之处在于支持多种类型的值，例如：

*   **字符串 (String)**：最基础的类型，可以是文本、JSON 或二进制数据。
*   **列表 (List)**：一个字符串链表，按照插入顺序排序。
*   **集合 (Set)**：无序且唯一的字符串集合。
*   **有序集合 (Sorted Set/ZSet)**：与 Set 类似，但每个元素都会关联一个 double 类型的分数，Redis 通过分数来为集合中的成员进行从小到大的排序。
*   **哈希表 (Hash)**：包含字段和值的映射表，适合存储对象。
*   **地理信息 (Geospatial)**：用于存储地理位置信息，并支持距离计算和范围查询。
*   **位图 (Bitmap)**：通过二进制位来进行高效存储和计算。

## Redis 的安装与使用
最简单的启动方式是使用 Docker。

在 Docker Desktop 中搜索 Redis 镜像，点击 Run 启动容器：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687878928060-b644fce4-5515-4a29-aa91-5ef53bafc9fe.png)

配置端口映射，将宿主机的 `6379` 端口映射到容器内的 `6379` 端口，这样我们就可以通过本机的端口访问容器内的 Redis 服务。

为了数据持久化，还需要将宿主机的目录挂载到容器内的 `/data` 目录，确保数据保存在本机：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687879045960-95835350-01ac-4a9c-b7b8-f71b0c3782a8.png)

运行成功后，你就可以在 Docker Desktop 中看到正在运行的 Redis 容器。

## 命令行与 GUI 工具

### 命令行操作 (redis-cli)
进入容器的 Terminal，输入 `redis-cli`，即可进入交互模式：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687879538022-77d4306c-a858-47cd-80bd-fcf03f9d798d.png)

你可以执行 `set`、`get` 等命令来操作数据：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713105624846-d9f21b06-efef-4874-bc06-d7591783975f.png)

### Redis GUI 工具 (RedisInsight)
官方提供了名为 [RedisInsight](https://redis.com/redis-enterprise/redis-insight/) 的 GUI 工具，可以更直观地查看和管理数据。

下载并安装后，点击 "Add Database"，使用默认的连接信息（`localhost:6379`）即可连接到本地运行的 Redis 实例。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687880325893-0806be3a-d3fc-4444-87d0-e5fe4a8d4c92.png)

连接成功后，你可以可视化地查看所有的键值对，并直接在工具中执行命令。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687880415536-728a69f7-5980-41c6-9f5c-6a521001019f.png)

## 核心数据结构详解

### 字符串 (String)
`set` 和 `get` 是最基础的命令。`incr` 命令用于将字符串值递增，非常适合实现计数器功能，如文章阅读量、点赞数。

```bash
# 设置键值
set page_views 100

# 获取键值
get page_views

# 递增
incr page_views
```

### 列表 (List)
List 是一个有序的字符串链表，支持从两端进行推入（push）和弹出（pop）操作。

*   `lpush`: 从列表左侧添加元素。
*   `rpush`: 从列表右侧添加元素。
*   `lpop`: 从列表左侧移除并返回一个元素。
*   `rpop`: 从列表右侧移除并返回一个元素。
*   `lrange`: 获取列表指定范围内的元素。`lrange mylist 0 -1` 可获取所有元素。

```bash
lpush mylist "world"
lpush mylist "hello"
rpush mylist "!"
# 此时列表为 ["hello", "world", "!"]
```

### 集合 (Set)
Set 是无序且唯一的字符串集合。

*   `sadd`: 添加一个或多个元素到集合中，重复的元素会被忽略。
*   `sismember`: 检查一个元素是否存在于集合中。
*   `smembers`: 返回集合中的所有成员。

```bash
sadd tags "javascript" "typescript" "nodejs" "javascript"
# 集合内容为 {"javascript", "typescript", "nodejs"}
sismember tags "nodejs"
# 返回 1 (true)
```

### 有序集合 (Sorted Set / ZSet)
ZSet 在 Set 的基础上为每个元素关联了一个分数（score），并根据分数对元素进行排序。

*   `zadd`: 添加元素并指定其分数。
*   `zrange`: 按分数从小到大返回指定范围的元素。
*   `zrevrange`: 按分数从大到小返回指定范围的元素。

这在实现排行榜等功能时非常有用。

```bash
zadd leaderboard 100 "player1"
zadd leaderboard 250 "player2"
zadd leaderboard 150 "player3"

# 获取排名前两位的玩家
zrevrange leaderboard 0 1
# 返回 ["player2", "player3"]
```

### 哈希表 (Hash)
Hash 是一个字段-值（field-value）的映射表，适合存储对象。

*   `hset`: 设置一个哈希表中的字段值。
*   `hget`: 获取一个哈希表中指定字段的值。
*   `hgetall`: 获取哈希表中所有的字段和值。

```bash
hset user:1 username "Alice" email "alice@example.com"
hget user:1 username
# 返回 "Alice"
```

### 地理信息 (Geo)
Geo 结构用于存储经纬度信息。

*   `geoadd`: 添加一个或多个地理位置点。
*   `geodist`: 计算两个位置点之间的距离。
*   `georadius`: 根据给定的经纬度，搜索指定半径内的其他点。

这在实现“附近的人”或“附近的地点”等功能时非常方便。

```bash
geoadd locations 116.404269 39.913164 "Beijing" 121.473701 31.230416 "Shanghai"
geodist locations "Beijing" "Shanghai" km
# 计算北京和上海的距离（单位：千米）
```

### 过期时间
Redis 可以为键设置过期时间，到期后键会自动被删除。

*   `expire`: 为键设置一个以秒为单位的过期时间。
*   `ttl`: 查看键的剩余过期时间（Time To Live）。

```bash
set session:xyz "some-data"
expire session:xyz 3600 # 1小时后过期
```

## 在 Node.js 中操作 Redis
要在 Node.js 中与 Redis 交互，我们需要使用 Redis 客户端库。社区中最流行的两个库是 `redis` 和 `ioredis`。

### 使用 `redis` 包
这是由 Redis 官方维护的 npm 包。

1.  **安装**:
    ```bash
    npm install redis
    ```

2.  **使用**:
    ```typescript
    import { createClient } from 'redis';
    
    // 创建客户端实例
    const client = createClient({
      socket: {
        host: 'localhost',
        port: 6379,
      },
    });
    
    // 监听错误事件
    client.on('error', err => console.log('Redis Client Error', err));
    
    // 连接 Redis 服务
    await client.connect();
    
    // 执行命令
    await client.set('key', 'value');
    const value = await client.get('key');
    console.log(value);
    
    // 断开连接
    await client.disconnect();
    ```

### 使用 `ioredis` 包
`ioredis` 是一个功能丰富的第三方客户端，以其高性能和对集群、Sentinel 的良好支持而闻名。

1.  **安装**:
    ```bash
    npm install ioredis
    ```

2.  **使用**:
    ```typescript
    import Redis from 'ioredis';
    
    // 默认连接 localhost:6379
    const redis = new Redis();
    
    // 执行命令
    const value = await redis.keys('*');
    console.log(value);
    
    // ioredis 会自动管理连接，通常不需要手动断开
    ```

## 在 Nest.js 中集成 Redis
在 Nest.js 项目中，我们可以通过自定义 Provider 的方式来集成和管理 Redis 客户端。

1.  **安装依赖**:
    ```bash
    npm install redis
    ```

2.  **创建自定义 Provider**:
    在 `AppModule` (或一个专门的 `RedisModule`) 中，我们使用 `useFactory` 来创建一个 Redis 客户端实例，并将其注册为一个 Provider。

    ```typescript
    // app.module.ts
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
          provide: 'REDIS_CLIENT', // 定义一个唯一的提供者令牌
          async useFactory() {
            const client = createClient({
              socket: {
                host: 'localhost',
                port: 6379,
              },
            });
            await client.connect();
            return client; // 返回连接后的客户端实例
          },
        },
      ],
    })
    export class AppModule {}
    ```

3.  **在 Service 中注入和使用**:
    现在，我们可以在任何服务中通过 `@Inject()` 装饰器注入 Redis 客户端。

    ```typescript
    // app.service.ts
    import { Inject, Injectable } from '@nestjs/common';
    import { RedisClientType } from 'redis';
    
    @Injectable()
    export class AppService {
      @Inject('REDIS_CLIENT')
      private redisClient: RedisClientType;
    
      async getHello() {
        const value = await this.redisClient.keys('*');
        console.log(value);
    
        // 示例：设置和获取值
        await this.redisClient.set('nest-key', 'Hello from Nest.js!');
        const nestValue = await this.redisClient.get('nest-key');
        console.log(nestValue);
    
        return 'Hello World!';
      }
    }
    ```

## 实战：使用 Redis 实现缓存拦截器
虽然 Nest.js 官方的 `cache-manager` 提供了基础缓存功能，但它不支持 Redis 的高级数据结构。我们可以自己封装一个拦截器来实现更灵活的缓存策略。

1.  **创建拦截器**:
    ```bash
    nest g interceptor my-cache --no-spec --flat
    ```

2.  **实现拦截器逻辑**:
    拦截器的核心思想是：在请求到达 Controller 之前，检查 Redis 中是否存在缓存。如果存在，则直接返回缓存数据；如果不存在，则执行 Controller 中的方法，并将结果存入 Redis 后再返回。

    ```typescript
    // my-cache.interceptor.ts
    import {
      CallHandler,
      ExecutionContext,
      Inject,
      Injectable,
      NestInterceptor,
    } from '@nestjs/common';
    import { RedisClientType } from 'redis';
    import { Observable, of } from 'rxjs';
    import { tap } from 'rxjs/operators';
    
    @Injectable()
    export class MyCacheInterceptor implements NestInterceptor {
      @Inject('REDIS_CLIENT')
      private redisClient: RedisClientType;
    
      async intercept(context: ExecutionContext, next: CallHandler): Promise<Observable<any>> {
        const request = context.switchToHttp().getRequest();
        
        // 使用请求 URL 作为缓存的 key
        const key = `${request.method}:${request.originalUrl || request.url}`;
    
        // 尝试从 Redis 获取缓存
        const cachedValue = await this.redisClient.get(key);
    
        if (cachedValue) {
          // 如果缓存存在，直接返回 Observable 包装的缓存数据
          return of(JSON.parse(cachedValue));
        }
    
        // 如果缓存不存在，则执行 handle() 方法，并用 tap 操作符将结果缓存
        return next.handle().pipe(
          tap(response => {
            // 将 Controller 返回的结果序列化后存入 Redis
            this.redisClient.set(key, JSON.stringify(response));
          }),
        );
      }
    }
    ```

3.  **应用拦截器**:
    你可以在需要缓存的 Controller 方法上使用 `@UseInterceptors()` 装饰器。

    ```typescript
    import { Controller, Get, UseInterceptors } from '@nestjs/common';
    import { MyCacheInterceptor } from './my-cache.interceptor';
    
    @Controller()
    export class AppController {
      // ...
    
      @Get('cached-data')
      @UseInterceptors(MyCacheInterceptor)
      getSomeData() {
        console.log('Executing controller method...');
        return { message: 'This data is from the controller', timestamp: new Date() };
      }
    }
    ```
    第一次访问 `/cached-data` 时，控制台会打印 "Executing controller method..."。再次访问时，将直接从 Redis 返回数据，不再执行该方法。

## 总结
本文从 Redis 的基础概念出发，介绍了其核心数据结构、安装方式以及基本操作。随后，我们深入探讨了如何在 Node.js 和 Nest.js 环境中集成和使用 Redis，并通过一个自定义缓存拦截器的实战案例，展示了 Redis 在现代 Web 应用开发中的强大能力。

通过将 Redis 作为缓存、数据库或消息队列，你可以极大地提升应用的性能和可扩展性。
