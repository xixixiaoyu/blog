## React 项目
前提：我们可以使用 `pnpm create vite react-app --template react-ts` 来创建一个 React 项目。

### 项目根目录创建 `.dockerignore` 文件
```dockerignore
# 依赖目录（构建时重新安装）
node_modules
.pnpm-store

# 构建输出目录（构建时重新生成）
dist

# 环境变量文件
.env
.env.development
.env.production
.env.local
.env.*.local

# 编辑器和 IDE 文件
.DS_Store
.idea
.vscode
*.swp
*.swo

# 日志文件
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# 测试和覆盖率文件
coverage
.nyc_output

# 版本控制和文档
.git
.gitignore
README.md
LICENSE
CHANGELOG.md

# 临时文件
*.tmp
*.temp

# 测试文件
test/
**/*.spec.ts
**/*.test.ts

# TypeScript 编译缓存
*.tsbuildinfo
```

### 创建 `Dockerfile` 文件
同样在根目录，创建 `Dockerfile` 文件，定义镜像的构建过程。

这里我们会用到一个很棒的技巧 —— **多阶段构建 (multi-stage build)**，它可以让最终的镜像非常小巧：

```dockerfile
# 第一阶段：构建我们的应用
# 使用 Node.js 18.17 的轻量版本作为基础镜像
FROM node:18.17-alpine AS build

# 全局安装 pnpm
RUN npm install -g pnpm

# 设置工作目录（在容器内创建 /app 文件夹并进入）
WORKDIR /app

# 先复制依赖配置文件
# pnpm 需要 package.json 和 pnpm-lock.yaml
COPY package*.json pnpm-lock.yaml ./

# 安装所有依赖（包括开发依赖，构建需要）
RUN pnpm install --frozen-lockfile

# 复制所有源代码到容器中
COPY . .

# 构建项目（生成可部署的静态文件）
RUN pnpm run build

# 第二阶段：创建最终的生产环境镜像
# 使用轻量级的 nginx 服务器来托管我们的静态文件
FROM nginx:alpine

# 复制自定义的 nginx 配置文件
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 把第一阶段构建好的静态文件复制到 nginx 的网站目录
COPY --from=build /app/dist /usr/share/nginx/html

# 设置文件权限
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# 声明容器对外提供服务的端口
EXPOSE 80

# 启动 nginx 服务器
CMD ["nginx", "-g", "daemon off;"]
```

### 创建 nginx.conf
```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html index.htm;
    
    # 处理 SPA 路由 - 所有请求都返回 index.html
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # 安全设置 - 隐藏 nginx 版本
    server_tokens off;
    
    # 错误页面
    error_page 404 /index.html;
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:;" always;
}
```

### 打包镜像
确保你的 Docker Desktop (或其他 Docker 环境) 已经启动。然后在项目根目录打开终端，运行：

```bash
docker build -t react-app:latest .
```

### 运行镜像
```bash
docker run -d -p 8888:80 --name my-react-app react-app:latest
```

现在，打开浏览器访问 `http://localhost:8888`：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748615853115-a083184c-7a81-4c47-b6ed-aa3042dd2890.png)

运行成功，没问题。



## Nest 项目
### **创建 Nest 项目**
```bash
nest new nest-app -p pnpm
cd nest-app
```

### 创建 `.dockerignore` 文件
在项目根目录创建 `.dockerignore`：

```dockerignore
# Git
.git/
.gitignore

# Node
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# Editor/OS specific
.vscode/
.idea/
*.code-workspace
.DS_Store
Thumbs.db

# Build artifacts
dist/
*.tsbuildinfo

# Documentation / Test reports
*.md
coverage/
.nyc_output/

# Environment files
.env*
!.env.example

# Logs
logs/
*.log
```

### 创建 `Dockerfile` 文件
```dockerfile
# ---- 阶段 1: 构建阶段 ----
FROM node:18.17-alpine AS builder

# 设置工作目录
WORKDIR /usr/src/app

# 安装 pnpm
RUN npm install -g pnpm

# 复制 package.json 和 pnpm-lock.yaml
COPY package*.json pnpm-lock.yaml ./

# 安装所有依赖（包括开发依赖，用于构建）
RUN pnpm install --frozen-lockfile

# 复制源代码
COPY . .

# 执行构建
RUN pnpm run build

# 移除开发依赖，使得 node_modules 目录仅包含生产环境所需的依赖
RUN pnpm prune --prod

# ---- 阶段 2: 运行阶段 ----
FROM node:18.17-alpine AS runner

# 创建非 root 用户
RUN addgroup -g 1001 -S nestjs && \
    adduser -u 1001 -S -G nestjs nestjs

# 切换到非 root 用户
USER nestjs

# 设置工作目录
WORKDIR /usr/src/app

# 从构建阶段复制构建产物和生产依赖
COPY --from=builder --chown=nestjs:nestjs /usr/src/app/dist ./dist
COPY --from=builder --chown=nestjs:nestjs /usr/src/app/node_modules ./node_modules
COPY --from=builder --chown=nestjs:nestjs /usr/src/app/package.json ./package.json

# 暴露端口
EXPOSE 3000

# 启动应用
CMD ["node", "dist/main.js"]
```

### 打包镜像
```bash
docker build -t nest-api:latest .
```

### 运行镜像
```bash
docker run -d -p 3002:3000 --name my-nest-app nest-api:latest
```

访问 [http://localhost:3002](http://localhost:3002)：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748428329584-c6d3b353-3011-4ca0-9307-cef1324af70a.png)

Nest 返回了，没问题。



## Dockerfile 最佳优化实践
![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748585255674-e4c79ac8-a23f-4d43-9be0-383b08f8c671.png)

写出能用的 Dockerfile 只是第一步，写出高效、小巧、安全的 Dockerfile 才是我们的追求。下面是一些实用的优化技巧：

### 选用官方、轻量级的基础镜像
+ 尽量选择官方维护的镜像，比如 `node`、`python`、`nginx` 等。
+ 在官方镜像中，优先考虑带有 `alpine` 或 `slim` 后缀的版本，它们通常体积小得多。例如，`node:18-alpine` 就比 `node:18` 小很多。
+ 避免使用 `latest` 标签，而是指定具体的版本号（如 `node:18.16-alpine`），这样能保证构建的可重复性和稳定性。

### 最小化镜像层数
+ Dockerfile 中的每一条指令（如 `RUN`, `COPY`, `ADD`）都会创建一层镜像。层数越多，镜像可能越大，构建和拉取也可能变慢。
+ **合并命令**：把多个 `RUN` 命令用 `&&` 连接起来，并在同一条 `RUN` 指令中清理缓存：

```dockerfile
# ❌ 不推荐
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2

# ✅ 推荐
RUN apt-get update && \
    apt-get install -y package1 package2 && \
    rm -rf /var/lib/apt/lists/*
```

### 充分利用缓存
+ Docker 在构建镜像时会尝试重用之前构建的层，如果某一层对应的指令和文件没有变化，就会直接使用缓存。
+ **优化指令顺序**：把不经常变化的指令（比如安装固定版本的依赖）放在 Dockerfile 的前面，把经常变化的内容（比如复制源代码）放在后面。

```dockerfile
# 先复制不怎么变的 package.json 并安装依赖
COPY package*.json ./
RUN npm install

# 再复制经常变动的项目代码
COPY . .
```

### 及时清理不必要的文件
对于 pnpm，在多阶段构建中，通常在**构建阶段**执行 `pnpm install --frozen-lockfile`（安装所有依赖，包括 devDependencies 用于构建）和 `pnpm run build`。

之后，仍然在**构建阶段**，可以运行 `pnpm prune --prod` 来移除 devDependencies，然后将精简后的 `node_modules` 目录和构建产物复制到**运行阶段**。

Nest 项目的 Dockerfile 就是一个很好的例子。

### 使用多阶段构建
+ 这个技巧太重要了，所以再强调一遍！就像我们前面 React 和 Nest.js 例子中做的那样，在一个 Dockerfile 中使用多个 `FROM` 指令。
+ 第一个阶段（构建阶段）可以使用包含完整编译工具链的基础镜像来编译代码、安装依赖。
+ 第二个阶段（运行阶段）则使用一个非常轻量级的基础镜像，只从构建阶段拷贝必要的产物（比如编译好的可执行文件、静态资源、生产依赖）。这样最终的镜像就只包含运行应用所必需的东西，体积大大减小。

### 用好 `.dockerignore` 文件
+ 前面已经详细介绍过了，确保你把所有不需要进入镜像的文件和目录都列在 `.dockerignore` 里。

### 注意安全
+ **定期更新基础镜像**：基础镜像也可能存在安全漏洞，定期拉取更新的版本并重建你的应用镜像是个好习惯。
+ **使用非 root 用户**：默认情况下，容器内的进程是以 `root` 用户身份运行的，这存在一定的安全风险。可以通过 `USER` 指令切换到非 `root` 用户。

```dockerfile
# 创建一个用户和用户组
RUN addgroup -S myappgroup && adduser -S myappuser -G myappgroup
# ... 其他指令 ...
# 切换到非 root 用户
USER myappuser
```

### 善用环境变量 (ARG 和 ENV)
+ `ARG` <font style="color:rgb(38, 38, 38);">定义构建时参数，只在镜像构建过程中有效，不会持久化到最终镜像中</font>
+ `ENV` <font style="color:rgb(38, 38, 38);">定义环境变量，会成为镜像的元数据，在容器运行时作为环境变量存在</font>

🌰 新建一个 `test.js` 文件：

```js
console.log(process.env.name);
console.log(process.env.age);
```

创建 `Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY ./test.js .

# ARG 定义构建时参数，可以有默认值
ARG name=Yun
ARG age=20

# ENV 将 ARG 的值设为环境变量，使其在容器运行时可用
ENV name=${name}
ENV age=${age}

CMD ["node", "/app/test.js"]
```

打包镜像：

```bash
docker build -t env-test:v1.0 .
```

在 build 时可以通过 `--build-arg` 修改 `ARG` 的值。

运行镜像：

```bash
docker run -it --rm env-test:v1.0
```

你会看到输出了默认的 "Yun" 和 "20"：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748430902347-d067c145-08a9-4288-b303-8844e3eefc96.png)

+ `-it` 参数表示运行一个带有交互式 shell 的 Docker 容器。
+ `--rm` 参数表示在容器退出时自动删除容器。

也可以运行时通过 `-e` 修改 `ENV` 的值：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748430957093-f604adbb-afe3-4e81-af1d-982afa1581d0.png)

如果有很多环境变量，可以把它们写在一个文件里（比如 `my-env.file`，每行一个 `KEY=VALUE`），然后在运行容器时使用 `--env-file` 选项：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748430975486-b4b96c5a-72cb-46ad-b3eb-30609eacfa65.png)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748430984820-2d264e2e-bea4-4fa5-b307-4b9c6d3eedeb.png)


