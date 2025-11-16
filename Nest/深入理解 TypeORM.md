# 深入理解 TypeORM：从入门到实战

## 一、初识 TypeORM

TypeORM 是一个流行的 TypeScript 和 JavaScript ORM（对象关系映射）工具，它支持使用 MySQL、PostgreSQL、SQLite、Microsoft SQL Server、Oracle 以及 MongoDB 等多种数据库。

TypeORM 旨在提供一种有效的方式来管理数据库操作，并通过实体（Entity）和数据库表之间的映射来简化数据层的开发。它可以在 Node.js 环境中运行，特别适合于使用 TypeScript 编写的应用程序。

### 1.1 环境搭建与初始化

在开始之前，请确保你的环境中已经安装了 Node.js 和 npm。

#### 步骤 1：初始化 TypeORM 项目

使用官方脚手架可以快速创建一个新的 TypeORM 项目。

```bash
npx typeorm@latest init --name typeorm-app --database mysql
cd typeorm-app
```

#### 步骤 2：安装数据库驱动

TypeORM 需要相应的数据库驱动来连接数据库。对于 MySQL，我们推荐使用 `mysql2`。

```bash
npm install mysql2
```

#### 步骤 3：配置数据源（`data-source.ts`）

项目根目录下的 `src/data-source.ts` 文件是数据库连接的核心配置文件。你需要根据你的数据库信息修改它。

```typescript
// src/data-source.ts
import 'reflect-metadata'
import { DataSource } from 'typeorm'
import { User } from './entity/User'

// 配置和管理数据库连接
export const AppDataSource = new DataSource({
	type: 'mysql', // 指定数据库类型为 MySQL
	host: 'localhost', // 数据库主机地址
	port: 3306, // MySQL 数据库的默认端口号
	username: 'root', // 数据库连接的用户名
	password: 'xxx', // 数据库连接的密码，请替换为你的实际密码
	database: 'typeorm_test', // 要连接的数据库名称
	synchronize: true, // 在开发环境中，设置为 true 可自动创建或更新数据库表结构
	logging: true, // 开启日志记录，便于调试
	entities: [User], // 注册实体到当前数据源
	migrations: [], // 迁移文件数组
	subscribers: [], // 订阅者文件数组
	connectorPackage: 'mysql2', // 指定连接器包为 'mysql2'
	extra: {
		connectionLimit: 10, // 连接池的大小
	},
})
```

**注意**：`synchronize: true` 功能强大，它会根据你的实体定义自动同步数据库表结构。这在开发阶段非常方便，但**在生产环境中极其危险**，可能导致数据丢失，后续我们会介绍更安全的“迁移（Migration）”方案。

#### 步骤 4：创建数据库

在你的 MySQL 服务中创建一个用于测试的数据库。

```sql
CREATE DATABASE `typeorm_test` DEFAULT CHARACTER SET utf8mb4;
```

#### 步骤 5：运行项目

脚手架项目默认会在 `src/index.ts` 中包含一些示例代码。你可以通过以下命令运行它：

```bash
npm run start
```

如果一切顺利，TypeORM 会连接到数据库，并根据 `src/entity/User.ts` 中的定义自动创建 `user` 表，并插入一条示例数据。

## 二、核心概念与基础 CRUD

### 2.1 实体（Entity）与数据表映射

在 TypeORM 中，一个实体类对应数据库中的一张表。通过装饰器，我们可以精确地控制实体属性如何映射到表字段。

脚手架生成的 `User` 实体是一个很好的例子：

```typescript
// src/entity/User.ts
import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm'

@Entity() // 标记这个类是一个实体
export class User {
	@PrimaryGeneratedColumn() // 标记为主键，并设置自增
	id: number

	@Column() // 标记为一个数据列
	firstName: string

	@Column()
	lastName: string

	@Column()
	age: number
}
```

#### @Column 装饰器的常用选项

`@Column` 装饰器非常灵活，它接受一个选项对象来定义字段的各种属性：

1.  **`type`**：指定列的数据库类型，如 `varchar`, `int`, `text`, `double`, `boolean` 等。若不指定，TypeORM 会根据 TypeScript 类型自动推断。
    ```typescript
    @Column({ type: 'text' })
    description: string;
    ```

2.  **`length`**：为字符串类型（如 `varchar`）指定长度。
    ```typescript
    @Column({ length: 100 })
    title: string;
    ```

3.  **`name`**：指定数据库中字段的名称。
    ```typescript
    @Column({ name: 'first_name' })
    firstName: string;
    ```

4.  **`nullable`**：布尔值，表示该列是否可以存储 `NULL`，默认为 `false`。
    ```typescript
    @Column({ nullable: true })
    nickname: string | null;
    ```

5.  **`default`**：为列设置默认值。
    ```typescript
    @Column({ default: 1 })
    status: number;
    ```

6.  **`unique`**：布尔值，确保该列的值在表中是唯一的。
    ```typescript
    @Column({ unique: true })
    email: string;
    ```

7.  **`comment`**：为数据库字段添加注释。
    ```typescript
    @Column({ comment: '用户年龄' })
    age: number;
    ```

8.  **`update`** 和 **`select`**：布尔值，分别控制该列是否在 `save` 操作时被更新、在查询时是否默认被选中，默认为 `true`。
    ```typescript
    @Column({ select: false }) // 默认查询时不返回密码
    password: string;
    ```

9.  **`precision`** 和 **`scale`**：用于 `decimal` 或 `numeric` 类型，定义数值的总精度和 小数位数。
    ```typescript
    @Column({ type: 'decimal', precision: 10, scale: 2 })
    price: number;
    ```

### 2.2 增删改查（CRUD）

TypeORM 主要通过 `EntityManager` 或 `Repository` 来执行数据库操作。

#### 初始化连接

所有操作前，都需要初始化 `DataSource`。通常在应用的入口文件执行。

```typescript
// src/index.ts
import { AppDataSource } from './data-source'
import { User } from './entity/User'

AppDataSource.initialize()
	.then(async () => {
		console.log('数据源已初始化...')
		// 在这里执行你的数据库操作

	})
	.catch(error => console.log('数据源初始化错误', error))
```

#### 增加与修改 (`save`)

`save` 方法是一个通用方法。如果传入的对象**不包含主键**，它会执行**插入**操作；如果**包含主键**，则会执行**更新**操作。它会根据主键是否存在来决定，不会总是进行预查询。

```typescript
// 插入新用户
const user = new User()
user.firstName = 'Timber'
user.lastName = 'Saw'
user.age = 25
await AppDataSource.manager.save(user)
console.log('用户已保存，id 为: ' + user.id)

// 更新用户
const userToUpdate = await AppDataSource.manager.findOneBy(User, { id: 1 })
if (userToUpdate) {
    userToUpdate.age = 26
    await AppDataSource.manager.save(userToUpdate)
    console.log('用户已更新')
}
```

**批量操作**：`save` 也支持批量插入和更新。

```typescript
// 批量插入
await AppDataSource.manager.save(User, [
    { firstName: 'n1', lastName: 'n1', age: 21 },
    { firstName: 'n2', lastName: 'n2', age: 22 },
]);

// 批量更新
await AppDataSource.manager.save(User, [
    { id: 2, firstName: 'new_n2' },
    { id: 3, firstName: 'new_n3' },
]);
```

#### 查询 (`find`, `findOne`, `findBy`, `findOneBy`)

TypeORM 提供了丰富的查询方法。

*   `find`：查询多条记录。
*   `findOne`：查询单条记录。
*   `findBy` 和 `findOneBy`：`find` 和 `findOne` 的简化版，只接受 `where` 条件。

```typescript
// 查询所有用户
const allUsers = await AppDataSource.manager.find(User)

// 带条件查询
const users = await AppDataSource.manager.find(User, {
    select: { // 选择要查询的列
        firstName: true,
        age: true,
    },
    where: { // 查询条件
        age: 21,
    },
    order: { // 排序
        id: 'DESC',
    },
    skip: 0, // 分页：跳过
    take: 10, // 分页：获取
})

// 查询单个用户
const firstUser = await AppDataSource.manager.findOneBy(User, { age: 21 })
```

#### 删除 (`delete`, `remove`)

*   `delete`：根据主键或条件删除，效率更高。
*   `remove`：需要先获取实体对象，再进行删除。

```typescript
// 根据 ID 删除
await AppDataSource.manager.delete(User, 1) // 删除 id 为 1 的记录
await AppDataSource.manager.delete(User, [2, 3]) // 删除 id 为 2 和 3 的记录

// 根据实体对象删除
const userToRemove = await AppDataSource.manager.findOneBy(User, { id: 4 })
if (userToRemove) {
    await AppDataSource.manager.remove(userToRemove)
}
```

#### 使用 Repository 简化操作

每次都使用 `AppDataSource.manager` 并传入实体类会有些繁琐。`Repository` 模式可以将操作范围限定在单个实体上。

```typescript
const userRepository = AppDataSource.getRepository(User)

// 使用 userRepository 进行操作
await userRepository.save({ firstName: 'repo', lastName: 'test', age: 30 })
const specificUser = await userRepository.findOneBy({ id: 5 })
```

#### 事务处理

对于需要保证原子性的多个操作，可以使用 `transaction`。

```typescript
await AppDataSource.manager.transaction(async transactionalEntityManager => {
    await transactionalEntityManager.save(User, { id: 6, age: 99 })
    // ... 其他操作
    // 如果这里发生错误，所有操作都会回滚
})
```

## 三、深入理解实体关系映射

数据库表关系是构建复杂应用的基础。TypeORM 通过装饰器优雅地处理了这些关系。

### 3.1 一对一（One-to-One）关系

例如，一个用户（User）对应一张身份证（IdCard）。

#### 步骤 1：创建实体

```bash
npx typeorm entity:create src/entity/IdCard
```

```typescript
// src/entity/IdCard.ts
import { Entity, PrimaryGeneratedColumn, Column, OneToOne, JoinColumn } from 'typeorm'
import { User } from './User'

@Entity()
export class IdCard {
    @PrimaryGeneratedColumn()
    id: number

    @Column({ length: 50, comment: '身份证号' })
    cardNumber: string

    // 建立与 User 的一对一关系
    @OneToOne(() => User)
    @JoinColumn() // 指定 IdCard 是关系的所有者，它将包含外键
    user: User
}
```

*   `@OneToOne`: 定义一对一关系。
*   `@JoinColumn`: 标记关系的所有者方，外键将建在这张表上。

#### 步骤 2：反向关系（可选）

如果你希望从 `User` 实体也能访问到 `IdCard`，需要在 `User` 实体中添加反向关系。

```typescript
// src/entity/User.ts
// ...
import { IdCard } from './IdCard'

@Entity()
export class User {
    // ... 其他字段

    @OneToOne(() => IdCard, idCard => idCard.user) // 第二个参数指定了关系的另一端是如何关联回来的
    idCard: IdCard
}
```

#### 步骤 3：关联 CRUD

**保存**：通过设置 `cascade: true`，可以实现级联保存。

```typescript
// 在 IdCard 的 @OneToOne 装饰器中设置
@OneToOne(() => User, { cascade: true })
user: User
```

```typescript
// 保存时，只需保存关系的主要实体
const user = new User()
user.firstName = 'yun'
user.lastName = 'mu'
user.age = 18

const idCard = new IdCard()
idCard.cardNumber = '123456789'
idCard.user = user // 建立关联

// 只需保存 idCard，关联的 user 会被自动保存
await AppDataSource.manager.save(idCard)
```

**查询**：使用 `relations` 选项来加载关联数据。

```typescript
const idCards = await AppDataSource.manager.find(IdCard, {
    relations: {
        user: true, // 加载关联的 user
    },
})
console.log(idCards[0].user)
```

**使用 QueryBuilder 进行连接查询**：

```typescript
const idCardWithUser = await AppDataSource.getRepository(IdCard)
    .createQueryBuilder('idCard') // 'idCard' 是别名
    .leftJoinAndSelect('idCard.user', 'user') // 'user' 是关联属性和别名
    .where('idCard.id = :id', { id: 1 })
    .getOne()
```

### 3.2 一对多（One-to-Many）关系

例如，一个部门（Department）可以有多个员工（Employee）。

#### 步骤 1：创建实体

```typescript
// src/entity/Department.ts
import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm'
import { Employee } from './Employee'

@Entity()
export class Department {
    @PrimaryGeneratedColumn()
    id: number

    @Column({ length: 50 })
    name: string

    // "一" 的一方
    @OneToMany(() => Employee, employee => employee.department, {
        cascade: true, // 级联保存
    })
    employees: Employee[]
}

// src/entity/Employee.ts
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm'
import { Department } from './Department'

@Entity()
export class Employee {
    @PrimaryGeneratedColumn()
    id: number

    @Column({ length: 50 })
    name: string

    // "多" 的一方，是关系的所有者
    @ManyToOne(() => Department, department => department.employees)
    department: Department
}
```

*   `@OneToMany`: 定义“一”的一方，它不拥有外键。
*   `@ManyToOne`: 定义“多”的一方，它拥有外键。

#### 步骤 2：关联 CRUD

**保存**：

```typescript
const e1 = new Employee(); e1.name = '张三';
const e2 = new Employee(); e2.name = '李四';

const d1 = new Department();
d1.name = '技术部';
d1.employees = [e1, e2]; // 建立关联

// 因为设置了 cascade，保存 d1 会同时保存 e1 和 e2
await AppDataSource.manager.save(d1);
```

**查询**：

```typescript
const departments = await AppDataSource.manager.find(Department, {
    relations: {
        employees: true,
    },
})
console.log(departments[0].employees)
```

### 3.3 多对多（Many-to-Many）关系

例如，一篇文章（Article）可以有多个标签（Tag），一个标签也可以属于多篇文章。

#### 步骤 1：创建实体

TypeORM 会自动创建一个中间表来处理多对多关系。

```typescript
// src/entity/Article.ts
import { Entity, PrimaryGeneratedColumn, Column, ManyToMany, JoinTable } from 'typeorm'
import { Tag } from './Tag'

@Entity()
export class Article {
    @PrimaryGeneratedColumn()
    id: number

    @Column({ length: 100 })
    title: string

    @Column('text')
    content: string

    @ManyToMany(() => Tag, { cascade: true })
    @JoinTable() // 关系的所有者方需要 @JoinTable
    tags: Tag[]
}

// src/entity/Tag.ts
import { Entity, PrimaryGeneratedColumn, Column, ManyToMany } from 'typeorm'
import { Article } from './Article'

@Entity()
export class Tag {
    @PrimaryGeneratedColumn()
    id: number

    @Column({ length: 100 })
    name: string

    // 反向关系
    @ManyToMany(() => Article, article => article.tags)
    articles: Article[]
}
```

*   `@ManyToMany`: 定义多对多关系。
*   `@JoinTable`: 必须在关系的一方使用，通常是更容易操作的一方。它会创建中间表。

#### 步骤 2：关联 CRUD

**保存**：

```typescript
const tag1 = new Tag(); tag1.name = 'TS';
const tag2 = new Tag(); tag2.name = 'Node.js';
await AppDataSource.manager.save([tag1, tag2]); // 先保存 Tag

const article = new Article();
article.title = '深入 TypeORM';
article.content = '...';
article.tags = [tag1, tag2]; // 建立关联

await AppDataSource.manager.save(article);
```

**查询**：

```typescript
const articles = await AppDataSource.manager.find(Article, {
    relations: {
        tags: true,
    },
})
console.log(articles[0].tags)
```

**更新关系**：要修改文章的标签，只需查询文章，修改 `tags` 数组，然后重新 `save`。

```typescript
const articleToUpdate = await AppDataSource.manager.findOne(Article, {
    where: { id: 1 },
    relations: { tags: true },
});
if (articleToUpdate) {
    // 只保留 TS 标签
    articleToUpdate.tags = articleToUpdate.tags.filter(tag => tag.name === 'TS');
    await AppDataSource.manager.save(articleToUpdate);
}
```

## 四、生产环境最佳实践：数据库迁移（Migration）

在开发中，`synchronize: true` 非常方便。但在生产环境中，自动同步可能导致删除列、修改类型等破坏性操作，从而丢失数据。因此，生产环境必须使用**迁移（Migration）**。

迁移允许你通过代码来管理数据库结构的版本变更。每个变更都是一个迁移文件，可以被执行或回滚。

#### 步骤 1：关闭 `synchronize`

在 `data-source.ts` 中，将 `synchronize` 设置为 `false`，并配置 `migrations` 路径。

```typescript
// ...
synchronize: false, // 关闭自动同步
migrations: ['src/migration/*.ts'], // 指定迁移文件目录
// ...
```

#### 步骤 2：生成迁移文件

当你修改了实体（例如，给 `User` 添加一个 `nickname` 字段）后，TypeORM 可以比较当前实体定义和数据库结构，自动生成迁移文件。

```bash
npx typeorm-ts-node-esm migration:generate ./src/migration/AddUserNickname -d ./src/data-source.ts
```

这会创建一个类似 `1714217766579-AddUserNickname.ts` 的文件，内容如下：

```typescript
import { MigrationInterface, QueryRunner } from "typeorm";

export class AddUserNickname1714217766579 implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        // "up" 方法定义了如何应用变更
        await queryRunner.query(`ALTER TABLE \`user\` ADD \`nickname\` varchar(255) NOT NULL`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        // "down" 方法定义了如何撤销变更
        await queryRunner.query(`ALTER TABLE \`user\` DROP COLUMN \`nickname\``);
    }
}
```

#### 步骤 3：执行迁移

使用 `migration:run` 命令来应用所有尚未执行的迁移。

```bash
npx typeorm-ts-node-esm migration:run -d ./src/data-source.ts
```

TypeORM 会在数据库中创建一个 `migrations` 表来记录哪些迁移已经被执行。

#### 步骤 4：回滚迁移

如果需要撤销上一次的迁移，使用 `migration:revert` 命令。

```bash
npx typeorm-ts-node-esm migration:revert -d ./src/data-source.ts
```

这将执行上一次迁移文件中的 `down` 方法。

## 五、框架集成：在 NestJS 中使用 TypeORM

NestJS 与 TypeORM 有着官方的集成包，使得整合过程非常顺畅。

#### 步骤 1：安装依赖

```bash
npm install @nestjs/typeorm typeorm mysql2
```

#### 步骤 2：配置 `AppModule`

在 `app.module.ts` 中，使用 `TypeOrmModule.forRoot()` 来进行全局数据库配置。这相当于 `DataSource` 的配置。

```typescript
// src/app.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserModule } from './user/user.module';
import { User } from './user/entities/user.entity';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: 'localhost',
      port: 3306,
      username: 'root',
      password: 'xxx',
      database: 'typeorm_test',
      entities: [User], // 也可以使用 autoLoadEntities: true
      synchronize: true, // 同样，生产环境应为 false
    }),
    UserModule,
  ],
})
export class AppModule {}
```

#### 步骤 3：在功能模块中注册实体

在具体的业务模块（如 `UserModule`）中，使用 `TypeOrmModule.forFeature()` 来注册该模块需要用到的实体。这使得我们可以在服务中注入对应的 `Repository`。

```typescript
// src/user/user.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserService } from './user.service';
import { UserController } from './user.controller';
import { User } from './entities/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User])], // 注册 User 实体
  controllers: [UserController],
  providers: [UserService],
})
export class UserModule {}
```

#### 步骤 4：在服务中注入 Repository

现在，你可以在 `UserService` 中通过 `@InjectRepository()` 装饰器注入 `User` 的 `Repository`，并用它来操作数据库。

```typescript
// src/user/user.service.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CreateUserDto } from './dto/create-user.dto';
import { User } from './entities/user.entity';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}

  create(createUserDto: CreateUserDto) {
    const newUser = this.userRepository.create(createUserDto);
    return this.userRepository.save(newUser);
  }

  findAll() {
    return this.userRepository.find();
  }

  findOne(id: number) {
    return this.userRepository.findOneBy({ id });
  }

  async update(id: number, updateUserDto: UpdateUserDto) {
    const user = await this.findOne(id);
    // ... 更新逻辑
    return this.userRepository.save({ ...user, ...updateUserDto });
  }

  remove(id: number) {
    return this.userRepository.delete(id);
  }
}
```

通过这种方式，NestJS 的依赖注入系统与 TypeORM 完美结合，使得数据层的开发既高效又易于维护。
