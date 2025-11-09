Nest 底层默认使用 Express 作为 HTTP 服务器框架。

了解 Node 原声模块和 Express 的发展脉络，能让你更清楚 Nest 为啥这么设计，以及它解决了什么痛点。



## 最初的模样：Node 原生 HTTP 模块
在 Node 最开始的时候，我们要处理一个网络请求，需要用到它内置 `http` 模块。

这里面有两个核心：请求对象 (`req`) 和响应对象 (`res`)。

**请求对象 (**`**req**`**)**: 客户端发来的所有信息都在这里，比如：

+ `req.url`: 请求的路径，不包括域名和端口。
+ `req.method`: 请求方法，像 `GET`、`POST` 这种。
+ `req.headers`: 请求头，一大堆键值对。
+ `req.params`: 路由里的参数，比如 `/users/123` 里的 `123`。
+ `req.query`: URL 问号后面的参数，比如 `/search?keyword=nest` 里的 `keyword=nest`。
+ `req.body`: `POST` 请求时，请求体里的数据。原生 Node 得自己一点点接收和解析。

实际用起来有点繁琐，比如处理一个简单的 `GET` 请求，获取 URL 参数：

```javascript
// 原生 Node 处理请求 URL 示例
const http = require("http");
const url = require("url");

const server = http.createServer((req, res) => {
  // 解析请求的 URL
  const parsedUrl = url.parse(req.url, true);
  // 获取路径和查询参数
  const path = parsedUrl.pathname;
  const queryParams = parsedUrl.query;

  // 设置响应头
  res.writeHead(200, { "Content-Type": "text/plain; charset=utf-8" }); // 加上 charset=utf-8 避免中文乱码
  res.end(`你请求的路径是: ${path}, 查询参数是: ${JSON.stringify(queryParams)}`);
});

const PORT = 3000;
server.listen(PORT, () => {
  console.log(`服务器跑起来啦，在 http://localhost:${PORT}`);
});
```

如果是 `POST` 请求，要获取请求体里的数据，那就更麻烦了，需要监听 `data` 事件和 `end` 事件来手动拼接和解析。

每次响应都得手动设置 `Content-Type`，然后用 `res.end()` 发送。有点刀耕火种的味道：

```javascript
const http = require('http');

const server = http.createServer((req, res) => {
  // 只处理POST请求
  if (req.method === 'POST') {
    // 存储接收到的数据片段
    let body = '';
    
    // 监听数据片段到达事件
    req.on('data', (chunk) => {
      body += chunk.toString();
    });
    
    // 监听数据接收完成事件
    req.on('end', () => {
      let parsedBody;
      
      // 根据Content-Type解析数据
      const contentType = req.headers['content-type'];
      
      if (contentType === 'application/json') {
        try {
          parsedBody = JSON.parse(body);
        } catch (error) {
          res.statusCode = 400;
          res.end('Invalid JSON');
          return;
        }
      } else if (contentType === 'application/x-www-form-urlencoded') {
        // 解析表单数据
        parsedBody = {};
        body.split('&').forEach(item => {
          const [key, value] = item.split('=');
          parsedBody[decodeURIComponent(key)] = decodeURIComponent(value);
        });
      } else {
        // 其他类型的数据，可能需要其他解析方法
        parsedBody = body;
      }
      
      // 现在可以使用解析后的请求体数据
      console.log('请求体数据:', parsedBody);
      
      // 返回响应
      res.statusCode = 200;
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify({ message: '数据接收成功', data: parsedBody }));
    });
  } else {
    res.statusCode = 405;
    res.end('只接受POST请求');
  }
});

server.listen(3000, () => {
  console.log('服务器运行在 http://localhost:3000/');
});
```



## Express 框架登场
原生 node 开发太繁琐？Express 提供了更友好的 API 和强大的路由系统，还有中间件这个强大的功能。

看看用 Express 处理同样的请求有多简单：

```javascript
// Express 处理请求 URL 示例
const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
  const path = req.path; // 直接获取路径
  const queryParams = req.query; // 直接获取查询参数
  res.send(`Express 说：你请求的路径是: ${path}, 查询参数是: ${JSON.stringify(queryParams)}`);
});

app.listen(PORT, () => {
  console.log(`Express 服务器跑起来啦，在 http://localhost:${PORT}`);
});
```

处理 POST 请求体数据：

```javascript
// Express 处理请求体示例
const express = require('express');
const app = express();
const PORT = 3000;

// 使用中间件来解析 JSON 和 URL 编码的请求体
app.use(express.json()); // 解析 application/json
app.use(express.urlencoded({ extended: true })); // 解析 application/x-www-form-urlencoded

app.post('/submit', (req, res) => {
  const bodyData = req.body; // 直接获取解析后的请求体数据
  res.send(`Express 说：收到了你的 POST 数据: ${JSON.stringify(bodyData)}`);
});

app.listen(PORT, () => {
  console.log(`Express 服务器跑起来啦，在 http://localhost:${PORT}`);
});
```

`req.query` 直接就能拿到 URL 参数，`req.body` 在用了 `express.json()` 和 `express.urlencoded()` 中间件之后，也能直接拿到解析好的请求体数据，不用再手动折腾了。

Express 的好用还不止这些，它还有模板引擎、静态文件服务、错误处理机制等等。

但是，Express 太灵活了，它不强制你用某种特定的方式组织代码。

这就导致了一个问题：项目一大，不同开发者的代码风格五花八门，路由管理可能变得很混乱，维护起来头很大啊。

比如，有的项目可能把所有路由都写在一个文件里，像这样：

```javascript
// app.js (一种路由管理方式)
app.get('/users', (req, res) => { /* ... */ });
app.post('/users', (req, res) => { /* ... */ });
app.get('/products', (req, res) => { /* ... */ });
// ... 无数个路由
```

有经验的开发者可能会用模块化的方式来管理：

```javascript
// app.js (另一种模块化路由管理方式)
const usersRoutes = require('./routes/users');
const productsRoutes = require('./routes/products');

app.use('/users', usersRoutes);
app.use('/products', productsRoutes);
```

第二种显然更好维护。但 Express 不会“逼”你用第二种。这种“自由”有时候反而成了麻烦。

这时候，就需要一个更高层次的框架来解决架构层面的问题了，这就看我们 Nest 了。



## 优雅的进化：Nest 处理 HTTP 请求
Nest 处理 GET 请求 URL 参数 (通常在 Controller 文件中)：

```typescript
// 在某个 controller.ts 文件中
import { Controller, Get, Query, Param } from '@nestjs/common';

@Controller('items') // 定义路由前缀 /items
export class ItemsController {
  @Get(':id') // 匹配 /items/:id
  findItemById(@Param('id') id: string, @Query('version') version: string) {
    return `你要找的商品 ID 是: ${id}, 版本是: ${version || '未指定'}`;
  }
}
```

Nest 处理 POST 请求体示例：

```typescript
// 在某个 controller.ts 文件中
import { Controller, Post, Body } from '@nestjs/common';

interface CreateItemDto {
  name: string;
  price: number;
}

@Controller('items')
export class ItemsController {
  @Post()
  createItem(@Body() createItemDto: CreateItemDto) {
    return `成功创建商品: ${createItemDto.name}, 价格: ${createItemDto.price}`;
  }
}
```

可以看到上面 Nest 用大量的装饰器（如 `@Controller()`, `@Get()`, `@Post()`, `@Param()`, `@Query()`, `@Body()`）来声明路由、获取参数，代码非常清晰。

而且，它会自动根据你返回的数据类型（比如对象、字符串）来设置合适的 `Content-Type` 响应头，就很舒服。

总结下：

+ **原生 Node**** **`**http**`** ****模块**：最底层，最基础，但用起来麻烦。
+ **Express**：在原生基础上做了封装，大大简化了 Web 开发，提供了路由、中间件等核心功能，非常灵活。
+ Nest：更进一步，基于 Express (也可以换成 Fastify)，引入了 TypeScript、装饰器、模块化、依赖注入等概念，提供了一套强大的**架构**，让大型应用的开发和维护变得更加规范和高效。



## 为什么 NestJS 优于 Egg.js、MidwayJS
Egg.js 和 MidwayJS 都是阿里开发的 Node.js 框架，但是还是和 Nest 有明显差距：

+ 生态上：Nest** **拥有庞大且高度活跃的全球开发者社区，而 Egg.js 和 MidwayJS 主要面对国内和中文用户。
+ 架构上：Nest 依赖注入、模块系统、装饰器等架构模式，借鉴 Java Spring、Angular，已经非常成熟和经过广泛验证，而 Egg.js 和 MidwayJS 在这方面弱很多、虽然 MidwayJS 学习引进了依赖注入等。
+ TS 原生上：Nest 的第一行代码就是用 TS 构建，所有特性都和 TS 融合的非常好，而 Egg.js 的 TS 支持是后续加入的，并非框架设计的核心，MidwayJS 虽然也是 TS 优先，但还是没有 Nest 融合的那么好。

我们来看看 github star 参考下：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1747384251120-caa3fc75-0015-4fe7-b8e5-d433c2b52849.png)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1747384288593-85a8502d-7edd-48dc-b7a7-6da3317fb5de.png)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1747384336757-1832b19b-c084-4ff5-81d8-47b5786f2f57.png)

