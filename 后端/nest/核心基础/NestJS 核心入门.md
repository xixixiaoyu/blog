## NestJS 是什么？
Nest 是一个用来构建高效、可扩展的 Node.js 服务器端应用的**框架。**

主要用 TS 编写，当然也可以纯 JS 来写，而且它还融合了面向对象编程 (OOP)、函数式编程 (FP) 和函数式响应编程 (FRP) 的优点。

Nest 底层基于 Express 框架，如果追求极致性能，也可以切换到 Fastify。

Nest 在它们之上加了一层“抽象”，提供了更结构化的开发方式，但同时也允许你直接调用底层框架 (比如 Express) 的功能，非常灵活。

但是 Nest 本身本身并不和特定的 HTTP 库（像 Express 或 Fastify）紧密耦合，它定义了一个 `HttpServer` 接口，Express 和 Fastify 都有对应的适配器去实现这个接口。你想换底层 HTTP 平台？简单，换个适配器就行，核心业务代码基本不用动。

nest 官网：[https://nestjs.com/](https://nestjs.com/)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746688270505-d94f381c-3fc5-43da-81eb-6fcf0a7b62a1.png)

github：[https://github.com/nestjs/nest](https://github.com/nestjs/nest)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746689937949-dc8920ac-b1f2-4c43-a339-6bd71f4e6f22.png)

这其中令我印象深刻的是 issues 很少，某种程度上也反映了它较好的维护和成熟的设计。



## 为什么用 Nest？它解决了什么痛点？
前端有 Vue、React、Angular 这些好用的框架。

但是 Node.js 后端这边，虽然库和工具很多，但在“**如何组织项目架构**”这个核心问题上，一直没有一个像前端那样公认的、开箱即用的最佳实践。

Nest 就是来填补这个空白的。它提供了一套经过深思熟虑的应用架构（深受 Angular 的启发），能轻松创建出：

+ **高可测试性**：代码结构清晰，方便写单元测试和端到端测试。
+ **可扩展性**：模块化的设计，方便功能的增加和拆分。
+ **松耦合**：模块之间依赖清晰，降低修改代码带来的风险。
+ **易于维护**：代码结构统一，新人接手也更容易看懂。

用 Node 开发后端大概分三个层次：

+ **初级玩家**：使用 Node.js 中的原生 http 或 https 模块提供的 `createServer API` 来创建服务器。这种玩法适合搞点小工具的开发服务，简单快捷。
+ **进阶玩家**：用上 Express、Koa 这类库来处理请求和响应。它们很灵活，但也因为太灵活，代码想怎么写就怎么写，项目一大，代码就是一坨，而且这类框架只实现基本 web 服务，路由、日志、请求拦截等都需要自己实现。
+ **专业玩家**：选择 Nest、Egg.js、MidwayJS 这类企业级框架。这类框架最大的特点就是“有规矩”，它会告诉你代码该怎么组织，很多常用的功能（比如日志、配置、安全）都给你准备好了，开箱即用。

我们来看看 Nest 项目结构：

```plain
src
├── user
│   ├── user.controller.ts
│   ├── user.service.ts
│   ├── user.module.ts
│   └── dto
│       └── create-user.dto.ts
├── product
│   ├── product.controller.ts
│   ├── product.service.ts
│   ├── product.module.ts
│   └── dto
│       └── create-product.dto.ts
└── app.module.ts
```

模块化非常清晰，每个模块里，Controller 管路由，Service 管业务逻辑，DTO 管数据传输，Guard 管权限，Filter 管异常

什么代码放哪里，都安排得妥妥的。

所以正得益于这么优秀的结构，放眼全球，NestJS 的火爆程度和社区活跃度都是顶级的（比 Egg.js 和 MidwayJS 好太多了），在国内也会越来越流行。如果你想学一个靠谱的 Node.js 框架，NestJS 基本上就是那个“唯一的答案”了。

Nest 架构：

![画板](https://cdn.nlark.com/yuque/0/2025/jpeg/21596389/1746692840336-4bb81140-a30d-4b32-9845-ba368f08790f.jpeg)



## 不只学框架，更是拥抱整个后端生态
学 NestJS 的过程，你可不只是在学一个框架那么简单。你会接触到一大堆后端常用的“神兵利器”：

+ 数据库：MySQL、PostgreSQL、MongoDB
+ 缓存：Redis
+ 消息队列：RabbitMQ、Kafka
+ 服务发现/配置中心：Nacos
+ 搜索引擎：Elasticsearch

你会慢慢理解一个典型的后端架构长啥样，比如请求怎么进来，怎么做负载均衡，数据怎么存储和查询，异步任务怎么处理等等。

这些知识，就算你以后换用 Go 或者 Java，也都是通用的。

所以，学 NestJS 是个切入点，帮你打开整个后端技术生态的大门。

Vue/React/Angular + NestJS 这样的全栈技术栈开发起来爽歪歪。

最后说一嘴，虽然大部分人不会找远程工作，但 Nest 在电鸭社区的出现率也蛮高的，国外的初创公司或者小团队，也特别喜欢用 NestJS 来做服务端。

****

## Nest，启动！
直接用官方提供的命令行工具 (CLI)。

1. 全局安装 Nest CLI 打开你的终端（命令行窗口），输入：

```plain
npm install -g @nestjs/cli
```

2. **创建 Nest 项目**：

```plain
nest new my-awesome-project -p pnpm
```

把 `my-awesome-project` 换成你想要的项目名。CLI 会自动帮你创建好项目文件夹，并安装好所有必需的依赖，还会生成一套标准的项目结构。

这里我使用 pnpm 来管理项目依赖。



## 项目里都有些什么？
进入你刚创建的项目文件夹 (`cd my-awesome-project`)，你会看到一个 `src` 目录，里面有几个核心文件：

+ `main.ts`: 这是你应用的入口文件，就像大门一样。它用 `NestFactory` 来创建 Nest 应用实例，并启动服务器监听端口。
+ `app.module.ts`: 应用的根模块，是组织你应用代码结构的核心。
+ `app.controller.ts`: 一个简单的控制器，处理进来的 Web 请求（比如用户访问某个网址）。
+ `app.service.ts`: 一个简单的服务，通常用来放业务逻辑（比如从数据库查数据）。
+ `app.controller.spec.ts`: 控制器的单元测试文件（先不用太关心这个）。

`main.ts` 里的代码大概长这样：

```plain
// main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  // 用 AppModule 这个根模块来创建 Nest 应用实例
  const app = await NestFactory.create(AppModule);
  // 让应用监听 3000 端口 (或者环境变量里指定的端口)
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap(); // 跑起来！
```

是不是很简单？`NestFactory.create(AppModule)` 就是创建应用实例的关键，然后 `app.listen(3000)` 就让你的应用跑起来，等待浏览器的访问了。

## 跑起来看看！
在你的项目文件夹里，运行：

```plain
pnpm run start
```

这个命令会启动应用，打开浏览器，访问 `http://localhost:3000/`。如果顺利，你应该能看到 `Hello World!` 的字样。

想让开发更爽一点？试试这个命令：

```plain
pnpm run start:dev
```

这个命令会以“开发模式”启动应用。

它会监视你的代码文件，一旦你修改并保存了代码，它会自动重新编译和重启服务。

> **加速小技巧**：想让 `start:dev` 跑得更快？可以试试用 SWC 这个更快的构建工具。运行 `pnpm run start:dev -- -b swc` 试试。
>
## 核心基础概览
Nest 虽然借鉴了 Java Spring 框架的核心设计理念，但也引入了许多新概念特性。本节我们大概浏览下 Nest 的核心概念：

### 路由（Route）
首先，咱们上网访问不同的功能，通常通过不同的网址路径：

+ `/user/create` (创建用户)
+ `/user/list` (查看用户列表)
+ `/book/create` (添加书籍)
  + `/book/list` (查看书籍列表)


这些不同的网址路径，在 Nest 中被称为**路由（Route）**，它们负责将特定的请求映射到对应的处理函数。



### 控制器 (Controller)
谁来管理这些路由呢？那就是“**控制器** (Controller)”。

你可以把控制器想象成一个交通警察，它负责指挥不同的网络请求（比如用户想访问 `/user/list`）到正确的处理代码那里去。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933036441-00e88895-2780-441f-8a64-ec54407f8d29.png)

在 Nest 里，我们通常会用一些特殊的标记（叫做“**装饰器**”），比如 `@Controller()`, `@Get()`, `@Post()`来声明一个类是控制器，以及这个控制器里的哪些方法负责处理哪些路由和哪种请求类型（GET, POST 等）。

控制器里具体处理某个路由请求的方法，我们叫它“**处理器** (Handler)”。



### 获取请求数据：参数、查询和请求体
用户发请求过来，总得带点信息吧？比如：

+ 想看哪个用户的详情 (`/user/list` 里的 `list`)
+ 或者搜索的关键词 (`/user/list?id=牧云` 里的 牧云)
+ 又或者创建一个新用户时提交的表单数据 (比如 `{ username: '张三', password: 'password123' }`)

Nest 提供了方便的装饰器来获取这些数据：

+ `@Param()`: 用来拿 URL 路径里的参数 (比如上面例子里的 `list`)。
+ `@Query()`: 用来拿 URL 问号后面的查询参数 (比如上面例子里的 `牧云`)。
+ `@Body()`: 用来拿请求体里的数据 (比如上面例子里的 JSON 对象)。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933109977-a1b87a4f-9d16-42ff-9bc4-a2348ab3b885.png)

对于请求体里的数据，我们通常会用一个叫 **DTO** (Data Transfer Object，数据传输对象) 的东西来接收和校验。

简单说，DTO 就是一个专门用来封装和传递数据的 TypeScript 类或接口，这样代码会更整洁，也方便做数据校验。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933148977-ced46942-971c-4b1c-b83b-04bab3f1f651.png)

![画板](https://cdn.nlark.com/yuque/0/2025/jpeg/21596389/1746693423136-4e3f4f2e-c4f7-432b-9dc7-9424bcea606d.jpeg)



### 服务 (Service)：业务逻辑的核心
控制器拿到数据后，就要开始干正事了，比如把用户信息存到数据库，或者从数据库里查数据。

这些具体的业务逻辑，我们不写在控制器里，而是放在“**服务** (Service)”里。控制器负责“传达指令”和“解析参数”，服务负责“执行核心任务”。

这里我调用了 CatsService 定义的方法：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933189000-29e6668d-ac04-4631-bb32-2d2ac1e2c4a9.png)

看看 CatsService：

```typescript
import { Injectable } from '@nestjs/common';
import { CreateCatDto } from './dto/create-cat.dto';
import { UpdateCatDto } from './dto/update-cat.dto';
import { ListAllEntities } from './dto/list-all-entities.dto';

// 模拟 Cat 类型
interface Cat {
  id: number;
  name: string;
  age: number;
  breed: string;
}

@Injectable()
export class CatsService {
  private readonly cats: Cat[] = [
    { id: 1, name: '波斯猫', age: 2, breed: 'Persian' },
    { id: 2, name: '英短', age: 1, breed: 'British Shorthair' },
  ];
  private nextId = 3;

  async create(createCatDto: CreateCatDto): Promise<Cat> {
    console.log('Service: Creating cat with data:', createCatDto);
    const newCat = { id: this.nextId++, ...createCatDto };
    this.cats.push(newCat);
    return newCat;
  }

  async findAll(query: ListAllEntities): Promise<Cat[]> {
    console.log('Service: Finding all cats with query:', query);
    // 实际应用中会根据 query.limit 和 query.offset 进行分页
    return this.cats;
  }

  async findOne(id: number): Promise<Cat | undefined> {
    console.log(`Service: Finding cat with id: ${id}`);
    return this.cats.find((cat) => cat.id === id);
  }

  async update(
    id: number,
    updateCatDto: UpdateCatDto,
  ): Promise<Cat | undefined> {
    console.log(`Service: Updating cat with id: ${id} and data:`, updateCatDto);
    const catIndex = this.cats.findIndex((cat) => cat.id === id);
    if (catIndex === -1) {
      return undefined; // 或者抛出 NotFoundException
    }
    const updatedCat = { ...this.cats[catIndex], ...updateCatDto };
    this.cats[catIndex] = updatedCat;
    return updatedCat;
  }

  async remove(id: number): Promise<boolean> {
    console.log(`Service: Removing cat with id: ${id}`);
    const initialLength = this.cats.length;
    this.cats.splice(
      this.cats.findIndex((cat) => cat.id === id),
      1,
    );
    return this.cats.length < initialLength;
  }
}
```



### 模块 (Module)：代码的组织者
一个应用里会有很多控制器和服务。比如用户相关的 UserController 和 UserService，书籍相关的 BookController 和 BookService。

为了不让代码乱成一锅粥，Nest 引入了“**模块** (Module)”的概念。你可以把用户相关的一套东西（Controller, Service 等）放进用户模块 (UserModule)，书籍相关的放进书籍模块 (BookModule)，各管各的，清清楚楚。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933241083-755c5108-c9f9-4337-b720-4a9e1afeac99.png)

通过 `@Module()` 装饰器来声明一个模块，它会告诉 Nest 这个模块里有哪些控制器 (controllers)，还有哪些“**提供者** (providers)”。



### IoC (控制反转) 与依赖注入
这就引出了 Nest 的一个核心特性——“**控制反转** (IoC, Inverse of Control)”或者叫“**依赖注入** (DI, Dependency Injection)”。

听起来蛮高大上的，其实就是：你不用自己去 `new` 对象实例了。比如你的 UserController 可能需要用到 UserService，你只需要在 UserController 里声明一下“我需要 UserService”，Nest 的 IoC 容器就会自动帮你把 UserService 的实例准备好，然后“注入”进来供你使用。你不用关心它是怎么创建的。

在模块的 `providers` 数组里声明的东西，就是告诉 Nest 这里列出的东西，请你负责创建和管理，当有组件需要用到它们时，自动提供给他们。

Service 只是 provider 的一种常见形式，你还可以通过 `useValue` (直接提供一个值) 或 `useFactory` (通过一个工厂函数创建) 等方式定义 provider。

注入依赖的方式主要有两种：

1. **构造器注入**：在类的构造函数参数里声明依赖（更推荐）。
2. **属性注入**：通过 `@Inject()` 装饰器直接在类属性上声明依赖。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746933314478-70c1f468-9aff-4e5f-a426-801ec585315c.png)



### 实体 (Entity)：数据库表的映射
当我们的服务需要和数据库打交道时，通常会用到“**实体** (Entity)”。

实体可以看作是程序代码里对数据库中一张表的映射。比如你有一个 `users` 表，那在代码里可能就会有一个 `UserEntity` 类，它的属性对应着表里的字段。

```typescript
// src/users/entities/user.entity.ts
import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

// 用户实体类，映射到数据库中的 users 表
@Entity('users')
export class User {
  // 使用 UUID 作为主键
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // 用户名，最大长度50，唯一
  @Column({ length: 50, unique: true })
  username: string;

  // 密码，最大长度100
  @Column({ length: 100 })
  password: string;

  // 邮箱，最大长度100，唯一
  @Column({ name: 'email', length: 100, unique: true })
  email: string;

  // 用户全名，最大长度100，允许为空
  @Column({ name: 'full_name', length: 100, nullable: true })
  fullName: string;

  // 用户状态，默认为激活状态(true)
  @Column({ default: true })
  isActive: boolean;

  // 记录创建时间，自动生成
  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  // 记录更新时间，自动更新
  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
```

1. 实体类（如 `UserEntity`）是数据库表的映射
2. 每个属性对应表中的一个字段
3. 装饰器用于定义字段类型、约束和关系



### MVC 模式：一种经典的架构思想
![画板](https://cdn.nlark.com/yuque/0/2025/jpeg/21596389/1747022815585-4e7d642c-d99f-4e4c-a7b8-52048be549c4.jpeg)

Nest 架构融合了多种设计模式，其核心是一种增强版的 MVC（Model-View-Controller，模型-视图-控制器）模式。

在这种架构中，Controller（控制器）负责接收 HTTP 请求、参数校验和解析，通常使用 DTO (Data Transfer Objects) 进行数据验证和转换，然后将处理后的数据传递给 Service 层。

Service 层封装核心业务逻辑，协调各种资源和操作，遵循单一职责原则。Service 通常通过 Repository/DAO 层与数据库交互，操作领域模型（Entity），这部分对应传统 MVC 中的 Model（模型）。

在 API 开发中，View（视图）则简化为数据序列化过程，负责将模型数据转换为客户端所需的格式。

这种分层架构不仅是对传统 MVC 模式的扩展和细化，更融入了依赖注入（DI）和面向切面编程（AOP）等现代设计理念。Nest 的模块化设计（Module）使应用程序结构更加清晰。

在 Nest 中，Model 被拆分为 Service、Repository 和领域实体等多个层次，View 则简化为响应转换过程，而 Controller 更专注于请求处理和路由。

```typescript
// 1. Controller 接收请求
@Controller('users')
export class UserController {
  constructor(private userService: UserService) {}

  @Get(':id')
  async getUser(@Param('id') id: number) {
    // 2. 调用服务层
    const user = await this.userService.findById(id);
    
    // 5. 转换为响应格式
    return {
      status: 'success',
      data: {
        id: user.id,
        username: user.username,
        email: user.email
      }
    };
  }
}

// 服务层
@Injectable()
export class UserService {
  constructor(private userRepository: UserRepository) {}

  async findById(id: number): Promise<User> {
    // 3. 调用仓储层
    const userEntity = await this.userRepository.findById(id);
    if (!userEntity) throw new NotFoundException();
    
    // 4. 可能进行额外的业务逻辑处理
    return userEntity;
  }
}
```



### AOP (面向切面编程)：处理通用逻辑的利器
![画板](https://cdn.nlark.com/yuque/0/2025/jpeg/21596389/1747304897525-b51c6063-00dd-48b6-803c-0bfb664c667e.jpeg)

有时候，我们有些逻辑是很多地方都会用到的，比如记录每个请求的处理时间、检查用户有没有权限访问某个接口、统一处理错误等等。

如果每个控制器都写一遍，那也太麻烦了。这时候，“**面向切面编程** (AOP, Aspect Oriented Programming)”就派上用场了。

Nest 提供了几种 AOP 的实现方式，它们可以在你的主要业务逻辑执行前或执行后，“切入”一些额外的通用逻辑：

+ **中间件 (Middleware)**: 主要用于处理请求和响应对象，或者调用下一个中间件函数。
+ **守卫 (Guard)**: 主要用于权限控制，决定某个请求是否可以被处理。
+ **拦截器 (Interceptor)**: 功能更强大，可以绑定额外的逻辑到方法执行前后，转换方法返回的结果，或者覆盖抛出的异常。
+ **管道 (Pipe)**: 主要用于数据转换（比如把字符串转成数字）和数据校验。
+ **异常过滤器 (Exception Filter)**: 用于捕获未处理的异常，并发送适当的响应。

比如，记录请求响应时间的逻辑，通过 Interceptor 来实现就非常优雅，需要时在 Controller 或 Handler 上用装饰器声明一下即可。



### Nest CLI：快捷创建助手
创建 Nest 项目、模块、控制器、服务这些，每次手动敲也麻烦，Nest  提供了一个命令行工具 `@nestjs/cli`，几条命令就能帮你把项目结构和基础文件都搭好：

+ `nest new project-name`: 创建一个新项目。
+ `nest generate module users`: 创建一个名为 `users` 的新模块。



### 总结
+ **Controller (控制器)**：处理路由，解析请求参数。
+ **Handler (处理器)**：控制器里处理具体路由的方法。
+ **Service (服务)**：实现业务逻辑的地方，比如操作数据库。
+ **DTO (数据传输对象)**：封装请求体等数据的对象。
+ **Module (模块)**：组织 Controller、Service 等的单元。
+ **Entity (实体)**：对应数据库表的类。
+ **IoC (控制反转) / DI (依赖注入)**：Nest 自动管理和注入依赖的机制。
+ **AOP (面向切面编程)**：通过 Middleware, Guard, Interceptor, Pipe, Exception Filter 等实现可复用的通用逻辑。
+ **Nest CLI**：创建和管理 Nest 项目的命令行工具。

这些只是 Nest 的一些核心概念，刚开始理解个大概就行。

随着你先熟悉 CLI 的使用，再逐步深入这些核心概念，然后学习数据库、ORM 框架等，最后进行项目实战，你会越来越得心应手的。

## node.js 对比 java
| 特性 | Node.js | Java |
| :--- | :--- | :--- |
| **本质** | JavaScript 的服务器端运行环境 | 面向对象的编程语言和平台 |
| **语言** | JavaScript (动态类型) | Java (静态类型) |
| **线程模型** | 单线程、事件驱动、非阻塞 I/O | 多线程、阻塞 I/O (但也有非阻塞 NIO 库) |
| **并发处理** | 通过事件循环和异步回调/Promises/Async-Await | 通过多线程和锁机制 |
| **性能特点** | I/O 密集型应用表现优异 | CPU 密集型应用、大型复杂应用表现稳定 |
| **生态系统** | NPM，模块数量巨大，更新快 | Maven/Gradle，库成熟稳定，企业级方案多 |
| **开发效率** | 通常上手快，开发速度较快 | 相对学习曲线陡峭些，但大型项目更易于维护 |
| **主要应用领域** | Web API、实时应用、微服务、全栈 JS | 企业级应用、安卓开发、大数据、金融系统 |
| **内存占用** | 通常相对较小 | JVM 启动和运行时内存占用可能较大，但可调优 |


node 适合：

+ **高并发应用：** 如实时聊天应用、在线游戏服务器、协作工具等。Node.js 的单线程事件循环机制能够高效处理大量并发连接，而不会造成过多的线程开销。
+ **I/O 密集型应用：** 如数据流应用、文件上传/下载服务、API 网关等。当应用需要频繁地读写文件、访问数据库或进行网络请求时，Node.js 的非阻塞特性可以显著提高性能。
+ **原型开发和快速迭代：** JavaScript 的灵活性和庞大的 npm 生态系统使得 Node.js 非常适合快速构建原型和进行敏捷开发。
+ **Serverlss 及前后端一体化项目，cli 及中间层开发。**

java 更适合：

+ **大型企业级应用：** 如银行系统、保险系统、大型电商平台等。Java 的稳定性和成熟的框架（如 Spring）使其成为构建复杂、高可靠性企业应用的理想选择。
+ **高性能计算和大数据处理：** Java 在多线程处理和内存管理方面有很好的表现，并且拥有如 Hadoop、Spark 等强大的大数据处理框架。
+ **Android 应用开发：** Java (以及后来的 Kotlin) 是 Android 官方支持的开发语言。
+ **对安全性和稳定性要求极高的系统，且需要长期维护和支持的项目。**

如果在公司使用，nest.js 更适合内部前端工具链的开发，如果开发后端应用来说，前提是公司有 Node 开发先例最好，且前端人数明显大于后端人数，且前端的经验基本都是两三年以上最好。
