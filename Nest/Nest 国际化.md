在全球化的今天，一个成功的 Web 应用往往需要面向不同国家和地区的用户。想象一下，当一个英文用户兴致勃勃地使用你的应用时，突然弹出"用户不存在"这样的中文错误提示，那种困惑感可想而知。这就是为什么国际化（i18n）功能如此重要的原因。

很多开发者认为国际化只是前端的事情，但这种想法是不完整的。后端的错误提示、验证消息、邮件内容等同样需要根据用户的语言偏好进行本地化。一个完整的国际化方案应该覆盖整个技术栈。

## 国际化的本质

在深入代码之前，我们先思考一下：**国际化的本质是什么？**

它无非是解决两个核心问题：

1.  **如何识别用户的语言偏好？** （比如从请求头、Cookie 或 URL 参数中获取）
2.  **如何根据这个偏好，提供对应语言的文本？** （比如将 `hello` 这个 key，在中文环境下渲染为“你好”，在英文环境下渲染为“Hello”）

NestJS 通过其强大的模块化系统和社区生态，优雅地解决了这两个问题。目前社区最主流的解决方案是 `nestjs-i18n`，本文将以它为例，带你从零到一掌握 NestJS 的国际化方案。

## 快速开始：搭建基础项目

首先，创建一个新的 Nest 项目：

```bash
nest new nest-i18n-test -p pnpm
cd nest-i18n-test
```

接着，安装核心的国际化包：

```bash
pnpm i nestjs-i18n
```

## 创建语言资源文件

我们需要一个地方存放不同语言的翻译文本。在 `src` 目录下创建 `i18n` 文件夹，然后按语言代码分别创建资源文件。良好的组织结构是项目可维护性的关键。

```
src/
├── i18n/
│   ├── en/
│   │   └── test.json
│   └── zh/
│       └── test.json
└── ...
```

现在，我们为资源文件添加一些内容：

**`src/i18n/en/test.json`**：

```json
{
  "hello": "Hello World"
}
```

**`src/i18n/zh/test.json`**：

```json
{
  "hello": "你好世界"
}
```

为了确保在项目打包后，这些语言文件能被正确复制到 `dist` 目录，我们需要在 `nest-cli.json` 中配置 `assets`：

```json
{
  "compilerOptions": {
    "assets": [
      { "include": "i18n/**/*", "watchAssets": true }
    ]
  }
}
```
`watchAssets: true` 可以在开发模式下监听资源文件的变化，非常方便。

## 核心配置：让应用理解多语言

配置是连接应用和翻译文件的桥梁。我们在 `AppModule` 中导入并配置 `I18nModule`。

```typescript
// src/app.module.ts
import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { I18nModule, QueryResolver } from 'nestjs-i18n';
import * as path from 'path';

@Module({
  imports: [
    I18nModule.forRoot({
      fallbackLanguage: 'en', // 默认语言
      loaderOptions: {
        path: path.join(__dirname, '/i18n/'), // 语言文件路径
        watch: true, // 开发时监听文件变化
      },
      resolvers: [
        new QueryResolver(['lang', 'l']), // 通过查询参数 ?lang=zh 或者 ?l=zh 切换语言
      ],
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
```

### 多样化的语言检测方式

`nestjs-i18n` 的强大之处在于其灵活的语言检测策略。`resolvers` 数组定义了应用如何确定当前请求的语言，它会**从上到下**依次尝试解析，一旦成功便会停止。

除了上面用到的 `QueryResolver`，我们还可以组合多种方式：

```typescript
// src/app.module.ts
import {
  AcceptLanguageResolver,
  CookieResolver,
  HeaderResolver,
  I18nModule,
  QueryResolver,
} from 'nestjs-i18n';
import * as path from 'path';

@Module({
  imports: [
    I18nModule.forRoot({
      fallbackLanguage: 'en',
      loaderOptions: {
        path: path.join(__dirname, '/i18n/'),
        watch: true,
      },
      // 按顺序匹配，优先级从高到低
      resolvers: [
        new QueryResolver(['lang', 'l']),       // 1. URL 查询参数: /?lang=zh
        new HeaderResolver(['x-custom-lang']),  // 2. 自定义请求头: x-custom-lang: zh
        new CookieResolver(['lang']),           // 3. Cookie: lang=zh
        AcceptLanguageResolver,                 // 4. 浏览器语言偏好: Accept-Language
      ],
    }),
  ],
  // ...
})
export class AppModule {}
```

这个设计让你可以灵活地覆盖默认行为，例如允许用户通过 URL 参数临时切换语言，同时又能兼容标准的浏览器行为。

## 在服务中使用国际化

配置完成后，我们就可以在代码中注入 `I18nService` 来获取翻译文本了。

修改 `AppService`：

```typescript
// src/app.service.ts
import { Injectable } from '@nestjs/common';
import { I18nService } from 'nestjs-i18n';

@Injectable()
export class AppService {
  constructor(private readonly i18n: I18nService) {}

  getHello(): string {
    // 'test.hello' 对应文件名 test.json 和里面的 hello 字段
    return this.i18n.t('test.hello');
  }
}
```

启动项目 (`pnpm run start:dev`) 后，可以测试效果：

*   访问 `http://localhost:3000?lang=zh` 会看到 "你好世界"。
*   访问 `http://localhost:3000?lang=en` 会看到 "Hello World"。
*   不带参数访问，则会根据 `resolvers` 的后续规则（如 `Accept-Language` 请求头）或最终回退到 `fallbackLanguage` ('en')。

## 进阶：表单验证的国际化

在实际项目中，表单验证消息的国际化是一个核心需求。`nestjs-i18n` 与 `class-validator` 结合得非常完美。

首先，安装验证相关的包：

```bash
pnpm install class-validator class-transformer
```

接下来，我们创建一个用户模块和对应的 DTO：

```bash
nest g resource user --no-spec
```

在 DTO 中，我们使用 `i18nValidationMessage` 来指定验证消息的 key：

```typescript
// src/user/dto/create-user.dto.ts
import { IsNotEmpty, MinLength } from "class-validator";
import { i18nValidationMessage } from 'nestjs-i18n';

export class CreateUserDto {
  @IsNotEmpty({
    message: i18nValidationMessage('validate.usernameNotEmpty')
  })
  username: string;
  
  @MinLength(6, {
    message: i18nValidationMessage('validate.passwordNotLessThan6')
  })
  password: string;
}
```

然后，我们需要在 `main.ts` 中配置全局管道和异常过滤器，以便自动处理国际化验证：

```typescript
// src/main.ts
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { I18nValidationExceptionFilter, I18nValidationPipe } from 'nestjs-i18n';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 使用全局验证管道，进行国际化验证
  app.useGlobalPipes(new I18nValidationPipe());

  // 使用全局异常过滤器，处理国际化验证异常
  app.useGlobalFilters(
    new I18nValidationExceptionFilter({
      detailedErrors: false, // 设置为 false，仅返回 message 数组
    }),
  );

  await app.listen(3000);
}

bootstrap();
```

最后，添加对应的验证消息资源文件：

**`src/i18n/zh/validate.json`**：

```json
{
  "usernameNotEmpty": "用户名不能为空",
  "passwordNotLessThan6": "密码不能少于 6 位"
}
```

**`src/i18n/en/validate.json`**：

```json
{
  "usernameNotEmpty": "The username cannot be empty",
  "passwordNotLessThan6": "The password cannot be less than 6 characters"
}
```

现在，当你向创建用户的接口发送一个不合法的数据时，应用会根据请求的语言环境，返回对应的错误信息。

## 进阶：动态消息与占位符

有时候，我们需要在消息中插入动态内容，比如 "密码不能少于 6 位" 中的 "6"。`nestjs-i18n` 支持占位符功能。

**在资源文件中使用占位符**：

`{{variable}}` 或 `{variable}` 都可以作为占位符。

**`src/i18n/zh/validate.json`**
```json
{
  "passwordNotLessThan": "密码不能少于 {len} 位"
}
```

**在 DTO 验证中使用**：

```typescript
// src/user/dto/create-user.dto.ts
import { i18nValidationMessage } from 'nestjs-i18n';
import { MinLength } from 'class-validator';

// ...
@MinLength(6, {
  message: i18nValidationMessage('validate.passwordNotLessThan', {
    len: 6
  })
})
password: string;
```

**在服务中使用**：

同样，你可以在调用 `i18n.t` 时传递参数。

```typescript
// 资源文件: { "welcome": "你好, {name}!" }

// 服务代码
this.i18n.t('test.welcome', {
  args: {
    name: '云牧',
  },
});
```

## 总结与实战建议

我们来回顾一下 NestJS 国际化的核心思路并提供一些实战建议。

### 核心思路

1.  **模块化配置**：通过 `I18nModule` 统一管理翻译源和语言解析策略。
2.  **策略模式**：`resolvers` 的设计让你可以灵活组合，从不同来源（Header、Query、Cookie、Accept-Language）判断用户语言。
3.  **依赖注入**：`I18nService` 可以注入到任何地方（Controller、Service 等），实现翻译逻辑的复用。
4.  **生态集成**：与 `class-validator` 等库无缝集成，将国际化的能力延伸到数据验证层。

### 实战建议

1.  **文件组织**：建议按功能模块组织语言文件，比如 `user.json`、`order.json` 等，而不是把所有文本放在一个文件里，便于维护。
2.  **默认语言**：选择一个主要的目标市场语言作为 `fallbackLanguage`，确保即使某些翻译缺失，用户也能看到可理解的内容。
3.  **性能考虑**：在生产环境中关闭 `watch` 选项 (`watch: false`)，避免不必要的文件监听开销。
4.  **团队协作**：建立清晰的翻译流程，可以考虑使用专门的翻译管理平台来协作管理 JSON 文件。
