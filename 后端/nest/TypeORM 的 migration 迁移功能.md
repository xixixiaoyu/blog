## TypeORM 简介与环境配置
TypeORM 是一个基于 TypeScript 的 ORM 框架，支持使用 TypeScript 或 JavaScript 进行数据库操作。

它提供了一个高级的接口来操作数据库，使得数据库操作更加简洁和高效。



### 环境搭建步骤
#### 创建 TypeORM 项目
```bash
npx typeorm@latest init --name typeorm-migration --database mysql
cd typeorm-migration
```



#### 安装 MySQL2
```bash
npm install mysql2
```



#### 配置数据源（data-source.ts）
```typescript
import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { User } from './entity/User';

export const AppDataSource = new DataSource({
	type: 'mysql',
	host: 'localhost',
	port: 3306,
	username: 'root',
	password: 'xxx',
	database: 'migration-test',
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
});
```



#### 创建数据库
可以使用 MySQL Workbenc：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714215666560-9ec034d4-9bfb-4963-92c4-b6fd887d085e.png)

也可以执行 sql 命令：

```bash
CREATE SCHEMA `migration-test` DEFAULT CHARACTER SET utf8mb4 ;
```



#### 运行项目
```bash
npm run start
```

生成对应的表并插入了数据：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714215791842-aeb577b9-5632-4df3-9a90-46d7f959294b.png)

因为代码默认 save 了一条数据：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714215915743-15df5e38-52f4-4e01-a2f0-6455f5f52c6d.png)



## 开发环境与生产环境的差异
在开发环境中，使用 synchronize 功能可以在修改代码后，自动创建和修改表结构，极大地方便了开发。

然而，在生产环境中，这种做法可能会导致数据丢失，因此不推荐使用。



## 迁移（Migration）的使用
迁移允许你以编程方式管理数据库的变更，每次变更都会被记录，可以随时撤销。



### 创建和执行迁移的步骤：
#### 创建迁移文件
使用命令 `npx typeorm-ts-node-esm migration:create ./src/migration/first` 创建一个新的迁移文件。

生成了 时间戳-first 的 ts 文件：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714216015135-06e6b047-9bd7-4a22-9673-e4dbce0c785d.png)



#### 编写迁移逻辑
在上面生成的迁移文件中，可以使用 SQL 语句编写创建或修改表的逻辑。



#### 执行迁移
使用命令 `npx typeorm-ts-node-esm migration:run -d ./src/data-source.ts` 执行迁移，应用数据库变更。



#### 生成迁移文件
我们修改下实体：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714216155169-d806e72c-b2ba-4c9d-83a6-e2dbd4628a4b.png)

这时实体已经发生变化，可以使用 `npx typeorm-ts-node-esm migration:generate ./src/migration/first -d ./src/data-source.ts` 命令自动生成迁移文件，简化迁移流程。

生成的文件如下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714217766579-4ea6255b-b1df-490b-983a-73bbaa18afd3.png)

把 synchronize 关掉，用 migration 来手动建表：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714217055145-c2254976-0fd3-4f23-aae3-2af216ba9c31.png)

`npx typeorm-ts-node-esm migration:run -d ./src/data-source.ts` 执行下迁移后：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714218042678-068903d8-a43c-42b0-825a-c94b06f1eb26.png)

确实没有 age 字段了：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714217671342-903d1026-1e2a-4265-ba9b-d8556fd21569.png)



### 撤销迁移
使用命令 `npx typeorm-ts-node-esm migration:revert -d ./src/data-source.ts` 撤销上一次的迁移操作。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714217744456-4ce72df6-2b70-43a8-96e5-1c9937bc23fc.png)

看看数据库：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714217811883-b35749d2-f813-4897-bf65-1e1a23fc590b.png)

age 添加回来了。

