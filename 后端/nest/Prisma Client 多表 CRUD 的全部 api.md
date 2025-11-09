## 项目设置
首先，创建并初始化一个新的 Node.js 项目，设置如下：

```bash
# 创建项目目录
mkdir prisma-more-client-api
cd prisma-more-client-api

# 初始化 Node.js 项目
npm init -y

# 初始化 Prisma
npx prisma init
```

此操作将生成 `.env` 和 `schema.prisma` 文件。接下来，修改 `.env` 文件中的数据库连接信息：

```bash
DATABASE_URL="mysql://root:自己的密码@localhost:3306/prisma_test"
```



## 数据模型定义
在 `schema.prisma` 文件中，配置数据源和 Prisma 客户端，并定义相关的数据模型：

```bash
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}

model Department {
  id         Int        @id @default(autoincrement())
  name       String     @db.VarChar(20)
  createTime DateTime   @default(now())
  updateTime DateTime   @updatedAt
  employees  Employee[]
}

model Employee {
  id           Int        @id @default(autoincrement())
  name         String     @db.VarChar(20)
  phone        String     @db.VarChar(30)
  departmentId Int
  department   Department @relation(fields: [departmentId], references: [id])
}
```

执行数据库迁移：

```bash
npx prisma migrate reset
npx prisma migrate dev --name init_migration
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714813591057-4762e269-81b4-4e2c-98fa-447244aae22d.png)



## CRUD 操作
### 安装依赖和配置 TypeScript
```bash
npm install typescript ts-node @types/node -D
npx tsc --init
```

在 `tsconfig.json` 中保留以下配置：

```json
{
  "compilerOptions": {
    "target": "es2016",
    "module": "commonjs",
    "types": ["node"],
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "strict": true,
    "skipLibCheck": true
  }
}
```



### 实现 CRUD 操作
在 `src/index.ts` 文件中，实现各种 CRUD 操作：



#### 插入数据
```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
	log: [
		{
			emit: 'stdout',
			level: 'query',
		},
	],
});

async function test() {
	await prisma.department.create({
		data: {
			name: '技术部',
			employees: {
				create: [
					{
						name: '小张',
						phone: '111',
					},
					{
						name: '小李',
						phone: '222',
					},
				],
			},
		},
	});
}

test();
```

运行 `npx ts-node ./src/index.ts` 后：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714813783372-cf05d630-1013-4f86-bfd5-b35e66653600.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714813798114-fd3c1a42-f52f-4cf7-865c-3cf569e8ec8f.png)



#### 查询数据
```typescript
async function queryDepartmentWithEmployees() {
	const department = await prisma.department.findUnique({
		where: { id: 1 },
		include: { employees: true },
	});
	console.log(department);
}

queryDepartmentWithEmployees();
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714813916569-a41df501-99fe-40c5-a835-38217326c6d2.png)



#### 更新数据
```typescript
async function updateDepartmentAndAddEmployee() {
	const updatedDepartment = await prisma.department.update({
		where: { id: 1 },
		data: {
			name: '销售部',
			//  在 employees 关联字段进行操作
			employees: {
				//  创建一个新员工，姓名为 '小刘'，电话为 '333'
				create: [{ name: '小刘', phone: '333' }],
				// 关联一个 id 为 2 的已存在员工
				connect: [{ id: 2 }],
			},
		},
	});
	console.log(updatedDepartment);
}

updateDepartmentAndAddEmployee();
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714814173568-2c1d6dd4-0455-4f0f-9bda-6d9b40fbcd98.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714814242103-735f654d-f3aa-414e-b462-81bb4e0ccef2.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714814203768-a3d96c72-15a0-42f3-97d1-deb56ed3e366.png)



### 删除数据
```typescript
async function deleteEmployeesOfDepartment() {
	const res = await prisma.employee.deleteMany({
		where: {
			department: { id: 1 },
		},
	});

	console.log(res);
}

deleteEmployeesOfDepartment();
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714814366388-208ad071-57fc-4af0-a825-0eb68524b360.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714814389362-2c94b822-637c-4f09-899a-a900ebe91ef8.png)





## 执行直接 SQL
在特定情况下，直接执行 SQL 可能更为直接有效：

```typescript
async function executeRawSQL() {
	// 使用 Prisma 的 $executeRaw 方法来执行一个原生 SQL 命令，清空 Department 表
	await prisma.$executeRaw`DELETE FROM Department`;

	// 使用 Prisma 的 $queryRaw 方法执行一个查询 SQL 命令，这里是从 Department 表中选取所有记录
	const departments = await prisma.$queryRaw`SELECT * FROM Department`;

	console.log(departments);
}

executeRawSQL();
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714815216428-e731a288-57e9-4cde-92e4-b802b1ef52da.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714815293080-62f40071-b5ac-4343-9624-d7a1e141228a.png)

