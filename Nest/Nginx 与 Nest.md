Nginx 是一款高性能的 Web 服务器，它既能高效地托管静态资源（HTML、图片），又能作为反向代理服务器，为后端的动态服务（如 NestJS、Java、Go）提供网关支持。

今天，我们将借助 Docker，通过实战掌握 Nginx 的核心用法。

## 一、 初识：在 Docker 中运行 Nginx

Docker 容器化技术让我们无需在本地安装复杂的环境，即可快速启动服务。

### 1. 启动容器
首先，确保你已安装 Docker Desktop。在搜索栏输入 `nginx`，点击 Run（或者使用命令行启动）。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1717086267380-37bbee21-e396-4f31-94a5-4bf2990c62c6.png)

配置端口映射：将宿主机的 `81` 端口映射到容器内部的 `80` 端口。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1717086317581-eea41f3e-7480-48ed-84bc-75bde7fde637.png)

启动后，浏览器访问 [http://localhost:81](http://localhost:81)，你将看到 Nginx 经典的欢迎页面：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1717084576514-5984b52f-016e-496e-adc7-0caca8db917d.png)

### 2. 探索容器内部
Nginx 默认的静态文件存放于容器内的 `/usr/share/nginx/html/` 目录。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1717084736410-528a761a-97a2-4baa-9f7a-cf6ec5f26fc6.png)

### 3. 修改容器内容 (docker cp)
我们可以使用 `docker cp` 命令在宿主机和容器之间复制文件，从而修改页面内容。

**步骤演示：**

1.  **复制出来**：把容器内的 html 目录复制到宿主机。
    ```bash
    # 语法：docker cp <容器ID/名称>:<容器内路径> <宿主机路径>
    docker cp nginx-test:/usr/share/nginx/html ~/nginx-html
    ```
    ![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1717086374562-f150fd91-f512-47ea-b38e-2bd021597eb0.png)

2.  **修改内容**：在宿主机新建 `test1.html` 和 `test2.html`。
    ```bash
    cd ~/nginx-html
    echo 'hello test1' > test1.html
    echo 'hello test2' > test2.html
    ```

3.  **复制回去**：将修改后的目录覆盖回容器。
    ```bash
    docker cp ~/nginx-html nginx-test:/usr/share/nginx/html
    ```
    ![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1717086763051-bfde005f-c743-4364-b8d4-e9d05a3c45c5.png)

现在访问 `http://localhost:81/test1.html`，即可看到新页面。这证明只要文件位于 `/usr/share/nginx/html` 下，Nginx 就能默认访问到。

---

## 二、 核心：Nginx 配置详解

要驾驭 Nginx，必须读懂它的配置文件。

### 1. 配置文件结构
主配置文件位于 `/etc/nginx/nginx.conf`。它通常包含全局设置，并通过 `include` 指令引入子配置。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688307846529-e7669414-74ea-48e9-b3da-a3da9f18e88a.png)

我们重点关注 `/etc/nginx/conf.d/*.conf`，这里通常定义了具体的 `server`（虚拟主机）和路由规则。

### 2. Location 路由匹配规则
`location` 指令决定了 Nginx 如何处理不同的 URL 请求。

**匹配优先级（从高到低）：**
1.  `location = /uri`：**精确匹配**。
2.  `location ^~ /uri`：**前缀匹配**（高优先级），一旦匹配成功，不再检查正则。
3.  `location ~ /pattern`：**正则匹配**（区分大小写）。
4.  `location ~* /pattern`：**正则匹配**（忽略大小写）。
5.  `location /uri`：**普通前缀匹配**。

**示例：**
```nginx
server {
  listen 80;
  
  # 1. 精确匹配：只有访问 / 时触发
  location = / {
    root /var/www/html;
    index index.html;
  }

  # 2. 正则匹配：访问 .png 结尾的图片
  location ~ \.png$ {
    root /var/www/images;
  }

  # 3. 通用匹配：兜底规则
  location / {
    root /var/www/html;
  }
}
```

### 3. Root 与 Alias 的区别（易错点）
这两个指令都用于指定文件路径，但拼接逻辑完全不同。

*   **root (追加)**：
    ```nginx
    location /images/ {
      root /data;
    }
    ```
    请求 `/images/cat.png` -> 寻找 `/data/images/cat.png` (路径 = root + uri)。

*   **alias (替换)**：
    ```nginx
    location /images/ {
      alias /data/pictures/;
    }
    ```
    请求 `/images/cat.png` -> 寻找 `/data/pictures/cat.png` (路径 = alias + uri 去除 location 部分)。

**总结**：如果你只是想指定一个基础目录，用 `root`；如果你想把 URL 映射到一个完全不同的目录结构，用 `alias`。

---

## 三、 进阶：反向代理与 NestJS

Nginx 处于请求的最前端，被称为“网关”。它可以将请求转发给后端的应用服务器（如 NestJS）。

### 1. 架构说明
*   **正向代理**：代理客户端（如 VPN），服务器不知道真实客户端是谁。
*   **反向代理**：代理服务器（如 Nginx），客户端不知道真实服务器是谁。

### 2. 搭建 NestJS 服务
创建一个简单的 NestJS 应用并启动：
```bash
npx nest new nest-app -p npm
npm run start:dev
```
确保访问 `http://localhost:3000` 能看到 "Hello World"。

### 3. 配置 Nginx 反向代理
我们希望访问 Nginx 的 `81` 端口时，自动转发给 NestJS 的 `3000` 端口。

修改 Nginx 配置（`default.conf`）：

```nginx
server {
  listen 80;
  server_name localhost;

  location ^~ /api {
    # 注意：在 Docker 中，不能直接写 localhost，需使用宿主机 IP
    proxy_pass http://192.168.1.6:3000;
  }
}
```

将配置复制回容器并重载：
```bash
docker cp default.conf nginx1:/etc/nginx/conf.d/default.conf
docker exec nginx1 nginx -s reload
```

此时，访问 `http://localhost:81/api`，实际上就是访问了 NestJS。

---

## 四、 高级：负载均衡

当一台服务器扛不住流量时，我们需要多台服务器分担，这就是负载均衡。

### 1. 准备环境
启动两个 NestJS 实例，分别监听 `3000` 和 `3001` 端口，并修改返回值以便区分（如 "Hello 111", "Hello 222"）。

### 2. 配置 Upstream
在 Nginx 中使用 `upstream` 定义服务器组。

**策略一：轮询（默认）与权重**
```nginx
upstream nest_server {
  server 192.168.1.6:3000 weight=1;
  server 192.168.1.6:3001 weight=2; # 权重越高，分配的请求越多
}

server {
  listen 80;
  location /api {
    proxy_pass http://nest_server;
  }
}
```
![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688313380863-8bb8d58a-a821-4e49-aeff-4f400f85e0c8.png)
*可以看到请求按 1:2 的比例分发。*

**策略二：IP Hash**
```nginx
upstream nest_server {
  ip_hash; # 保证同一个 IP 的用户总是访问同一台服务器
  server 192.168.1.6:3000;
  server 192.168.1.6:3001;
}
```
这解决了 Session 丢失的问题，但在现代无状态架构（JWT）中，轮询更为常用。

---

## 五、 实战：灰度发布 (Gray Release)

灰度发布允许我们将新版本只推送给一小部分用户（如 5%），验证无误后再全量发布。

### 1. 原理
![流程图](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1714442918633-cf847de7-de92-41c2-9839-1fb58f800eb5.jpeg)

1.  用户携带特定 Cookie（如 `version=2.0`）。
2.  Nginx 解析 Cookie。
3.  根据 Cookie 将流量转发到不同的 Upstream（新版或旧版）。

### 2. Nginx 配置实现
我们需要定义两组服务器，并使用 `map` 或 `if` 指令进行分流。

```nginx
# 1. 定义两组服务
upstream version1.0_server {
    server 192.168.0.100:3000; # 旧版
}

upstream version2.0_server {
    server 192.168.0.100:3001; # 新版
}

server {
    listen 80;
    server_name localhost;

    # 2. 动态设置变量 $group
    set $group "version1.0_server"; # 默认走旧版

    # 如果 Cookie 中包含 version=2.0，则走新版
    if ($http_cookie ~* "version=2.0"){
        set $group version2.0_server;
    }

    location ^~ /api {
        # 去掉 URL 中的 /api 前缀
        rewrite ^/api/(.*)$ /$1 break;
        
        # 3. 转发到动态变量对应的服务组
        proxy_pass http://$group;
    }
}
```

### 3. 验证
*   **普通访问**：访问 `http://localhost:83/api/` -> 返回旧版数据。
*   **灰度访问**：在浏览器控制台设置 `document.cookie="version=2.0"`，再次刷新 -> 返回新版数据。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688401887308-84b670a6-34f7-44ee-ada0-2513025535ae.png)

---

## 总结

通过这篇文章，我们不仅学会了如何在 Docker 中运行 Nginx，还深入理解了它的核心配置：

1.  **静态托管**：利用 `root` 和 `alias` 灵活管理文件。
2.  **反向代理**：通过 `proxy_pass` 隐藏后端架构，提升安全性。
3.  **负载均衡**：利用 `upstream` 实现高可用和扩展性。
4.  **灰度发布**：利用 Cookie 和变量控制流量，降低发布风险。

Nginx 是现代 Web 架构的基石，掌握它，你的技术视野将更加开阔。