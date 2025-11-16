## **对象存储服务（OSS）介绍**
文件上传是常见的网络需求，通常我们不会将文件直接上传到应用服务器，因为单台服务器的存储空间有限，不易扩展。

为此，我们通常使用对象存储服务（Object Storage Service，简称OSS）来完成文件的上传和下载。例如，阿里云提供的 OSS 服务以及可以自建的 Minio 都是这样的平台。

OSS 存储和检索非结构化数据和元数据对象（如文档、图片、视频等）。

### 本地存储和 OSS 存储结构对比
- **本地文件存储**：采用目录和文件的组织方式。
- **OSS 存储结构**：
    - **对象（Object）**：是存储的基本单元，每个对象包含数据、元数据和唯一标识符。
    - **桶（Bucket）**：是用于组织对象的容器，每个桶内可以存储无数个对象，并且可以通过 RESTful API 接口进行操作。
    - 值得注意的是，虽然对象存储没有传统文件系统的目录层级结构，但它实际上可以通过在对象键（Object Key）中使用 `/` 来模拟目录，使得用户可以方便地组织和检索文件。

## 文件上传方案对比

### 传统的服务器中转方式
- **流程描述**：前端将文件上传到应用服务器，然后由服务器上传至 OSS。
- **问题分析**：此方法涉及重复的文件传输，增加了服务器的带宽和处理压力，导致不必要的资源浪费。

![画板](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1713071691522-5d5b4a1e-8e52-4e7d-bf3d-4dac4aae197d.jpeg)

### 前端直传方式
- **流程描述**：前端直接将文件上传至 OSS 服务，并将文件 URL 返回给应用服务器。
- **安全考虑**：如果直接在前端代码中暴露用于访问 OSS 的永久 `accessKey` 和 `secretKey`，会带来极大的安全隐患。一旦泄露，任何人都可以无限制地访问你的存储资源。

### 最佳实践：使用临时凭证直传
- **解决方案**：为了兼顾安全与效率，最佳实践是采用临时凭证（或称预签名 URL）的方式。
- **流程**：
    1. 前端向应用服务器请求一个用于上传的临时授权。
    2. 应用服务器使用自己安全的永久密钥与 OSS 服务交互，生成一个有时效性、有特定权限（如只能上传到指定位置）的预签名 URL，并将其返回给前端。
    3. 前端使用这个预签名 URL 直接将文件上传到 OSS。
- **优点**：此方案避免了服务器中转的流量消耗，同时也通过临时凭证机制保护了永久密钥的安全。

![画板](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1713071856598-13a4590b-acc8-437c-9519-71bce0ee406a.jpeg)

## 使用 Minio 自建 OSS 服务
Minio 是一个高性能的、与亚马逊 S3 兼容的开源对象存储服务。我们可以使用 Docker 非常方便地在本地或服务器上部署它。

### 启动 Docker 的 Minio 容器
首先，我们需要安装 [Docker 桌面端](https://link.juejin.cn/?target=https%3A%2F%2Fwww.docker.com%2F)。

打开 Docker 桌面端，搜索 Minio 镜像并进行配置：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713192488784-c918354d-099c-4d9c-8c90-ec596b2ae830.png)

填写容器创建信息：

- **容器名（name）**：自定义容器名称，例如 `minio-test`。
- **端口映射（port）**：
    - `9000`：用于 API 访问的端口。
    - `9001`：用于访问 Web 管理界面的端口。
- **数据卷（volume）**：挂载一个本地目录到容器内的 `/data` 目录，用于持久化存储数据。
- **环境变量**：
    - `MINIO_ROOT_USER`：设置登录管理后台的用户名。
    - `MINIO_ROOT_PASSWORD`：设置登录管理后台的密码。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713192524934-579b5417-e9c0-4044-8c1d-1ebf18bfa5f1.png)

点击 **Run** 运行镜像为容器。

### 访问 Minio 管理界面
1.  在浏览器中访问 `http://localhost:9001`。
2.  输入之前设置的用户名和密码进入管理界面。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713090130646-7a846581-78e1-487d-af2c-185a16cd2558.png)

### 管理存储桶与文件
在管理界面中，我们可以创建和管理存储桶（Bucket）。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713090941649-502f9eb9-02e0-4ee9-9795-7b320494eb55.png)

为了让外部能直接访问桶里的文件，需要设置桶的访问策略为公开（Public）。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713091547608-8c6adbb0-5f16-4f6d-82de-bdfc6c814136.png)

设置完成后，上传到这个桶的文件就可以通过 `http://localhost:9000/bucket-name/object-name` 的格式直接访问了。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713091699730-badc0fb3-54c9-4602-843f-b6ae8a2627f2.png)

此外，若要从浏览器前端直接向 Minio 发起 `PUT` 上传，请在桶的 CORS 配置中允许来源 `http://localhost:3000`，并开放 `PUT`、`GET` 方法以及必要的请求头（如 `Content-Type`）。否则浏览器的跨域预检会失败，导致无法上传。

## 实战：前端直传文件到 Minio
接下来，我们将使用 NestJS作为后端来生成预签名 URL，并创建一个简单的前端页面来实现文件直传到 Minio。

### 后端实现 (NestJS)

#### 1. 初始化项目与安装依赖
```bash
# 初始化 NestJS 项目
nest new minio-upload-example -p npm

cd minio-upload-example

# 安装 minio 依赖
npm install minio
```

#### 2. 创建并配置 Minio 模块
为了在项目中方便地使用 Minio 客户端，我们创建一个全局的 `MinioModule`。

```bash
nest g module minio
```

修改 `src/minio/minio.module.ts` 文件，配置 Minio 客户端并将其导出为全局提供者。

```typescript
import { Global, Module } from '@nestjs/common';
import * as Minio from 'minio';

// 定义一个 token，用于注入 Minio 客户端
export const MINIO_CLIENT = 'MINIO_CLIENT';

@Global() // 设置为全局模块
@Module({
  providers: [
    {
      provide: MINIO_CLIENT,
      useFactory: () => {
        // 在这里配置你的 Minio 连接信息
        const client = new Minio.Client({
          endPoint: 'localhost', // Minio 服务地址
          port: 9000,          // API 端口
          useSSL: false,       // 不使用 SSL
          accessKey: 'YOUR_ACCESS_KEY', // 你的 Access Key
          secretKey: 'YOUR_SECRET_KEY', // 你的 Secret Key
        });
        return client;
      },
    },
  ],
  exports: [MINIO_CLIENT], // 导出 MINIO_CLIENT，以便在其他模块中注入
})
export class MinioModule {}
```
**注意**：这里的 `accessKey` 和 `secretKey` 不是 Docker 启动时设置的 `MINIO_ROOT_USER` 和 `MINIO_ROOT_PASSWORD`。你需要登录 Minio 管理后台，在 `Access Keys` 菜单下创建一个新的 Service Account 来获取专用的 Key。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715252809952-1c969d8c-cd45-4b2a-a890-d103ddcfb6d5.png)

最后，在 `AppModule` (`src/app.module.ts`) 中导入 `MinioModule`。

#### 3. 实现生成预签名 URL 的接口
在 `AppController` (`src/app.controller.ts`) 中，注入 `Minio.Client` 并创建一个接口，用于根据文件名生成一个预签名的上传 URL。

```typescript
import { Controller, Get, Inject, Query } from '@nestjs/common';
import { MINIO_CLIENT } from './minio/minio.module';
import * as Minio from 'minio';

@Controller()
export class AppController {
  constructor(@Inject(MINIO_CLIENT) private minioClient: Minio.Client) {}

  @Get('presignedUrl')
  async presignedUrl(@Query('name') name: string) {
    // 生成一个有效期为 1 小时（3600秒）的预签名 URL，用于上传指定名称的对象
    return this.minioClient.presignedPutObject('bucket1', name, 3600);
  }
}
```
`presignedPutObject` 方法会生成一个特殊的 URL，客户端可以在规定时间内使用 `PUT` 请求向这个 URL 上传文件，而无需提供密钥。

### 前端实现

#### 1. 配置静态文件服务
为了提供 HTML 页面，我们需要在 NestJS 中配置静态资源目录。修改 `src/main.ts`：

```typescript
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  
  // 指定 'public' 目录作为静态资源目录
  app.useStaticAssets(join(__dirname, '..', 'public'));

  await app.listen(3000);
}
bootstrap();
```
然后在项目根目录创建一个 `public` 文件夹。

#### 2. 创建前端 HTML 页面
在 `public` 文件夹下创建 `index.html` 文件，内容如下。这段代码来自 [Minio 官方文档](https://min.io/docs/minio/linux/integrations/presigned-put-upload-via-browser.html)。

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Minio Direct Upload</title>
  </head>
  <body>
    <h1>Upload File to Minio</h1>
    <!-- 文件选择输入框 -->
    <input type="file" id="selector" />
    <button onclick="upload()">Upload</button>
    <div id="status">No uploads</div>

    <script type="text/javascript">
      function upload() {
        const file = document.getElementById('selector').files[0];
        if (!file) {
          alert('Please select a file first!');
          return;
        }
        
        // 1. 从后端获取预签名 URL
        retrieveNewURL(file, (file, url) => {
          // 2. 使用获取到的 URL 上传文件
          uploadFile(file, url);
        });
      }

      function retrieveNewURL(file, callback) {
        // 向服务器请求预签名的URL，并附带文件名作为查询参数
        fetch(`/presignedUrl?name=${file.name}`)
          .then((response) => response.text())
          .then((url) => callback(file, url))
          .catch((e) => {
            console.error(e);
            document.getElementById('status').innerHTML = 'Failed to get upload URL.';
          });
      }

      function uploadFile(file, url) {
        document.getElementById('status').innerHTML = `Uploading ${file.name}...`;
        
        // 3. 使用 PUT 方法将文件内容作为请求体，上传到预签名 URL
        fetch(url, {
          method: 'PUT',
          headers: {
            'Content-Type': file.type || 'application/octet-stream',
          },
          body: file,
        })
          .then(() => {
            const fileUrl = `http://localhost:9000/bucket1/${file.name}`;
            document.getElementById('status').innerHTML = 
              `Uploaded ${file.name} successfully. <br> URL: <a href="${fileUrl}" target="_blank">${fileUrl}</a>`;
          })
          .catch((e) => {
            console.error(e);
            document.getElementById('status').innerHTML = `Failed to upload ${file.name}.`;
          });
      }
    </script>
  </body>
</html>
```

### 测试上传
1.  启动 NestJS 服务：`npm run start:dev`。
2.  访问前端页面 `http://localhost:3000`。
3.  选择一个文件并点击 "Upload"。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715262190975-654c80c5-f119-4744-b49d-d0d8f44773dc.png)

上传成功后，页面会显示文件的访问链接。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715262002299-77a81428-b002-4500-b589-c6ad7b8b3360.png)

同时，你可以在 Minio 的管理界面看到刚刚上传的文件。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715262137896-6a5b2520-5459-4af2-b54e-97190789f036.png)

## 结论
所有遵循 S3 规范的 OSS 服务（如阿里云 OSS、腾讯云 COS、Minio 等）其核心概念和操作方式都非常相似。掌握了通过后端生成临时凭证、前端直传的模式，你就可以轻松应对各种对象存储场景。这种方法不仅提升了性能和用户体验，还保证了系统的安全性。
