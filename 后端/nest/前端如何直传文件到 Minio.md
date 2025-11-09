## 文件存储问题及解决方案
在开发过程中，常见的做法是使用对象存储服务（OSS）来存放文件，这样可以避免直接在应用服务器上存储文件，从而解决存储上限和管理难题。

常用的 OSS 服务包括阿里云 OSS 和自建的 OSS 服务如 Minio。



## 文件上传方式
### 传统的服务器中转方式
+ 流程描述：前端将文件上传到应用服务器，然后由服务器上传至阿里云或 Minio。
+ 问题分析：此方法涉及重复的文件传输，导致不必要的流量浪费。



### 前端直传方式
+ 流程描述：前端直接将文件上传至 OSS 服务，并将文件 URL 返回给应用服务器。
+ 安全考虑：直接在前端暴露 accessKey 存在安全隐患。



### 使用临时凭证优化
+ 解决方案：应用服务器生成一个临时凭证，前端使用此凭证直传文件至 OSS，避免暴露 accessKey。



## Minio 的部署与使用
### 部署 Minio
+ 配置说明：
    - name：容器名。
    - port：映射本地 9000 和 9001 端口到容器内的对应端口。
    - volume：挂载本地目录至容器内的 /bitnami/minio/data，实现数据持久化。
    - 环境变量：MINIO_ROOT_USER 和 MINIO_ROOT_PASSWORD，用于登录验证。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715176480981-6d46becb-b12d-4551-9fa7-e6851763506e.png)



### Minio 的基本操作
在 Minio 管理界面中创建存储桶（bucket）：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715176710592-5bf59e68-ad47-4169-932c-5343cc19d0c4.png)

允许存储桶中的文件被公开访问：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715176945557-12ac2ec8-01df-4902-b4da-15fb739d4d02.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715177000128-c69dfb68-0bdc-4b44-8e9a-23ffa85a37d2.png)

上传后就能访问图片：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715177111156-0c5ef195-9dbf-4419-96d9-11f0800d576d.png)

当然我们也可以用 node 上传文件到 minio。

但是这节我们主要做直传。



## 后端直传实现
### 创建与配置 NestJS 项目
#### 初始化项目
```bash
nest new minio-fe-upload -p npm
```

#### 安装依赖
```bash
npm install minio
```

#### 创建配置 Minio 模块
```bash
nest g module minio
```

在 Minio 模块中，配置 Minio 客户端并设置为全局模块：

```typescript
import { Global, Module } from '@nestjs/common';
import * as Minio from 'minio';

export const MINIO_CLIENT = 'MINIO_CLIENT';

@Global()
@Module({
  providers: [
    {
      provide: MINIO_CLIENT,
      useFactory: async () => {
        const client = new Minio.Client({
          endPoint: 'localhost',
          port: 9000,
          useSSL: false,
          accessKey: 'YOUR_ACCESS_KEY',
          secretKey: 'YOUR_SECRET_KEY',
        });
        return client;
      },
    },
  ],
  exports: [MINIO_CLIENT],
})
export class MinioModule {}
```

accessKey 和 secretKey 在这获取：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715252809952-1c969d8c-cd45-4b2a-a890-d103ddcfb6d5.png)



### 配置控制器
在 AppController 中，注入 Minio 客户端并创建测试接口：

```typescript
import { Controller, Get, Inject } from '@nestjs/common';
import { AppService } from './app.service';
import { MINIO_CLIENT } from './minio/minio.module';
import * as Minio from 'minio';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    @Inject(MINIO_CLIENT) private minioClient: Minio.Client,
  ) {}

  @Get('test')
  async test() {
    try {
      await this.minioClient.fPutObject(
        'bucket1', // 指定Minio的存储桶名称
        'my_upload.json', // 指定上传后的文件名
        './package.json', // 指定本地文件路径，此处为上传项目的package.json文件
      );
      return 'http://localhost:9000/bucket1/my_upload.json';
    } catch (e) {
      console.error(e);
      return '上传失败';
    }
  }
}
```

### 启动服务
```typescript
npm run start:dev
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715253232565-5268805a-1824-432a-b7af-c503dbfc0475.png)

我们接着访问返回的 url：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715253279810-7e85b36b-14cc-40f7-b697-15d0fc19bd84.png)



## 前端直传实现
### 配置 nest 静态文件目录
```typescript
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  // 这里指定'public'目录作为静态资源目录
  app.useStaticAssets('public');
  await app.listen(3000);
}

bootstrap();
```



### 前端 HTML 页面
根目录创建 public/index.html 文件，实现文件上传功能，这部分是[文档里的](https://min.io/docs/minio/linux/integrations/presigned-put-upload-via-browser.html)：

```typescript
<!DOCTYPE html>
<html lang="en">
  <head> </head>
  <body>
    <!-- 文件选择输入框，允许选择多个文件 -->
    <input type="file" id="selector" multiple />
    <button onclick="upload()">Upload</button>
    <div id="status">No uploads</div>

    <script type="text/javascript">
      function upload() {
        // 获取文件选择器中选中的文件列表
        var files = document.getElementById('selector').files;
        for (var i = 0; i < files.length; i++) {
          var file = files[i];
          // 获取每个文件的新URL，并进行上传操作
          retrieveNewURL(file, (file, url) => {
            uploadFile(file, url);
          });
        }
      }

      function retrieveNewURL(file, callback) {
        // 向服务器请求预签名的URL
        fetch(`/presignedUrl?name=${file.name}`)
          .then((response) => response.text())
          .then((url) => callback(file, url))
          .catch((e) => console.error(e));
      }

      function uploadFile(file, url) {
        if (document.getElementById('status').innerText === 'No uploads') {
          document.getElementById('status').innerHTML = '';
        }
        // 使用PUT方法将文件上传到指定的URL
        fetch(url, {
          method: 'PUT',
          body: file,
        })
          .then(() => {
            document.getElementById(
              'status',
            ).innerHTML += `<br>Uploaded ${file.name}.`;
          })
          .catch((e) => console.error(e));
      }
    </script>
  </body>
</html>
```



### 实现签名接口
在服务端增加一个生成预签名 URL 的接口：

```typescript
@Get('presignedUrl')
async presignedUrl(@Query('name') name: string) {
  return this.minioClient.presignedPutObject('bucket1', name);
}
```



### 测试
启动服务并访问前端页面 [http://localhost:3000/](http://localhost:3000/)，选择文件并点击上传：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715262190975-654c80c5-f119-4744-b49d-d0d8f44773dc.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715262002299-77a81428-b002-4500-b589-c6ad7b8b3360.png)

通过控制台和 Minio 控制面板验证上传成功：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715262050822-75384596-a1c9-4ad3-8a9a-fe6bafacb59d.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715262137896-6a5b2520-5459-4af2-b54e-97190789f036.png)

上传成功了。

