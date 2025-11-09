想象一下，你正在开发一个复杂的应用，比如一个电商平台。里面会有很多通用的功能，比如：

+ **日志记录**：哪个用户在什么时间调用了哪个接口，参数是啥，返回了啥，花了多长时间。
+ **权限校验**：这个用户有没有权限访问这个接口？
+ **数据校验**：用户传过来的参数格式对不对，是不是缺了啥？
+ **缓存处理**：某些接口的结果是不是可以缓存起来，下次直接返回，不用老是查数据库？
+ **事务管理**：一系列数据库操作要么都成功，要么都失败。

如果每个业务逻辑的函数里都手动去写这些代码，那代码无疑非常臃肿重复，你想改个日志格式，可能得改几十上百个地方，估计都改的想跑路。

这时候，**AOP (Aspect-Oriented Programming，面向切面编程) **闪亮登场。

## 什么是 AOP？
AOP 就是一种编程思想，它允许你把那些“横跨”多个模块的通用功能（我们叫它“横切关注点”，Cross-Cutting Concerns）给拎出来，单独放到一个地方去管理。

我们平常的后端服务很多都是基于 MC 架构：

![画板](https://cdn.nlark.com/yuque/0/2025/jpeg/21596389/1747022799965-87e44715-76d1-4e53-b6e0-afbff499c489.jpeg)

在这个链路上，我们想加上一些通用的处理逻辑，比如在调用 Controller 前检查下权限，在 Service 处理完后记个日志。

AOP 就像一把锋利的刀，允许我们在这条主线上“横向”切入，把这些通用逻辑“织入”到流程中：

```javascript
          通用逻辑（比如日志、权限）
             ^
             |  (透明地切入)
请求 --> Controller --> Service --> Repository --> 响应
```

这个“横向”切入的点，就叫做“切面”（Aspect）。这种编程方式，就是面向切面编程。

好处显而易见，不用侵入原本业务逻辑代码，代码可以很灵活的插拔复用。

其实，如果你用过 Express，它的中间件（Middleware）那种“洋葱模型”就是 AOP 思想的一种体现。你可以在请求处理的核心逻辑外层，一层层包裹上各种中间件，每一层处理特定的通用任务，而核心逻辑并不需要知道这些外层逻辑的存在。

Nest 的 AOP 体现在，它提供了五种主要的“切面”工具，让我们可以更精细地控制这些通用逻辑的植入点。它们分别是：

1. **中间件 (Middleware)**
2. **守卫 (Guard)**
3. **拦截器 (Interceptor)**
4. **管道 (Pipe)**
5. **异常过滤器 (ExceptionFilter)**



## Nest AOP 顺序
![画板](https://cdn.nlark.com/yuque/0/2025/jpeg/21596389/1746772759627-f5b795da-7fa1-492b-8be1-5de9946f6c3f.jpeg)

作用域优先级: 

+ 全局 -> 控制器 -> 路由方法 -> 参数 (对于管道)。

同一作用域下的多个装饰器：

+ 如果同一个路由方法上应用了多个同类型的装饰器 (如多个 @UseGuards(GuardA,GuardB) 或 @UseGuards(GuardA) @UseGuards(GuardB) )，它们会按照代码中出现的顺序（从上到下，或数组中的从左到右）依次执行。

这里面特别注意下拦截器，它分为 pre 和 post：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749394983768-6a1d3c5a-02a2-435d-8e01-89703cf486bd.png)

假设有两个拦截器，一个日志拦截器：

```typescript
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const method = request.method;
    const url = request.url;
    const now = Date.now();
    
    console.log(`[PRE] 请求开始 - ${method} ${url}`);
    
    // pre 阶段结束，将控制权传递给路由处理器
    // next.handle() 返回一个 Observable，代表路由处理器的响应流
    
    return next
      .handle()
      .pipe(
        tap(responseBody => {
          // post 阶段开始，路由处理器已经返回响应
          const delay = Date.now() - now;
          console.log(`[POST] 请求结束 - ${method} ${url} - ${delay}ms`);
          console.log(`[POST] 响应数据:`, responseBody);
        }),
      );
  }
}
```

一个数据转换拦截器：

```typescript
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class TransformInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    console.log('[PRE] TransformInterceptor - 准备处理请求');
    
    // pre 阶段可以修改请求
    const request = context.switchToHttp().getRequest();
    if (!request.headers['x-request-id']) {
      request.headers['x-request-id'] = `req-${Date.now()}`;
      console.log(`[PRE] 添加请求ID: ${request.headers['x-request-id']}`);
    }
    
    return next.handle().pipe(
      map(data => {
        // post 阶段 - 转换响应数据
        console.log('[POST] TransformInterceptor - 转换响应');
        
        // 将任何响应包装在标准格式中
        return {
          success: true,
          timestamp: new Date().toISOString(),
          path: request.url,
          data
        };
      }),
    );
  }
}
```

使用这些拦截器：

```typescript
import { Controller, Get, UseInterceptors } from '@nestjs/common';
import { LoggingInterceptor } from './logging.interceptor';
import { TransformInterceptor } from './transform.interceptor';

@Controller('demo')
@UseInterceptors(LoggingInterceptor) // 控制器级别拦截器
export class DemoController {
  
  @Get()
  @UseInterceptors(TransformInterceptor) // 路由级别拦截器
  findAll() {
    console.log('[CONTROLLER] 处理请求中...');
    return ['item1', 'item2', 'item3'];
  }
}
```

```typescript
import { Module } from '@nestjs/common';
import { APP_INTERCEPTOR } from '@nestjs/core';
import { DemoController } from './demo.controller';
import { LoggingInterceptor } from './logging.interceptor';

@Module({
  controllers: [DemoController],
  providers: [
    // 全局拦截器
    {
      provide: APP_INTERCEPTOR,
      useClass: LoggingInterceptor,
    },
  ],
})
export class AppModule {}
```

当访问 `/demo` 端点时，执行结果：

```bash
[PRE] 请求开始 - GET /demo  (全局拦截器)
[PRE] 请求开始 - GET /demo  (控制器拦截器)
[PRE] TransformInterceptor - 准备处理请求  (路由拦截器)
[PRE] 添加请求ID: req-1621234567890  (路由拦截器)
[CONTROLLER] 处理请求中...  (控制器方法)
[POST] TransformInterceptor - 转换响应  (路由拦截器)
[POST] 请求结束 - GET /demo - 5ms  (控制器拦截器)
[POST] 响应数据: { success: true, timestamp: '2023-05-17T12:34:56.789Z', path: '/demo', data: ['item1', 'item2', 'item3'] }  (控制器拦截器)
[POST] 请求结束 - GET /demo - 7ms  (全局拦截器)
[POST] 响应数据: { success: true, timestamp: '2023-05-17T12:34:56.789Z', path: '/demo', data: ['item1', 'item2', 'item3'] }  (全局拦截器)
```

