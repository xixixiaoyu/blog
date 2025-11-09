## TypeORM：传统的 ORM 框架
TypeORM 是一种传统的 ORM（对象关系映射）框架，它将数据库表映射为实体类（entity），将表之间的关联映射为实体类属性的关联。

完成实体类和表的映射后，通过调用 userRepository 和 postRepository 的 API（如 find、delete、save 等），

TypeORM 会自动生成对应的 SQL 语句并执行。这就是对象关系映射的概念，即将对象和关系型数据库之间进行映射。



## Prisma：颠覆传统的 ORM
Prisma 与 TypeORM 不同，它没有实体类的概念。

相反，Prisma 创造了一种领域特定语言（DSL），类似这样：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696771144003-716a30f0-68cd-4473-946c-92c546fc4472.png)

将数据库表映射为 DSL 中的 model，然后编译这个 DSL 将生成 Prisma Client 的代码：

之后，可以调用 Prisma Client 的 API（如 find、delete、create 等）来进行 CRUD（创建、读取、更新、删除）操作。虽然 Prisma 使用了 DSL 的语法，但整个流程与 TypeORM 类似。



## 开始使用 Prisma
### 项目初始化
```bash
mkdir prisma-test
cd prisma-test
npm init -y
```

安装 TypeScript 相关的包，包括 TypeScript 编译器、ts-node 和 Node.js API 的类型声明：

```bash
npm install typescript ts-node @types/node -D
```

创建 tsconfig.json：

```bash
npx tsc --init
```

安装 prisma：

```bash
npm install prisma
```



### 编写代码
#### 编写 Schema
使用以下命令生成 schema 文件：

```bash
npx prisma init --datasource-provider mysql
```

项目目录下多了 schema 和 env 文件：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696770523023-d1332fa9-36ca-456f-b2a3-61fd1869bee5.png)

Schema 文件定义了数据模型（model）的结构。可以安装 Prisma 插件来获得语法高亮等支持：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696770595787-3db778d6-c4f2-4d1f-8f7c-7afb4e47b7b8.png)



#### 配置数据库连接信息
而 .env 文件里存储着连接信息：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696770626476-3a648ab1-16d5-4ef7-92a7-8d8446f4bb54.png)

我们先去 mysql workbench 里创建个数据库：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696770709382-fd60b0e1-c973-4c6b-bdc5-5185dc93bea7.png)

指定字符集为 utf8mb4，这个支持的字符集是最全的。

或者执行这个 sql：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696770861492-4f23fde4-7979-4663-bc85-4c4fe8c9cda8.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696770886543-13782a00-f3d9-4324-bfa4-06846e0878eb.png)

创建完 database 后，我们改下连接信息：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696770992018-eedb8199-ac92-474c-9c7c-529dfcff704c.png)



#### 定义 Model
在 schema 文件中定义数据模型（model），例如：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696771089411-0f550646-87e6-4de7-8353-95e69cd2129b.png)

```typescript
model User {
  id       Int      @id @default(autoincrement())
  email    String   @unique
  name     String?
  posts    Post[]
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String
  content   String?
  published Boolean  @default(false)
  author    User     @relation(fields: [authorId], references: [id])
  authorId  Int
}
```

@id 是主键

@default(autoincrement()) 是指定默认值是自增的数字

@unique 是添加唯一约束

@relation 是指定多对一的关联关系，通过 authorId 关联 User 的 id



#### 生成 Prisma Client 代码
```bash
npx prisma migrate dev
```

会根据 schema 文件生成 sql 并执行：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714738491656-c4dc3be4-7431-4ff9-aeab-7180d74d779f.png)

也可以通过 `npx prisma migrate dev --name test` 指定名字。

还会在 node_modules 下也生成了 client 代码：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714739489547-8ab7e2c3-9b6d-414a-b13d-eb0b122e682e.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714738565735-4d50a862-582d-4354-a126-19140ec6385c.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714738580937-bf6dc884-e13f-454f-8847-65ac58f3db99.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714738654076-445799ce-7499-4e96-b866-60a813dc3dee.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714739298350-aa691a82-7773-4f85-83ee-be0dc89ee735.png)





#### 编写应用代码
在 src/index.ts 中编写应用代码，例如：

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function createUser() {
	await prisma.user.create({
		data: {
			name: '云牧',
			email: 'xx@xx.com',
		},
	});

	await prisma.user.create({
		data: {
			name: '黛玉',
			email: 'xxx@xxx.com',
		},
	});

	const users = await prisma.user.findMany();
	console.log(users);
}

createUser();
```



### 运行代码
```bash
npx ts-node ./src/index.ts
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714738779957-78bd6ae7-32f1-4ac7-b533-7c9bb82b38cb.png)

user 表确实插入了 2 条记录：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714739578147-65cffbbd-2330-42e5-905f-5f86f395271d.png)





## CRUD 全流程
我们再来插入一个新的 user 和它的两个 post：

```typescript
import { PrismaClient } from '@prisma/client';

// 初始化 Prisma 客户端实例，并配置日志选项以输出查询日志到标准输出
const prisma = new PrismaClient({
	log: [
		{
			emit: 'stdout',
			level: 'query', // 设置日志级别为查询（query），这样只有查询语句会被记录
		},
	],
});

async function test() {
	const user = await prisma.user.create({
		data: {
			name: '云牧-牧云',
			email: 'ss@ss.com',
			// 在创建用户的同时创建关联的文章
			posts: {
				create: [
					{
						title: '文章1',
						content: '内容1',
					},
					{
						title: '文章2',
						content: '内容2',
					},
				],
			},
		},
	});
	console.log(user);
}

test();
```

执行：

```typescript
npx ts-node ./src/index.ts
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714740024741-753d8dde-31c9-44c8-93c5-f5d49a53cf08.png)

可以看到被事务包裹的三条 insert 语句。

看下数据库：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714740068339-fa838ebb-7594-4868-a66b-ff9931a4c756.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714740082552-b2a89ae8-30a6-4392-a84e-e6abefc43a38.png)



更新：

```typescript
async function test() {
	await prisma.post.update({
		where: {
			id: 2,
		},
		data: {
			content: '修改后的内容',
		},
	});
}

test();
```

执行 `npx ts-node ./src/index.ts`：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714740227265-ef977dc3-4f80-49cc-ad3e-79c2a6046ab7.png)

修改成功。



删除：

```typescript
async function test() {
	await prisma.post.delete({
		where: {
			id: 2,
		},
	});
}
test();
```

执行 `npx ts-node ./src/index.ts`：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714740295247-5fedec42-9a6d-482c-a142-348092d19459.png)

删除成功。

