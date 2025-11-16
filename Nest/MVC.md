如果你想用 Nest 来构建那种用户能直接在浏览器里看到页面的 Web 应用，而不是仅仅提供 API 接口，那么了解和使用 MVC（模型-视图-控制器）模式就非常重要。

## 创建初始化 Nest 项目
```bash
npm i -g @nestjs/cli
# 用 CLI 创建一个 my-mvc-app 新项目
nest new my-mvc-app -p pnpm
# 进入项目目录
cd my-mvc-app
```

## 安装模板引擎
要让服务器能把数据“填”到 HTML 模板里然后发送给浏览器，我们需要一个模板引擎。

我们使用 Handlebars (hbs) ，安装：

```bash
pnpm i hbs
```

也可以选择 Pug (Jade)、EJS 等其他你喜欢的模板引擎。

## 配置 Express 实例 (默认)
安装好模板引擎后，我们需要告诉 Nest (实际上是它背后的 Express) 如何找到我们的模板文件、静态资源（比如 CSS、JavaScript 文件、图片等），以及使用哪个模板引擎。

打开 `src/main.ts` 文件，修改：

```typescript
// src/main.ts

import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express'; // 注意这里引入的是 NestExpressApplication
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  // 指定应用类型为 NestExpressApplication
  const app = await NestFactory.create<NestExpressApplication>(
    AppModule,
  );

  // 设置静态资源目录，比如 'public' 文件夹
  app.useStaticAssets(join(__dirname, '..', 'public'));
  // 设置视图文件所在的目录，比如 'views' 文件夹
  app.setBaseViewsDir(join(__dirname, '..', 'views'));
  // 设置默认的模板引擎为 'hbs'
  app.setViewEngine('hbs');

  await app.listen(process.env.PORT ?? 3000);
  console.log(`应用正在运行在: ${await app.getUrl()}`);
}
bootstrap();
```

+ `app.useStaticAssets()`: `public` 文件夹将用来存放 CSS、图片这类静态文件。你需要手动在项目根目录下创建这个 `public` 文件夹。
+ `app.setBaseViewsDir()`: `views` 文件夹将用来存放我们的 `.hbs` 模板文件。同样，你需要在项目根目录下创建这个 `views` 文件夹。
+ `app.setViewEngine()`: 指定 `hbs` 作为渲染 HTML 的模板引擎。



## 创建第一个视图和控制器
### 创建视图模板
在项目根目录下创建 `views` 文件夹。然后在 `views` 文件夹里创建一个名为 `index.hbs` 的文件，内容如下：

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>我的第一个 Nest MVC 应用</title>
</head>
<body>
    <h1>{{ message }}</h1>
    <p>现在是：{{ time }}</p>
</body>
</html>
```

这里的 `{{ message }}` 和 `{{ time }}` 就是占位符，之后我们会从控制器传递数据来替换它们。

### 修改控制器
打开 `src/app.controller.ts` 文件，修改 `AppController` 来渲染这个视图：

```typescript
// src/app.controller.ts

import { Get, Controller, Render } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  @Render('index') // 告诉 NestJS 渲染 'views/index.hbs' 模板
  root() {
    return {
      message: '你好，世界！来自 NestJS MVC！',
      time: new Date().toLocaleTimeString(),
    };
  }
}
```

`@Render('index')` 装饰器告诉 Nest 当用户访问根路径 `/` 时，去 `views` 文件夹里找 `index.hbs` (后缀名 `.hbs` 可以省略，因为它在 `main.ts` 里已经指定了默认引擎) 并用它来渲染页面。

`root()` 方法返回的对象 `{ message: '...' }` 会被传递给模板，模板里的 `{{ message }}` 就会被替换成这个对象里 `message` 属性的值。

运行应用：

```bash
pnpm start:dev
```

打开浏览器，访问 `http://localhost:3000`。

你就能看到 "你好，世界！来自 NestJS MVC！" 以及当前的时间。



## 动态选择模板渲染
有时候，你可能需要根据一些逻辑动态决定渲染哪个模板。这时候，直接使用 `@Render()` 就不够灵活了。我们可以借助 `@Res()` 装饰器来直接操作响应对象。

修改 `src/app.controller.ts`：

```typescript
// src/app.controller.ts

import { Get, Controller, Res, Render } from '@nestjs/common'; // 引入 Res
import { Response } from 'express'; // 引入 Express 的 Response 类型
import { AppService } from './app.service'; // 假设你有一个 AppService

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {} // 注入 AppService

  @Get() // 覆盖之前的 root 方法，或者创建一个新的路由
  dynamicRoot(@Res() res: Response) {
    // 假设 appService 有个方法可以根据某些条件返回视图名称
    // const viewName = this.appService.getViewNameBasedOnLogic();
    let viewName = 'index'; // 简单示例，固定为 index
    let data = {
        message: '动态渲染的页面！',
        time: new Date().toUTCString(),
    };

    // 假设有个逻辑判断
    if (Math.random() > 0.5) {
        // 比如，你可能还有另一个模板叫 'alternative.hbs'
        // viewName = 'alternative';
        data.message = '动态渲染的页面 - 特别版！';
    }

    // 使用 res.render() 方法手动渲染
    return res.render(viewName, data);
  }
}
```

在这个例子中，我们使用了 `@Res()` 装饰器来注入 Express 的 `Response` 对象 (别忘了从 `express` 包导入 `Response` 类型)。

然后，我们就可以调用 `res.render('模板名', 数据对象)` 来手动控制渲染哪个模板以及传递什么数据。这样就灵活多啦。



## 🌰 代码示例
1. 安装 ejs： npm i ejs -D
2. 配置模版引擎：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749348015731-eedc1de6-4a1b-4eff-a8f2-a583ac5a53c3.png)

3. 项目根目录新建 views 目录，然后新建 index.ejs：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749348036461-a5e909f2-b8d2-465c-a4d8-94e311c53630.png)

4. 使用创建的 ejs 文件渲染页面：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749348046126-f75cac28-37e2-4e33-9b17-17c7c39de254.png)

5. 访问页面

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749348055720-02b6d25c-35b9-47dc-ae7a-7caeafc8021d.png)

结合 Post 表单演示：

创建 UserControll：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749348071854-137b3d86-7e7c-40e4-98a3-1ceac4234ea2.png)

自动帮我们生成了文件并导入到 AppModule 根模块：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749348081062-944d18e9-1669-460c-ae87-ced7918d662b.png)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749348084203-06637d29-7478-4690-8d00-6df7515e2339.png)

创建 user.ejs：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749348091146-fe75fdfe-aac0-4e50-8193-84a9b7b58264.png)

内容如下：

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>Document</title>
  </head>
  <body>
    <form action="/user/doAdd" method="post">
      <input type="text" name="username" placeholder="请输入用户名" />
      <br />
      <input type="text" name="age" placeholder="年龄" />
      <br />
      <input type="submit" value="提交" />
    </form>
  </body>
</html>
```

UserController 内容如下：

```typescript
import { Controller, Get, Post, Body, Res, Render } from '@nestjs/common';
import { Response } from 'express';

@Controller('user')
export class UserController {
  @Get()
  @Render('default/user')
  index() {
    return { name: '张三' };
  }

  @Post('doAdd')
  doAdd(@Body() body, @Res() res: Response) {
    console.log(body);
    res.redirect('/user'); //路由跳转
  }
}
```

访问页面：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1749348120519-6a6b5809-899c-4fd4-bb69-069785998027.png)

输入内容提交：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706420945225-a1785fc2-558a-4857-9657-070ef1744af2.png)

此时 form 表单会提交 POST 请求，路径是 /user/doAdd，命中我们的 UserController 路由

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706421058244-37a6d4fc-5910-4221-b827-b87e5bc28bdd.png)

会打印 body 然后重定向页面到 user：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706421088853-e7774236-91e8-4831-be4e-019eac617147.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1706421096474-f97f59be-b32e-4ab5-8f84-00cfbbbcfa80.png)
