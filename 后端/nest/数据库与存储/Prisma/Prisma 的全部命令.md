 Prisma 的全部命令：

```bash
npx prisma -h
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696775230112-a7a3e784-f844-4fe4-8f93-3ef955c21d0d.png)

+ init：创建 schema 文件，初始化项目结构。
+ generate：根据 schema 文件生成客户端代码。
+ db：包括数据库与 schema 的同步。
+ migrate：处理数据表结构的迁移。
+ studio：提供图形化界面进行 CRUD 操作。
+ validate：验证 schema 文件的语法。
+ format：格式化 schema 文件。
+ version：显示版本信息。



## 环境设置与初始化
首先，我们需要创建一个新的项目并设置 Prisma：

```bash
mkdir prisma-all-command
cd prisma-all-command
npm init -y
npm install prisma -g
prisma init
```



## 初始化与配置
执行 init 命令：

```bash
prisma init --datasource-provider mysql
```

执行后，生成 `prisma/schema.prisma` 和 `.env` 文件，配置数据库连接。



修改数据库连接：

+ 可通过修改 `.env` 文件中的 URL 来更改数据库连接，例如：

```bash
prisma init --url mysql://root:password@localhost:3306/prisma_test
```

+ password：这是连接数据库的密码。在实际使用中，你应该替换成你的实际数据库密码。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714793981410-c4f5fee2-b3a2-47c6-a969-d9221abf3130.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714796550849-d63440a8-26fb-4b61-a190-5c240db7f598.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714796561021-b7bd8ee1-ef7b-408d-99a5-af519316a2f8.png)



## 数据库与 Schema 同步
### 拉取数据库结构到 Schema
```bash
prisma db pull
```

此命令将数据库中的表结构同步到 Prisma 的 schema 文件中。

现在连接的 prisma_test 数据库里是有这两个表：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714796633947-e840b6fe-6b2b-4ed3-a6b5-6b21978325d2.png)

执行 `prisma db pull` 后：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714796678425-cdb29e46-d10d-4e22-b948-b9a40e534765.png)



### 推送 Schema 更改到数据库
```bash
prisma db push
```

将 schema 文件中的更改推送到数据库，同步表结构。  
我们先把表全部删除：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714796741138-3d55eb1e-8947-48b9-9a15-f8aa731e25fc.png)

执行 `prisma db push` 后：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714796964194-90d30e01-a1fa-4800-b6f9-931950c0dbd0.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714796885666-53cbac0b-e7df-49bc-93c2-6a549fd2c59e.png)

重新生成了这两张表。



## 数据迁移
创建与应用迁移：

```bash
prisma migrate dev --name init
```

此命令根据 schema 的更改生成 SQL 文件，并执行这些 SQL 来更新数据库结构，同时生成客户端代码。

数据库中的 _prisma_migrations 表记录所有迁移历史，有助于跟踪每次迁移的详细信息：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714797092550-d1ee03e7-1b01-4d58-9227-2d156920fac5.png)



## 数据初始化与脚本执行
### 数据初始化脚本
prisma/seed.ts：

```typescript
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
	const user = await prisma.user.create({
		data: {
			name: '云牧',
			email: 'xx@xx.com',
			Post: {
				create: [
					{ title: '文章1', content: '内容1' },
					{ title: '文章2', content: '内容2' },
				],
			},
		},
	});
	console.log(user);
}

main();
```

在 package.json 中添加脚本执行命令：

```json
"prisma": {
    "seed": "npx ts-node prisma/seed.ts"
}
```

执行命令 `prisma db seed` 来插入初始数据：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714797499095-4fb24d8a-7e4f-4ffc-b770-b1b555a2dd77.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714797515819-9e1a0e31-0df4-4e62-9f64-5668819d8a67.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714797531459-691f04fc-ad98-4d1f-9a6c-545c523ddc51.png)

数据正确插入了。



### 执行 SQL 脚本
写一个 prisma/test.sql：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714797672965-aa134be6-c1cc-49f9-a304-bb91ff799596.png)

执行命令：

```bash
prisma db execute --file prisma/test.sql --schema prisma/schema.prisma
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714797721872-04d32d40-ad51-47ed-8164-99f7268ddc47.png)

SQL 脚本执行后，会删除 id 为 2 的文章：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714797752669-6f1c20cb-7859-422f-8bfc-926a4a0c0113.png)



## **重置数据库**
使用 `prisma migrate reset` 命令可以重置数据库，清空所有数据，并重新执行所有迁移和数据初始化。



## 代码生成
`prisma generate` 命令用于根据 `schema.prisma` 文件生成 Prisma 客户端代码，这些代码位于 `node_modules/@prisma/client` 目录下，主要用于实现 CRUD 操作。

注意：该命令不会同步数据库结构，仅根据 schema 文件生成客户端代码。



## 图形界面操作
`prisma studio` 提供了一个用户友好的图形界面，使得用户可以直接在浏览器中进行数据的增删改查操作：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714799749135-405ec6ee-a69b-4de0-8a21-a571e01fdf2a.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714799771550-5bae1d08-3cdf-48ec-9347-df051e6ee4df.png)  
![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714799826353-7326ef1b-1664-4724-a5e9-619bb4db0f13.png)

用户可以通过界面直接编辑、删除或新增数据记录。

一般我更倾向使用如 MySQL Workbench，进行数据库操作。



## Schema 验证
`prisma validate` 命令用于检查 `schema.prisma` 文件中是否存在语法错误。

安装 Prisma 的 VSCode 插件后，可以在编辑器内直接看到 schema 文件的错误，类似于 ESLint 的功能。



## 文件格式化
`prisma format` 命令用于自动格式化 `schema.prisma` 文件，确保文件的风格一致性和可读性。

安装 Prisma 的 VSCode 插件，直接使用编辑器的格式化功能来格式化 schema 文件，提高开发效率。



## 版本信息
`prisma version` 命令用于显示 Prisma CLI 和 Prisma Client 的当前版本信息。这对于调试问题或确保使用的是最新功能非常有用。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714800099208-333e83c9-c8c6-412b-a76a-c4071e526861.png)

