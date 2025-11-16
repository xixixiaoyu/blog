日志记录是现代应用的“黑匣子”，不仅帮助开发者调试代码，还为生产环境提供关键的监控和问题追踪能力。NestJS 提供了一套强大而灵活的日志系统，兼顾开箱即用的便利性和高度可定制的扩展性。

本文将带你从 NestJS 的内置 Logger 入手，逐步深入到集成强大的 Winston 日志框架，并最终通过拦截器实战构建一个完善的请求日志系统。

## 快速上手：NestJS 内置日志系统

NestJS 内置的 `ConsoleLogger` 简单易用，支持多种配置方式，让你轻松控制日志行为。

### 基础日志配置

默认情况下，Nest 应用启动时会打印启动日志。你可以通过 `NestFactory.create` 的第二个参数来控制日志级别：

```typescript
// main.ts

// 完全禁用日志
const app = await NestFactory.create(AppModule, { logger: false });

// 仅显示错误和警告
const app = await NestFactory.create(AppModule, { logger: ['error', 'warn'] });
```

Nest 支持以下日志级别，从最详细到最严重：`verbose`、`debug`、`log`、`warn`、`error`。你可以根据环境需求灵活选择。例如，开发时开启 `verbose` 保留完整信息，生产环境只保留 `error` 和 `warn` 以减少 I/O 开销。

### 美化日志输出

为了提升开发体验，Nest 允许自定义日志格式：

```typescript
// main.ts
import { ConsoleLogger, Logger } from '@nestjs/common';

// 使用自定义 LoggerService 时传入实例
const app = await NestFactory.create(AppModule, {
  logger: new ConsoleLogger()
});

// 在业务代码中通过 Logger 启用时间戳与上下文
const logger = new Logger('MyService', { timestamp: true });
```

启用时间戳后，输出示例：

```bash
[Nest] 19096 - 11/16/2025, 9:56:00 AM [MyService] Processing order +5ms
```

时间戳会显示与上一条日志的时间差（如 `+5ms`），便于性能分析。

### JSON 结构化日志

内置 `ConsoleLogger` 不支持直接输出 JSON。若需要结构化日志，建议实现自定义 `LoggerService` 或集成第三方库（如 Winston 或 Pino）。下文的 Winston 方案即提供了 JSON 文件输出。

### 在服务中使用日志

在业务逻辑中，推荐使用 `Logger` 类并注入上下文以区分日志来源：

```typescript
// src/order.service.ts
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
class OrderService {
  private readonly logger = new Logger(OrderService.name, { timestamp: true });

  processOrder(order: Order) {
    this.logger.debug(`Processing order ${order.id}`);
    try {
      // 业务逻辑
      this.logger.log(`Order ${order.id} processed successfully`);
    } catch (error) {
      this.logger.error(`Order ${order.id} failed`, error.stack);
    }
  }
}
```

这种方式确保日志带上 `[OrderService]` 上下文标记，便于追踪来源。

### 自定义 Logger 类

对于复杂需求，Nest 支持通过继承 `ConsoleLogger` 或实现 `LoggerService` 接口进行深度定制：

```typescript
// src/custom-logger.service.ts
import { Injectable, LoggerService } from '@nestjs/common';

@Injectable()
export class CustomLogger implements LoggerService {
  log(message: any, context?: string) {
    console.log(`[LOG] ${new Date().toISOString()} [${context}] ${message}`);
  }

  error(message: any, trace?: string, context?: string) {
    console.error(`[ERROR] ${new Date().toISOString()} [${context}] ${message}`);
    if (trace) {
      console.error(trace);
    }
  }

  warn(message: any, context?: string) {
    console.warn(`[WARN] ${new Date().toISOString()} [${context}] ${message}`);
  }
  
  // ... 其他方法
}
```

然后在 `main.ts` 中启用它：

```typescript
// main.ts
const app = await NestFactory.create(AppModule);
app.useLogger(app.get(CustomLogger));
await app.listen(3000);
```

## 集成专业日志库 Winston

虽然内置 Logger 功能够用，但对于复杂的生产环境需求，如日志轮转（按日期或大小分割文件）、多种存储目标（数据库、远程服务）等，集成专业的日志库是更好的选择。Winston 是 Node.js 生态中最流行的日志框架之一。

### 为什么选择 Winston？

1.  **多种日志级别**：支持 `error`、`warn`、`info`、`http`、`verbose`、`debug`、`silly` 等多种级别。
2.  **可插拔的存储（Transports）**：支持将日志输出到控制台、文件、HTTP 端点、数据库等多种目标，社区生态丰富。
3.  **自定义日志格式 (Formats)**：可轻松自定义日志格式，添加时间戳、颜色、标签，或输出为 JSON。
4.  **日志轮转**：通过 `winston-daily-rotate-file` 等 transport，可以按时间或文件大小自动分割归档日志文件。
5.  **高性能**：为异步日志记录设计，对应用性能影响小。

### 在 NestJS 中集成 Winston

我们的目标是创建一个 `WinstonLoggerService` 来替换 Nest 的内置 Logger。

1.  **安装依赖**

    ```bash
    npm install winston winston-daily-rotate-file dayjs chalk@4
    ```
    *   `winston`: 核心库。
    *   `winston-daily-rotate-file`: 用于日志文件按日轮转。
    *   `dayjs`: 用于格式化时间。
    *   `chalk@4`: 用于在控制台输出彩色日志（注意需使用 v4 版本）。

2.  **创建 WinstonLoggerService**

    我们来实现一个功能完备的 Logger 服务，它能模仿 Nest 的默认日志格式，并同时将日志写入文件。

    ```typescript
    // src/logger/winston-logger.service.ts
    import { Injectable, LoggerService } from '@nestjs/common';
    import * as chalk from 'chalk';
    import * as dayjs from 'dayjs';
    import { createLogger, format, Logger, transports } from 'winston';
    import 'winston-daily-rotate-file';

    @Injectable()
    export class WinstonLoggerService implements LoggerService {
      private logger: Logger;

      constructor() {
        this.logger = createLogger({
          level: 'debug',
          format: format.combine(
            format.colorize(),
            format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
            format.printf(({ context, level, message, timestamp }) => {
              const appStr = chalk.green(`[NEST]`);
              const contextStr = chalk.yellow(`[${context}]`);
              return `${appStr} ${timestamp} ${level} ${contextStr} ${message}`;
            }),
          ),
          transports: [
            // 控制台输出
            new transports.Console(),
            // 文件输出，按日轮转
            new transports.DailyRotateFile({
              level: 'info',
              dirname: 'logs', // 日志文件存放目录
              filename: 'application-%DATE%.log', // 文件名
              datePattern: 'YYYY-MM-DD', // 日期格式
              zippedArchive: true, // 是否压缩归档
              maxSize: '20m', // 单个文件最大尺寸
              maxFiles: '14d', // 最多保留14天
              format: format.combine(
                format.uncolorize(), // 从文件输出中移除颜色
                format.json(),
              ),
            }),
            // 错误日志文件
            new transports.DailyRotateFile({
              level: 'error',
              dirname: 'logs',
              filename: 'error-%DATE%.log',
              datePattern: 'YYYY-MM-DD',
              zippedArchive: true,
              maxSize: '20m',
              maxFiles: '14d',
              format: format.combine(
                format.uncolorize(),
                format.json(),
              ),
            }),
          ],
          // 捕获未处理的异常
          exceptionHandlers: [
            new transports.File({
              dirname: 'logs',
              filename: 'exceptions.log',
            }),
          ],
          rejectionHandlers: [
            new transports.File({
              dirname: 'logs',
              filename: 'rejections.log',
            }),
          ],
        });
      }

      log(message: string, context?: string) {
        this.logger.info(message, { context });
      }

      error(message: string, trace?: string, context?: string) {
        this.logger.error(message, { context, trace });
      }

      warn(message: string, context?: string) {
        this.logger.warn(message, { context });
      }

      debug(message: string, context?: string) {
        this.logger.debug(message, { context });
      }

      verbose(message: string, context?: string) {
        this.logger.verbose(message, { context });
      }
    }
    ```

3.  **全局替换 Logger**

    在 `main.ts` 中，使用我们刚创建的 `WinstonLoggerService`。

    ```typescript
    // main.ts
    import { NestFactory } from '@nestjs/core';
    import { AppModule } from './app.module';
    import { WinstonLoggerService } from './logger/winston-logger.service';
    
    async function bootstrap() {
      const app = await NestFactory.create(AppModule, {
        // 使用我们自定义的 Winston Logger
        logger: new WinstonLoggerService(),
        // 也可以在启动时缓存日志，直到自定义 logger 准备就绪
        bufferLogs: true,
      });
      
      // 如果没有在 create 时传入，也可以用 useLogger
      // app.useLogger(app.get(WinstonLoggerService));
      
      await app.listen(3000);
    }
    bootstrap();
    ```

现在，当你运行应用时，控制台会显示彩色的、格式化的日志，同时在 `logs` 目录下会生成结构化的 JSON 日志文件，并按天分割。

### 封装为动态模块

为了更好的复用性和可配置性，我们可以将 Logger 封装成一个动态模块。这部分可以参考 `nest-winston` 的实现思路，这里不再赘述，核心是创建一个 `LoggerModule`，通过 `forRoot` 或 `forRootAsync` 方法接收配置，并提供 `WinstonLoggerService`。

## 实战：使用拦截器构建请求日志系统

日志的一个核心用途是追踪 API 请求。在每个 Controller 手动记录日志是不可维护的，最佳实践是使用 NestJS 的拦截器（Interceptor）实现 AOP（面向切面编程）。

### 为什么选择拦截器？

拦截器可以在请求到达路由处理函数之前或之后执行特定逻辑，非常适合实现日志、缓存、身份验证等横切关注点，让业务代码保持纯净。

1.  **创建拦截器**

    ```bash
    nest g interceptor request-log --no-spec --flat
    ```

2.  **实现拦截器逻辑**

    我们的目标是记录请求的方法、路径、IP、User-Agent、耗时、状态码等信息。

    ```typescript
    // src/request-log.interceptor.ts
    import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
    import { Request, Response } from 'express';
    import { Observable } from 'rxjs';
    import { tap } from 'rxjs/operators';
    import * as requestIp from 'request-ip';
    import { WinstonLoggerService } from './logger/winston-logger.service'; // 引入我们的 Logger

    @Injectable()
    export class RequestLogInterceptor implements NestInterceptor {
      // 注入自定义的 Logger 服务
      constructor(private readonly logger: WinstonLoggerService) {}

      intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
        const request = context.switchToHttp().getRequest<Request>();
        const response = context.switchToHttp().getResponse<Response>();
        const handlerName = `${context.getClass().name}.${context.getHandler().name}`;

        const { method, path } = request;
        const clientIp = requestIp.getClientIp(request); // 使用 request-ip 获取真实 IP
        const userAgent = request.headers['user-agent'] || 'Unknown';

        const startTime = Date.now();

        // 记录请求信息
        this.logger.debug(
          `[Request] ${method} ${path} - IP: ${clientIp} - User-Agent: ${userAgent}`,
          handlerName,
        );

        return next.handle().pipe(
          tap((data) => {
            const duration = Date.now() - startTime;
            // 记录响应信息
            this.logger.log(
              `[Response] ${method} ${path} - IP: ${clientIp} - Status: ${response.statusCode} - Duration: ${duration}ms`,
              handlerName,
            );
            // 可选：记录响应体（注意生产环境中可能需要脱敏或截断）
            // this.logger.debug(`Response Body: ${JSON.stringify(data)}`, handlerName);
          }),
        );
      }
    }
    ```
    *   我们注入了之前创建的 `WinstonLoggerService`。
    *   使用 `request-ip` 库来获取真实的客户端 IP，这在应用部署于 Nginx 等反向代理后非常重要。
    *   通过 `rxjs` 的 `tap` 操作符，我们在不改变响应流的情况下，记录下响应完成后的信息，如状态码和耗时。

3.  **全局注册拦截器**

    在 `app.module.ts` 中全局注册，使其对所有请求生效。

    ```typescript
    // src/app.module.ts
    import { Module } from '@nestjs/common';
    import { APP_INTERCEPTOR } from '@nestjs/core';
    import { RequestLogInterceptor } from './request-log.interceptor';
    import { LoggerModule } from './logger/logger.module'; // 假设已封装为模块
    
    @Module({
      imports: [LoggerModule], // 引入 Logger 模块
      providers: [
        {
          provide: APP_INTERCEPTOR,
          useClass: RequestLogInterceptor,
        },
      ],
    })
    export class AppModule {}
    ```

### 拓展：通过 IP 查询地理位置

为了让日志信息更丰富，我们甚至可以调用第三方 API 查询 IP 的地理位置。

> **注意**：每次请求都调用外部 API 会显著增加响应时间。在生产环境中，强烈建议结合缓存（如 Redis）使用，或只在关键业务（如登录）中执行。

这里给出一个简单示例：

```typescript
// 在 RequestLogInterceptor 中
// ...
import { HttpService } from '@nestjs/axios';
import * as iconv from 'iconv-lite';
import { from, Observable } from 'rxjs';
import { mergeMap, tap } from 'rxjs/operators';

// ...
constructor(
    private readonly logger: WinstonLoggerService,
    private readonly httpService: HttpService,
) {}

private async getCityFromIp(ip?: string): Promise<string> {
    if (!ip) {
        return '未知'
    }
    if (ip.includes('127.0.0.1') || ip.includes('::1')) {
        return '本地'
    }
    try {
        const url = `https://whois.pconline.com.cn/ipJson.jsp?ip=${ip}&json=true`
        const response = await this.httpService.axiosRef.get(url, {
            responseType: 'arraybuffer',
        })
        const dataStr = iconv.decode(response.data, 'gbk')
        const data = JSON.parse(dataStr)
        return data.addr?.trim() || '未知'
    } catch (error) {
        this.logger.error(`IP 查询失败: ${ip}`, error.stack, 'IpQuery')
        return '未知'
    }
}

intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    // 省略前置获取 request/response 等代码
    const request = context.switchToHttp().getRequest<Request>();
    const response = context.switchToHttp().getResponse<Response>();
    const handlerName = `${context.getClass().name}.${context.getHandler().name}`;
    const { method, path } = request;
    const clientIp = request.headers['x-forwarded-for'] as string || request.ip;
    const startTime = Date.now();

    return from(this.getCityFromIp(clientIp)).pipe(
      mergeMap((city) => {
        this.logger.debug(
          `[Request] ${method} ${path} - IP: ${clientIp} (${city}) ...`,
          handlerName,
        );
        return next.handle().pipe(
          tap(() => {
            const duration = Date.now() - startTime;
            this.logger.log(
              `[Response] ${method} ${path} - IP: ${clientIp} - Status: ${response.statusCode} - Duration: ${duration}ms`,
              handlerName,
            );
          }),
        );
      }),
    );
}
```

## 生产环境最佳实践与总结

1.  **分环境配置**：
    *   **开发环境**：启用彩色日志和 `debug` 级别，便于调试。
    *   **生产环境**：使用 JSON 结构化日志，级别设为 `info` 或 `warn`，避免 I/O 性能瓶颈。
2.  **日志脱敏**：绝不在日志中记录密码、Token、信用卡号等敏感信息。创建自定义 Logger 或重写 `log` 方法，在记录前进行数据脱敏。
3.  **错误捕获**：使用 Winston 的 `exceptionHandlers` 和 `rejectionHandlers` 来捕获未处理的异常和 Promise 拒绝，确保没有错误被遗漏。
4.  **日志轮转与归档**：必须配置日志轮转，防止单个日志文件过大撑爆磁盘，并定期清理或归档旧日志。
5.  **使用 `bufferLogs`**：在 `NestFactory.create` 中设置 `bufferLogs: true`，可以缓存应用启动过程中的日志，直到你的自定义 Logger 完全实例化，防止日志丢失。

### 总结

NestJS 的日志系统兼具简单性和灵活性。通过本文的引导，你已经掌握了从使用内置 Logger 快速上手，到集成 Winston 实现专业、可扩展的日志方案，再到利用拦截器构建自动化请求追踪系统的全过程。

一个设计良好的日志系统是保障应用稳定、快速定位问题的基石。将这些实践应用到你的项目中，你将能轻松掌控应用的每一个“心跳”。
