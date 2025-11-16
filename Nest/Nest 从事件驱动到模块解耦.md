在开发复杂应用时，我们经常遇到这样的场景：一个核心功能（如用户注册、创建订单）完成后，需要触发一系列后续操作（如发送邮件、更新库存、记录日志）。如果将这些操作全部写在同一个服务里，模块之间就会产生紧密耦合，变得难以维护和扩展。

这就像现实中的办公室协作——当销售部门成功签下一个大单时，不需要逐个通知财务、仓库、客服等部门，只需要在公司群里发个消息：“新订单来了！” 各个相关部门看到后自然会处理自己的工作。

事件驱动架构正是为了解决这类问题而生的，其本质是 **解耦**。它遵循一种被称为“发布-订阅”（Publisher-Subscriber）的模式，让系统的各个部分可以独立地进行通信和扩展。

## 核心思想：第一性原理

想象一下报社和读者的关系：

*   **报社（事件发布者）**：只负责发布报纸（事件），它不关心谁订阅了报纸，也不关心读者读了报纸后会做什么。
*   **报纸（事件本身）**：承载着信息（如新闻标题、内容）。
*   **读者（事件订阅者/监听器）**：只订阅自己感兴趣的报纸。当新报纸出版时，他们会收到并做出自己的反应（如阅读、讨论、收藏）。

发布者和订阅者互相不知道对方的存在，它们之间唯一的联系就是“事件”这个桥梁。这样一来，系统就变得非常松散和易于扩展。我们可以随时增加新的读者（订阅者），而报社（发布者）完全不受影响。

NestJS 的 `@nestjs/event-emitter` 包正是基于这一思想，为我们提供了一套与框架深度融合的事件驱动解决方案。

## 基础实践：从用户注册说起

我们通过一个经典的用户注册场景，一步步掌握事件通信的用法。

### 第一步：安装与配置

首先，创建新项目并安装必要的包。

```bash
nest new event-emitter-test -p pnpm
cd event-emitter-test
pnpm i @nestjs/event-emitter
```

然后，在根模块（`app.module.ts`）中导入 `EventEmitterModule`。

```typescript
// app.module.ts
import { Module } from '@nestjs/common';
import { EventEmitterModule } from '@nestjs/event-emitter';

@Module({
  imports: [
    // 全局注册事件模块，这样所有服务都可以使用它
    EventEmitterModule.forRoot({
      // 建议开启，以便使用通配符等高级功能
      wildcard: true,
      // 事件名层级分隔符
      delimiter: '.',
      // 单个事件最大监听器数量
      maxListeners: 20,
      // 当触发特殊的 'error' 事件且没有监听器处理时，是否抛出异常
      ignoreErrors: false,
    }),
  ],
})
export class AppModule {}
```

### 第二步：定义事件载体 (Payload)

为事件创建一个专用的类，这样做的好处是类型安全，代码也更清晰。

```typescript
// src/user/events/user-created.event.ts
export class UserCreatedEvent {
  constructor(
    public readonly userId: string,
    public readonly email: string,
    public readonly username: string,
  ) {}
}
```

这个事件类非常纯粹，只包含数据，不包含任何业务逻辑。

### 第三步：发布事件

在用户服务（`user.service.ts`）中，当用户创建成功后，注入 `EventEmitter2` 并发布事件。

```typescript
// src/user/user.service.ts
import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { CreateUserDto } from './dto/create-user.dto';
import { UserCreatedEvent } from './events/user-created.event';

@Injectable()
export class UserService {
  // 1. 注入 EventEmitter2
  constructor(private readonly eventEmitter: EventEmitter2) {}

  create(createUserDto: CreateUserDto) {
    // 假设这里完成了用户创建逻辑，并得到了新用户信息
    const userId = 'a-unique-user-id';
    console.log(`用户 ${createUserDto.username} 注册成功`);

    // 2. 发布事件，解耦后续操作
    // 'user.created' 是事件的名称，需要是唯一的字符串
    // 第二个参数是事件携带的数据
    this.eventEmitter.emit(
      'user.created',
      new UserCreatedEvent(userId, createUserDto.email, createUserDto.username),
    );

    return { message: '用户创建成功，后续操作已触发' };
  }
}
```

**设计思路**：`UserService` 的核心职责是创建用户。完成后，它通过 `emit` 方法宣告“用户已创建”这件事，然后就完成了自己的使命。它不关心谁会收到这个消息，也不关心收到消息后会做什么。这使得 `UserService` 保持专注和简洁。

### 第四步：监听事件

现在，让其他服务来订阅这个事件。例如，创建一个通知服务（`notification.service.ts`）来发送欢迎邮件。

```typescript
// src/notification/notification.service.ts
import { Injectable } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { UserCreatedEvent } from '../user/events/user-created.event';
// 假设你有一个邮件服务
import { EmailService } from '../email/email.service';

@Injectable()
export class NotificationService {
  constructor(private readonly emailService: EmailService) {}

  // 使用 @OnEvent 装饰器来监听特定名称的事件
  @OnEvent('user.created', { async: true }) // 推荐将耗时操作设为异步
  async handleUserCreatedEvent(payload: UserCreatedEvent) {
    // payload 就是发布时传递的事件数据
    console.log(`[NotificationService] 收到用户创建事件，准备给 ${payload.email} 发送欢迎邮件...`);
    
    await this.emailService.sendMail({
      to: payload.email,
      subject: `欢迎 ${payload.username}`,
      html: '欢迎加入我们的大家庭！',
    });
  }
}
```

**设计思路**：`NotificationService` 独立地对 `user.created` 事件做出反应。未来如果需要增加“给新用户发放优惠券”的功能，我们只需再创建一个 `CouponService` 并监听同一个事件即可，完全不需要修改 `UserService` 或 `NotificationService`。

## 进阶应用：电商订单处理流程

我们看一个更完整的电商订单处理示例，它清晰地展示了事件驱动如何协调多个复杂业务。

### 1. 事件定义

```typescript
// events/order-created.event.ts
export class OrderCreatedEvent {
  constructor(
    public orderId: number,
    public customerId: number,
    public items: Array<{ productId: number; quantity: number; price: number }>,
    public totalAmount: number,
  ) {}
}

// events/payment-processed.event.ts
export class PaymentProcessedEvent {
  constructor(
    public orderId: number,
    public paymentId: string,
  ) {}
}
```

### 2. 发布事件的订单服务

```typescript
// order/order.service.ts
@Injectable()
export class OrderService {
  constructor(private eventEmitter: EventEmitter2) {}

  async createOrder(orderData: any): Promise<any> {
    const order = await this.saveOrderToDb(orderData);
    
    // 发射订单创建事件
    this.eventEmitter.emit('order.created', new OrderCreatedEvent(
      order.id,
      order.customerId,
      order.items,
      order.totalAmount
    ));

    return order;
  }

  async processPayment(orderId: number, paymentData: any): Promise<void> {
    const payment = await this.handlePaymentGateway(paymentData);
    
    // 发射支付完成事件
    this.eventEmitter.emit('payment.processed', new PaymentProcessedEvent(
      orderId,
      payment.id,
    ));
  }

  private async saveOrderToDb(data: any) { /* 实现保存订单到数据库的逻辑 */ }
  private async handlePaymentGateway(data: any) { /* 实现调用支付网关的逻辑 */ }
}
```

### 3. 监听事件的多个微服务

```typescript
// email/email.service.ts
@Injectable()
export class EmailService {
  @OnEvent('order.created')
  sendOrderConfirmation(event: OrderCreatedEvent) {
    console.log(`发送订单确认邮件，订单号：${event.orderId}`);
    // ...发送邮件逻辑
  }

  @OnEvent('payment.processed')
  sendPaymentReceipt(event: PaymentProcessedEvent) {
    console.log(`发送支付凭证邮件，订单号：${event.orderId}`);
    // ...发送邮件逻辑
  }
}

// inventory/inventory.service.ts
@Injectable()
export class InventoryService {
  @OnEvent('order.created', { async: true })
  async reserveInventory(event: OrderCreatedEvent) {
    console.log(`为订单 ${event.orderId} 预留库存...`);
    for (const item of event.items) {
      await this.reserveItem(item.productId, item.quantity);
    }
    console.log(`订单 ${event.orderId} 库存预留完毕。`);
  }

  private async reserveItem(productId: number, quantity: number) { /* 实现库存扣减 */ }
}

// logistics/logistics.service.ts
@Injectable()
export class LogisticsService {
  @OnEvent('payment.processed', { async: true })
  async arrangeShipping(event: PaymentProcessedEvent) {
    console.log(`为订单 ${event.orderId} 安排发货...`);
    await this.createShippingOrder(event.orderId);
    console.log(`订单 ${event.orderId} 已通知仓库发货。`);
  }

  private async createShippingOrder(orderId: number) { /* 实现创建物流单 */ }
}
```

在这个例子中，`OrderService` 只负责核心的订单和支付流程，而后续的邮件通知、库存管理、物流发货等操作被完全解耦到各自的模块中，每个模块只关心自己需要响应的事件。

## 高级特性与监听器选项

### 通配符监听

当 `wildcard` 设置为 `true` 时，你可以监听一类事件。

```typescript
// 发布多个相关事件
findAll() {
  this.eventEmitter.emit('test.find.one', { data: 'data 1' });
  this.eventEmitter.emit('test.find.two', { data: 'data 2' });
}

// 使用通配符监听
@OnEvent('test.find.*')
handleAllFindEvents(payload: any) {
  console.log('捕获到 test.find.* 事件', payload);
}
```

### `@OnEvent()` 装饰器选项

`@OnEvent()` 提供了丰富的配置来控制监听器的行为：

```typescript
@Injectable()
export class AdvancedListenerService {
  // 1. 异步处理：不阻塞事件循环和其他监听器，适用于 I/O 密集型任务。
  @OnEvent('user.registered', { async: true })
  async handleUserRegistration(event: any) {
    await this.sendWelcomeEmail(event.userId);
  }

  // 2. 优先执行：将此监听器添加到监听器队列的开头，确保它比其他监听器更早执行。
  @OnEvent('order.cancelled', { prependListener: true })
  handleOrderCancellation(event: any) {
    console.log('优先处理订单取消，例如立即返还优惠券。');
  }

  // 3. 错误隔离：在监听器内捕获异常，避免影响其他监听器的执行。
  @OnEvent('data.sync')
  handleDataSync(event: any) {
    try {
      // 可能会失败的同步逻辑
    } catch (e) {
      // 错误被捕获，但不会向上传播
      // 在这里使用应用级日志或错误上报服务进行处理
    }
  }

  private async sendWelcomeEmail(userId: number) { /* ... */ }
}
```

## 最佳实践与思考

1.  **事件命名规范**：采用点分隔的层级结构（如 `user.created`, `order.shipped`），清晰明了，便于使用通配符。建议将事件名定义为常量，避免“魔法字符串”。
    ```typescript
    export const EVENTS = {
      USER_CREATED: 'user.created',
      ORDER_PLACED: 'order.placed',
    }
    ```

2.  **处理耗时操作**：对于发送邮件、调用第三方 API、复杂计算等耗时任务，务必在 `@OnEvent()` 中设置 `{ async: true }`，否则会阻塞整个事件流程，影响其他监听器的执行。

3.  **监听器健壮性**：监听器中的代码应该健壮。一个监听器抛出未捕获的异常可能会影响其他监听器。使用 `try-catch` 或 `{ suppressErrors: true }` 来妥善处理错误。

4.  **避免循环事件**：警惕事件循环依赖，例如 A 事件触发 B 事件，B 事件又反过来触发 A 事件，这会导致无限循环和栈溢出。设计事件流时，尽量保持单向数据流。

5.  **选择正确的发布时机**：在某些场景下，你可能希望确保所有模块都已加载完毕再发布事件。`OnApplicationBootstrap` 生命周期钩子是一个常见的、安全的选择，因为此时所有模块和提供者都已实例化。

### 启发式提问

现在，轮到你来思考了：

*   在你当前的项目里，有没有哪些业务流程是“一步接着一步”，但后续步骤其实并不那么紧急，或者可以独立失败的？（比如下单后扣减库存、生成订单号、通知仓库等）
*   如果把其中一些步骤改造成事件模式，你觉得系统的哪个部分会变得更“灵活”？哪个部分可能会变得更“复杂”？（比如，调试和追踪问题可能会稍微困难一些）
*   除了 `EventEmitterModule`，你还知道哪些可以实现类似“解耦”目的的模式或工具吗？（比如消息队列 RabbitMQ/Kafka）
