在日常的开发和部署工作中，经常会遇到需要同时跑好几个服务的情况。

比如一个 Web 应用，可能需要一个后端服务、一个数据库服务，可能还会加上一个缓存服务像 Redis。

如果这些服务都用 Docker 容器来跑，那手动一个一个去 `docker run`，还要配置它们之间的网络连接、数据共享，想想就有点麻烦。

这时候，Docker Compose 就派上用场了。

**Docker Compose** 是一个帮你轻松定义和运行多个 Docker 容器应用的工具。

你只需要一个叫做 `docker-compose.yml` 的 YAML 文件，把你的应用需要哪些服务、它们怎么配置、怎么连接都写清楚，然后一条命令就能把所有服务都启动起来。

管理起来也特别方便，比如一起启动、一起停止、查看日志等等。

## Docker Compose 的基本构成
在 `docker-compose.yml` 文件里，主要有几个概念：

1. **Services (服务)**：这就是应用的核心。每个服务都会运行在一个或多个 Docker 容器里。比如，Nest 应用是一个服务，MySQL 数据库是另一个服务，Redis 也是一个服务。
2. **Networks (网络)**：可以给这些服务指定特定的网络，这样就能控制容器之间怎么通信了。比如，让 Nest 应用能够找到并连接到 MySQL 服务。
3. **Volumes (数据卷)**：如果希望数据能够在容器重启后依然存在（持久化），或者在多个容器间共享数据，就需要用到数据卷。比如，MySQL 的数据文件就应该存放在数据卷里。



## 🌰 用 Docker Compose 部署 NestJS + MySQL + Redis 应用
### 1. 准备 Nest 项目
假设我们已经有了一个 NestJS 项目，并且在本地开发环境中配置好了 MySQL 和 Redis。

创建 Nest 项目：

```bash
nest new docker-compose-test -p pnpm
cd docker-compose-test
```

安装依赖：

```bash
pnpm install @nestjs/typeorm typeorm mysql2 redis
```

在 MySQL Workbench 或者其他数据库工具里创建一个数据库，比如叫 `test`。

```sql
CREATE DATABASE `test` DEFAULT CHARACTER SET utf8mb4;
```

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748444419091-1884103c-0661-42e5-9519-ee069aac1c0c.png)

配置 `AppModule.ts` 连接 MySQL 和 Redis。**TypeORM (MySQL) 配置示例：**

```typescript
// app.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { Test } from './test.entity'; // 假设你创建了一个 Test 实体
import { createClient } from 'redis'; // 引入 redis

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: 'localhost', // 本地开发时通常是 localhost
      port: 3306,
      username: 'root', // 你的 MySQL 用户名
      password: 'xxx',  // 你的 MySQL 密码
      database: 'test',
      synchronize: true, // 开发环境方便，生产环境慎用
      logging: true,
      entities: [Test], // 注册实体
      poolSize: 10,
      connectorPackage: 'mysql2',
      extra: {
        authPlugin: 'sha256_password',
      },
    }),
  ],
  controllers: [AppController],
  providers: [
    AppService,
    // Redis Provider 示例
    {
      provide: 'REDIS_CLIENT',
      async useFactory() {
        const client = createClient({
          socket: {
            host: 'localhost', // 本地开发时
            port: 6379,
          },
        });
        await client.connect();
        return client;
      },
    },
  ],
})
export class AppModule {}
```

创建一个简单的实体 `src/test.entity.ts`：

```typescript
// src/test.entity.ts
import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity()
export class Test {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column()
  email: string;
}
```

在 `AppModule` 的 `entities` 数组中注册它：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748444482379-190ea5c1-b9af-485b-9b0a-fbb0385393b9.png)

启动 Nest 服务：

```bash
pnpm start:dev
```

在本地，如果你的 MySQL 和 Redis 服务都正常运行并且配置正确，那么 Nest 应用应该能成功连接它们。

你可以在 `AppController` 里注入 `REDIS_CLIENT` 和 TypeORM 的 `Repository` 来测试连接：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748444750360-4f780130-7ab6-4295-a864-23fee0ec7bec.png)

这说明 mysql 服务没问题。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748444681357-751ad5aa-b2c5-4414-a55a-4434adc136f6.png)

访问下 [http://localhost:3000](https://link.juejin.cn/?target=http%3A%2F%2Flocalhost%3A3000) 后。

服务端打印了 redis 里的 key：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748444783140-eaed249d-3a80-4d8e-a0ad-b5e5b1e02caa.png)

这说明 redis 服务连接成功了。



### 2. 如果没有 Docker Compose，部署会怎么样？
好了，假设我们的 Nest 服务在本地开发测试都没问题了，现在想把它容器化部署。

首先，我们需要为 Nest 应用写一个 `Dockerfile`：

```dockerfile
# Step 1: 使用带有 Node.js 的基础镜像作为构建环境
FROM node:18-alpine as builder

# 设置工作目录
WORKDIR /usr/src/app

# 复制 package.json 和 package-lock.json (如果可用)
COPY package*.json ./

# 安装依赖
RUN npm install

# 复制所有文件到容器中
COPY . .

# 构建应用程序
RUN npm run build

# Step 2: 运行时使用更精简的基础镜像
FROM node:18-alpine

WORKDIR /usr/src/app

# 从 builder 阶段复制构建好的文件
COPY --from=builder /usr/src/app/dist ./dist
# 复制 package.json 和 lock 文件
COPY package*.json ./

# 只安装生产依赖
RUN npm install --only=production

# 暴露 3000 端口
EXPOSE 3000

# 运行 Nest.js 应用程序
CMD ["node", "dist/main"]
```

然后，我们需要分别启动 MySQL、Redis 和 Nest 应用的容器：

1. 启动 MySQL 容器。
2. 启动 Redis 容器。
3. 构建 Nest 应用的镜像：`docker build -t nest-app-image .`
4. 启动 Nest 应用容器。

这时候问题就来了：在 Nest 应用的容器内部，`localhost` 指的是 Nest 容器自己，它找不到宿主机上或者其他独立容器里的 MySQL 和 Redis 服务！你可能会看到连接错误，比如 `connect ECONNREFUSED 127.0.0.1:6379`：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748445576968-a5fdc65c-7436-40c9-bf9e-d492d93688c7.png)

一个“笨”办法（更好的方法是利用 Docker 的自定义桥接网络）：在 Nest 应用的配置里，把 MySQL 和 Redis 的 `host` 改成宿主机的 IP 地址（比如通过 `ifconfig` 或 `ip addr` 查到的 `192.168.x.x` 这样的地址，mac 看看 en0）。

但这非常不灵活，每次部署环境变化都可能要改代码。而且，容器的启动顺序也得我们自己控制。

### 3. 引入 Docker Compose，优雅解决
有了 Docker Compose，事情就简单多了。

我们在项目根目录下创建一个 `docker-compose.yml` 文件：

```yaml
version: '3.8' # 推荐使用较新的版本号，比如 '3.8'

services:
  # 定义 NestJS 应用服务
  nest-app:
    build:
      context: ./ # Dockerfile 的上下文路径，就是当前目录
      dockerfile: Dockerfile # Dockerfile 的文件名
    ports:
      - '3000:3000' # 将宿主机的 3000 端口映射到容器的 3000 端口
    depends_on: # 定义依赖关系，确保 mysql 和 redis 先启动
      - mysql-container
      - redis-container
    environment: # 环境变量可以传递给 Nest 应用，用于配置
      DB_HOST: mysql-container # 注意这里！我们用服务名作为 host
      DB_PORT: 3306
      DB_USERNAME: root
      DB_PASSWORD: yoursecurepassword # 保持和 mysql-container 一致
      DB_DATABASE: test
      REDIS_HOST: redis-container # 同样使用服务名
      REDIS_PORT: 6379
    # networks: # 如果使用自定义网络，在这里指定
    #   - common-network

  # 定义 MySQL 服务
  mysql-container:
    image: mysql:8.0 # 使用官方 MySQL 8.0 镜像
    ports:
      - '3306:3306' # 映射端口，方便从宿主机访问（可选）
    environment:
      MYSQL_ROOT_PASSWORD: yoursecurepassword # 设置 root 密码
      MYSQL_DATABASE: test # 启动时自动创建 test 数据库
    volumes:
      - mysql-data:/var/lib/mysql # 数据持久化，mysql-data 是一个具名数据卷
    # networks:
    #   - common-network

  # 定义 Redis 服务
  redis-container:
    image: redis:alpine # 使用官方 Redis Alpine 镜像
    ports:
      - '6379:6379' # 映射端口（可选）
    volumes:
      - redis-data:/data # 数据持久化
    # networks:
    #   - common-network

# 定义具名数据卷，用于持久化数据
volumes:
  mysql-data:
  redis-data:

# (可选) 定义自定义网络
# networks:
#   common-network:
#     driver: bridge
```

**每个 services 都是一个 docker 容器，名字随便指定。**

改动：在 `AppModule.ts` 中，我们需要修改数据库和 Redis 的连接配置，让它们从环境变量中读取 `host`：

```typescript
// app.module.ts (部分修改)
// ...
TypeOrmModule.forRoot({
  type: 'mysql',
  host: process.env.DB_HOST || 'localhost', // 从环境变量读取，提供默认值
  port: parseInt(process.env.DB_PORT) || 3306,
  username: process.env.DB_USERNAME || 'root',
  password: process.env.DB_PASSWORD || 'xxx',
  database: process.env.DB_DATABASE || 'test',
  // ... 其他配置保持不变
}),
// ...
// Redis Provider (部分修改)
{
  provide: 'REDIS_CLIENT',
  async useFactory() {
    const client = createClient({
      socket: {
        host: process.env.REDIS_HOST || 'localhost', // 从环境变量读取
        port: parseInt(process.env.REDIS_PORT) || 6379,
      },
    });
    await client.connect();
    return client;
  },
},
// ...
```

现在，我们只需要在项目根目录下运行：

```bash
docker-compose up
```

Docker Compose 会自动：

1. 读取 `docker-compose.yml` 文件。
2. 根据 `depends_on` 的设置，先启动 `mysql-container` 和 `redis-container` 服务。
3. 然后，它会根据 `nest-app` 服务的 `build` 配置，构建 Docker 镜像（如果镜像不存在或需要更新）。
4. 最后启动 `nest-app` 服务。
5. 所有服务的日志会一起输出到控制台。

如果想在后台运行，并强制重新构建镜像和容器：

```bash
docker-compose up -d --build --force-recreate
```

+ `-d`: 后台运行 (Detached mode)。
+ `--build`: 启动前强制重新构建服务的镜像。
+ `--force-recreate`: 即使容器配置没变，也强制重新创建容器。

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748446010428-2cd7f003-e064-4d5f-9626-2314175f7f59.png)

现在，访问 `http://localhost:3000`：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748446061047-a70fa4f4-2a9c-4300-ab40-1ee16cf3d6a8.png)

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748446066024-700d6a18-e00d-43d0-957d-7d258c228068.png)

Nest 容器内打印了 Redis 的 key。

要停止并移除所有相关的容器、网络：

```bash
docker-compose down
```

如果还想把构建的镜像也删掉：

```bash
docker-compose down --rmi all
```



## 🌐 Docker Compose 与桥接网络 (Bridge Network)
<font style="color:rgb(38, 38, 38);">在使用 Docker Compose 时，我们经常在 </font>`<font style="color:rgb(38, 38, 38);background-color:rgba(175, 184, 193, 0.2);">docker-compose.yml</font>`<font style="color:rgb(38, 38, 38);"> 的 </font>`<font style="color:rgb(38, 38, 38);background-color:rgba(175, 184, 193, 0.2);">environment</font>`<font style="color:rgb(38, 38, 38);"> 部分看到这样的配置：</font>

```yaml
DB_HOST: mysql-container
REDIS_HOST: redis-container
```

<font style="color:rgb(38, 38, 38);">这允许我们的应用程序直接使用服务名作为主机名来连接数据库或缓存。这是如何实现的呢？答案在于 Docker Compose 强大的网络功能。</font>

###  🌉 默认的桥接网络
<font style="color:rgb(38, 38, 38);">当你运行 </font>`<font style="color:rgb(38, 38, 38);background-color:rgba(175, 184, 193, 0.2);">docker-compose up</font>`<font style="color:rgb(38, 38, 38);"> 时，Docker Compose 会自动执行以下操作：</font>

1. **创建默认网络：** 它会自动创建一个**桥接网络 (bridge network)**。
2. **<font style="color:rgb(38, 38, 38);">连接服务</font>**<font style="color:rgb(38, 38, 38);">：将 </font>`<font style="color:rgb(38, 38, 38);background-color:rgba(175, 184, 193, 0.2);">docker-compose.yml</font>`<font style="color:rgb(38, 38, 38);"> 文件中定义的所有服务（容器）连接到这个网络</font>
3. **启****<font style="color:rgb(38, 38, 38);">启用服务发现</font>**<font style="color:rgb(38, 38, 38);">：在网络内部提供内置的 DNS 服务，每个容器都可以通过服务名（如 </font>`<font style="color:rgb(38, 38, 38);background-color:rgba(175, 184, 193, 0.2);">mysql-container</font>`<font style="color:rgb(38, 38, 38);">、</font>`<font style="color:rgb(38, 38, 38);background-color:rgba(175, 184, 193, 0.2);">redis-container</font>`<font style="color:rgb(38, 38, 38);">）作为主机名访问其他容器</font>

> <font style="color:rgb(89, 89, 89);">💡</font><font style="color:rgb(89, 89, 89);"> </font>**<font style="color:rgb(89, 89, 89);">网络命名规则</font>**<font style="color:rgb(89, 89, 89);">：默认网络名称遵循 </font>`<font style="color:rgb(89, 89, 89);background-color:rgba(175, 184, 193, 0.2);">项目目录名_default</font>`<font style="color:rgb(89, 89, 89);"> 的格式。例如，项目目录为 </font>`<font style="color:rgb(89, 89, 89);background-color:rgba(175, 184, 193, 0.2);">my-nest-project</font>`<font style="color:rgb(89, 89, 89);">，则网络名为 </font>`<font style="color:rgb(89, 89, 89);background-color:rgba(175, 184, 193, 0.2);">my-nest-project_default</font>`<font style="color:rgb(89, 89, 89);">。</font>
>

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748450820490-b4896f49-d7fd-46c1-b44e-cb19cec22d6e.png)

**对于大多数场景来说，这个默认网络已经足够满足需求了。** <font style="color:rgb(38, 38, 38);">无需进行任何特殊配置即可实现容器间通信。</font>

<font style="color:rgb(38, 38, 38);"></font>

### 🛠️ 自定义网络
<font style="color:rgb(38, 38, 38);">虽然默认网络很方便，但在某些情况下我们需要更精细的网络控制，或让多个 Docker Compose 项目共享同一网络。</font>

#### 使用外部网络 (External Network)
1. 如果想让服务连接到一个**已经存在**的网络，使用 `external: true`。
2. 创建一个网络：

```bash
docker network create common-network
```

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748450434120-8ac5e17c-ac4c-4184-a6a3-5fa0e352e29d.png)

3. 修改 `docker-compose.yml`，让所有服务都使用这个网络：

```yaml
version: '3.8'

services:
  nest-app:
    # ... 其他配置 ...
    networks:
      - common-network # 指定使用 common-network

  mysql-container:
    # ... 其他配置 ...
    networks:
      - common-network # 指定使用 common-network

  redis-container:
    # ... 其他配置 ...
    networks:
      - common-network # 指定使用 common-network

networks:
  common-network:
    external: true # 关键：表明这是一个外部已存在的网络
```

这时 Nest 也能用服务名 `mysql-container` 和 `redis-container` 作为主机名：

![](https://cdn.nlark.com/yuque/0/2025/png/21596389/1748450497987-a1c419e9-cb2f-47bb-8ad5-10ca3f7a06b7.png)

#### 由 Compose 创建网络
如果你想让 Docker Compose 为你创建和管理一个**具有特定名称**的网络，可以在 `docker-compose.yml` 中定义它，但**不要**设置 `external: true`：

```yaml
version: '3.8'

services:
  nest-app:
    # ... 其他配置 ...
    networks:
      - my-app-net

  mysql-container:
    # ... 其他配置 ...
    networks:
      - my-app-net

networks:
  my-app-net: # Docker Compose 会创建 "项目目录名_my-app-net" 网络
    driver: bridge # 可以指定驱动，默认为 bridge
```



### <font style="color:rgb(38, 38, 38);">🔧</font><font style="color:rgb(38, 38, 38);"> 技术原理</font>
<font style="color:rgb(38, 38, 38);">这种机制的本质是 </font>**<font style="color:rgb(38, 38, 38);">Docker 的网络命名空间 (Network Namespace)</font>**<font style="color:rgb(38, 38, 38);">：</font>

+ <font style="color:rgb(38, 38, 38);">默认情况下，每个容器都有独立的网络栈</font>
+ <font style="color:rgb(38, 38, 38);">当容器加入同一个 Docker 网络时，Docker 会配置路由和 DNS</font>
+ <font style="color:rgb(38, 38, 38);">容器可以在共享网络环境内通过服务名互相发现和通信</font>



### 🚀 与 `docker run` 的对比
<font style="color:rgb(38, 38, 38);">果不使用 Docker Compose，手动使用 </font>`<font style="color:rgb(38, 38, 38);background-color:rgba(175, 184, 193, 0.2);">docker run</font>`<font style="color:rgb(38, 38, 38);"> 也能达到相同效果，但过程更繁琐：</font>

```bash
# 1. 创建网络
docker network create my-app-network

# 2. 运行各个容器并连接到网络
docker run -d --name mysql-db --network my-app-network \
  -e MYSQL_ROOT_PASSWORD=yourpass -e MYSQL_DATABASE=test mysql:8.0

docker run -d --name redis-cache --network my-app-network redis:alpine

# 3. 运行应用容器
docker run -d --name my-nest-app --network my-app-network \
  -p 3000:3000 -e DB_HOST=mysql-db -e REDIS_HOST=redis-cache \
  your-nest-app-image
```

<font style="color:rgb(38, 38, 38);">Docker Compose 的真正价值在于将网络创建、容器连接及其他配置集中在一个 </font>`<font style="color:rgb(38, 38, 38);background-color:rgba(175, 184, 193, 0.2);">docker-compose.yml</font>`<font style="color:rgb(38, 38, 38);"> 文件中，大大简化了多容器应用的定义、部署和管理。</font>

<font style="color:rgb(38, 38, 38);">通过 Network Namespace 的处理，原本独立的容器在加入同一个 Docker 桥接网络后，都会获得连接到公共虚拟网桥的接口，从而实现通过 Docker DNS 解析服务名进行互相通信。</font>

