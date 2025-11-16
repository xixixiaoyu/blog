## 1. Prisma 简介：颠覆传统的 ORM

### TypeORM：传统的 ORM 框架

在探讨 Prisma 之前，我们先回顾一下像 TypeORM 这样的传统 ORM（对象关系映射）框架。TypeORM 将数据库表映射为实体类（Entity），表之间的关联则映射为实体类属性的关联。开发者定义好实体类后，通过调用 Repository 的 API（如 `find`、`save` 等），TypeORM 会自动生成并执行相应的 SQL 语句。这便是“对象关系映射”的核心思想。

### Prisma：新一代 ORM

Prisma 则另辟蹊径，它不采用实体类的概念，而是引入了一种领域特定语言（DSL, Domain-Specific Language）来定义数据模型。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696771144003-716a30f0-68cd-4473-946c-92c546fc4472.png)

开发者在 `schema.prisma` 文件中使用 DSL 将数据库表映射为 `model`，然后通过编译这个 DSL 生成类型安全的 Prisma Client 代码。之后，应用代码便可调用 Prisma Client 提供的 API（如 `findUnique`、`create`、`update` 等）进行数据库操作。

尽管实现方式不同，但 Prisma 的目标与传统 ORM 一致：提供一种更高效、更安全的方式来操作数据库。

## 2. 快速入门

本节将引导你完成一个 Prisma 项目的初始化、配置和基本数据操作。

### 2.1. 项目初始化

首先，创建项目并安装必要的开发依赖。

```bash
# 创建项目目录并进入
mkdir prisma-test
cd prisma-test

# 初始化 npm 项目
npm init -y

# 安装 TypeScript 相关依赖
npm install typescript ts-node @types/node -D

# 生成 tsconfig.json 配置文件
npx tsc --init

# 安装 Prisma
npm install prisma
```

### 2.2. 初始化 Prisma

执行 `init` 命令来创建 Prisma 的基础配置文件。

```bash
# 初始化 Prisma，指定数据源为 MySQL
npx prisma init --datasource-provider mysql
```

此命令会创建两个核心文件：
1.  `prisma/schema.prisma`：用于定义数据源、生成器和数据模型。
2.  `.env`：用于存放环境变量，如数据库连接字符串。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696770523023-d1332fa9-36ca-456f-b2a3-61fd1869bee5.png)

建议安装 VSCode 的 [Prisma 插件](https://marketplace.visualstudio.com/items?itemName=Prisma.prisma)，它能提供语法高亮、自动格式化、代码补全等实用功能。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696770595787-3db778d6-c4f2-4d1f-8f7c-7afb4e47b7b8.png)

### 2.3. 配置数据库连接

首先，请确保你已创建用于测试的数据库。例如，在 MySQL 中创建一个名为 `prisma_test` 的数据库，并设置为 `utf8mb4` 字符集。

```sql
CREATE DATABASE prisma_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

然后，打开 `.env` 文件，修改 `DATABASE_URL`，填入你的数据库连接信息。

```env
DATABASE_URL="mysql://root:你的密码@localhost:3306/prisma_test"
```

`schema.prisma` 文件中的 `datasource` 部分会自动读取这个环境变量。

```prisma
datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}
```

### 2.4. 定义数据模型

在 `schema.prisma` 文件中，使用 Prisma 的 DSL 定义数据模型。这里我们定义一个 `User` 和 `Post` 模型，并建立它们之间的一对多关系。

```prisma
model User {
  id    Int     @id @default(autoincrement())
  email String  @unique
  name  String?
  posts Post[]
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

*   `@id`：定义主键。
*   `@default(autoincrement())`：设置默认值为自增。
*   `@unique`：添加唯一约束。
*   `?`：表示该字段可选（nullable）。
*   `[]`：表示一对多关系中的“多”方。
*   `@relation`：定义两个模型间的关系。

### 2.5. 数据库迁移与生成客户端

定义好模型后，使用 `migrate dev` 命令来创建数据库表并生成 Prisma Client。

```bash
npx prisma migrate dev --name init
```

该命令会：
1.  **创建迁移文件**：在 `prisma/migrations` 目录下生成一个包含 SQL 语句的迁移文件。
2.  **执行迁移**：将 SQL 应用于数据库，创建 `User` 和 `Post` 表。
3.  **生成 Prisma Client**：在 `node_modules/@prisma/client` 目录下生成类型安全的客户端代码。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714738565735-4d50a862-582d-4354-a126-19140ec6385c.png)

### 2.6. 编写第一个脚本

现在，我们可以使用生成的 Prisma Client 来操作数据库了。创建一个 `src/index.ts` 文件：

```typescript
// src/index.ts
import { PrismaClient } from '@prisma/client';

// 初始化 Prisma 客户端
const prisma = new PrismaClient({
  log: ['query'], // 配置日志，打印执行的 SQL
});

async function main() {
  // 创建一个新用户，并关联创建两篇文章
  const user = await prisma.user.create({
    data: {
      name: '云牧',
      email: 'yunmu@example.com',
      posts: {
        create: [
          { title: '文章1', content: '内容1' },
          { title: '文章2', content: '内容2' },
        ],
      },
    },
  });
  console.log('创建的用户:', user);

  // 查询所有用户，并包含其关联的文章
  const usersWithPosts = await prisma.user.findMany({
    include: {
      posts: true,
    },
  });
  console.dir(usersWithPosts, { depth: null });
}

main()
  .catch((e) => {
    throw e;
  })
  .finally(async () => {
    // 关闭数据库连接
    await prisma.$disconnect();
  });
```

使用 `ts-node` 运行脚本：

```bash
npx ts-node ./src/index.ts
```

你将会在控制台看到执行的 SQL 语句以及查询结果。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714740024741-753d8dde-31c9-44c8-93c5-f5d49a53cf08.png)

数据库中也成功插入了相应的数据。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714740068339-fa838ebb-7594-4868-a66b-ff9931a4c756.png)
![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714740082552-b2a89ae8-30a6-4392-a84e-e6abefc43a38.png)

## 3. Prisma CLI 命令详解

Prisma 提供了一套强大的命令行工具来管理项目的生命周期。

```bash
npx prisma -h
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1696775230112-a7a3e784-f844-4fe4-8f93-3ef955c21d0d.png)

以下是常用命令的详细说明：

*   **`prisma init`**: 初始化项目，创建 `schema.prisma` 和 `.env` 文件。
    ```bash
    prisma init --datasource-provider postgresql
    ```

*   **`prisma generate`**: 根据 `schema.prisma` 文件生成 Prisma Client。每次修改 schema 后，通常需要手动或自动执行此命令。

*   **`prisma db pull`**: **拉取**数据库结构。此命令会连接到数据库，读取其现有结构，并将其转换为 Prisma schema 语法写入 `schema.prisma` 文件。适用于从现有数据库开始项目。

*   **`prisma db push`**: **推送** Schema 更改。此命令将 `schema.prisma` 中的模型与数据库进行比较，并生成必要的 SQL 来使数据库结构与模型同步。它适用于快速原型开发，但不创建迁移历史。**生产环境请使用 `migrate`**。

*   **`prisma migrate dev`**: 创建并应用迁移。这是开发环境中最常用的迁移命令。它会根据自上次迁移以来的模型变更，生成一个新的 SQL 迁移文件，并将其应用到数据库。
    ```bash
    prisma migrate dev --name add-user-role
    ```

*   **`prisma migrate reset`**: 重置数据库。此命令会删除数据库中的所有数据和表，然后重新运行所有迁移，并可选地执行 `seed` 脚本。

*   **`prisma db seed`**: 执行数据填充脚本。该脚本通常位于 `prisma/seed.ts`，用于向数据库插入初始数据。需要在 `package.json` 中配置执行方式。
    ```json
    "prisma": {
      "seed": "ts-node prisma/seed.ts"
    }
    ```

*   **`prisma db execute`**: 执行 SQL 脚本。允许你直接对数据库执行一个 SQL 文件。
    ```bash
    prisma db execute --file prisma/cleanup.sql --schema prisma/schema.prisma
    ```

*   **`prisma studio`**: 启动一个本地的、基于 Web 的 GUI，用于浏览和编辑数据库中的数据。这是一个进行快速数据操作和调试的强大工具。
    ![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714799749135-405ec6ee-a69b-4de0-8a21-a571e01fdf2a.png)

*   **`prisma validate`**: 验证 `schema.prisma` 文件的语法是否正确。

*   **`prisma format`**: 自动格式化 `schema.prisma` 文件，保持代码风格一致。

*   **`prisma version`**: 显示 Prisma CLI 和 Prisma Client 的版本信息。

## 4. Prisma Schema 语法深度解析

`schema.prisma` 是 Prisma 的核心，它定义了你的数据模型、数据库连接和客户端生成方式。

### 4.1. 主要组成部分

一个典型的 `schema.prisma` 文件包含三个主要部分：

1.  **`datasource`**: 配置数据库连接。
    ```prisma
    datasource db {
      provider = "mysql" // 数据库类型 (mysql, postgresql, sqlite, etc.)
      url      = env("DATABASE_URL") // 连接字符串
    }
    ```

2.  **`generator`**: 配置要生成的客户端或工具。
    ```prisma
    generator client {
      provider = "prisma-client-js" // 指定生成 JavaScript/TypeScript 客户端
      output   = "../generated/client" // 可选：自定义输出目录
    }
    ```
    你还可以添加其他生成器，例如用于生成文档的 `prisma-docs-generator`。

3.  **`model`**: 定义数据模型，它会映射到数据库中的表。
    ```prisma
    model User {
      id    Int    @id @default(autoincrement())
      email String @unique
      name  String?
    }
    ```

### 4.2. 字段类型

Prisma 支持多种标量类型，它们会映射到具体的数据库类型：
`String`, `Boolean`, `Int`, `Float`, `DateTime`, `Json`, `Bytes`, `Decimal`。

### 4.3. 属性（Attributes）

属性以 `@` 或 `@@` 开头，用于为字段或模型块添加元数据。

#### 字段属性

*   `@id`: 将字段标记为主键。
*   `@default(...)`: 定义字段的默认值。可以是静态值、函数（如 `now()`、`uuid()`）或自增（`autoincrement()`）。
*   `@unique`: 为字段创建唯一约束。
*   `@updatedAt`: 将字段标记为自动更新的时间戳，每次记录更新时都会设置为当前时间。
*   `@relation(...)`: 定义两个模型之间的关系。
*   `@map(...)`: 将字段名映射到数据库中不同的列名。例如 `t2 Int @map("tt2")`。
*   `@db.(...)`: 指定底层的原生数据库列类型。例如 `@db.VarChar(200)`、`@db.Text`。

#### 块级属性

*   `@@id([...])`: 定义复合主键。
*   `@@unique([...])`: 定义复合唯一约束。
*   `@@index([...])`: 定义索引。
*   `@@map(...)`: 将模型名映射到数据库中不同的表名。例如 `@@map("test_test")`。

### 4.4. 关系（Relations）

Prisma 支持所有常见的数据库关系。

#### 一对多（One-to-Many）

一个部门（Department）有多个员工（Employee）。

```prisma
model Department {
  id        Int        @id @default(autoincrement())
  name      String
  employees Employee[] // 关系字段，表示拥有多个 Employee
}

model Employee {
  id           Int        @id @default(autoincrement())
  name         String
  departmentId Int        // 外键字段
  department   Department @relation(fields: [departmentId], references: [id]) // 关系标量字段
}
```

#### 多对多（Many-to-Many）

一个帖子（Post）可以有多个标签（Tag），一个标签也可以用于多个帖子。这需要一个显式的关联表。

```prisma
model Post {
  id    Int         @id @default(autoincrement())
  title String
  tags  TagOnPosts[]
}

model Tag {
  id    Int         @id @default(autoincrement())
  name  String
  posts TagOnPosts[]
}

// 关联表
model TagOnPosts {
  post   Post @relation(fields: [postId], references: [id])
  postId Int
  tag    Tag  @relation(fields: [tagId], references: [id])
  tagId  Int

  @@id([postId, tagId]) // 复合主键
}
```

### 4.5. 枚举（Enums）

使用 `enum` 关键字可以定义一组固定的字符串值，用于限制字段的取值范围。

```prisma
enum Role {
  USER
  ADMIN
  GUEST
}

model Account {
  id   Int     @id @default(autoincrement())
  role Role    @default(USER)
}
```

## 5. Prisma Client API 深度解析

Prisma Client 是与数据库交互的主要接口，它提供了类型安全、自动补全的 API。

### 5.1. 单表 CRUD 操作

#### 创建（Create）

*   **`create`**: 创建单条记录。
    ```typescript
    const newUser = await prisma.user.create({
      data: { name: '宝钗', email: 'baochai@example.com' },
      select: { id: true, email: true }, // 可选：只返回指定字段
    });
    ```

*   **`createMany`**: 批量创建多条记录（注意：此操作在某些数据库（如 SQLite）中可能不是事务性的）。
    ```typescript
    await prisma.user.createMany({
      data: [
        { name: '黛玉', email: 'daiyu@example.com' },
        { name: '惜春', email: 'xichun@example.com' },
      ],
    });
    ```

#### 查询（Read）

*   **`findUnique` / `findUniqueOrThrow`**: 根据唯一标识（如主键或 `@unique` 字段）查找单条记录。如果未找到，`findUnique` 返回 `null`，而 `findUniqueOrThrow` 会抛出异常。
    ```typescript
    const user = await prisma.user.findUnique({
      where: { id: 1 },
    });
    ```

*   **`findFirst` / `findFirstOrThrow`**: 查找满足条件的第一条记录。

*   **`findMany`**: 查找所有满足条件的记录，支持丰富的过滤、排序和分页选项。
    ```typescript
    const users = await prisma.user.findMany({
      where: { email: { contains: 'example.com' } },
      orderBy: { name: 'desc' },
      skip: 0,  // 分页：跳过记录数
      take: 10, // 分页：获取记录数
    });
    ```

#### 更新（Update）

*   **`update`**: 根据 `where` 条件更新单条记录。
    ```typescript
    const updatedUser = await prisma.user.update({
      where: { id: 3 },
      data: { name: '王熙凤' },
    });
    ```

*   **`updateMany`**: 批量更新满足 `where` 条件的多条记录。返回一个包含更新记录数的对象。
    ```typescript
    const result = await prisma.user.updateMany({
      where: { email: { contains: 'example.com' } },
      data: { name: '红楼梦' },
    });
    console.log(`更新了 ${result.count} 条记录`);
    ```

*   **`upsert`**: 更新或插入。如果 `where` 条件匹配到记录，则执行 `update`；否则，执行 `create`。
    ```typescript
    const user = await prisma.user.upsert({
      where: { email: 'xifeng@example.com' },
      update: { name: '凤姐' },
      create: { name: '王熙凤', email: 'xifeng@example.com' },
    });
    ```

#### 删除（Delete）

*   **`delete`**: 删除单条记录。
    ```typescript
    await prisma.user.delete({
      where: { id: 1 },
    });
    ```

*   **`deleteMany`**: 批量删除多条记录。
    ```typescript
    await prisma.user.deleteMany({
      where: { id: { in: [2, 3] } },
    });
    ```

### 5.2. 高级查询

#### 聚合（Aggregation）

使用 `aggregate` 方法可以执行计数、求和、平均值、最大/最小值等计算。

```typescript
const stats = await prisma.post.aggregate({
  where: { published: true },
  _count: { _all: true },
  _max: { id: true },
  _min: { id: true },
});
console.log(stats);
```

#### 分组（Grouping）

使用 `groupBy` 方法可以对记录进行分组，并对每个分组执行聚合计算。

```typescript
const groupedByPublished = await prisma.post.groupBy({
  by: ['published'],
  _count: { id: true },
});
```

### 5.3. 多表（关系）CRUD 操作

Prisma 的强大之处在于其处理关系数据的简洁语法。

#### 创建关联记录（Nested Writes）

在创建一条记录时，可以同时创建并关联其他记录。

```typescript
// 创建一个技术部，并同时创建两名员工
await prisma.department.create({
  data: {
    name: '技术部',
    employees: {
      create: [
        { name: '小张' },
        { name: '小李' },
      ],
    },
  },
});
```

#### 查询关联记录

使用 `include` 选项可以在查询主记录时，一并带出其关联的记录。

```typescript
const departmentWithEmployees = await prisma.department.findUnique({
  where: { id: 1 },
  include: { employees: true }, // 包含所有关联的员工
});
```

#### 更新关联记录

在更新时，可以使用 `connect`、`disconnect`、`create`、`update`、`delete` 等操作来管理关系。

```typescript
await prisma.department.update({
  where: { id: 1 },
  data: {
    name: '新部门',
    employees: {
      create: [{ name: '小刘' }], // 创建一个新员工并关联
      connect: [{ id: 5 }], // 关联一个已存在的 ID 为 5 的员工
      disconnect: [{ id: 2 }], // 解除与 ID 为 2 的员工的关联
      delete: [{ id: 3 }], // 删除 ID 为 3 的员工并解除关联
    },
  },
});
```

### 5.4. 执行原生 SQL

在某些复杂场景下，你可能需要执行原生 SQL。

*   **`$queryRaw`**: 用于执行返回结果的查询（如 `SELECT`）。
    ```typescript
    const users = await prisma.$queryRaw`SELECT * FROM User WHERE age > ${minAge}`;
    ```

*   **`$executeRaw`**: 用于执行不返回数据的命令（如 `UPDATE`, `DELETE`）。
    ```typescript
    const deletedCount = await prisma.$executeRaw`DELETE FROM Post WHERE published = false`;
    ```

## 6. 实战：整合 Prisma 与 NestJS

本节将演示如何将 Prisma 集成到一个 NestJS 项目中，构建一个健壮的后端服务。

### 6.1. 初始化 NestJS 项目

```bash
nest new nest-prisma-project -p npm
cd nest-prisma-project
```

### 6.2. 添加并配置 Prisma

```bash
# 安装 Prisma
npm install prisma

# 初始化 Prisma
npx prisma init
```

修改 `.env` 和 `prisma/schema.prisma` 文件，定义 `Department` 和 `Employee` 模型，如前文所示。然后运行迁移：

```bash
npx prisma migrate dev --name init-department-employee
```

### 6.3. 创建 PrismaService

为了在 NestJS 的依赖注入系统中使用 Prisma Client，我们创建一个可注入的 `PrismaService`。

```bash
nest g service prisma --flat --no-spec
```

修改 `src/prisma.service.ts`：

```typescript
// src/prisma.service.ts
import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  constructor() {
    super({
      log: [{ emit: 'stdout', level: 'query' }],
    });
  }

  async onModuleInit() {
    // 在模块初始化时连接数据库
    await this.$connect();
  }
}
```
这个服务继承了 `PrismaClient`，并在模块初始化时自动连接数据库。

### 6.4. 创建业务模块

现在我们创建 `Department` 相关的服务和控制器。

```bash
nest g module department
nest g service department/department --no-spec
nest g controller department/department --no-spec
```

将 `PrismaService` 注册为全局模块，这样任何模块都可以注入它。

修改 `src/app.module.ts`：

```typescript
import { Module, Global } from '@nestjs/common';
import { PrismaService } from './prisma.service';
// ... 其他 imports

@Global() // 声明为全局模块
@Module({
  providers: [PrismaService],
  exports: [PrismaService], // 导出 PrismaService 供其他模块使用
})
export class PrismaModule {}

@Module({
  imports: [PrismaModule], // 导入 PrismaModule
  // ...
})
export class AppModule {}
```

### 6.5. 实现业务逻辑

在 `DepartmentService` 中注入 `PrismaService` 并实现业务逻辑。

修改 `src/department/department.service.ts`：

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class DepartmentService {
  constructor(private prisma: PrismaService) {}

  async create(data: Prisma.DepartmentCreateInput) {
    return this.prisma.department.create({ data });
  }

  async findAll() {
    return this.prisma.department.findMany({ include: { employees: true } });
  }
}
```

### 6.6. 创建 API 接口

在 `DepartmentController` 中创建 API 端点。

修改 `src/department/department.controller.ts`：

```typescript
import { Controller, Get, Post, Body } from '@nestjs/common';
import { DepartmentService } from './department.service';
import { Prisma } from '@prisma/client';

@Controller('department')
export class DepartmentController {
  constructor(private readonly departmentService: DepartmentService) {}

  @Post()
  create(@Body() createDepartmentDto: Prisma.DepartmentCreateInput) {
    return this.departmentService.create(createDepartmentDto);
  }

  @Get()
  findAll() {
    return this.departmentService.findAll();
  }
}
```

### 6.7. 启动并测试

最后，启动 NestJS 应用：

```bash
npm run start:dev
```

现在你可以使用 Postman 或 `curl` 等工具访问 `http://localhost:3000/department` 来创建和查询部门数据了。

## 7. 总结

Prisma 以其独特的 DSL、类型安全的客户端和强大的迁移工具，为现代应用开发提供了一套高效、可靠的数据库解决方案。从快速原型开发到复杂的生产级应用，Prisma 都能游刃有余。通过与 NestJS 等框架的无缝集成，它进一步简化了后端开发的复杂性，让开发者能更专注于业务逻辑本身。希望这篇全面的指南能帮助你掌握 Prisma，并在你的下一个项目中发挥它的威力。
