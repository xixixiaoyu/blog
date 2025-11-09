在后端开发完成后，通常需要为前端提供一份详细的接口文档。

这份文档应包含接口列表、请求类型（GET 或 POST）、参数详情和响应格式。

手动编写和维护这样的文档既繁琐又容易出错，尤其是在接口频繁变动的情况下。

为了解决这个问题，我们可以使用 Swagger 自动生成 API 文档。

## 生成 api 文档
新建项目：

```bash
nest new swagger-test -p npm
```

安装 swagger 包：

```bash
npm install @nestjs/swagger
```

main.ts 添加代码：

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 使用 'DocumentBuilder' 创建一个Swagger文档的配置
  const config = new DocumentBuilder()
    .setTitle('Example API') // 设置API文档的标题
    .setDescription('The example API description') // 设置API文档的描述
    .setVersion('1.0') // 设置API的版本
    .addTag('example') // 添加一个标签
    .build();

  // 使用 'SwaggerModule.createDocument' 方法根据配置创建Swagger文档
  const document = SwaggerModule.createDocument(app, config);

  // 使用 'SwaggerModule.setup' 方法将Swagger文档与应用关联，并设置访问API文档的路径为 'api'
  SwaggerModule.setup('api', app, document);

  await app.listen(3000);
}

bootstrap();
```

运行：

```typescript
npm run start:dev
```

访问 http://localhost:3000/api，就可以看见文档了：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708243615563-9a8df1a0-1249-4afb-b10d-ee5acf7f4bf9.png)

只有一个接口，点击 try it out：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708243743708-5e60fb6a-f0c1-40d2-b35a-ae1131de6e0c.png)

再点击 execute：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708243712125-e143afde-1d69-4019-adb4-92181db38573.png)

就可以看到请求响应信息：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708243782178-ae301b5a-4004-476b-9d05-349eeabb6fb9.png)



## 添加接口
```typescript
import { Controller, Get, Query, Param, Post, Body } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('fine-name')
  findByName(@Query('name') name: string) {
    console.log(name);
    return 'findByName';
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    console.log(id);
    return 'findOne';
  }

  @Post()
  create(@Body('data') data) {
    console.log(data);
    return 'success';
  }
}
```



## @ApiTags
使用 `@ApiTags` 给 API 分组：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708244597019-c80fc064-df6b-4a35-970e-954a35c37d5f.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715519188564-c3e737c5-56ee-45a9-9dab-6ce2e829a2e8.png)



## @ApiOperation
使用 `@ApiOperation` 提供操作描述信息：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708244793688-b5a74aaf-e7a9-4ee0-b039-da8d5ad128b1.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708244813776-6d92e3c7-3bd6-467d-ae8e-62c5e39b9b08.png)



## @ApiResponse
使用 `@ApiResponse` 描述方法的响应：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708244937581-8d2350d9-780c-4d70-96da-8d5734ca5282.png)

上面可以用 Nest 内置的 `HttpStatus` 来描述状态码。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708244948732-7edfc0f1-a29d-4136-bcfb-390d923c7dec.png)



## @ApiQuery
使用 `@ApiQuery` 描述查询参数：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708346408061-d47f09e5-dc37-446f-8f8a-3625b48f051e.png)

刷新页面，多了两个参数：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708346418404-b76771be-4f59-4d4e-9c58-a7e144059f3d.png)

点击 try it out 和 execute，就可以看到发送了请求并返回了响应：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708346487066-832f69ff-8f55-4fdc-a48d-0217ee166c85.png)



## @ApiParam
使用 `@ApiParam` 描述路径参数：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708346978062-490b5c49-f219-480b-94c0-1725cc76afe1.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708347001867-6c724a60-ac9a-46f6-8f50-117bfa40fbdf.png)



## @ApiBody
使用 `@ApiBody` 描述请求体的内容：

添加 dto 和 @ApiBody：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709463907977-8f39737a-76e5-41a6-b9e9-2f9ab5124259.png)

swigger 出现对应的内容了：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709463951283-2691a6a3-e9d7-40b3-9eab-350dd8e8bd8d.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709464008877-3ced53c5-1167-4a10-8e83-3a5cf4686755.png)



返回给视图的数据的封装，我们可以创建个 vo：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708349313111-ecd01bd2-db46-421e-abb1-d23de11d6e1b.png)

使用 vo：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1708349336790-725c9cbf-d0b7-4ac7-bebb-546f8a676bf6.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709477599542-f0f17d34-f197-4cbd-8b5d-f6dc4dd645fb.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709477578888-fb4f98e5-6a08-43dc-8b9d-5280a7bd86cd.png)



点下 try it out，可以自己编辑请求体：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709477701271-21a78a87-9157-42a8-81ab-018a24bd0f9c.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709481181251-4cee275f-caca-4321-9864-0f49090bab24.png)

然后点击 execute， 就可以看到响应的内容和 header：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709477743047-5d6cfdc9-7f9f-4327-9b2d-99c263c3b60a.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709477785136-4f0edf0b-1bfb-47ee-90e1-d65a8f0b9e42.png)

服务端也收到了这个请求：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1709481209140-1431bb03-0010-4c6f-a7f5-6146b6ee4103.png)



## @ApiProperty
@ApiProperty，其实它还有很多属性：

比如 required、minium、maximum、default、maxLength 等。

此外，很多接口是需要登录才能访问的，那如何限制呢？

swagger 也提供了这方面的支持。

常用的认证方式就是 jwt、cookie：

```typescript
@ApiBearerAuth('bearer')
@Get('fine-name')
findByName(@Query('name') name: string) {
  console.log(name);
  return 'findByName';
}

@ApiCookieAuth('cookie')
@Get(':id')
findOne(@Param('id') id: string) {
  console.log(id);
  return 'findOne';
}

@ApiBasicAuth('basic')
@Post()
create(@Body('data') data) {
  console.log(data);
  return 'success';
}
```

然后在 main.ts 里添 3 种认证方式的信息：

```typescript
// 使用 'DocumentBuilder' 创建一个Swagger文档的配置
const config = new DocumentBuilder()
  .setTitle('Example API') // 设置API文档的标题
  .setDescription('The example API description') // 设置API文档的描述
  .setVersion('1.0') // 设置API的版本
  .addTag('example') // 添加一个标签
  .addBasicAuth({
    type: 'http',
    name: 'basic',
    description: '用户名 + 密码',
  })
  .addCookieAuth('sid', {
    type: 'apiKey',
    name: 'cookie',
    description: '基于 cookie 的认证',
  })
  .addBearerAuth({
    type: 'http',
    description: '基于 jwt 的认证',
    name: 'bearer',
  })
  .build();
```

刷新页面就可以看到接口出现了锁的标记：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715519760567-34607c25-cb9c-4a88-94c2-d0b737547a53.png)

点击第一个锁：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715521511310-9d0a56a8-0c3e-4cd0-a21b-7fcf610093d5.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715521237111-f2fae5a3-2ce5-470f-b359-db0fe8965666.png)

输入账号密码，发送请求：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715520691401-52f3518e-53f7-4743-982c-6025be07a5f8.png)

他会将信息 base64 化后在请求头发送给后端。



点击第二个锁：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715521034466-5f7efa1c-2726-4565-a2ae-8c9c4375cd23.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715521079815-88315ab4-7dba-45ac-934b-0cd8e0fb481e.png)



点击第三个锁：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715521161749-e5959c8f-c312-466e-8a2d-4effeb509584.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715521185130-4f49fd49-70d4-4fa1-8a14-bfc77a32d7a6.png)





## 导出与美化
其实，swagger 是一种叫做 openapi 标准的实现。

在 /doc 后加上个 -json 就可以看到对应的 json

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1690001634320-fff8f765-13c2-4e79-a170-bc3eb7a9d66d.png)

装个格式化 chrome 插件格式化一下，大概是这样的：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1690001701694-c93fd7e5-79a8-4695-bb95-acded8b61eac.png)

如果觉得 swagger 文档比较丑，可以这个 json 导入别的平台。

一般 api 接口的平台都是支持 openapi 的。

