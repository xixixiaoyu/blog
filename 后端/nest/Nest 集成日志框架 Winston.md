## 初步集成
创建项目：

```bash
nest new nest-winston-test -p npm
```

进入目录将服务跑起来：

```bash
npm run start:dev
```

安装 winston：

```bash
npm install winston
```

创建 logger.service.ts：

```typescript
import { Injectable, LoggerService } from '@nestjs/common';
import * as winston from 'winston';

@Injectable()
export class WinstonLoggerService implements LoggerService {
  private readonly logger: winston.Logger;

  constructor() {
    this.logger = winston.createLogger({
      transports: [
        new winston.transports.Console(),
        // 根据需要添加更多的 transports
      ],
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.printf(
          (info) => `${info.timestamp} ${info.level}: ${info.message}`,
        ),
      ),
    });
  }

  log(message: string) {
    this.logger.log('info', message);
  }

  error(message: string, trace: string) {
    this.logger.log('error', `${message} - ${trace}`);
  }

  warn(message: string) {
    this.logger.log('warn', message);
  }

  // 根据需要添加更多的日志级别方法
}
```

注册：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1707883271814-b3f10aba-4b5f-4031-817c-94262b88d4bf.png)

使用：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1707883303295-cb5cb27c-03bb-4b33-bbca-93ab38f8dbff.png)

访问下 localhost:3000：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1707883356213-54ac7408-43ca-4cfa-98d4-5afda2a2da9b.png)

成功打印了日志。但是和 nest 内置的日志格式不一样。我们可以模仿下。



## 添加更多
安装 dayjs 格式化日期：

```bash
npm install dayjs
```

安装 chalk 来打印颜色：

```bash
npm install chalk@4
```

注意：这里用的是 chalk 4.x 的版本。

然后来实现下 nest 日志的格式：

```typescript
import { LoggerService } from '@nestjs/common';
import * as chalk from 'chalk';
import * as dayjs from 'dayjs';
import { createLogger, format, Logger, transports } from 'winston';

export class WinstonLoggerService implements LoggerService {
  private logger: Logger;

  constructor() {
    this.logger = createLogger({
      level: 'debug',
      transports: [
        new transports.Console({
          format: format.combine(
            format.colorize(),
            format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
            format.printf(({ context, level, message, time }) => {
              const appStr = chalk.green(`[NEST]`);
              const contextStr = chalk.yellow(`[${context}]`);

              return `${appStr} ${time} ${level} ${contextStr} ${message} `;
            }),
          ),
        }),
      ],
    });
  }

  getTime() {
    return dayjs(Date.now()).format('YYYY-MM-DD HH:mm:ss');
  }

  log(message: string, context: string) {
    this.logger.info(message, { context, time: this.getTime() });
  }

  error(message: string, context: string) {
    this.logger.error(message, { context, time: this.getTime() });
  }

  warn(message: string, context: string) {
    this.logger.warn(message, { context, time: this.getTime() });
  }
}
```

main.ts 替换 Nest.js 内置的 logger：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1707885613830-c86b6be6-0cb8-4c38-bc1e-f4e0bffb67c1.png)

加下第二个上下文参数：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1707885661343-e0e6e9d2-196c-4182-a6af-6dc3a52aaad4.png)

访问下页面：打印：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1707885695188-23fb4170-0209-48d1-9a18-b42a1a022af2.png)

然后加一个 File 的 transport。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1707885527091-417e90f7-9931-4100-9d6c-a6e16034ec0c.png)

会生成日志文件：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1707885748309-12dab399-5f4f-4e92-a514-50154b81c34e.png)



## 封装成动态模块
我们可以将 winston 集成到 nest 中，社区也有对应的包：`nest-winston`，我们来自己封装下叭：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1700403882747-c31aea4f-b747-4a54-b24f-47132ebe6adc.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708071910107-9968b32e-f327-4893-8255-4f2222c07c8a.png)

logger.service.ts：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1700404008332-435a6878-d0a2-42f8-a04f-ef666c9cc97d.png)

然后在 AppModule 引入下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708072040493-7c454b12-23d4-4510-8921-d9d32b809648.png)

改一下 main.ts 里用的 logger：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1700404118731-d7ce2084-f967-4be8-bef7-66f72a2be63c.png)

正常打印：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708072542330-fa700b5e-803c-403f-b2bd-84f6bca93b28.png)

使用：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708072575522-70f340b1-3a02-4240-9763-dd4758effa70.png)

