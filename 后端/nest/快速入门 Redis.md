## 引言
MySQL是一种关系型数据库，通过表和字段来存储信息，表与表之间通过 ID 关联。它使用 SQL 语言进行数据的增删改查操作。

由于 MySQL 是基于硬盘存储，并且需要解析执行 SQL 语句，这可能会导致性能瓶颈。

通常情况下，服务端执行计算的速度很快，但等待数据库查询结果的过程却较为缓慢。



## redis 简介
在计算机科学领域，性能优化的常见策略之一是使用缓存（cache）。考虑到内存与硬盘速度的显著差异，我们通常会采用内存数据库，如 Redis 作为缓存，以提高数据访问速度。

Redis 通常用作数据库、缓存或消息传递中间件。它以键值对（key-value pair）的形式设计，支持多种类型的值，例如：

+ 字符串（String）
+ 列表（List）
+ 集合（Set）
+ 有序集合（Sorted Set）
+ 哈希表（Hash）
+ 地理信息（Geospatial）
+ 位图（Bitmap）



## Redis 的使用
在 Docker Desktop 中搜索 Redis，点击 Run：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687878928060-b644fce4-5515-4a29-aa91-5ef53bafc9fe.png)

将宿主机的 6379 端口映射到容器内的 6379 端口，以便通过本机端口访问容器内 Redis 服务。



将宿主机的目录挂载到容器内的 /data 目录，确保数据保存在本机：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687879045960-95835350-01ac-4a9c-b7b8-f71b0c3782a8.png)

运行成功后：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687879111816-d9da0b29-7d70-4404-92e8-bdc9eb3bbf7c.png)

files 里可以看到所有的容器内的文件：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687879239934-220e2cb7-adf8-41d1-9a99-d35a4406226b.png)

这个 mounted 标志代表挂载的目录。

我们在本地目录添加一个文件：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687879369527-61e192d0-7e9a-427a-ba41-3fe067ccf5e9.png)

在容器内的 data 目录就能访问到这个文件了：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687879406132-cbe0aa54-5913-43b3-8654-4940afddba7c.png)

同样，在容器内修改了 data 目录，那本机目录下也会修改。

使用 redis 也可以将数据持久化到硬盘。，不用 mysql。



## 命令行操作
在 terminal 输入 redis-cli，进入交互模式：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687879538022-77d4306c-a858-47cd-80bd-fcf03f9d798d.png)



### 字符串操作
set、get：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713105624846-d9f21b06-efef-4874-bc06-d7591783975f.png)

incr 用于递增：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713105938668-e778795e-5d19-4fa2-aa0e-02d78b2fa940.png)

适用于计数场景，如阅读量、点赞量。

使用 keys 命令，查询有哪些 key。keys 后支持模式匹配，如使用 * 查询所有键。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687879912993-49b0b863-d2d4-42bd-a464-43fa65f0c7f7.png)



## Redis GUI工具
这里的 GUI 工具用官方的 [RedisInsight](https://link.juejin.cn/?target=https%3A%2F%2Fredis.com%2Fredis-enterprise%2Fredis-insight%2F%23insight-form)。

点击 add database：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687880259817-62bf1a61-9d16-4840-90e0-78dbd9cff680.png)  
连接信息用默认的就行：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687880325893-0806be3a-d3fc-4444-87d0-e5fe4a8d4c92.png)

然后就可以看到新建的这个链接：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687880295429-2ba9c1f6-5530-4585-b75b-56fc3c3f931c.png)

点击它就可以可视化看到所有的 key 和值：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687880415536-728a69f7-5980-41c6-9f5c-6a521001019f.png)

同样也可以执行命令：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687880486637-643a107f-5136-49e9-94c3-85c4cc724afc.png)



## 其他 Redis 数据结构
### 列表（List）：
#### lpush：从列表左侧添加元素
```bash
lpush list1 111
lpush list1 222
lpush list1 333
```

执行上面的命令，点击刷新，就可以最新值：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687880781634-f6c06ede-041f-40ab-a95d-c17ce8ff4e54.png)

#### rpush：从列表右侧添加元素
```bash
rpush list1 444
rpush list1 555
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687881081500-c4d46750-abf3-40e4-81c7-f1d4952c059c.png)

#### lpop：从左侧移除元素
```bash
lpop list1
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687881283107-1837eb57-0ed5-437c-807d-b5be8abe1482.png)

#### rpop：从右侧移除元素
```bash
rpop list1
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687881346923-c9947096-ee6b-4c3f-bd50-694e7e97a97e.png)

#### lrange：获取列表中的元素
![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687881405757-8b8971a7-4400-4c17-8688-17a7a6355b06.png)

`lrange list1 0 -1` 就是查询 list1 的全部数据。



### 集合（Set）
set 的特点是无序并且元素不重复。

#### sadd：添加元素，自动去重
```bash
sadd set1 111
sadd set1 111
sadd set1 111
sadd set1 222
sadd set1 222
sadd set1 333
```

刷新之后就可以看到它去重后的数据：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687881538067-64bb0075-2003-4a7e-8d72-57b1fc8c7d9e.png)

#### sismember：检查元素是否属于集合
```bash
sismember set1 111
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687881610049-5cf25dcb-f53f-4490-a686-3d6b69e8bf9a.png)

```bash
sismember set1 444
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687881635695-0e1e13c3-7b0e-41c3-b841-2d2f95dff947.png)



### 有序集合（Sorted Set/ZSet）
#### zadd：添加元素，并指定分数（排序依据）
```bash
zadd zset1 4 yun
zadd zset1 2 yu
zadd zset1 1 dai
zadd zset1 3 mu
```

会按照分数来排序：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713192356710-9edad9f9-2030-48d1-b056-b8b265018958.png)

#### zrange：按分数获取元素
通过 zrange 命令取数据，比如取排名前三的数据：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1713192892123-8df3d1bb-55aa-4690-8b2b-267b4ca8487f.png)



### 哈希表（Hash）
#### hset：设置键值对
```bash
hset hash1 key1 1
hset hash1 key2 2
hset hash1 key3 3
hset hash1 key4 4
hset hash1 key5 5
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687881910992-828ca10e-7989-4133-9c8e-508dec26a3ce.png)

#### hget：获取键对应的值
```bash
hget hash1 key3
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687881947038-f6b7dd09-8fd6-4c3a-b926-2955a3eaac93.png)



### 地理信息（Geo）
geo 的数据结构存储经纬度信息，根据距离计算周围的人用的：

#### geoadd：添加地理坐标
用 loc 作为 key，分别添加 yunyun 和 mumu 的经纬度：

```bash
geoadd loc 13.361389 38.115556 "yunyun" 15.087269 37.502669 "mumu" 
```

redis 实际使用 zset 存储的，把经纬度转化为了二维平面的坐标：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687882088040-ef1e70b8-72f2-4049-a6ec-a0eeb738c91b.png)

#### geodist：计算两个坐标点之间的距离
```bash
geodist loc yunyun mumu
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687882230009-873284e7-f710-4eb9-9b96-6f9fe4f65031.png)

#### georadius：搜索指定半径内的其他点
传入经纬度、半径和单位：

```bash
georadius loc 15 37 200 km
georadius loc 15 37 100 km
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687882297230-c944dc7a-654a-4f33-ba6a-af930e208aac.png)



## 过期时间
Redis 的键可以通过 expire 命令设置过期时间，使用 ttl 命令查询剩余过期时间。

比如我设置 yun 的 key 为 30 秒过期：

```bash
expire yun 30
```

等到了过期时间就会自动删除。

想查看剩余过期时间使用 ttl：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687882871630-0fc4c8f1-6ae1-45f8-99ab-7a9d98996427.png)

所有的命令都可以在官方文档查： [redis.io/commands/](https://link.juejin.cn/?target=https%3A%2F%2Fredis.io%2Fcommands%2F)

