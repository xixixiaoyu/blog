在后端开发中，我们经常需要处理各种复杂的业务逻辑和数据操作。

随着项目规模的增长，代码中的对象依赖关系会变得越来越复杂，如果没有合适的管理方式，很容易陷入维护困境。

我们来看看 IoC（控制反转）和依赖注入是如何优雅地解决这个问题的。

想象下：我们正在开发一个典型的后端系统，通常会包含这些分层组件：

+ **Controller（控制器）**：接收 HTTP 请求，调用业务服务处理，并将结果返回给客户端
+ **Service（业务服务）**：实现核心业务逻辑
+ ** Repository（数据访问层）**：负责数据库的增删改查操作
+ **DataSource（数据源）**：管理数据库连接池
+ **Config（配置管理）**：存储应用配置信息，如数据库连接参数

这些组件之间存在明显的依赖关系：

+ Controller 依赖 Service 处理业务逻辑
+ Service 依赖 Repository 进行数据操作
+ Repository 依赖 DataSource 获取数据库连接
+ DataSource 依赖 Config 获取连接配置

在没有依赖注入的情况下，我们需要手动创建和管理这些依赖：

```javascript
// 按依赖顺序逐层创建对象
const config = new Config({ 
  username: 'admin', 
  password: 'password123' 
});

const dataSource = new DataSource(config);
const repository = new Repository(dataSource);
const service = new Service(repository);
const controller = new Controller(service);
```

这种方式有几个明显的问题：

1. **创建顺序不能乱**：必须先创建 Config，再创建 DataSource，以此类推
2. **重复创建浪费资源**：像 config、dataSource 这样的基础组件，理想情况下应该是单例
3. **维护成本高**：每次添加新的依赖，都要手动修改创建逻辑
4. **测试困难**：很难为单个组件编写独立的单元测试

如果每个项目都要手动处理这一堆依赖关系，光想想就让人头疼。

## IoC：把控制权交给容器
IoC（Inversion of Control，控制反转）的核心思想很简单：**不再由你主动创建和管理对象，而是把这个控制权交给一个专门的容器**。

我们来看个 🌰：

### 传统的"自己动手"模式
```javascript
// 传统方式：Car 类自己创建 Engine
class Engine {
  start() {
    console.log("引擎启动啦！");
  }
}

class Car {
  constructor() {
    this.engine = new Engine(); // 自己创建引擎
    console.log("车子造好了，用的是我自己造的引擎！");
  }

  run() {
    this.engine.start();
    console.log("车子跑起来啦！");
  }
}

const myCar = new Car();
myCar.run();
```

这种写法的问题是：如果想换个涡轮增压引擎或者电动引擎，就得修改 Car 类的内部代码。代码耦合度太高，扩展性差。

### 依赖注入的优雅方式
```javascript
// 使用依赖注入：Engine 从外部传入
class Engine {
  start() {
    console.log("引擎启动啦！");
  }
}

class TurboEngine extends Engine {
  start() {
    console.log("涡轮增压引擎，启动！动力澎湃！");
  }
}

class Car {
  constructor(engine) { // Engine 通过构造函数注入
    this.engine = engine;
    console.log("车子造好了，用的是外面给我的引擎！");
  }

  run() {
    this.engine.start();
    console.log("车子跑起来啦！");
  }
}

// 外部负责创建和注入依赖
const myNormalEngine = new Engine();
const myCarWithNormalEngine = new Car(myNormalEngine);
myCarWithNormalEngine.run();

// 轻松换个引擎试试
const myTurboEngine = new TurboEngine();
const myCarWithTurboEngine = new Car(myTurboEngine);
myCarWithTurboEngine.run();
```

改造后的 Car 类不再关心 Engine 是怎么来的，只要外部传给它一个引擎就行。这就是依赖注入的魅力所在。

在真正的 IoC 容器中，我们甚至不需要手动创建和传递对象。容器会自动扫描依赖声明，创建实例并注入到需要的地方。



## <font style="color:rgb(38, 38, 38);">Nest 中 IoC 和 DI 是</font>**<font style="color:rgb(38, 38, 38);">如何</font>**<font style="color:rgb(38, 38, 38);">运作的？</font>
### 标记类
**@Injectable()** 装饰器用来标记可注入的服务类：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746893140571-554fdd2b-85ef-42db-8886-5c8dade63f42.png)

**@Controller()** 装饰器用来标记控制器类：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1746931400077-78c37854-9607-48b5-9419-070ba2dc82fc.png)

注意这里的 `private readonly appService: AppService` 是一种简写，完整写法是：

```typescript
private readonly appService: AppService;

constructor(appService: AppService) {
  this.appService = appService;
}
```

AppController 在构造函数里声明了它需要一个 AppService 类型的参数，Nest 的 IoC 容器会自动找到对应的实例并注入进来。



### 模块 (Module) 来组织
Nest 通过 `@Module()` 装饰器来定义模块，模块就像一个打包盒，把相关的组件组织在一起：

```typescript
// app.module.ts
import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [],    // 引入其他模块
  controllers: [AppController], // 这个模块的控制器
  providers: [AppService],      // 这个模块的可注入服务
  exports: []     // 导出给其他模块使用的服务
})
export class AppModule {}
```



### 启动应用
当应用启动时，Nest 会从根模块开始，分析所有的依赖关系：

```typescript
// main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule); // 从根模块开始
  await app.listen(3000);
}
bootstrap();
```

整个过程完全自动化，例如我们只需要在 Controller 里声明依赖，然后就可以直接调用 Service 的方法了，完全不用操心对象的创建和生命周期管理。



### 模块间的协作
在大型应用中，通常会拆分成多个业务模块。如果 OrderService 需要使用 UserService，该怎么办呢？

首先，在 UserModule 中导出 UserService：

```typescript
// user.module.ts
@Module({
  providers: [UserService],
  exports: [UserService], // 导出服务
})
export class UserModule {}
```

然后，在 OrderModule 中导入 UserModule：

```typescript
// order.module.ts
@Module({
  imports: [UserModule], // 导入 UserModule
  controllers: [OrderController],
  providers: [OrderService],
})
export class OrderModule {}
```

这样，OrderService 就可以注入和使用 UserService 了：

```typescript
// order.service.ts
@Injectable()
export class OrderService {
  constructor(private readonly userService: UserService) {}

  createOrder(userId: number) {
    const userName = this.userService.getUserNameById(userId);
    return `Order created for user: ${userName}`;
  }
}
```

