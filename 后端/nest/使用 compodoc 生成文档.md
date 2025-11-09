## 启动 compodoc 文档
compodoc 是一个为 TypeScript 项目生成文档的工具，它支持 Angular、Nest。

compodoc 会分析你的代码，并生成一个包含所有类、接口、服务、控制器和模块以及它们依赖关系的文档。



创建 nest 项目：

```bash
nest new compodoc-test -p npm
```

安装 compodoc：

```bash
npm install @compodoc/compodoc -D
```

在 `package.json` 文件的 `scripts` 部分添加一个新的脚本来运行 compodoc：

```json
"scripts": {
  "compodoc": "compodoc -p tsconfig.json -s -o",
}
```

+ -p 是指定 tsconfig 文件
+ -s 是启动静态服务器
+ -o 是打开浏览器

更多选项在 [compodoc 文档](https://link.juejin.cn/?target=https%3A%2F%2Fcompodoc.app%2Fguides%2Foptions.html)里可以看到：

生成预览文档：

```bash
npm run compodoc
```

自动打开浏览器，并定位到了 README 菜单：  
![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709458507644-8cd8b8c1-303d-4a2e-b6ad-8bc6988092cd.png)

这个 README 菜单其实对应了项目里面的 README：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705747089878-f4b53017-0183-4c28-8da0-8f54f15ffb0b.png)

改一下 READMD.md，然后重新执行命令生成：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705747110755-8d8de72f-7b5c-438d-9e0a-e96b1b07522f.png)







## overview
文档的 overview 部分分贝是依赖图，和项目有几个模块、controller，可注入的 provider

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705747193552-f20c0e80-35a6-4910-aac6-24d66af9808c.png)



我们在项目下添加几个模块：

```typescript
nest g resource test1

nest g resource test2
```

在 Test1Module 导出 Test1Service：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709458583885-7a42b325-fb5d-4ce6-a89d-88e6b57fc006.png)





然后 Test2Module 引入 Test1Module：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709458656590-d9c75429-dc95-484b-b53d-1015cb884993.png)

在 Test2Service 里注入 Test1Service：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709458760462-8c1aa4a6-0c48-4b24-8524-14d0e164317d.png)

运行项目：

```typescript
npm run start:dev
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709458831201-5936485c-0e60-44f6-8f6c-7fd2cbbb0773.png)

这种依赖关系，compodoc 可视化之后是什么样的呢？

重新跑一下 compodoc：

```typescript
npm run compodoc
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709458930004-5ce51d05-d17b-440f-ac91-a13f7b2ed047.png)



点击左侧的 Modules，可以看到每个模块的可视化分析：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709459082447-77edc070-cd1e-4e11-b84c-90789d5ba975.png)

还可以定位到具体代码的实现：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709459124829-93b1cd45-ee3f-42d9-a05d-f30d3e4b4ac3.png)

当新人接手这个项目的时候，可以通过这份文档快速了解项目的结构。





## compodoc 配置文件
命令行选项也挺多的，我们可以写在 compodoc 配置文件中。

项目下添加一个 `.compodoc.json` 的文件：

```json
{
    "port": 8888,
    "theme": "postmark"
}
```

改下 scripts 里 compodoc 命令：

```json
"scripts": {
   "compodoc": "compodoc -s -o -c .compodoc.json",
 }
```

-c 参数告诉 compodoc 使用指定的配置文件。

运行：

```bash
npm run compodoc
```

同样能使配置生效。

