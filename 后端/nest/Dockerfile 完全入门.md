虽然 Docker Hub 上有很多现成的镜像，但很多时候我们需要根据自己的项目定制镜像。这时候就需要用到 **Dockerfile** 了。

Dockerfile 是一个文本文件，它包含了一系列指令，用来告诉 Docker 如何一步步自动化构建你想要的镜像。

基本流程：

![画板](https://cdn.nlark.com/yuque/0/2025/jpeg/21596389/1748336677147-987e6d60-f995-429c-8a88-db78a2f8e5c1.jpeg)

## Dockerfile 常用指令
![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748584967750-ede15854-32e2-4133-9595-2fa34ff4398f.png)

### 1. FROM - **选择一个好的基础镜像**
```dockerfile
FROM ubuntu:20.04
FROM node:16-alpine
```

这个必须放第一行（注释除外），就像盖房子先打地基一样。

推荐使用官方的、经过验证的基础镜像。`alpine` 版本更小巧，显著减小镜像体积，加快下载速度，但 `alpine` 可能缺少一些常用工具，需自行安装。

### 2. RUN - **执行命令并构建层**
```dockerfile
RUN apt-get update && apt-get install -y nginx
RUN npm install
```

每个 RUN 都会新增一层。

为了减少镜像层数和体积，应将多个相关命令用 `&&` 和 `\` (换行符) 连接在单个 `RUN` 指令中。例如：

```dockerfile
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && rm -rf /var/lib/apt/lists/*
```

### 3. CMD - **容器启动时默认执行的命令**
```dockerfile
CMD ["nginx", "-g", "daemon off;"]  # 推荐这种写法
CMD nginx -g "daemon off;"          # 也行，但不如上面的好
```

一个 Dockerfile 只能有一个 CMD，如果定义了多个，只有最后一个会生效。

如果 `docker run` 的时候指定了命令，`CMD` 的内容会被覆盖。

### 4. ENTRYPOINT - **配置容器启动时的“入口点”**
```dockerfile
ENTRYPOINT ["java", "-jar", "myapp.jar"]
ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;"]
```

与 CMD 类似，但 ENTRYPOINT 指定的命令不容易在 docker run 时被覆盖（需要使用 --entrypoint 参数显式覆盖）。

ENTRYPOINT 与 CMD 组合使用：

```dockerfile
ENTRYPOINT ["echo", "Hello"]
CMD ["world"]
```

+ `docker run myimage` -> 输出 `Hello world`
+ `docker run myimage Docker` -> 输出 `Hello Docker` (`CMD` 的 `world` 被 `Docker` 覆盖)

 ENTRYPOINT 确保容器始终执行特定的主命令，CMD 提供灵活的默认参数，可在运行时轻松覆盖

### 5. WORKDIR - 设置工作目录
```dockerfile
WORKDIR /app
```

为后续的 `RUN`, `CMD`, `ENTRYPOINT`, `COPY`, `ADD` 指令设置工作目录，避免频繁写绝对路径。如果目录不存在，`WORKDIR` 会自动创建它。

### 6. COPY vs ADD - **复制文件/目录到镜像**
```dockerfile
COPY ./myapp /app/myapp     # 老实本分，就是复制
ADD source.tar.gz /app/ # 能解压，还能从网上下载
```

`COPY`：将文件或目录从构建上下文复制到镜像文件系统中。

`ADD`：功能与 `COPY` 类似，但增加了两个额外功能：

1. 如果源文件是可识别的压缩包（如 `tar.gz`），`ADD` 会自动解压。
2. 如果源文件是 URL，`ADD` 会尝试下载文件。

**建议**：99% 的情况用 `COPY` 就够了，`ADD` 功能太多反而容易出问题。

### 7. EXPOSE - **声明容器运行时监听的端口**
```dockerfile
EXPOSE 80
EXPOSE 8080/tcp
EXPOSE 53/udp
```

声明容器在运行时会监听的网络端口。

⚠️ `EXPOSE` **不会**自动将端口发布到宿主机。要在宿主机上访问容器端口，仍需在 `docker run` 时使用 `-p` 或 `-P` 参数。

### 8. ENV - 设置环境变量
```dockerfile
ENV NODE_ENV=production
ENV APP_VERSION="1.0.0"
```

设置环境变量。这些变量在构建过程中（后续指令）和容器运行时都可用。

### 9. VOLUME - **声明挂载点**
```dockerfile
VOLUME ["/var/lib/mysql"]
VOLUME /data
```

声明容器中希望持久化或由外部管理的目录。这有助于镜像使用者了解哪些路径适合挂载卷。

实际持久化通过 `docker run -v /host_path:/var/lib/mysql` (绑定挂载) 或 `docker run -v volume_name:/var/lib/mysql`(命名卷) 来实现。

如果没有提供 `host_path`，比如直接 `docker run -d your_image`，Docker 会创建匿名卷挂载到我们声明的 `VOLUME`。

### 10. USER - 别老用 root
```dockerfile
USER nginx
USER 1001
USER appuser:appgroup
```

指定运行后续 `RUN`, `CMD`, `ENTRYPOINT` 指令时使用的用户名或 UID（以及可选的组名或 GID）

⚠️ 除非绝对必要，否则不要使用 `root` 用户运行应用。在 Dockerfile 中创建一个非 `root` 用户，并使用 `USER` 指令切换到该用户。

### 11. LABEL - **为镜像添加元数据**
```dockerfile
LABEL maintainer="zhang@example.com" 
LABEL version="1.0"
LABEL description="我的超棒应用"
```

以键值对的形式为镜像添加元数据，如维护者、版本号、描述等。方便组织和管理镜像。

## docker build - 构建镜像
```bash
docker build -t myapp:latest .
```

`-t myapp:latest`：给镜像打上标签（名称:版本号）。

`.` (点)：指定当前目录为构建上下文。Docker 守护进程会加载此目录中的所有文件（遵循 `.dockerignore` 规则）用于构建。

### 常用参数
1. **指定 Dockerfile 文件 **

当 Dockerfile 文件名不是默认的 Dockerfile 或不在构建上下文根目录时，需要使用 -f 参数指定文件路径。 

格式：

```bash
docker build -f <dockerfile-path> -t <image-name>:<tag> <build-context>
```

例子：

```bash
docker build -f /path/to/MyDockerfile -t myapp:1.0 .
```

2. **传递构建时参数 (**`**--build-arg**`**)：**

```dockerfile
# Dockerfile 中定义
ARG VERSION=latest
ENV APP_VERSION=${VERSION}
RUN echo "Building version ${APP_VERSION}"
```

```dockerfile
# 构建命令
docker build --build-arg VERSION=1.2.3 -t myapp:1.2.3 .
```

3. **禁用缓存（--no-cache）**

当缓存可能导致问题，或需要确保每一步都重新执行时：

```dockerfile
docker build --no-cache -t myapp:latest .
```

4. **指定构建平台（--platform）**

用于多平台构建，例如在 Apple Silicon Mac 上构建 x86_64 镜像：

```dockerfile
docker build --platform linux/amd64 -t myapp-amd64:latest .
```

5. **其他实用参数**

```dockerfile
# 静默模式，减少输出信息
docker build -q -t myapp:latest .

# 设置构建时的内存限制
docker build -m 1g -t myapp:latest .

# 指定构建目标阶段（多阶段构建）
docker build --target production -t myapp:prod .
```



## `.dockerignore` 文件
在把构建上下文发送给 Docker Daemon（守护进程）之前。

我们通常会用到一个叫做 `.dockerignore` 的文件。它的作用和 `.gitignore` 类似，告诉 Docker 在构建镜像时哪些文件或目录可以被忽略掉。

示例：

```dockerfile
# 依赖和构建产物
node_modules/
dist/
build/

# 开发工具配置
.vscode/
.idea/
*.log

# 敏感文件
.env
.env.local
*.key
*.pem

# 文档（根据需要）
*.md
!README.md

# Git 相关
.git/
.gitignore
```

能有效减少构建大小，加快构建速度以及脱敏。

`.dockerignore` 支持灵活的匹配模式：

+ `*.md` - 忽略所有 .md 文件（如文档）
+ `!README.md` - 排除规则，即使匹配了 `*.md`，也保留 README.md
+ `node_modules/` - 忽略整个 node_modules 目录
+ `**/*.log` - 忽略所有子目录中的 .log 文件
+ `temp*` - 忽略以 temp 开头的文件或目录
+ `.git/` - 忽略 Git 仓库信息



## 🌰 用 Dockerfile 构建一个自定义 Nginx 镜像
### 准备文件
假设我们有一个项目，包含一个 `index.html` 文件，我们想用 Nginx 来展示它：

```html
<!DOCTYPE html>
<html lang="en">
  <head> </head>
  <body>
    hello docker
  </body>
</html>
```

### 编写 Dockerfile
在 `docker test` 目录下创建一个名为 `Dockerfile` (没有扩展名) 的文件：

```dockerfile
# my-custom-nginx/Dockerfile

# 1. 使用官方最新的 Nginx 镜像作为基础
FROM nginx:latest

# 2. (可选) 添加标签信息
# LABEL maintainer="Your Name <your.email@example.com>"
# LABEL version="1.0"

# 3. 将我们自定义的 index.html 文件复制到 Nginx 默认的网站根目录
# 第一个参数是相对于构建上下文的源路径，第二个参数是镜像内的目标路径
COPY ./index.html /usr/share/nginx/html/index.html

# 4. (可选) 声明容器将监听 80 端口 (Nginx 默认就是 80)
EXPOSE 80

# 5. 容器启动时运行的命令：以前台模式启动 Nginx
# "daemon off;" 是 Nginx 的一个指令，让它在前台运行，这对于 Docker 容器是必要的
CMD ["nginx", "-g", "daemon off;"]
```

### 构建镜像
打开命令行`docker build`：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748159160093-16022ea0-9ea7-4d82-ba16-094578abb3c5.png)

你会看到 Dockerfile 中的指令一步步执行。

+ `-t my-app:v1` 给新镜像命名为 `my-app`，标签为 `v1`。
+ `.` 表示使用当前目录作为构建上下文，Docker 会在这个目录里寻找 `Dockerfile`。

我们上面使用 docker build 命令构建一个名为 `my-app`、标签为 `v1` 的镜像：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748159212029-1b412e01-daa0-4023-9bed-69466d47c235.png)

点击 run 填写参数

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748159268768-f707f84a-8696-4f42-91c3-a772ce2c7bcf.png)

点击 Run 之后，访问页面 [localhost:9999/](http://localhost:9999/)：

![](https://lh3.googleusercontent.com/gg-dl/AJfQ9KQKmhYl9M6OMKLrvZLUM0_GqnafwQmVReOmd0S2ooz8ZxIScvUc-1W7uxU8I45rWMUpqWT7np25SLjBGZtBoswnir97NXJeqIZPStglC7Ow-mHeC3XiGqAnODoNtmqIhcYDTbJAUWhhuA4-O5KGeJQM0zlvrUh39koEWT1ELp441wLMtg)![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748159440675-fa1dca03-63f1-452a-a45c-83cf929c5c51.png)

进入容器 files：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748159465709-e6bf5880-dbce-435d-9ff0-ddbd20bf94ae.png)

可以发现这个 index.html 文件就是我们之前项目目录下 index.html 文件。

有没有办法，我们项目 index.html 改动，容器内跟着改呢？

我们运行镜像：

```bash
docker run --name my-app-test2 -d -v ./:/usr/share/nginx/html -p 8888:80 my-app:v1
```

使用 `-v ./:/usr/share/nginx/htm`：当前目录（./）被映射到容器内的 `/usr/share/nginx/html` 目录。这意味着对宿主机当前目录的任何更改都会反映在容器的 `/usr/share/nginx/html` 目录中，反之亦然。

修改 index.html 文件：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748159954184-b79bf8d6-29e4-40bf-b172-9a3bfb9fa213.png)

访问 [localhost:8888/](http://localhost:8888/)：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748160471887-9fa4dc7f-0a94-42bb-8786-8a8a730e58cc.png)

成功。

