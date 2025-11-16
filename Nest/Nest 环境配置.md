为什么我们需要环境配置？你有没有想过，为什么不直接在代码里写死数据库地址、API 密钥或者端口号呢？

*   **安全性**：敏感信息（如数据库密码、第三方 API 密钥）如果直接写在代码中，一旦代码被泄露，这些信息将完全暴露。
*   **灵活性**：一个应用通常需要在多个环境中运行，比如开发环境、测试环境和生产环境。每个环境的数据库地址、日志级别等配置都可能不同。如果硬编码，每次部署到新环境都需要修改代码、重新编译，非常低效且容易出错。
*   **可维护性**：将配置与代码分离，使得配置的修改不会影响到业务逻辑代码，反之亦然。

因此，环境配置的核心思想是：**将易变的、与特定环境相关的信息从应用程序代码中抽离出来，通过外部化的方式进行管理。**

---

### NestJS 环境配置的核心：`@nestjs/config`

NestJS 官方提供了一个强大的包 `@nestjs/config` 来优雅地处理这个问题。它基于一个广受欢迎的 Node.js 库 `dotenv`，并提供了更多 NestJS 特有的功能，比如配置验证、自定义加载和模块化。

让我们一步步来搭建一个完整的环境配置系统。

#### 第 1 步：安装依赖

首先，我们需要安装 `@nestjs/config` 包。

```bash
npm install @nestjs/config
```

#### 第 2 步：创建 `.env` 文件

在项目的根目录下创建一个名为 `.env` 的文件。这个文件将存储我们的环境变量。

**.env**
```env
# 数据库配置
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=postgres
DATABASE_PASSWORD=mysecretpassword

# 应用配置
PORT=3000
NODE_ENV=development
```

> **重要提示**：`.env` 文件包含敏感信息，**绝对不能**提交到版本控制系统（如 Git）。请务必将 `.env` 添加到你的 `.gitignore` 文件中。

#### 第 3 步：在根模块中配置 `ConfigModule`

`ConfigModule` 是负责加载和解析 `.env` 文件的核心模块。我们通常在应用的根模块 `app.module.ts` 中进行全局配置。

**src/app.module.ts**
```typescript
import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'
import { AppController } from './app.controller'
import { AppService } from './app.service'

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true, // 将 ConfigService 注册为全局可用，避免在每个模块中重复导入
      envFilePath: '.env', // 指定 .env 文件的路径，默认就是根目录的 .env
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
```

这里的关键是 `ConfigModule.forRoot()` 方法：
*   `isGlobal: true`：这是一个非常方便的选项。它使得 `ConfigService` 在整个应用中都可以被注入，而不需要在其他模块的 `imports` 数组里再次引入 `ConfigModule`。
*   `envFilePath`：你可以指定环境文件的路径，这对于多环境配置非常有用，我们稍后会讲到。

#### 第 4 步：注入并使用 `ConfigService`

配置好后，你可以在任何服务或控制器中注入 `ConfigService` 来读取这些变量。

**src/app.service.ts**
```typescript
import { Injectable } from '@nestjs/common'
import { ConfigService } from '@nestjs/config'

@Injectable()
export class AppService {
  // 注入 ConfigService
  constructor(private configService: ConfigService) {}

  getDatabaseHost(): string {
    // 使用 get 方法读取变量，并提供一个默认值
    return this.configService.get<string>('DATABASE_HOST', 'default-host')
  }

  getPort(): number {
    // get 方法可以泛型来指定返回类型
    return this.configService.get<number>('PORT', 3000)
  }

  getEnvironment(): string {
    return this.configService.get<string>('NODE_ENV')
  }
}
```

`configService.get('KEY')` 方法用于读取环境变量。它还接受第二个参数作为默认值，当环境变量未定义时会使用该默认值，这是一个很好的编程习惯。

---

### 进阶实践：让配置更健壮

仅仅读取配置是不够的，我们还需要确保配置是**正确**的。如果 `DATABASE_PASSWORD` 忘记设置了，应用可能在运行时才报错，这太晚了。

#### 1. 配置验证（Validation）

我们可以在应用启动时就验证所有必需的环境变量是否存在、格式是否正确。这需要一个验证库，`joi` 是官方推荐的选项。

首先，安装 `joi`：
```bash
npm install joi
# joi 通常在开发时使用，但验证逻辑在运行时执行，所以不要加 --save-dev
```

然后，修改 `app.module.ts` 以添加验证模式：

**src/app.module.ts**
```typescript
import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'
import * as Joi from 'joi' // 导入 joi
import { AppController } from './app.controller'
import { AppService } from './app.service'

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      // 添加验证逻辑
      validationSchema: Joi.object({
        NODE_ENV: Joi.string().valid('development', 'production', 'test').default('development'),
        PORT: Joi.number().default(3000),
        DATABASE_HOST: Joi.string().required(),
        DATABASE_PORT: Joi.number().default(5432),
        DATABASE_USER: Joi.string().required(),
        DATABASE_PASSWORD: Joi.string().required(),
      }),
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
```

现在，当你启动应用时，`@nestjs/config` 会使用 `Joi` 的模式来检查环境变量。
*   如果 `DATABASE_HOST` 或 `DATABASE_PASSWORD` 未定义，应用会立即启动失败并给出明确的错误信息。
*   `NODE_ENV` 的值必须是 `'development'`, `'production'`, `'test'` 之一。
*   `PORT` 和 `DATABASE_PORT` 如果未定义，会使用 `default` 指定的默认值。

这个实践能极大地提高应用的可靠性，让你在部署前就发现配置问题。

#### 2. 多环境配置

在实际项目中，我们通常需要为不同环境准备不同的配置文件，例如 `.env.development`, `.env.production`。我们可以动态地加载这些文件。

**src/app.module.ts**
```typescript
import { Module } from '@nestjs/common'
import { ConfigModule } from '@nestjs/config'
// ... 其他导入

// 根据 NODE_ENV 决定加载哪个 .env 文件
const envFilePath = `.env.${process.env.NODE_ENV || 'development'}`

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: envFilePath, // 动态指定文件路径
      // ... validationSchema 保持不变
    }),
  ],
  // ...
})
export class AppModule {}
```

现在，你可以通过设置操作系统的环境变量 `NODE_ENV=production` 来启动应用，NestJS 就会自动加载 `.env.production` 文件。

你还可以同时加载多个文件，`envFilePath` 接受一个数组。配置项会根据文件顺序合并，后面的文件会覆盖前面文件中的同名变量。

```typescript
ConfigModule.forRoot({
  envFilePath: ['.env.local', `.env.${process.env.NODE_ENV}`],
})
```

---

### 高级加载策略

`@nestjs/config` 不仅限于加载 `.env` 文件，它还支持加载自定义的配置对象，甚至解析 YAML 等格式。

#### 1. 自定义配置对象（类型安全）

我们可以创建一个 `config.ts` 文件来导出一个配置对象。这对于组织有层次的配置、实现类型安全和嵌入逻辑非常有帮助。

**src/config/config.ts**
```typescript
// 我们甚至可以从数据库或其他异步来源获取配置
const getDbPort = async () => {
  return Promise.resolve(3306);
};

export default async () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  database: {
    host: process.env.DATABASE_HOST || 'localhost',
    port: await getDbPort(),
  },
});
```

在 `AppModule` 中使用 `load` 属性来加载这个自定义配置：

**src/app.module.ts**
```typescript
import { ConfigModule } from '@nestjs/config';
import appConfig from './config/config';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [appConfig], // 加载自定义配置
    }),
  ],
})
export class AppModule {}
```

使用时，可以通过点路径（`'database.host'`）来访问嵌套的配置项：

```typescript
// 在服务中
constructor(private configService: ConfigService) {
  const dbHost = this.configService.get<string>('database.host');
  console.log(dbHost);
}
```

#### 2. 解析 YAML 配置文件

对于更复杂的层次结构，YAML 是一个比 `.env` 更具可读性的选择。我们可以结合自定义加载功能来解析 YAML 文件。

首先，安装 `js-yaml`：
```bash
npm install js-yaml
```

创建一个 YAML 配置文件：

**config.yaml**
```yaml
server:
  port: 8000
database:
  host: localhost
  user: admin
  password: secret
```

创建一个加载器来读取和解析这个文件：

**src/config/yaml.loader.ts**
```typescript
import { readFileSync } from 'fs';
import * as yaml from 'js-yaml';
import { join } from 'path';

export default () => {
  const configFilePath = join(process.cwd(), 'config.yaml');
  try {
    const fileContents = readFileSync(configFilePath, 'utf8');
    return yaml.load(fileContents) as Record<string, any>;
  } catch (e) {
    console.error('Error loading YAML config:', e);
    return {};
  }
};
```

在 `AppModule` 中加载它：

```typescript
import { ConfigModule } from '@nestjs/config';
import yamlLoader from './config/yaml.loader';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [yamlLoader],
    }),
  ],
})
export class AppModule {}
```

#### 3. 局部配置 (`forFeature`)

如果某个配置只与特定模块相关，你可以使用 `ConfigModule.forFeature` 将其注册为局部配置，避免污染全局命名空间。

```typescript
// 在某个功能模块中，比如 users.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import databaseConfig from '../config/database.config';

@Module({
  imports: [ConfigModule.forFeature(databaseConfig)],
  providers: [UsersService],
})
export class UsersModule {}
```

---

### 总结与最佳实践

1.  **分离关注点**：始终将配置与代码分离，使用 `.env`、YAML 或自定义配置文件。
2.  **安全第一**：将 `.env` 等包含敏感信息的文件添加到 `.gitignore`，防止泄露。
3.  **全局可用**：在根模块中使用 `isGlobal: true` 来简化 `ConfigService` 的使用。
4.  **验证先行**：使用 `validationSchema` 和 `Joi` 在应用启动时验证配置，防患于未然。
5.  **环境隔离**：为不同环境（开发、测试、生产）创建独立的 `.env` 文件，并通过 `NODE_ENV` 动态加载。
6.  **提供默认值**：在使用 `configService.get()` 或 `Joi` 模式时，为非关键变量提供合理的默认值。
7.  **拥抱类型安全**：对于复杂的、结构化的配置，使用自定义加载函数 (`load`) 返回类型化的配置对象。
8.  **选择合适的格式**：`.env` 适合简单的键值对，而 YAML 或自定义对象更适合复杂的、有层次的配置。

希望这份详细的指南能帮助你更好地理解和使用 NestJS 的环境配置。如果你在实践中遇到任何问题，或者想探讨更复杂的场景，随时都可以再来找我。
