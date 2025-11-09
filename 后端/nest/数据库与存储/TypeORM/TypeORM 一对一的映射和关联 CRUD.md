## 数据库表关系
在数据库中，表与表之间存在不同类型的关系：

+ 一对一关系：例如用户（User）与身份证（IdCard）之间的关系。
+ 一对多关系：例如部门（Department）与员工（Employee）之间的关系。
+ 多对多关系：例如文章（Article）与标签（Tag）之间的关系。

这些关系通常通过外键（Foreign Key）来维护，而多对多关系还需要建立一个中间表（Intermediate Table）。



## 一对一映射关系创建
TypeORM 是一个 ORM 框架，它将数据库的表、字段以及表之间的关系映射为实体类（Entity Class）、属性（Property）和实体之间的关系。

下面是如何在 TypeORM 中映射这些关系的操作步骤：



### 创建数据库 
```sql
create database typeorm_test;
```



### 初始化项目
初始化 TypeORM 项目： 

```bash
npx typeorm@latest init --name typeorm-relation-mapping --database mysql
```

安装驱动包 mysql2：

```bash
npm install mysql2
```



### 修改 DataSource 文件的配置
```typescript
import 'reflect-metadata'
import { DataSource } from 'typeorm'
import { User } from './entity/User'

export const AppDataSource = new DataSource({
	type: 'mysql',
	host: 'localhost',
	port: 3306,
	username: 'root',
	password: 'xxx',
	database: 'typeorm_test',
	synchronize: true,
	logging: true,
	entities: [User],
	migrations: [],
	subscribers: [],
	poolSize: 10,
	connectorPackage: 'mysql2',
	extra: {
		authPlugin: 'sha256_password',
	},
})
```



### 启动项目
```bash
npm run start
```



### 创建身份证表（IdCard）
```bash
npx typeorm entity:create src/entity/IdCard
```



在 `IdCard` 实体中添加属性和映射信息：

```typescript
import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";

@Entity({ name: 'id_card' })
export class IdCard {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({
        length: 50,
        comment: '身份证号'
    })
    cardNumber: string;
}
```

在 DataSource 的 entities 里引入下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1715698836933-c21a6142-215f-4314-b991-22760ff25387.png)

重新 npm run start：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687593652101-786552c5-291f-4f90-8b7c-2ee9e69c8cee.png)

现在 user 和 id_card 表都有了，怎么让它们建立一对一的关联呢？



### 建立一对一关联
切换 typeorm_test 数据库，把这两个表删除：

```sql
drop table id_card,user;
```

在 `IdCard` 实体中添加 `user` 属性，并使用 `@OneToOne` 和 `@JoinColumn` 装饰器来指定与 `User` 实体的一对一关系：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687594445085-5326bb0a-5f63-4325-a780-0af3e3fa573f.png)

如果用 `@JoinColumn({ name: 'user_id' })` 会告诉 TypeORM 使用 `user_id` 作为外键列的名称，而不是默认的 `userId`。

一对一关系的外键列可以放在任何一方，通常，外键列放置在访问最频繁的那一方。

外键列放在哪一方，那一方就是拥有关系的一方（也称为拥有者方）。拥有者方负责维护关系，包括外键的更新和删除。



重新 npm run start 后，在 workbench 里看下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714576377613-083447c6-51b7-4788-b895-057a0d30ea89.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687594777179-5335c0a2-6c2a-4a8e-8356-2e4e4ffd41b2.png)

多出了 `userId` 外键列与 user 表相连。



### 级联操作
级联关系还是默认的：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687594887854-f6ffb70b-c305-41c6-b508-75a2092ec588.png)

如果我们想设置 CASCADE ，可以在第二个参数指定：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687594926250-8a273831-da77-43bb-a9a0-ed5aff7d2fda.png)

我们可以将其设置为 CASCADE。



## 一对一映射关系增删改查
### 增加
![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687595455993-4143de19-fbc6-4637-921f-1abb3ed5eeaa.png)

创建 `User` 和 `IdCard` 对象，建立关联后保存。先保存 user，再保存 idCard。

npm run start 后，数据都插入成功了：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687595617408-4288fa78-9e00-43b8-9335-696f92f6fb1a.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687595647204-184008cd-e6bf-4928-b313-ecef792f2129.png)

上面保存还要分别保存 user 和 idCard，能不能自动按照关联关系来保存呢？

可以的，在 @OneToOne 那里指定 cascade 为 true：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714541936815-0b6c3b80-e641-4ff8-a81a-f20dc28a58dc.png)

这样我们就不用自己保存 user 了：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687598992889-137b49ff-19fd-4b55-bfb4-f693fce7b407.png)



### 查询
使用 `find` 方法或 `QueryBuilder` 来查询数据，可以通过指定 `relations` 参数来实现关联查询：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687599659950-619f1310-3a8c-444c-9769-61615508e893.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687599312693-40c85103-e82b-4ca6-9197-25a15ac76bc3.png)



`QueryBuilder`进行更复杂查询：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687599719184-06489eaf-c129-4897-91b4-a952b55ada6e.png)

先 getRepository 拿到操作 IdCard 的 Repository 对象。

再创建 queryBuilder 来连接查询，给 idCard 起个别名 ic，然后连接的是 ic.user，起个别名为 u：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687599312693-40c85103-e82b-4ca6-9197-25a15ac76bc3.png)

或者也可以直接用 EntityManager 创建 queryBuilder 来连接查询：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687599837349-a3a190e2-ac65-419d-85f6-70430ca7f40a.png)

查询的结果是一样的。



### 修改
我们来修改下数据，数据长这样：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687599970505-d425c81f-8fc2-4062-a219-e0ec23a26aec.png)![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687599987677-9153000a-bac8-431f-94ba-5843971c2524.png)

我们给它加上 id 再 save：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687600096558-3ae6e062-48a2-4679-a56b-3f0b4952f8b3.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687600118029-df5ed230-2b49-4e5e-bf0a-0b2d3ac98b6e.png)![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687600134020-9a40ab28-ff4a-4aa7-94a4-5e70f7e7db8f.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687600155336-c086e717-172f-4a8c-8987-af55cdeb2793.png)

可以看到在一个事务内，执行了两条 update 的 sql。



### 删除
如果设置了外键的 `onDelete` 为 `cascade`，删除 `User` 实体时，关联的 `IdCard` 实体也会被自动删除：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687600207200-afbaeb12-df06-4795-a1b4-9f371f43e925.png)

如果没有设置级联删除，需要手动删除关联的实体：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687600243194-99f9b4f5-f70a-4267-86ef-76dde8a819e2.png)



## 反向关系
如果现在想在 user 里访问 idCard 呢？

同样需要加一个 @OneToOne 的装饰器：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687600819919-5f649095-8f6d-451c-a9da-ffad1e2ffda2.png)

需要通过第二个参数告诉 typeorm，外键是另一个 Entity 的哪个属性。

我们查一下试试：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687600857744-5575a8df-eb5f-4296-abfe-39eeb6bb2e9c.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687600891080-490fd16f-9b18-4f88-bfe9-f74db8831544.png)

可以看到，同样关联查询成功了。

这就是一对一关系的映射和增删改查。

