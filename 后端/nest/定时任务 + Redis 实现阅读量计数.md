<font style="background-color:rgba(255, 255, 255, 0);">文章都会有阅读量，怎么做呢？</font>

<font style="background-color:rgba(255, 255, 255, 0);">每次刷新页面都往数据库 +1 嘛，这样一来阅读量不准，二来浪费性能。</font>

<font style="background-color:rgba(255, 255, 255, 0);">我们可以在 redis 中存储 user 和 article 的关系，10 分钟后删除。</font>

<font style="background-color:rgba(255, 255, 255, 0);">如果存在 userKey 则代表用户看过这篇文章，就不更新阅读量。10 分钟后，这个人再看这篇文章，算作一个新的阅读量。</font>

<font style="background-color:rgba(255, 255, 255, 0);">访问文章时把阅读量加载到 redis，之后的阅读量计数只更新 redis，不更新数据库，等业务低峰期再把最新的阅读量写入数据库，这里可以用定时任务来做。</font>

<font style="background-color:rgba(255, 255, 255, 0);">我们来实现下：</font>

```typescript
nest new article-views -p npm
```

<font style="background-color:rgba(255, 255, 255, 0);">安装 typeorm 相关的包：</font>

```typescript
npm install --save @nestjs/typeorm typeorm mysql2
```

<font style="background-color:rgba(255, 255, 255, 0);">在 AppModule 引入 TypeOrmModule：</font>

```typescript
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: 'localhost',
      port: 3306,
      username: 'root',
      password: 'xxx',
      database: 'article_views',
      synchronize: true,
      logging: true,
      entities: [],
      poolSize: 10,
      connectorPackage: 'mysql2',
      extra: {
        authPlugin: 'sha256_password',
      },
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
```

<font style="background-color:rgba(255, 255, 255, 0);">创建 database：</font>

```typescript
CREATE DATABASE article_views DEFAULT CHARACTER SET utf8mb4;
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693126803154-c9799457-588e-41a5-b14d-b637ddb587ba.png)

<font style="background-color:rgba(255, 255, 255, 0);">创建</font><font style="background-color:rgba(255, 255, 255, 0);">文章和用户的模块：</font>

```typescript
nest g resource user --no-spec
nest g resource article --no-spec
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693125965338-43fcb55c-f046-4681-955e-f8e2eae2ce08.png)

<font style="background-color:rgba(255, 255, 255, 0);">添加 user 和 article 的 entity：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693126040924-da00f00e-be71-4445-b833-794595a4bc72.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693126013367-c674cf8e-a0c5-4a82-9e25-2fbc77955c3e.png)

<font style="background-color:rgba(255, 255, 255, 0);">entities 引入：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693126100499-8d161807-7656-480b-ae70-f45a03084f9e.png)

<font style="background-color:rgba(255, 255, 255, 0);">在 AppController 创建 init-data 的路由，然后注入 EntityManager：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693126368535-35b821e4-09d3-49a5-a7f8-68654e7c7237.png)<font style="background-color:rgba(255, 255, 255, 0);">  
</font><font style="background-color:rgba(255, 255, 255, 0);">浏览器访问下：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693126850776-a280dd2b-80b7-4b60-8836-692f3ce8a9eb.png)

<font style="background-color:rgba(255, 255, 255, 0);">两个表都插入了数据：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693126912768-b7ef7d9b-fb9e-4e67-995d-469cee7e2e5b.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693126893143-8f4abf9d-ea09-4840-9e33-aaee84220876.png)

<font style="background-color:rgba(255, 255, 255, 0);">实现下登录，这次用</font><font style="background-color:rgba(255, 255, 255, 0);"> session 的方案：</font>

```typescript
npm install express-session @types/express-session
```

<font style="background-color:rgba(255, 255, 255, 0);">在 main.ts 里启用：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693126992284-83049d42-6a4e-4237-a701-7b09e8555097.png)

<font style="background-color:rgba(255, 255, 255, 0);">在 UserController 添加 login 的路由：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693127196133-d7789c69-64fd-4314-aed4-183059d28fb6.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693127231745-1a814836-c728-4b1e-bbea-2caa210515b4.png)

<font style="background-color:rgba(255, 255, 255, 0);">这下我们就能拿到用户发送过来的账号密码了。</font>

<font style="background-color:rgba(255, 255, 255, 0);">然后在 UserService 实现登录逻辑：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693137366250-9431eb21-72a3-4d54-a58b-40831fe346f5.png)

<font style="background-color:rgba(255, 255, 255, 0);">UserController 调用下：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693137490994-3c29942f-b9a0-484f-9544-4b01bda7fc6b.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693137757973-799d2d6b-1029-455b-818c-428577c2c094.png)

<font style="background-color:rgba(255, 255, 255, 0);">输入正确的账号密码登录成功。</font>

<font style="background-color:rgba(255, 255, 255, 0);"></font>

<font style="background-color:rgba(255, 255, 255, 0);">然后在 ArticleController 添加一个查询文章的接口：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693137858808-74bd9bab-9282-4495-865d-cbd01a684c67.png)

<font style="background-color:rgba(255, 255, 255, 0);">实现 articleService.findOne 方法：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693137904951-c64c8931-6714-4cf6-af54-37f8d626ac0e.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693137979865-8bd31340-f913-49ef-bb6a-f7ffdd464036.png)

<font style="background-color:rgba(255, 255, 255, 0);">正确查询到对应 id 的文章。</font>

<font style="background-color:rgba(255, 255, 255, 0);"></font>

<font style="background-color:rgba(255, 255, 255, 0);">在 ArticleController 加一个阅读的接口：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693138028984-df4fb76e-6a64-4394-b5db-02e1ae275b8d.png)

<font style="background-color:rgba(255, 255, 255, 0);">实现 view 方法：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693138336217-01e7acf1-cb50-4248-9d71-9e07f80c07ac.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693138377547-e14828c4-0f2c-4ca3-ac3e-943884df366b.png)

<font style="background-color:rgba(255, 255, 255, 0);">访问几次，就变成几。</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693138445432-fec25989-5a55-4404-bc5b-d13b12c3c31f.png)

<font style="background-color:rgba(255, 255, 255, 0);"></font>

<font style="background-color:rgba(255, 255, 255, 0);">我们引入 redis 解决开头的问题，</font><font style="background-color:rgba(255, 255, 255, 0);">安装 redis 的包：</font>

```typescript
npm install --save redis
```

<font style="background-color:rgba(255, 255, 255, 0);">创建 redis 模块：</font>

```typescript
nest g module redis
nest g service redis
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693138577099-7fb9e336-9dc6-4d15-b0f8-6b8703f48d01.png)

<font style="background-color:rgba(255, 255, 255, 0);">在 RedisService 里注入 REDIS_CLIENT，并封装一些方法：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693141772391-4d192168-f2b1-4383-9264-7b89883a8272.png)

<font style="background-color:rgba(255, 255, 255, 0);">我们封装了 get、set、hashGet、hashSet 方法，分别是对 redis 的 string、hash 数据结构的读取。</font>

<font style="background-color:rgba(255, 255, 255, 0);">然后在 ArticleService 的 view 方法里引入 redis：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693141915927-3cfb9bc9-7ce4-4a81-b86f-bc76836478aa.png)

<font style="background-color:rgba(255, 255, 255, 0);">查询 redis，如果没查到就从数据库里查出来返回，并存到 redis 里。</font>

<font style="background-color:rgba(255, 255, 255, 0);">查到了就更新 redis 的 viewCount，直接返回 viewCount + 1。</font>

<font style="background-color:rgba(255, 255, 255, 0);">测试下：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693142320137-a14eda6b-b882-4597-a468-089370976fa1.png)![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693142359498-b9816fba-3fe0-4fb7-ab4e-acab4c7ef74f.png)

<font style="background-color:rgba(255, 255, 255, 0);">save 会先发一条 select，再发一条 update。把 save 换成 update：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693142481882-32c707c6-1775-476a-af1d-2de93c7aaac0.png)

<font style="background-color:rgba(255, 255, 255, 0);">更新完，接下来就只需要</font><font style="background-color:rgba(255, 255, 255, 0);">访问量少的时候通过定时任务同步数据库。</font>

<font style="background-color:rgba(255, 255, 255, 0);">引入定时任务包 @nestjs/schedule：</font>

```typescript
npm install --save @nestjs/schedule
```

<font style="background-color:rgba(255, 255, 255, 0);">AppModule 注册：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693145959170-8e7b6489-4d9c-423d-b89a-e113daa6fdda.png)

<font style="background-color:rgba(255, 255, 255, 0);">创建一个 service：</font>

```typescript
nest g module task
nest g service task
```

<font style="background-color:rgba(255, 255, 255, 0);">定义个方法，通过 @Cron 声明每 10s 执行一次：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693146316887-75edcfed-0c2f-4b5a-8d73-e6424423da52.png)

<font style="background-color:rgba(255, 255, 255, 0);">这时候控制台每 10s 就会打印：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693146352566-66bd7854-15ab-4606-9995-0999faced58c.png)

<font style="background-color:rgba(255, 255, 255, 0);">在 TaskModule 引入 ArticleModule：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693146411409-3e5e19fc-0859-4a34-b867-554df85ae862.png)

<font style="background-color:rgba(255, 255, 255, 0);">并且在 ArticleModule 导出 ArticleService：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693147313286-b027f4db-3e93-45b5-ad9e-1fa879665f0a.png)

<font style="background-color:rgba(255, 255, 255, 0);">然后在 TaskService 里注入 articleService</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693147354259-7d2a9f62-bfff-4f7e-bf4c-df5c383dc623.png)

<font style="background-color:rgba(255, 255, 255, 0);">每分钟执行一次，调用 articleService 的 flushRedisToDB 方法。</font>

<font style="background-color:rgba(255, 255, 255, 0);">然后我们实现 flushRedisToDB 方法，在此之前，我们先在 RedisService 添加一个 keys 方法，用来查询 key：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693147433183-fa5a23ef-344e-4abb-8574-cc9658813f10.png)

<font style="background-color:rgba(255, 255, 255, 0);">然后在 ArticleService 里实现同步数据库的逻辑：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693147463749-1c98847b-7672-479d-8ffd-3509720eb74e.png)

<font style="background-color:rgba(255, 255, 255, 0);">打印下 keys：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693147777957-3c58f68c-2120-4425-a931-415d4e7ee4ef.png)

<font style="background-color:rgba(255, 255, 255, 0);">现在只有一个 key，我们再访问下另一篇文章：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693147805545-044070b0-eab4-4f91-8645-ebd9d7a8fa90.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693147836874-13bb7e48-3ee7-4ae3-9fdb-033fa69fcac6.png)

<font style="background-color:rgba(255, 255, 255, 0);">有两个 key 了。</font>

<font style="background-color:rgba(255, 255, 255, 0);">我们把所有的 key 对应的值存入数据库：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693148299023-f1ffc65c-ffab-4ab9-904c-1411a01bedcf.png)

<font style="background-color:rgba(255, 255, 255, 0);">查询出 key 对应的值，更新到数据库。</font>

<font style="background-color:rgba(255, 255, 255, 0);">刷新几次 view 接口，redis 里阅读量增加了，数据库不会变，当定时任务执行后，会同步到数据库。</font>

<font style="background-color:rgba(255, 255, 255, 0);">定时任务的执行时间改为 4 点：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693148819998-6205fef6-e628-476c-87f0-a78c3b14b3ed.png)

<font style="background-color:rgba(255, 255, 255, 0);">这样</font><font style="background-color:rgba(255, 255, 255, 0);">基于 redis 的阅读量缓存，以及定时任务更新数据库就完成了。</font>

<font style="background-color:rgba(255, 255, 255, 0);">还有一个问题是如何区分同一个人阅读？</font>

<font style="background-color:rgba(255, 255, 255, 0);">我们可以在用户访问文章的时候在 redis 存一个 10 分钟过期的标记，有这个标记的时候阅读量不增加。</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693150204299-1a195644-bda2-4793-86e1-4640e6cfeef8.png)

<font style="background-color:rgba(255, 255, 255, 0);">先设置成 8s 过期，方便测试。</font>

<font style="background-color:rgba(255, 255, 255, 0);">我们在 ArticleController 的 view 方法里传入 userId：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693149188945-8d8ddbf3-7db2-4e05-b78f-a36e1f0afbb3.png)

<font style="background-color:rgba(255, 255, 255, 0);">现在就不是每次刷新都增加阅读量了，而是 8s 之后再刷新才增加。</font>

<font style="background-color:rgba(255, 255, 255, 0);">在 redis 里可以看到这个 key：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693150307721-cf54ccc5-c093-4f3a-b050-940ad208764d.png)

<font style="background-color:rgba(255, 255, 255, 0);">只不过现在没登录，用的是 ip，而本地访问的时候获取的 ip 就是 ::1 这样的，线上就能拿到具体的 ip 了。</font>

<font style="background-color:rgba(255, 255, 255, 0);">登录下再访问：</font>

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693150385437-e6dc05df-70db-407c-ab39-fb5e91c821fa.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693150408613-a380c641-7420-425e-ab0d-2759941bb23e.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1693150559530-74288dda-c140-442a-a087-445805739004.png)

<font style="background-color:rgba(255, 255, 255, 0);">这时用的就是用户 id 了。</font>

<font style="background-color:rgba(255, 255, 255, 0);">这样就实现了真实的阅读量计数。</font>

<font style="background-color:rgba(255, 255, 255, 0);"></font>

## <font style="background-color:rgba(255, 255, 255, 0);">总结</font>
<font style="background-color:rgba(255, 255, 255, 0);">我们通过 redis + 定时任务实现了阅读量计数的功能。</font>

<font style="background-color:rgba(255, 255, 255, 0);">因为阅读是个高频操作，所以我们查出数据后存在 redis里，之后一直访问 redis 的数据，然后通过定时任务在凌晨 4 点把最新数据写入数据库。</font>

<font style="background-color:rgba(255, 255, 255, 0);">并且为了统计真实的用户阅读量，我们在 redis 存储了用户看了哪篇文章的标识，10 分钟后过期。</font>

<font style="background-color:rgba(255, 255, 255, 0);">这就是我们常见的阅读量功能的实现原理。</font>

