开发 Node.js 应用的时候，本地调试一切正常，但一部署到服务器上，各种问题就来了：应用突然崩溃了怎么办？能不能自动重启？日志怎么管理？多核 CPU 怎么充分利用？这些问题，PM2 全都能帮你解决。

PM2 (Process Manager 2) 就像是专门为 Node 应用配备的贴身管家，它能管理进程、记录日志、实现负载均衡，还能实时监控应用状态。

有了它，你的应用在生产环境中就能真正做到稳如磐石。

## 快速上手：安装和启动
首先，全局安装它：

```bash
sudo npm install pm2 -g
```

1. 接下来我们用一个 NestJS 项目来演示：

```bash
nest new pm2-test -p pnpm
```

2. 进入项目目录并编译项目：

```bash
# 进入项目目录并构建
cd pm2-test
pnpm run build

# 用 PM2 启动应用
pm2 start ./dist/main.js
```

现在你的应用已经在 PM2 的保护下运行了。PM2 会给每个进程分配一个 ID 和名字，方便你后续管理：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748531964008-042260a9-642b-449a-ae71-3c067e9802a8.png)



## 日志管理：应用运行状况一目了然
想知道应用跑得怎么样，看日志是最直接的方式。PM2 提供了很方便的日志查看功能：

```bash
pm2 logs
```

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748532016227-96127bda-b98e-4d5e-8f82-74c9961fe221.png)

这个命令会把 PM2 管理的所有进程的实时日志都打印出来。

为了区分是哪个应用的日志，每条日志前面都会有类似 `0|main` 这样的标记，`0` 代表进程 ID，`main` 代表进程名（默认是你的入口文件名，不含后缀）。

PM2 会很贴心地把不同进程的日志分别存到文件里，这些日志文件通常在用户目录下的 `.pm2/logs` 文件夹中：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748532131569-e49fbf00-eaca-4eb9-9876-8d410dd42f75.png)

比如，名为 `main` 的进程，它的标准输出日志会存为 `main-out.log`，错误日志会存为 `main-error.log`。

想看某个具体进程的日志文件内容，可以用 `cat` 命令，例如：

```bash
cat ~/.pm2/logs/main-out.log
```

当然，PM2 也提供了更直接的方式查看特定进程的日志：

```bash
pm2 logs main       # 按进程名查看
pm2 logs 0          # 按进程 ID 查看
```

如果日志太多，想清空一下，可以用：

```bash
pm2 flush           # 清空所有日志
pm2 flush main      # 清空 main 进程的日志
pm2 flush 0         # 清空 ID 为 0 的进程的日志
```

只想看最近的日志？也没问题，比如查看 `main` 进程最新的 100 行日志：

```bash
pm2 logs main --lines 100
```



## 进程管理：让应用永不宕机
PM2 最强大的地方就是进程管理。它能帮你应对各种意外情况：

### 自动重启策略
```bash
# 内存超限重启（超过 100MB 就重启），--name myApp 给应用起了个别名，方便管理
pm2 start app.js --name myApp --max-memory-restart 100M

# 定时重启（每天凌晨重启，使用了 cron 表达式）
pm2 start app.js --name myApp --cron-restart="0 0 * * *"

# 文件变化时重启（开发时很有用）
pm2 start app.js --name myApp --watch

# 禁止自动重启
pm2 start app.js --name myApp --no-autorestart
```

### 基本操作命令
```bash
# 查看所有进程状态
pm2 list

# 停止和删除进程
pm2 stop all        # 停止所有
pm2 delete all      # 删除所有
pm2 stop app_name_or_id      # 停止指定名称或 ID 进程
pm2 delete app_name_or_id    # 删除指定名称或 ID 的进程

# 重启进程
pm2 restart myApp
pm2 reload myApp    # 优雅重启，不中断服务
```



## 负载均衡：榨干多核 CPU 的性能
Node 默认只使用单核 CPU，这在高并发场景下显然不够用。PM2 基于 cluster 模块，可以轻松启动多个进程来共同处理请求：

只需要在启动命令上加一个 `-i` 参数：

```bash
pm2 start app.js -i max     # PM2 会根据 CPU 核心数自动决定启动多少个进程
# 或者
pm2 start app.js -i 0       # 效果同 max，动态设置进程数
# 或者，指定具体数量，比如启动 4 个进程
pm2 start app.js -i 4
```

比如，在我的 8 核 CPU 电脑上执行 `pm2 start ./dist/main.js -i max --name nest-cluster`，PM2 就会启动 8 个 `nest-cluster` 进程：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748533568460-9f698a51-7251-45e6-a61b-061339df56a4.png)

应用跑起来之后，你还可以动态调整进程数量，用 `pm2 scale` 命令：

把 `nest-cluster` 应用的进程数调整为 1 个：

```bash
pm2 scale nest-cluster 1
```

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748533617080-0afded53-5967-471f-afb2-ad27c4260d27.png)

在现有基础上增加 3 个进程：

```bash
pm2 scale nest-cluster +3
```

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748533632519-74c65363-8851-45a0-b5a6-5a95aba9a3fb.png)

现在变成 4 个进程了，通过这些方式可以动态伸缩进程的数量，PM2 会自动把进来的请求分发到这些进程上，这就是负载均衡的能力。

可以通过 `pm2 list` 命令查看所有 PM2 管理的应用程序及其状态：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748533795589-365f847e-ea9a-4f64-baeb-834142d67b8b.png)



## 实时监控：掌握应用健康状态
想了解应用的资源使用情况，用这个命令：

```bash
pm2 monit
```

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748533825107-b29bad3b-3f6a-4e56-9574-5075f22087ad.png)

它会打开一个实时监控面板，显示每个进程的 CPU 使用率、内存占用等关键指标，让你对应用状态心中有数。



## 配置文件：批量管理应用
当你需要管理多个应用时，一个个敲命令就太麻烦了。PM2 支持配置文件管理：

```bash
# 生成配置文件模板
pm2 ecosystem
```

这会创建一个 `ecosystem.config.js` 文件：

```javascript
module.exports = {
  apps : [{
    name   : "app1",
    script : "./app.js",
    instances: "max", // 或者具体的数字，比如 4
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: { // 普通环境变量
      NODE_ENV: "development",
    },
    env_production : { // 生产环境变量
      NODE_ENV: "production",
    }
  },{
    name   : "api-server",
    script : "./api/server.js",
    // ...更多配置
  }]
};
```

你可以把之前命令行里的各种启动参数都写到这个配置文件里。

然后，只需要一条命令就能启动所有定义好的应用：

```bash
# 启动所有应用
pm2 start ecosystem.config.js
```

如果只想启动生产环境配置的应用：

```bash
pm2 start ecosystem.config.js --env production
```



## PM2 Plus：云端监控升级版
PM2 还提供了一个可选的云端监控服务 PM2 Plus (现在也叫 PM2 Enterprise 或者 Keymetrics)。

1. 访问 [PM2 网站](https://id.keymetrics.io/api/oauth/login)，登录并创建一个 Bucket：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748534021681-e0ad123e-72b5-4c3d-a8b1-b5245cf5eb45.png)

2. 你会得到一条类似 `pm2 link xxx` 的命令：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748708405407-6daddbf5-66ba-43b8-a31b-7aa92f368a12.png)

3. 然后执行：

```bash
pm2 plus
```

这个命令通常会打开一个网页，你就可以在那个网页上实时监控你本地（或服务器上）PM2 管理的应用了：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748534071759-069a80bf-77be-4ccb-8fa6-c9c196458aaa.png)

很直观。



## Docker 与 PM2：黄金搭档
在 Docker 容器中使用 PM2 时，关键是用 `pm2-runtime` 而不是直接用 `node`。

比如，一个之前用 `node` 启动的 Nest 应用的 Dockerfile 可能是这样的：

```bash
# ... (省略了 Node 安装、拷贝文件、安装依赖等步骤)
# CMD [ "node", "dist/main.js" ]
```

要结合 PM2，你需要先在 Dockerfile 中全局安装 PM2，然后把 `CMD` 改成使用 `pm2-runtime`：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748534241919-475213f8-d3e2-49dc-b27a-b2fbeae837ea.png)

然后构建并运行你的 Docker 镜像：

```bash
docker build -t nest-pm2-test:v1.0 .
docker run -p 3000:3000 -d nest-pm2-test:v1.0
```

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748534266475-32bd8c98-4131-4ff1-a25e-16a57849064d.png)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748534274671-81ff7624-9bd2-4cd2-bb4d-1c01d61479a4.png)

现在，运行在 Docker 容器里的 Node 应用如果崩溃了，PM2 会自动把它拉起来。

你也可以通过 `docker logs <container_id>` 查看 PM2 打印的日志。

如果需要进入容器内部执行 PM2 命令（比如 `pm2 list`），可以使用 `docker exec -it <container_id> sh`，然后在容器的 shell 里执行 PM2 命令。

