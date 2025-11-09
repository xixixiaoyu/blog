## 灰度发布概述
软件开发过程中，通常不会直接推出最终版本，而是通过逐步迭代的方式进行降低风险。

灰度发布系统的核心是将用户流量分成不同部分，一部分用户使用新版本，而另一部分用户继续使用旧版本。通过控制流量比例，例如最初只有 5% 的用户使用新版本，如果没有问题，比例可以逐步提高到 10%、50%，最终实现 100% 用户使用新版本。这种方法可以最大程度地减少潜在问题对用户的影响。

除了逐步推出新版本外，灰度发布系统还可用于产品的 A/B 测试。通过将流量分成两部分，一部分用户使用 A 版本，另一部分用户使用 B 版本，可以测试哪个版本更有利于业务。



## 灰度发布的流程
+ 用户首次请求时，根据设定的比例随机设置 cookie，实现流量染色。
+ 用户再次访问时，根据 cookie 转发至不同版本的服务。
+ 后端根据 cookie 请求不同的服务，前端根据 cookie 执行不同逻辑。

![画板](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1714442918633-cf847de7-de92-41c2-9839-1fb58f800eb5.jpeg)





## 实现灰度发布
其灰度发布通常是通过 Nginx 实现的。Nginx 是一个反向代理服务，可以将用户请求转发给具体的应用服务器，这一层也被称为网关层。在网关层，可以控制流量分配，决定哪些流量使用 A 版本，哪些使用 B 版本。



### 创建 nest
创建个 nest 项目开启两个端口，一个 3000，一个 3001：

```bash
npx nest new gray_test -p npm
```

分别访问返回 Hello111 和 Hello 222：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688399468012-ce6061c1-8969-45de-b8cc-c8329b4de143.png)![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688399477120-dff0f3c0-4f66-4ec4-adb9-fda11f753f83.png)

现在我们就有了两个版本的 nest 代码。



### 使用 docker 运行 nginx 服务
设置容器名为 gray1，端口映射宿主机的 82 到容器内的 80：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688399702020-e317c9c5-8978-4744-86af-450318c4489a.png?x-oss-process=image%2Fformat%2Cwebp)

现在访问 [http://localhost:82/](http://localhost:82/) 就可以看到 nginx 页面了：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688399751130-399ec5cf-666f-4935-bce0-50a766bd70de.png?x-oss-process=image%2Fformat%2Cwebp)

继续跑个 nginx 容器：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688400355348-747b566c-1a51-4adf-a9a9-75eee4077408.png?x-oss-process=image%2Fformat%2Cwebp)

容器名为 gray2，端口映射 83 到容器内的 80。

挂载目录不变。



### 修改 Nginx 配置文件，设置路由规则，将特定请求转发给指定的服务
把配置文件复制出来：

```bash
docker cp gray1:/etc/nginx/conf.d/default.conf ~/nginx-config
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688400914940-80a43945-672f-43e3-b18e-53b7846bd9e7.png?x-oss-process=image%2Fformat%2Cwebp)

编辑复制文件：

```nginx
# 定义一个location块，用于处理以/api开头的请求
location ^~ /api {
    # 使用rewrite模块来重写请求的URI
    # 将请求中/api/(.*)的部分重写为/$1，即去掉/api前缀
    # 'break'标志表示停止后续的重写操作
    rewrite ^/api/(.*)$/$1 break;

    # 将重写后的请求代理到后端服务器
    # 请求将被转发到192.168.0.100:3001这个地址
    proxy_pass http://192.168.0.100:3001;
}
```

然后我们访问下  [http://localhost:83/api/](http://localhost:83/api/)：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688401316797-2f2bf6c7-83f3-40c8-bc3e-26a53d1e573a.png?x-oss-process=image%2Fformat%2Cwebp)



### 创建多组 upstream，分别代表不同版本的服务
之前负载均衡的时候，是这么配的：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688401482727-76b12af5-9508-43d8-b4b8-6c16bd2089bc.png?x-oss-process=image%2Fformat%2Cwebp)

现在我们需要配置多组 upstream：

```nginx
# 定义上游服务器组，用于版本1.0的服务
upstream version1.0_server {
    server 192.168.0.100:3000; # 指定服务器IP地址和端口号
}

# 定义上游服务器组，用于版本2.0的服务
upstream version2.0_server {
    server 192.168.0.100:3001; # 指定服务器IP地址和端口号
}

# 定义默认的上游服务器组，当请求没有指定版本时使用
upstream default {
    server 192.168.0.100:3000; # 指定默认的服务器IP地址和端口号
}
```



### 根据请求中的 cookie 决定流量转发的版本
```nginx
# 设置一个名为 $group 的变量，默认值为 "default"。
# 这个变量用于后面决定将请求转发到哪个服务器组。
set $group "default";

# 检查请求的 cookie 是否包含 "version=1.0"（不区分大小写）。
# 如果包含，就将 $group 变量的值设置为 "version1.0_server"。
# 这意味着请求将被转发到名为 version1.0_server 的服务器组。
if ($http_cookie ~* "version=1.0"){
    set $group version1.0_server;
}

# 检查请求的 cookie 是否包含 "version=2.0"（不区分大小写）。
# 如果包含，就将 $group 变量的值设置为 "version2.0_server"。
# 这意味着请求将被转发到名为 version2.0_server 的服务器组。
if ($http_cookie ~* "version=2.0"){
    set $group version2.0_server;
}

# 定义一个处理所有以 /api 开头的请求的 location 块。
location ^~ /api {
    # 使用 rewrite 指令重写 URL，去掉 URL 中的 "/api" 部分。
    # 例如，将 "/api/user" 重写为 "/user"。
    # "^/api/(.*)$" 是一个正则表达式，用于匹配以 /api 开头的任何路径。
    # "/$1" 表示使用正则表达式匹配的第一个括号内的内容替换 URL。
    # "break" 表示停止处理后续的 rewrite 指令。
    rewrite ^/api/(.*)$ /$1 break;

    # 使用 proxy_pass 指令将请求转发到根据 cookie 决定的服务器组。
    # $group 变量包含了目标服务器组的名称，这个名称是根据请求的 cookie 决定的。
    proxy_pass http://$group;
}
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688401626964-bf3c72c3-fe1b-42d1-a2b4-95f86d43a2d5.png?x-oss-process=image%2Fformat%2Cwebp%2Fresize%2Cw_474%2Climit_0)



### 测试验证
我们重新跑下容器：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688401684679-f1ee6838-512b-4916-9283-26ecd21cc367.png?x-oss-process=image%2Fformat%2Cwebp)

访问 [http://localhost:83/api/](https://link.juejin.cn/?target=http%3A%2F%2Flocalhost%3A83%2Fapi%2F) 走到的就是默认的版本：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688401786811-568a5849-0d73-4346-b991-0fc156115968.png?x-oss-process=image%2Fformat%2Cwebp)

带上 version=2.0 的 cookie，走到的就是另一个版本的代码：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1688401887308-84b670a6-34f7-44ee-ada0-2513025535ae.png?x-oss-process=image%2Fformat%2Cwebp)

