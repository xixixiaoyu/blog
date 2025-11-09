## 什么是 REPL？
在开发 Nest.js 应用时，通常需要在浏览器中访问特定 URL 并通过 GET 或 POST 方式传参来测试模块、服务和控制器，这种方法虽然有效，但有时候可能会显得繁琐。

Nest.js 提供了 REPL 模式，类似于 Node.js 的 REPL，允许开发者在控制台中直接测试代码。



创建 Nest 项目：

```bash
nest new repl-test -p npm
```

创建 test 模块：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708783236969-e7e30eff-68ee-448a-800e-e3b3d4241f3d.png)

运行项目：

```typescript
npm run start:dev
```





## 运行 repl 模式
在 src 下创建 repl.ts，内容如下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708783562858-9a160764-ab97-47dc-b332-a1ec8d887e68.png)

重新通过这种方式运行项目：

```bash
npm run start:dev -- --entryFile repl
```

 其中 --entryFile 用于指定入口文件为 `repl.ts`。





## REPL 模式下的操作
使用 `debug()` 查看所有模块以及模块下的控制器和提供者：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708788207673-57258c6e-1636-457b-9dee-0a8d50d21f59.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708788266180-111a7adb-b4c8-4def-8054-70fbf90da5a7.png)





methods()  查看某个控制器或提供者的方法：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708788325736-ad89a146-5def-4181-8fed-bc6f19196dae.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708788349998-50cc081e-66d0-4fa9-b320-8084a44e4bba.png)





使用 `get()` 或 `$()` 获取提供者或控制器的实例并调用其方法：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708788790891-9c332628-8ae0-4e5b-974a-91d780ab9076.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708789050568-b90ce09e-8c21-4538-9881-6a3137ac8928.png)

**注意事项**：REPL 模式下，直接调用的方法不会触发管道（pipe）、拦截器（interceptor）等，仅用于传参测试函数。

忘记了这些函数怎么用，别担心，随时可以呼叫 `help()`：

```bash
> help()
// ...会列出所有可用的 REPL 函数及其说明
```

如果你想查看某个特定函数的详细用法（比如参数和返回类型），可以这样做：

```bash
> get.help
Retrieves an instance of either injectable or controller, otherwise, throws exception.
Interface: get(token: InjectionToken) => any
```



## 配置命令历史
为了保留命令历史，可以按住上下键进行历史导航，可以在 `repl.ts` 中添加历史设置代码：

```typescript
import { repl } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const replServer = await repl(AppModule);
  replServer.setupHistory('.nestjs_repl_history', (err) => {
    if (err) {
      console.error(err);
    }
  });
}
bootstrap();
```

最后我们可以把命令配置到 npm script：

```bash
"repl:dev": "npm run start:dev -- --entryFile repl",
```

