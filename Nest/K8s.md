## 我们为什么需要 Kubernetes？

在 K8s 出现之前，我们是怎么部署应用的？

可能是在一台服务器上手动安装、配置、运行。后来应用变多了，服务器也变多了，问题就来了：

*   **资源浪费**：一台服务器可能只跑了一个小应用，CPU 和内存大量闲置。
*   **故障影响大**：这台服务器宕机，上面的应用就全挂了。
*   **扩容缩容难**：流量高峰来了，想快速增加 10 个应用实例，怎么办？手动再部署 10 台服务器吗？流量过去了，这些多余的资源又怎么处理？
*   **环境不一致**：开发环境、测试环境、生产环境配置总有差异，导致“在我电脑上是好的”这类问题。

当我们面对一个现代 Web 应用（比如用 Nest.js 构建的）时，这些挑战会变得更加具体：

*   **高可用性**：如果运行应用的服务器宕机了，服务就中断了。我们希望有备用机能自动接管。
*   **可扩展性**：在双十一这样的流量高峰期，我们希望能快速增加应用实例来分担压力；高峰过后，再自动缩减，节省资源。
*   **自我修复**：如果某个应用实例崩溃了，我们希望系统能自动检测并重启它，而不是需要人工半夜起来运维。
*   **零停机部署**：我们发布新版本时，不希望中断用户的服务。希望新版本启动成功后，再优雅地关闭旧版本。

手动管理这一切会变得极其复杂。而 **Kubernetes (K8s)**，正是为了解决这些问题而生的。它是一个**容器编排平台**，你可以把它想象成一个**专门为“集群”设计的操作系统**，或者一个经验丰富的“交响乐团总指挥”。

它只关心：

1.  你要运行几个应用实例？
2.  它们需要多少 CPU 和内存？
3.  应用之间如何互相访问？
4.  如何保证它们一直健康地运行？

---

## 核心隐喻：把 K8s 集群想象成一个自动化集装箱码头

为了更好地理解 K8s，让我们想象一个巨大、繁忙的自动化集装箱码头：

*   **整个码头**：就是 K8s 的 **Cluster（集群）**，是所有资源的总和。
*   **码头里的各种吊车、卡车、工人**：就是集群里的 **Node（节点）**，通常是一台物理机或虚拟机，是真正干活的。
*   **码头的中央调度系统**：就是 K8s 的 **Master（或称 Control Plane）**。它是整个码头的大脑，负责接收指令、监控所有节点和集装箱的状态、并指挥吊车（Node）把集装箱（Pod）放到合适的地方。
*   **标准化的集装箱**：就是 **容器（Container）**，比如 Docker 容器，它们封装了应用及其所有依赖。

现在，你是一个货主，要把一批货物（你的应用）运到这个码头。你不需要亲自去指挥吊车，你只需要填写一张“货运需求单”（YAML 文件），告诉调度系统你的“期望状态”。K8s 会自动化地让现实状态向你的期望状态靠拢。

这张“需求单”由 K8s 的核心概念（“乐高积木”）构成。

---

## 核心概念：Kubernetes 的“乐高积木”

要指挥 K8s，我们得先学会它的基本指令。下面是几个最核心的概念：

#### 1. Pod：最小的部署单元

*   **本质**：K8s 中**可以创建和管理的最小单元**。它像是一个“豆荚”或“包装盒”，里面包裹着一个或多个紧密协作的容器。
*   **类比**：一个“包装盒”。我们的 Nest.js 应用容器就被装在这个盒子里。同一个 Pod 内的容器共享网络 IP 和存储资源，可以像在同一台机器上一样通过 `localhost` 通信。
*   **为什么需要 Pod？** 因为有些容器必须“绑”在一起，比如主应用容器和它的日志收集容器，它们必须被调度到同一个节点上。Pod 是短暂的，可能会被创建或销毁，所以我们不直接操作它。

#### 2. Deployment：应用的“蓝图”与“控制器”

*   **本质**：管理 Pod 的“蓝图”和“控制器”。这是我们最常提交的“货运需求单”之一。它声明了应用的期望状态。
*   **类比**：一份“产品说明书”。你告诉 K8s：“请按照这份说明书，帮我维护 3 个一模一样的 Nest.js 应用 Pod。” 如果某个 Pod 挂了，Deployment 会自动创建一个新的来替代（**自愈能力**）。当你更新应用版本时，Deployment 会负责平滑的滚动更新。

#### 3. Service：稳定的“访问入口”

*   **本质**：为一组功能相同的 Pod 提供一个**稳定、统一的访问入口**（一个固定的虚拟 IP 和 DNS 名称）。
*   **类比**：公司的“前台电话”。Pod 的 IP 地址会随着销毁和重建而改变，但 Service 的地址是固定的。外部请求或者集群内的其他服务想访问我们的 Nest.js 应用，只需要拨打这个“前台电话”，Service 会自动将请求转接到一个健康的 Pod 上。

#### 4. Ingress：集群的“大门保安”

*   **本质**：管理集群**外部流量**如何访问到内部的 Service。它通常基于 URL 路径或域名进行路由。
*   **类比**：公司大楼的“大门保安”。当外部请求（比如 `https://api.example.com/users`）到达时，Ingress 会根据规则，将其引导到正确的 Service（比如我们的 Nest.js 用户服务），而无需为每个 Service 都暴露一个昂贵的外部 IP。

---

## 实战演练：将 Nest.js 应用部署到 Kubernetes

理论讲完了，让我们动手把一个简单的 Nest.js 应用部署到 K8s 上。

#### 第 0 步：准备一个简单的 Nest.js 应用

假设你已经有一个 Nest.js 项目，并且它监听在 `3000` 端口。

#### 第 1 步：容器化 —— 编写 Dockerfile

K8s 运行的是容器镜像，所以第一步是把我们的应用打包成 Docker 镜像。在项目根目录创建 `Dockerfile`：

```dockerfile
# 多阶段构建：第一阶段构建应用
# 为什么用多阶段构建？ -> 为了让最终镜像更小、更安全，只包含运行时需要的文件。
FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
# 为什么用 pnpm? -> 更快的安装速度和更高效的磁盘空间利用，是现代 Node.js 项目的优选。
RUN corepack enable pnpm && pnpm install --frozen-lockfile

COPY . .
RUN pnpm run build


# 第二阶段：运行应用（仅安装生产依赖）
FROM node:20-alpine

WORKDIR /app

# 仅安装生产依赖，避免将开发依赖带入运行时镜像
COPY package.json pnpm-lock.yaml ./
RUN corepack enable pnpm && pnpm install --frozen-lockfile --prod

# 复制构建产物
COPY --from=builder /app/dist ./dist

# 为什么用非 root 用户？ -> 安全最佳实践，减小潜在的安全风险。
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001
USER nestjs

EXPOSE 3000

CMD ["node", "dist/main.js"]
```

构建镜像并推送到镜像仓库（如 Docker Hub, ACR, GCR 等）：
```bash
# 请将 your-username/nestjs-k8s-demo 替换为你自己的镜像名
docker build -t your-username/nestjs-k8s-demo:v1 .
docker push your-username/nestjs-k8s-demo:v1
```

#### 第 2 步：编写 Kubernetes 清单文件

现在，我们用 YAML 语言来告诉 K8s 如何部署我们的应用。创建两个文件：`deployment.yaml` 和 `service.yaml`。

**`deployment.yaml`**

```yaml
# apiVersion: 为什么是 apps/v1？因为 Deployment 是在 apps/v1 这个 API 组中定义的。
apiVersion: apps/v1
# kind: 为什么是 Deployment？因为我们想要一个自愈、可伸缩的应用。
kind: Deployment
metadata:
  name: nestjs-app-deployment # 给这个 Deployment 起个名字，方便管理
spec:
  # replicas: 为什么是 3？为了高可用性，如果一个挂了，还有两个在运行。
  replicas: 3
  # selector: 为什么需要 selector？为了让 Deployment 知道它应该管理哪些 Pod。
  selector:
    matchLabels:
      app: nestjs-app
  # template: 这是 Pod 的模板，Deployment 会根据它来创建 Pod。
  template:
    metadata:
      # labels: 为什么这里要加标签？为了与上面的 selector 匹配，建立管理关系。
      labels:
        app: nestjs-app
    spec:
      containers:
        - name: nestjs-app-container
          # image: 为什么指定版本？为了保证环境的一致性和可复现性。
          image: your-username/nestjs-k8s-demo:v1 # 使用我们刚才推送的镜像
          ports:
            - containerPort: 3000 # 容器内部监听的端口
```

**`service.yaml`**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nestjs-app-service # 给这个 Service 起个名字
spec:
  # type: ClusterIP 是默认类型，仅在集群内部可访问。适合作为后端服务。
  # 其他类型还有 NodePort（在每个节点上暴露端口）和 LoadBalancer（使用云服务商的负载均衡器）。
  type: ClusterIP
  # selector: Service 如何知道要将流量发送到哪些 Pod（通过标签匹配）。
  selector:
    app: nestjs-app
  ports:
    - protocol: TCP
      port: 80 # Service 自身暴露的端口
      targetPort: 3000 # 流量最终转发到 Pod 的容器端口
```

#### 第 3 步：部署与验证

确保你已经配置好了 `kubectl` 并连接到了一个 K8s 集群（本地可以用 Minikube 或 Docker Desktop 自带的 K8s）。

1.  **应用配置**：
    ```bash
    kubectl apply -f deployment.yaml
    kubectl apply -f service.yaml
    ```

2.  **查看状态**：
    ```bash
    # 查看 Deployment 状态，确保 READY 是 3/3
    kubectl get deployments
    
    # 查看 Pod 状态，确保它们都在 RUNNING
    kubectl get pods
    
    # 查看 Service 状态，获取 CLUSTER-IP
    kubectl get services
    ```

3.  **验证连接**：
    你可以在集群内创建一个临时的 Pod 来访问我们的 Service：
    ```bash
    # 运行一个临时的 curl Pod，并在命令结束后自动删除它
    kubectl run -it --rm debug-pod --image=curlimages/curl -- sh
    
    # 进入临时 Pod 后，通过 Service 的名称访问应用
    # K8s 内部提供了 DNS 解析，可以直接使用 service name 作为域名
    curl http://nestjs-app-service
    
    # 你应该能看到你的 Nest.js 应用返回的响应
    ```

---

## 总结与展望

恭喜你！你已经成功地将 Nest.js 应用部署到了 Kubernetes 集群中。

K8s 的核心，就是**“声明式”的“期望状态管理”**。你不需要告诉它“第一步做什么，第二步做什么”，你只需要告诉它“我最终想要什么样子”，它就会像一个尽职尽责的管家，调动所有资源，并持续不断地维持这个状态。

我们回顾一下整个过程：

1.  **理解了为什么**：K8s 解决了高可用、可扩展、自我修复等核心运维问题。
2.  **掌握了核心概念**：Pod（最小单元）、Deployment（管理 Pod）、Service（稳定入口）和 Ingress（外部网关）。
3.  **完成了实践**：通过编写 `Dockerfile`、`deployment.yaml` 和 `service.yaml`，将应用容器化并部署到 K8s。

这只是第一步。接下来，你还可以探索：

*   **Ingress**：如何让外部用户通过域名访问你的服务。
*   **ConfigMap & Secret**：如何管理应用配置和敏感信息。
*   **PersistentVolume**：如何为需要持久化存储的应用（如文件上传）提供存储。
*   **Liveness & Readiness Probes**：如何更精细地控制 Pod 的健康状态检查。

现在，我想把问题抛回给你：

> 如果你现在更新了 Nest.js 应用的代码，并构建了一个新版本的 Docker 镜像（比如 `v2`），你觉得该如何更新 Deployment，让 K8s 用新镜像替换掉旧的 Pod 呢？

思考一下这个过程，你会对 K8s 的“声明式”和“滚动更新”有更深的理解。
