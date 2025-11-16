### 1. GraphQL 是什么？为什么需要它？

想象一下你去餐厅吃饭。

*   **传统 REST API** 就像是**套餐**。菜单上写着“A 套餐：汉堡 + 薯条 + 可乐”。你想要汉堡和薯条，但不想喝可乐，对不起，套餐是固定的，可乐也一起上来了（数据冗余/Over-fetching）。你又想额外加一份洋葱圈，对不起，套餐里没有，你需要再单独点一份“洋葱圈 API”，多跑一趟（数据不足/Under-fetching）。

*   **GraphQL** 则像是**单点**。你拿着菜单，可以精确地告诉服务员：“我想要一个汉堡（只要肉饼和面包），一份薯条，不要可乐。” 服务员（后端）就只给你你想要的东西，不多也不少。

**所以，GraphQL 的核心思想是：按需查询，让客户端精确地声明它需要什么数据，服务端就返回什么数据。**

它是一种用于 API 的**查询语言**，也是一个用于执行这些查询的**运行时**。

> **启发式提问**：在你过去的项目中，是否曾遇到过前端为了获取某个页面的数据，需要请求多个不同的 API 接口，或者某个接口返回了大量用不上的数据？GraphQL 正是为了解决这类痛点而生的。

---

### 2. 核心概念：Schema、Resolver、DTO

现在我们来拆解 GraphQL 的三个关键角色。它们就像一个精密的团队，各司其职。

#### Schema（契约/蓝图）

Schema 是 GraphQL API 的**核心**。它定义了所有客户端可以查询的“能力”，是前后端之间的**契约**。

*   **作用**：描述了数据的“形状”。比如，一个用户 `User` 有哪些字段（`id`, `name`, `email`），以及可以执行哪些操作（查询用户 `user`，创建用户 `createUser`）。
*   **语言**：通常使用 Schema Definition Language (SDL) 来编写。
*   **类比**：餐厅的**菜单**。菜单上清晰地列出了所有菜品（类型）和你可以点的操作（查询/变更）。

一个简单的 Schema 示例 (SDL)：

```graphql
# 定义一个 User 类型
type User {
  id: ID!
  name: String!
  email: String!
}

# 定义所有查询的入口
type Query {
  user(id: ID!): User
}

# 定义所有变更的入口
type Mutation {
  createUser(name: String!, email: String!): User
}
```

#### Resolver（实现者/厨房）

Schema 只是“菜单”，它声明了有什么，但没说怎么做。Resolver 就是负责**实现**这些声明的**函数**。

*   **作用**：为 Schema 中的每个字段提供实际的数据。当一个查询请求到达时，GraphQL 引擎会调用相应的 Resolver 来获取数据。
*   **类比**：餐厅的**厨房**。你点了“汉堡”（查询 `user`），厨房（Resolver）就开始动手做，最终把做好的汉堡（数据）端给你。

#### DTO（数据传输对象/订单）

DTO 主要用于**变更**操作。它定义了创建或更新数据时，客户端需要提交的数据结构。

*   **作用**：规范和验证输入数据。比如，创建用户时，`name` 和 `email` 是必填的。
*   **类比**：你点菜时填写的**订单**。订单上会写明你要的汉堡是“辣的”还是“不辣的”，面包是“黑的”还是“白的”。这个订单确保了厨房能准确理解你的需求。

> **总结一下三者的关系**：
> *   **Schema** 是**“承诺”**：我（服务端）承诺能提供这些数据和操作。
> *   **Resolver** 是**“行动”**：我来兑现这个承诺，负责把数据找出来。
> *   **DTO** 是**“规则”**：如果你想让我创建或修改数据，请按照这个规则来提供信息。

---

### 3. NestJS 中的 GraphQL 集成

NestJS 提供了非常优雅的方式来构建 GraphQL 应用，它主要通过装饰器来简化开发。NestJS 支持两种开发方式：

1.  **Code-first (代码优先)**：先写 TypeScript 类，然后用装饰器标记，NestJS 会根据这些类**自动生成** GraphQL Schema。这是我们接下来要重点演示的方式，因为它更符合 TypeScript 开发者的习惯。
2.  **Schema-first (Schema 优先)**：先写 SDL 文件定义 Schema，然后 NestJS 根据这个 Schema 来生成对应的类。

#### 实战演练：Code-first 方式

假设我们要构建一个简单的用户管理功能。

**第一步：安装依赖**

```bash
npm install @nestjs/graphql @nestjs/apollo graphql apollo-server-express
# class-validator 和 class-transformer 用于 DTO 验证
npm install class-validator class-transformer
```

**第二步：在 `app.module.ts` 中配置 GraphQL**

```typescript
// src/app.module.ts
import { Module } from '@nestjs/common'
import { GraphQLModule } from '@nestjs/graphql'
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo'
import { join } from 'path'

@Module({
  imports: [
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      // 自动生成 schema 文件，方便查看和调试
      autoSchemaFile: join(process.cwd(), 'src/schema.gql'),
      // 开发环境下开启 playground，一个可以测试 GraphQL 的 UI 界面
      playground: true,
    }),
    // ... 其他模块
  ],
})
export class AppModule {}
```

**第三步：创建实体和 DTO (定义 Schema 的“零件”)**

这里我们用 TypeScript 类来定义 GraphQL 的类型。

```typescript
// src/users/dto/user.dto.ts
import { Field, ID, ObjectType, InputType } from '@nestjs/graphql'
import { IsEmail, IsNotEmpty } from 'class-validator'

// @ObjectType() 告诉 NestJS，这个类对应 GraphQL 的一个 "type"
@ObjectType('User')
export class User {
  @Field(() => ID) // 使用 @Field 来描述 GraphQL 字段
  id: number

  @Field()
  name: string

  @Field()
  email: string
}

// @InputType() 告诉 NestJS，这个类对应 GraphQL 的一个 "input"
// 它专门用于 Mutation 的参数
@InputType()
export class CreateUserInput {
  // class-validator 的装饰器可以在这里直接使用，NestJS 会自动处理验证
  @Field()
  @IsNotEmpty()
  name: string

  @Field()
  @IsEmail()
  email: string
}
```
> **代码注释**：我们用 `@ObjectType` 和 `@InputType` 装饰器将普通的 TypeScript 类“升级”成了 GraphQL 类型定义。`@Field` 装饰器则标记了哪些属性需要暴露在 GraphQL Schema 中。这就是 Code-first 的精髓：用代码来定义 Schema。

**第四步：创建 Resolver (实现业务逻辑)**

Resolver 是处理请求的地方。

```typescript
// src/users/users.resolver.ts
import { Resolver, Query, Mutation, Args } from '@nestjs/graphql'
import { User, CreateUserInput } from './dto/user.dto'
import { UsersService } from './users.service'

@Resolver(() => User) // 声明这个 Resolver 主要负责处理 User 类型的请求
export class UsersResolver {
  // 注入 Service，保持 Resolver 的简洁，业务逻辑交给 Service
  constructor(private readonly usersService: UsersService) {}

  // @Query 将此方法标记为 Schema 中的一个 Query 字段
  // { nullable: true } 表示当找不到用户时，可以返回 null
  @Query(() => User, { name: 'user', nullable: true })
  async getUser(@Args('id', { type: () => ID }) id: number): Promise<User> {
    return this.usersService.findById(id)
  }

  // @Mutation 将此方法标记为 Schema 中的一个 Mutation 字段
  @Mutation(() => User, { name: 'createUser' })
  async createUser(
    @Args('input') createUserInput: CreateUserInput, // 使用 DTO 作为参数类型
  ): Promise<User> {
    // NestJS 会自动根据 CreateUserInput 的验证规则来校验输入
    return this.usersService.create(createUserInput)
  }
}
```
> **代码注释**：`@Resolver`、`@Query`、`@Mutation`、`@Args` 这些装饰器是 NestJS 的魔法所在。它们将我们的方法与 GraphQL Schema 紧密地绑定在一起，让代码可读性极高。我们将数据操作逻辑（比如增删改查）放在 `UsersService` 中，这是一种良好的分层设计。

**第五步：创建 Service (处理数据)**

Service 负责具体的业务逻辑和数据操作。

```typescript
// src/users/users.service.ts
import { Injectable } from '@nestjs/common'
import { User, CreateUserInput } from './dto/user.dto'

@Injectable()
export class UsersService {
  // 假设这是我们内存中的“数据库”
  private readonly users: User[] = []
  private nextId = 1

  async create(createUserInput: CreateUserInput): Promise<User> {
    const newUser = {
      id: this.nextId++,
      ...createUserInput,
    }
    this.users.push(newUser)
    return newUser
  }

  async findById(id: number): Promise<User | undefined> {
    return this.users.find(user => user.id === id)
  }
}
```

最后，不要忘记在 `users.module.ts` 中将所有部分组合起来。

```typescript
// src/users/users.module.ts
import { Module } from '@nestjs/common'
import { UsersResolver } from './users.resolver'
import { UsersService } from './users.service'

@Module({
  providers: [UsersResolver, UsersService], // 注册 Resolver 和 Service
})
export class UsersModule {}
```

现在，启动你的 NestJS 应用，访问 `http://localhost:3000/graphql`，你就能看到 Apollo Playground 了。你可以尝试执行如下查询和变更：

```graphql
# 创建一个用户
mutation {
  createUser(input: { name: "Alice", email: "alice@example.com" }) {
    id
    name
    email
  }
}

# 查询刚刚创建的用户 (假设返回的 id 是 1)
query {
  user(id: "1") {
    name
  }
}
```

### 总结

我们来回顾一下今天的内容：

*   **GraphQL** 是一种强大的 API 查询语言，核心是**按需获取**，解决了 REST 中的 Over-fetching 和 Under-fetching 问题。
*   **Schema** 是 API 的**契约**，定义了数据的类型和可执行的操作。
*   **Resolver** 是 Schema 的**实现**，负责为每个字段提供数据。
*   **DTO** 是用于**变更操作**的**数据验证和传输对象**。
*   **NestJS** 通过**装饰器**和**模块化**，极大地简化了 GraphQL 应用的开发。在 **Code-first** 模式下，我们用 TypeScript 类来定义 Schema，NestJS 帮我们处理了其余的繁琐工作。

这只是一个开始，GraphQL 还有更多强大的特性，比如数据加载、订阅、中间件等。