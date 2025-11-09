Minio 是一个高性能的分布式对象存储服务，它与亚马逊 S3 兼容。

## 启动 docker 的 Minio 容器
首先，我们需要安装 [docker 桌面端](https://link.juejin.cn/?target=https%3A%2F%2Fwww.docker.com%2F)。

打开 Docker 桌面端，搜索 Minio 镜像：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713192488784-c918354d-099c-4d9c-8c90-ec596b2ae830.png)

填写信息：

+ 容器名（name）：自定义容器名称。
+ 端口映射（port）：将本地 9000 和 9001 端口映射到容器内。
+ 数据卷（volume）：挂载本地目录到容器内的数据目录。
+ 环境变量：设置 MINIO_ROOT_USER 和 MINIO_ROOT_PASSWORD 作为登录凭据。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713192524934-579b5417-e9c0-4044-8c1d-1ebf18bfa5f1.png)

点击 run 运行镜像为容器。



## 访问 Minio 管理界面
1. 访问 http://localhost:9001
2. 输入之前设置的用户名和密码进入管理界面：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713090130646-7a846581-78e1-487d-af2c-185a16cd2558.png)





## 管理存储桶与文件
在管理界面中，可以创建和管理存储桶（bucket）和对象（object）：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713090941649-502f9eb9-02e0-4ee9-9795-7b320494eb55.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713090992005-7da10385-94d7-42f3-9996-930b5533357e.png)

可以在这个桶中上传文件：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713091080809-8d05dfa7-3485-4e68-9bad-45fd4329ea15.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713091466271-c8d7af3e-435b-404d-80ea-4d6e068165ce.png)

点击 share 就可以看到这个文件的 url：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713091165953-7af075aa-8a0a-431c-a0f8-cab93b3a1a79.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713091495223-153282f2-866c-482f-82ba-884bdf2bd5f4.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713091626760-29cd1fc4-cd72-45e9-b123-bc87b56a2681.png)

带了很长一串密钥才能访问。



## 设置文件访问权限
默认情况下，文件访问权限不是公开的。您可以添加匿名访问规则以允许直接访问文件：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713091547608-8c6adbb0-5f16-4f6d-82de-bdfc6c814136.png)

不带后面那串密钥也可以访问了：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713091699730-badc0fb3-54c9-4602-843f-b6ae8a2627f2.png)



## 使用 SDK 上传和下载文件
安装 Minio 包：

```bash
npm install minio
```

代码：

```javascript
var Minio = require('minio')

var minioClient = new Minio.Client({
  endPoint: 'localhost',
  port: 9000,
  useSSL: false,
  accessKey: 'your-accessKey',
  secretKey: 'your-secretKey',
})

// 上传文件
function put() {
    minioClient.fPutObject('bucket-name', 'object-name', 'file-path', function (err, etag) {
        if (err) return console.log(err)
        console.log('上传成功');
    });
}

// 下载文件
function get() {
    minioClient.getObject('bucket-name', 'object-name', (err, stream) => {
        if (err) return console.log(err)
        stream.pipe(fs.createWriteStream('output-file-path'));
    });
}

// 调用函数
put();
get();
```

这里可以创建 accessKey：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713091898067-6f21715a-3828-457b-9d68-d05b8d174bda.png)

所有 OSS 服务（如阿里云 OSS、Minio）其实都是相似的，因为它们都遵循 AWS 的 Simple Storage Service（S3）规范。

因此，无论使用哪家服务，其操作方式大致相同。

更多的 api 用法可以看 [minio 文档](https://link.juejin.cn/?target=https%3A%2F%2Fmin.io%2Fdocs%2Fminio%2Flinux%2Fdevelopers%2Fjavascript%2Fminio-javascript.html)。

