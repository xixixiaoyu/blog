## 微服务间通信的挑战
在当前的后端系统架构中，微服务已成为主流设计模式。

这些微服务通常采用不同的编程语言来实现，例如 Java、Go、Python、C++ 和 Node.js。

然而，多语言环境下的微服务之间如何高效通信成为一个关键问题。



虽然 HTTP 协议常用于服务间通信，但其文本传输方式效率较低，且并非所有微服务都面向前端提供 HTTP 接口。

因此，对于跨语言环境下的微服务调用，Google 开发的 gRPC（Google Remote Procedure Call 远程过程调用）成为了一种更高效的解决方案。



比如 java 微服务有个方法 test，node 微服务想调用它，就可以通过 gRPC 来实现：

![画板](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1710050138162-92ee24e8-8aec-45db-8fd2-ad2a8efeec95.jpeg)



## Nest 实现 gRPC
### 创建两个 nest 微服务
我们先创建 nest 项目进入其目录：

```bash
nest new grpc-client -p npm
cd grpc-client
```

使用 monorepo 的方式，在同一项目中创建 gRPC 服务：

```plain
nest g app grpc-server
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694962813875-3c45b838-6277-430c-bc22-db48289f4ec2.png)

这样，就有了两个 nest 的 application。

改下 grpc-server 的启动端口号为 3001：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694962861304-73a899be-944b-49b0-b34c-d80285be6204.png)

分别把两个 nest 应用跑起来：

```plain
npm run start:dev grpc-client

npm run start:dev grpc-server
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694963506974-6c3425d5-5130-4c95-a432-504e14debc0b.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694963514282-919fdc1a-3384-4c91-ae4e-917dbc8f286e.png)

这就代表两个 nest 应用都跑起来了。



### 将 gRPC 服务器端改造成微服务：
安装用到的微服务的包：

```bash
npm install @nestjs/microservices

# 如果没成功，强制安装
npm install @nestjs/microservices --legacy-peer-deps
```

grpc 的包：

```bash
npm install @grpc/grpc-js @grpc/proto-loader

# 如果没成功，强制安装
npm install @grpc/grpc-js @grpc/proto-loader --legacy-peer-deps
```

修改下 grpc-server 的 main.ts：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710172517814-4fad296d-1dba-400f-a04f-7e6d5258c02c.png)

在 src 下创建这个对应的文件：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694963962462-ded91c2b-aac1-4079-b43d-df0c5efcce2a.png)



我们安装个 proto 语法高亮插件。

搜索 ext:proto：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694964010110-3220a448-51d0-4770-a927-5af12d7d8687.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694964067866-f7a94cbb-5e2d-428a-b803-98d5d9058907.png)

这是一种叫做 protocol buffers 的语法。

由于需要跨语言通信，不同语言的语法各不相同，因此需要一种用于通信的共同语言。Protocol Buffers 定义了这种语言，

这些语法也很容易看懂：

```plain
syntax = "proto3"
```

是使用 proto3 版本的语法。

```plain
package book;
```

是当前包为 book，也就是一种命名空间。

```plain
service BookService {
  rpc FindBook (BookById) returns (Book) {}
}
```

这个就是定义当前服务可以远程调用的方法。

有一个 FindBook 方法，参数是 BookById，返回值是 Book。

然后下面就是参数和返回值的消息格式：

```plain
message BookById {
  int32 id = 1;
}

message Book {
  int32 id = 1;
  string name = 2;
  string desc = 3;
}
```





### 实现 gRPC 服务端逻辑
book.proto 只是定义了可用的方法和参数返回值的格式，我们还要在 controller 里实现对应的方法：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694964205328-2dcb791f-4f94-46a6-9e3e-f8c8e6387ecc.png)

实现了 findBook 方法，并通过 @GrpcMethod 把它标识为 grpc 的远程调用的方法。

在 nest-cli.json 添加 assets 配置，让 nest 在 build 的时候把 proto 也复制到 dist 目录下：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694964316506-6ff97e24-4b5d-4a90-a14a-ee21e145d227.png)

把它跑起来：

```plain
npm run start:dev grpc-server
```

这时 dist 下就有 grpc-server 的代码了：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694964382731-4167ad37-7571-44be-a4ab-bd4260609174.png)



### 配置 gRPC 客户端
然后我们在 grpc-client 里连上它：

在 AppModule 里添加连接 grpc-server 的微服务的配置：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694964433034-b60fcfb7-a0d0-4cb5-82fa-798940f116fc.png)

同样，客户端也是需要 proto 文件的，不然不知道怎么解析协议数据。

把 book 文件夹从 server 复制过来就可以了。

然后在 AppController 里实现调用远程方法的逻辑：

```typescript
import { Controller, Get, Inject, Param } from '@nestjs/common';
import { AppService } from './app.service';
import { ClientGrpc } from '@nestjs/microservices';

interface FindById {
  id: number;
}
interface Book {
  id: number;
  name: string;
  desc: string;
}
interface BookService {
  findBook(param: FindById): Book;
}
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Inject('BOOK_PACKAGE')
  private client: ClientGrpc;

  private bookService: BookService;

  onModuleInit() {
    this.bookService = this.client.getService('BookService');
  }

  @Get('book/:id')
  getHero(@Param('id') id: number) {
    return this.bookService.findBook({
      id,
    });
  }
}
```

注入 BOOK_PACKAGE 的 grpc 客户端对象。

在 onModuleInit 的时候调用 getService 方法，拿到 BookService 的实例。

然后调用它的 findBook 方法。



### 运行和测试
启动 grpc-client：

```typescript
npm run start:dev grpc-client
```

浏览器访问下：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694964692660-b2c63477-a59e-4467-bebb-bf484af38502.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694964704417-facfb5f5-065e-4a6d-ab78-2f9c27a49912.png)

可以看到，远程方法调用成功了。

这就是基于 grpc 的远程方法调用，用 java、python、go、c++ 等实现的微服务也是这样来通信。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1694964738105-18534f15-5494-413a-9600-4da1b407cfd2.png)

通过 protocol buffer 的语法定义通信数据的格式，比如 package、service 等。

然后 server 端实现 service 对应的方法，client 端远程调用这个 service。

这样就实现了远程方法调用。

