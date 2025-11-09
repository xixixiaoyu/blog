想象一下：你辛辛苦苦写好的 Node.js 应用，用 Docker 打包部署后运行良好。但天有不测风云，万一应用因为某个意外错误崩溃，服务停止，用户无法访问，这该怎么办？这时候，自动重启机制就显得至关重要了。

## Docker 自带的重启策略
Docker 本身提供了一套完整的容器重启策略，使用起来非常方便。

首先，我们创建一个会故意崩溃的示例应用来测试重启机制：

```javascript
// index.js
setTimeout(() => {
  throw new Error('Oops, something went wrong!');  // 模拟程序崩溃退出
}, 1000);
```

然后，我们写一个 `Dockerfile` 来打包它：

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY ./index.js .

# 容器启动时直接运行 Node.js 程序
CMD ["node", "/app/index.js"]
```

接着，我们来构建镜像并运行它：

```bash
# 打包镜像
docker build -t restart-test:v1.0 .

# 运行镜像（不加任何重启策略）
docker run -d --name=restart-test-container restart-test:v1.0
```

大约 1 秒后，容器会因为进程退出而停止运行：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748505241010-f1b323b4-1a9e-481f-85ab-0195d9b2ca2f.png)

我们希望它能自动重启。Docker 提供了 `--restart` 参数：

```bash
docker run -d --restart=always --name=restart-test-container2 restart-test:v1.0
```

加上 `--restart=always` 后，你会看到容器 `restart-test-container2` 一直在尝试重启：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748505423798-8dfc39d7-caf7-4b2d-9797-436ea5456232.png)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748505427283-d2459b3e-de88-4712-985f-23406448b91b.png)

如果你想停止这种无限重启，手动 `docker stop restart-test-container2` 就行。

`--restart` 参数还有几个常用的值：

1. **no**（默认）：容器退出后不重启。
2. `on-failure`: 仅在非零退出码时重启，可指定重试次数：

```bash
# on-failure:3，表示最多尝试重启 3 次。
docker run -d --restart=on-failure:3 --name=test restart-test:v1.0
```

3. `unless-stopped`: 除非手动停止，否则总是重启。
4. **always**：总是重启，即使 Docker 服务重启后也会自动启动容器

**推荐使用 **`**unless-stopped**`，它在大多数场景下比 `always` 更合适。



## PM2：专业的 Node 进程管理
PM2 是 Node 生态中最流行的进程管理器，提供进程级别的重启和监控功能。

现在，我们想在 Docker 容器里用 PM2 来管理我们的 `index.js`。可以这样写 `Dockerfile`：

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY ./index.js .

# 安装 PM2
RUN npm install -g pm2

# 使用 pm2-runtime 在前台运行，适合 Docker 环境
CMD ["pm2-runtime", "/app/index.js"]
```

构建并运行这个新镜像：

```bash
# 使用 pm2.Dockerfile 构建镜像
docker build -t restart-test:v2.0 -f pm2.Dockerfile .

# 运行镜像
docker run -d --name=restart-test-container3 restart-test:v2.0
```

这次容器会持续运行，PM2 会在应用崩溃时自动重启 Node.js 进程：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748506397999-88fd21b6-129a-48fa-8306-30bdede0a2d3.png)



## Docker 重启 vs PM2 重启：到底用哪个？
**简单部署场景**：大多数情况下部署一个 Node 应用，使用 Docker 的 `--restart=unless-stopped` 策略就行了。

**容器编排环境**：如果使用像 Kubernetes (K8s) 这样的容器编排工具，依赖自身的重启和健康检查机制来管理容器的生命周期即可。K8s 会监控 Pod（里面可以包含一个或多个容器），并在容器失败时根据定义的策略进行重启。

**混合场景**：**优先使用 Docker 或容器编排工具的重启机制**，如果你的应用确实需要 PM2 提供的其他高级功能 (如集群模式、日志管理、监控等)，那么再考虑在容器内使用 PM2，并且可以考虑将 Docker 的 `--restart` 策略设置为 `on-failure`：

```bash
# PM2 管理进程重启，Docker 在 PM2 失效时重启容器
docker run -d --restart=on-failure:3 --name=app restart-test:v2.0
```

当 PM2 本身也无法恢复应用时，Docker 还能最后尝试重启整个容器。



## Docker Compose 中的重启配置
如果你用 Docker Compose 来组织和运行多个容器服务，配置重启策略也很简单。

在你的 `docker-compose.yml` 文件里，可以为每个服务指定 `restart` 策略：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748517438633-4aa1186b-d6d0-4278-8f1e-23f9c77f9827.png)

