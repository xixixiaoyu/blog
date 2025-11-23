你花了一整天在本地搭建好项目环境，所有功能都运行完美。但当需要部署到服务器或分享给同事时，却接连遇到"依赖缺失"、"版本冲突"、"环境不兼容"等问题...

Docker 就是来解决这些痛点的。

本文将带你从 Docker 的基础概念出发，逐步深入网络、多进程管理和多容器编排，最终掌握一套稳如磐石的生产环境部署方案。

## Part 1: Docker 核心概念与入门

### Docker 是什么？
Docker 是一个开源的**应用容器引擎**，它允许开发者将应用及其所有依赖（库、配置文件、运行时等）打包到一个**标准化的单元**中，这个单元被称为 **Docker 镜像 (Image)**。

可以把它形象地理解为一个“**标准化的软件集装箱**”。

Docker 镜像确保了软件的分发和运行标准。无论是在你的笔记本电脑、测试服务器还是生产环境，只要安装了 Docker，这个“软件集装箱”——即 **Docker 容器 (Container)**（镜像的运行实例）—— 就能**一键启动**，并且表现得**完全一致**。

### Docker 的核心优势
**🎯** 彻底解决环境差异问题，确保开发、测试、生产环境的高度一致性。

**⚡** 相比传统虚拟机，Docker 容器启动速度达到秒级，资源占用更少，运行效率更高。

**🔒** 每个应用运行在独立的容器中，互不影响，可以安全地运行不同版本依赖的服务。

**🚀** 一次构建，处处运行。简化部署流程，实现应用的快速迭代与弹性伸缩。

**☁️** 主流云平台（AWS、阿里云、腾讯云等）都提供容器服务，可直接部署 Docker 镜像。

### 虚拟机 VS 容器
![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748099781568-2b64adfa-00d7-462e-8132-16363126fc92.png)

| 特性 | 虚拟机 (VM) | 容器 (Container) |
| :--- | :--- | :--- |
| **隔离性** | 强（硬件级隔离） | 中等（进程级隔离） |
| **资源占用** | 高（需分配固定资源） | 低（动态共享资源） |
| **启动速度** | 慢（分钟级） | 快（秒级） |
| **存储占用** | 大（GB 级） | 小（MB 级） |
| **系统要求** | 需完整操作系统 | 共享宿主机内核 |
| **性能开销** | 较高 | 接近原生性能 |

虚拟机和容器最本质的区别就是虚拟化的层次不同。

虚拟机是把**整个操作系统都虚拟出来**，就像你在一台电脑上安装了好几个完整的操作系统，每个都有自己的内核、驱动什么的。

而容器呢，它只是把**应用程序隔离开**，大家还是共用同一个操作系统内核。

这就导致了很明显的差异：虚拟机启动要好几分钟，因为要启动整个操作系统；容器几秒钟就能起来，因为操作系统已经在那了。

资源消耗上，虚拟机也要重得多，一个虚拟机可能要占几个 G 的内存，而容器可能只要几十 M。

不过虚拟机的隔离性更好，一个虚拟机崩了不会影响其他的，而容器因为共享内核，理论上安全性会差一点。

所以选择哪个主要看你的需求，如果要快速部署和扩展（微服务很适合），容器更合适；如果要强隔离或者运行不同操作系统，虚拟机更好。

### Docker 核心概念
#### 镜像（Image）
它是一个**只读的模板**，就像一张“光盘”或者一个“安装包”。里面包含了运行某个软件所需的所有东西：代码、运行时库、环境变量、配置文件等。

镜像是分层的，每一层都是一些文件变更的记录，这种设计让镜像构建和分发更高效。

你可以自己创建镜像，也可以从公共或私有的仓库 (Repository) 下载别人做好的镜像。

#### 容器（Container）
镜像是静态的模板，而容器是**镜像运行起来的实例**。你可以把镜像看成类 (Class)，容器就是这个类的一个对象 (Instance)。

容器被启动后，就在一个隔离的环境中运行，有自己的文件系统、网络空间和进程空间。

容器可以被启动、开始、停止、删除。

#### 仓库（Repository）
就是存放镜像的地方，好比代码仓库（像 GitHub）。

最著名的公共仓库是 **Docker Hub**，上面有成千上万的官方和社区贡献的镜像（比如 Nginx、MySQL、Redis 等）。你也可以搭建自己的私有仓库。

#### Dockerfile
这是一个**文本文件**，里面包含了一系列指令，用来告诉 Docker 如何一步步自动构建一个镜像。比如，基于哪个基础镜像、复制哪些文件进去、安装什么依赖、容器启动时默认执行什么命令等等。

#### 数据卷（Volume）
容器默认是无状态的，也就是说容器删除后，里面产生的数据也就没了。数据卷就是用来**持久化存储数据**的。

它可以让数据独立于容器的生命周期存在，即使容器被删除了，数据卷里的数据依然保留。也可以用于容器间共享数据。

#### 网络（Network）
Docker 允许容器之间、容器与宿主机、容器与外部网络之间进行通信。它提供了多种网络模式（如桥接模式、主机模式）来满足不同场景的需求。我们将在后续章节深入探讨。

### 安装 Docker
首先需要安装 Docker，直接从[官网](https://www.docker.com/products/docker-desktop/)下载 Docker Desktop 就行：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1747929949258-2da4968a-793c-4b9e-b33b-728cc819f7d9.png)

Docker Desktop 提供了一个图形化界面，方便我们查看和管理本地的镜像（Images）、运行中的容器（Containers） 和数据卷（Volumes） 等。

安装完成命令行输入 `docker -h` 看下 docker 命令是否可用：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748312091716-490b589d-bcc9-4418-b7b7-ed5b20af40d7.png)

### 快速上手：运行一个 Nginx 容器
虽然 Docker Desktop 很方便，但在服务器上或者进行自动化部署时，命令行才是王道。下面我们将使用命令行来完成操作。

#### 1. 拉取镜像 (pull)
```bash
# 从 Docker Hub 拉取最新版的 Nginx 镜像
docker pull nginx:latest
```
`nginx` 是镜像名，`latest` 是标签 (tag)。执行后，可以用 `docker images` 查看本地已有的镜像。

#### 2. 运行镜像（run）
```bash
# 创建一个 /tmp/test 目录用于挂载
mkdir -p /tmp/test
cd /tmp/test
echo "Hello Docker!" > ./index.html

# 运行 Nginx 容器
docker run --name nginx-test -p 8080:80 -v /tmp/test:/usr/share/nginx/html:ro -d nginx:latest
```

我们来拆解一下这个命令：
+ `docker run`: 运行镜像以创建并启动一个新容器。
+ `--name nginx-test`: 给容器命名为 `nginx-test`。
+ `-p 8080:80`: **端口映射**。将宿主机的 `8080` 端口映射到容器的 `80` 端口。这样访问 `http://localhost:8080` 就会被转发到容器内的 Nginx 服务。
+ `-v /tmp/test:/usr/share/nginx/html:ro`: **挂载数据卷**。
    - `/tmp/test` 是宿主机路径。
    - `/usr/share/nginx/html` 是容器内 Nginx 存放网页的路径。
    - `:ro` 表示 `read-only`，容器内对这个目录只有只读权限，保证了宿主机文件的安全。如果希望容器内可读写，可以省略或使用 `:rw`。
+ `-d`: 表示 `detached` 模式，即让容器在后台运行。
+ `nginx:latest`: 指定要使用的镜像及其标签。

#### 3. 验证
打开浏览器，访问 `http://localhost:8080`，你应该能看到 "Hello Docker!" 的字样。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748100496583-8e8fd8e3-4f3a-436f-9159-3efbc065ddc4.png)

这说明容器已经成功运行，并且数据卷挂载也生效了。

#### 4. 常用管理命令
```bash
# 查看正在运行的容器
docker ps

# 查看所有容器（包括已停止的）
docker ps -a

# 查看容器的实时日志
docker logs -f nginx-test

# 进入容器内部执行命令（打开一个交互式 shell）
docker exec -it nginx-test /bin/sh

# 停止容器
docker stop nginx-test

# 启动已停止的容器
docker start nginx-test

# 删除容器（必须先停止）
docker rm nginx-test
```

## Part 2: 深入 Docker 网络：容器如何通信

我们把 Docker 容器想象成一座座独立的房子，而你的宿主机就是它们所在的城市。网络要解决的问题就是：**如何让这些房子既能保持独立，又能按需与外界（或其他房子）通信呢？**

要理解网络模式，我们得先了解三个 Linux 内核提供的“积木”：

1. **Network Namespace (网络命名空间)**：这是实现网络隔离的关键。每个容器都有自己独立的网络命名空间，就像给每座房子分配了一个独立的、与世隔绝的院子。院子里的网络设备（网卡、路由表、iptables 规则等）都是独立的，看不到其他院子里的情况。
2. **Veth Pair (Virtual Ethernet Pair)**：这是一对虚拟网卡，像一根特殊的管道，一端在容器的命名空间（房子里），另一端在宿主机的根命名空间（街道上）。从一端进入的数据包会原封不动地从另一端出来，它是连接容器与宿主机网络的桥梁。
3. **Bridge (网桥)**：这是一个虚拟的二层交换机，工作在宿主机上。它就像一个小区的物业中心或交换机，可以连接多个 `veth pair` 的一端，让连接在上面的各个容器（房子）之间可以相互通信。

理解了这三点，我们再来看具体的网络模式，就会豁然开朗。Docker 提供了四种主要的原生网络模式。

#### 1. Bridge 模式（默认模式）
```bash
# 默认就是 bridge 模式
docker run -d --name my-nginx -p 8080:80 nginx
```
这是 Docker 的默认网络模式。当你不指定 `--network` 时，容器就会加入这个模式。

**工作原理**：
1. Docker 在宿主机上创建一个名为 `docker0` 的虚拟网桥。
2. 每次创建新容器时，Docker 会创建一对 `veth pair`。
3. `veth pair` 的一端（如 `eth0`）被放入容器的网络命名空间，并分配一个私有 IP（通常是 `172.17.0.0/16` 网段）。
4. `veth pair` 的另一端（如 `vethxxx`）被连接到宿主机的 `docker0` 网桥上。
5. `docker0` 网桥通过 NAT（网络地址转换）技术，让容器可以访问外网。

**特点**：

- **隔离性好**：每个容器都有独立的网络栈，互不影响。
- **可访问外网**：通过 NAT，容器可以自由访问互联网。
- **端口映射**：外网无法直接访问容器。需要通过 `-p` 参数将宿主机的端口映射到容器的端口，就像给小区的某个房子（容器）分配一个公开的门牌号（宿主机端口）。

**适用场景**：绝大多数单主机应用场景。比如，一个 Web 应用服务器和一个数据库服务器，它们都需要与外网交互，但彼此之间也需要隔离。

#### 2. Host 模式
```bash
# 容器内的 Nginx 将直接监听在宿主机的 80 端口
docker run -d --name my-nginx-host --network host nginx
```
在这种模式下，容器将不会获得独立的网络命名空间，而是与宿主机共享网络栈。

**工作原理**：
- 容器直接使用宿主机的 IP 地址和所有端口。
- 它没有自己的 `eth0`，看到的网络配置和宿主机 `ifconfig` 看到的一模一样。

**特点**：
- **性能最高**：没有 NAT 转换和虚拟网络的开销，网络性能接近原生。
- **无隔离性**：容器与宿主机共享网络，端口不能冲突。如果容器占用了 80 端口，宿主机就不能再使用 80 端口。
- **无需端口映射**：容器中运行的服务直接绑定在宿主机的端口上，外部可以直接访问。

**适用场景**：对网络性能要求极高的场景，或者需要监控宿主机网络的工具（如 `nmap`、`tcpdump`）。

#### 3. None 模式
```bash
# 这个容器将完全无法通过网络访问
docker run -d --name my-batch-job --network none my-batch-image
```
这种模式下，容器拥有自己的网络命名空间，但 Docker 不会为它进行任何网络配置。

**工作原理**：
- 容器创建后，只有一个 `lo`（回环）网卡。
- 没有任何 `veth pair`，没有 IP，无法与外界通信。

**特点**：
- **绝对隔离**：网络上是“孤岛”，最安全。
- **无法通信**：默认情况下，既不能访问外网，也不能被其他容器访问。

**适用场景**：对安全性要求极高，且不需要网络连接的后台任务或批处理任务。也可以用于需要自定义网络配置的场景，由用户手动配置网络。

#### 4. Container 模式
```bash
# 先启动一个容器
docker run -d --name my-app my-app-image

# 再启动一个容器，共享 my-app 的网络
# 在 my-logger 容器里，可以通过 localhost:8080 访问 my-app 的服务
docker run -d --name my-logger --network container:my-app my-logger-image
```
这种模式下，一个新创建的容器将与一个已存在的容器共享网络命名空间。

**工作原理**：
- 两个容器共享同一个 IP 地址、端口范围和网络配置。
- 它们之间的通信就像在同一个机器上的两个进程一样，通过 `localhost` 即可高效通信。

**特点**：
- **高效通信**：共享网络栈的容器间通信效率极高。
- **端口共享**：两个容器不能绑定相同的端口，否则会冲突。
- **紧耦合**：通常用于将紧密相关的服务（如主应用和其日志收集 sidecar）部署在一起。

**适用场景**：Pod 的概念雏形。一个主应用容器和一个辅助容器（如日志代理、监控代理）需要紧密协作。

#### 网络模式总结
| 模式          | 隔离性       | 性能                | 适用场景                               |
| :------------ | :----------- | :------------------ | :------------------------------------- |
| **Bridge**    | 良好         | 一般（有 NAT 开销） | 大多数单主机应用，需要隔离与外网访问   |
| **Host**      | 无           | 最高                | 高性能网络需求，或监控宿主机网络       |
| **None**      | 完全隔离     | 无网络              | 离线任务，或需要自定义网络的高安全场景 |
| **Container** | 容器间无隔离 | 高（容器间通信）    | 紧耦合的容器组，如 Pod                 |

选择哪种网络模式，本质上是在**隔离性、性能和易用性**之间做权衡。

## Part 3: 实践：构建与部署生产级应用

理论知识已经足够，现在让我们进入实战环节。我们将以一个 NestJS 应用为例，一步步构建一个稳如磐石的生产环境部署方案。

开发 Node.js 应用时，本地调试一切正常，但一部署到服务器上，挑战才真正开始：应用意外崩溃了怎么办？如何自动重启？日志如何统一管理？服务器的多核 CPU 性能如何充分利用？当应用依赖数据库、缓存等多个服务时，又该如何协同管理？

我们将结合使用 Docker、PM2 和 Docker Compose 来解决这些问题。

### Step 1: 应用容器化 - 编写 Dockerfile

Docker 能将你的应用连同其所有依赖打包到一个轻量、可移植的“容器”中，一次构建，处处运行。首先，我们需要为 NestJS 应用编写一个 `Dockerfile`。

一个典型的、用于生产环境的 `Dockerfile` 会采用**多阶段构建（Multi-stage build）**来优化镜像大小：

```dockerfile
# Dockerfile

# ---- Stage 1: 构建阶段 ----
# 使用一个包含完整构建工具链的镜像
FROM node:18-alpine as builder

# 设置工作目录
WORKDIR /usr/src/app

# 复制 package.json 和 lock 文件
COPY package*.json ./

# 安装所有依赖（包括 devDependencies 用于构建）
RUN npm install

# 复制所有源代码
COPY . .

# 执行构建
RUN npm run build

# ---- Stage 2: 运行阶段 ----
# 使用一个轻量的基础镜像
FROM node:18-alpine

WORKDIR /usr/src/app

# 从 builder 阶段复制构建好的 dist 目录
COPY --from=builder /usr/src/app/dist ./dist

# 复制 package.json 和 lock 文件
COPY package*.json ./

# 只安装生产环境依赖，减小镜像体积
RUN npm install --only=production

# 暴露应用端口
EXPOSE 3000

# 容器启动命令
CMD ["node", "dist/main.js"]
```

现在，我们构建并运行这个镜像：
```bash
# 构建镜像
docker build -t nest-app:v1.0 .

# 运行容器，并设置重启策略
docker run -d -p 3000:3000 --restart=unless-stopped --name=nest-app-container nest-app:v1.0
```
`--restart=unless-stopped` 是 Docker 提供的重启策略，它能保证在容器意外退出时自动重启，但在手动 `docker stop` 后不会重启，是大多数场景下的最佳选择。

### Step 2: 引入 PM2 - 专业的 Node.js 进程管家

Docker 的重启策略解决了容器级别的存活问题，但如果我们想对容器内部的 Node.js 进程进行更精细化的管理，比如实现**负载均衡、无缝重启、性能监控**等，就需要 PM2 了。

PM2 (Process Manager 2) 就像是专门为 Node.js 应用配备的贴身管家。

#### PM2 核心功能
*   **自动重启**：在应用崩溃时自动重启，比 Docker 的重启更快。
*   **负载均衡 (集群模式)**：Node.js 默认是单线程的。PM2 可以轻松启动多个进程实例来分摊请求，榨干服务器多核 CPU 性能。
*   **日志管理**：自动接管应用的 `stdout` 和 `stderr`，并支持日志分割、轮转。
*   **实时监控**：通过 `pm2 monit` 提供一个实时监控面板。
*   **优雅重启**：实现零停机时间的服务更新。

#### 在 Docker 中使用 PM2
要在 Docker 容器中正确地使用 PM2，关键是使用 `pm2-runtime` 而不是 `pm2`。`pm2-runtime` 是专门为容器化环境设计的启动命令，它会在前台运行 PM2，并将日志直接输出到容器的 stdout/stderr，这正是 Docker 所期望的行为。

我们来更新 `Dockerfile`，集成 PM2：

```dockerfile
# Dockerfile.pm2

# ---- Stage 1: 构建阶段 (与之前相同) ----
FROM node:18-alpine as builder
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# ---- Stage 2: 运行阶段 ----
FROM node:18-alpine

WORKDIR /usr/src/app

# 全局安装 PM2
RUN npm install -g pm2

# 从 builder 阶段复制构建产物
COPY --from=builder /usr/src/app/dist ./dist

# 复制 package.json 并只安装生产依赖
COPY package*.json ./
RUN npm install --only=production

# 暴露应用端口
EXPOSE 3000

# 使用 pm2-runtime 启动应用，并开启集群模式
# -i max 会根据 CPU 核心数自动启动最大数量的进程
CMD ["pm2-runtime", "dist/main.js", "-i", "max"]
```

**Docker 重启 vs PM2 重启：到底用哪个？**

最佳实践是：**两者都用，各司其职**。
*   **PM2**：作为**进程管理器**，负责应用级别的健康检查和重启。当 Node.js 进程因代码错误崩溃时，PM2 会迅速将其拉起。
*   **Docker**：作为**容器引擎**，负责容器级别的健康检查和重启。当整个容器因资源耗尽等原因退出时，Docker 的重启策略会作为最后一道防线，将整个容器重启。

### Step 3: 引入 Docker Compose - 编排多容器应用

现代应用很少独立存在，通常需要数据库（如 MySQL）、缓存（如 Redis）等配套服务。Docker Compose 允许你通过一个 `docker-compose.yml` 的 YAML 文件，来定义和管理一个由多个容器组成的应用。

#### Docker Compose 的基本概念
*   **Services (服务)**: 应用的组成部分，每个服务都运行在一个容器里。例如，`nest-app`、`mysql-db`、`redis-cache`。
*   **Networks (网络)**: Docker Compose 会默认创建一个桥接网络，让所有服务都加入其中。在这个网络内部，容器之间可以直接通过**服务名**作为主机名进行通信。
*   **Volumes (数据卷)**: 用于持久化数据，确保数据在容器删除后依然存在。

#### 部署 NestJS + MySQL + Redis 应用
让我们来看一个完整的 `docker-compose.yml` 示例。

```yaml
# docker-compose.yml
version: '3.8'

services:
  # 1. NestJS 应用服务
  nest-app:
    build:
      context: . # Dockerfile 所在目录
      dockerfile: Dockerfile.pm2 # 使用我们集成了 PM2 的 Dockerfile
    ports:
      - '3000:3000'
    restart: unless-stopped
    depends_on: # 仅定义启动顺序，不保证服务已就绪
      - mysql-db
      - redis-cache
    environment: # 环境变量，用于向应用传递配置
      DB_HOST: mysql-db      # 关键！使用服务名作为主机名
      DB_PORT: 3306
      DB_USERNAME: root
      DB_PASSWORD: yoursecurepassword
      DB_DATABASE: test
      REDIS_HOST: redis-cache # 同样使用服务名
      REDIS_PORT: 6379
    networks:
      - common-network

  # 2. MySQL 服务
  mysql-db:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: yoursecurepassword # 设置 root 密码
      MYSQL_DATABASE: test # 启动时自动创建 test 数据库
    volumes:
      - mysql-data:/var/lib/mysql # 将数据库文件持久化到具名数据卷
    ports:
      - '3306:3306'
    networks:
      - common-network

  # 3. Redis 服务
  redis-cache:
    image: redis:alpine
    restart: unless-stopped
    volumes:
      - redis-data:/data # 持久化 Redis 数据
    ports:
      - '6379:6379'
    networks:
      - common-network

# 定义具名数据卷，用于持久化数据
volumes:
  mysql-data:
  redis-data:

# 定义自定义网络
networks:
  common-network:
    driver: bridge
```

#### 修改 NestJS 应用以适应 Docker Compose
为了让 NestJS 应用能连接到由 Docker Compose 管理的数据库和 Redis，我们需要修改代码，让它从**环境变量**中读取连接信息。

```typescript
// app.module.ts (部分修改)
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
// ...

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: process.env.DB_HOST || 'localhost', // 从环境变量读取，提供默认值
      port: parseInt(process.env.DB_PORT, 10) || 3306,
      username: process.env.DB_USERNAME || 'root',
      password: process.env.DB_PASSWORD || 'your_local_password',
      database: process.env.DB_DATABASE || 'test',
      synchronize: true, // 生产环境慎用
      autoLoadEntities: true,
    }),
    // ...
  ],
  // ...
})
export class AppModule {}
```

#### 一键启动与停止
现在，管理整个应用栈变得异常简单。在项目根目录下执行：

```bash
# 启动所有服务（-d 表示后台运行）
docker compose up -d

# 如果需要重新构建镜像再启动
docker compose up -d --build

# 查看所有服务的日志
docker compose logs -f

# 停止并移除所有相关的容器、网络
docker compose down

# 如果还想删除数据卷
docker compose down -v
```

## Part 4: 总结与命令参考

### 总结
我们通过一个层层递进的旅程，构建了一套强大而优雅的生产环境部署方案。让我们回顾一下每个工具的角色：

*   **Dockerfile**：定义了应用的“标准照”，将应用和其环境固化下来，实现了标准化构建。
*   **PM2** (`pm2-runtime`)：作为容器内的“大内总管”，负责 Node.js 进程的健康、性能（通过集群模式）和日志，是保障应用高可用的核心。
*   **Docker** (`--restart` 策略)：作为容器的“守护神”，提供了最后一道安全防线，确保整个容器在极端情况下也能恢复。
*   **Docker Compose**：作为整个应用栈的“总指挥”，用声明式的方式编排所有服务（应用、数据库、缓存等），解决了服务依赖、网络和数据持久化的复杂问题，实现了一键部署和管理。

将这三者有机结合，你就拥有了一套既稳定可靠，又易于管理和扩展的现代化部署工作流。

### 附录：常用 Docker 命令一览
#### 镜像管理
+ `docker pull <image_name>:<tag>` - 从仓库拉取镜像
+ `docker images` 或 `docker image ls` - 列出本地所有镜像
+ `docker rmi <image_id_or_name>` - 删除本地镜像
+ `docker tag <source_image> <target_image>` - 给镜像打标签
+ `docker push <image_name>:<tag>` - 推送镜像到远程仓库
+ `docker login` - 登录到 Docker 仓库
+ `docker build -t <image_name>:<tag> .` - 构建镜像
+ `docker history <image>` - 查看镜像构建历史
+ `docker save -o <file.tar> <image>` - 导出镜像到文件
+ `docker load -i <file.tar>` - 从文件导入镜像

#### 容器管理
+ `docker run [OPTIONS] IMAGE [COMMAND]` - 创建并启动容器
+ `docker ps` - 列出运行中的容器
+ `docker ps -a` - 列出所有容器（包括已停止）
+ `docker start <container>` - 启动已停止的容器
+ `docker stop <container>` - 停止运行中的容器
+ `docker restart <container>` - 重启容器
+ `docker pause <container>` - 暂停容器
+ `docker unpause <container>` - 恢复暂停的容器
+ `docker rm <container>` - 删除已停止的容器
+ `docker rm -f <container>` - 强制删除容器（⚠️ 不推荐，会发送 SIGKILL 信号强行停止运行中的容器再删除，可能导致数据丢失或状态异常）
+ `docker logs <container>` - 查看容器日志
+ `docker logs -f <container>` - 实时跟踪日志
+ `docker exec -it <container> <command>` - 在容器内执行命令
+ `docker attach <container>` - 连接到运行中的容器
+ `docker inspect <container_or_image>` - 查看详细信息（JSON格式）
+ `docker stats` - 查看容器资源使用情况
+ `docker cp <src> <dest>` - 在容器和主机间复制文件
+ `docker rename <old_name> <new_name>` - 重命名容器

#### 数据卷管理
+ `docker volume ls` - 列出所有数据卷
+ `docker volume create <volume_name>` - 创建数据卷
+ `docker volume rm <volume_name>` - 删除数据卷
+ `docker volume inspect <volume_name>` - 查看数据卷详情
+ `docker volume prune` - 删除未使用的数据卷

#### 网络管理
+ `docker network ls` - 列出所有网络
+ `docker network create <network_name>` - 创建自定义网络
+ `docker network rm <network_name>` - 删除网络
+ `docker network inspect <network_name>` - 查看网络详情
+ `docker network connect <network> <container>` - 连接容器到网络
+ `docker network disconnect <network> <container>` - 断开容器网络连接
+ `docker network prune` - 删除未使用的网络

#### 系统管理
+ `docker info` - 显示 Docker 系统信息
+ `docker version` - 显示版本信息
