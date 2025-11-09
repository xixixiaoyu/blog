## TypeORM 基础回顾
+ DataSource 配置：包含数据库连接的详细信息，如用户名、密码、驱动、连接池等。
+ Entity 映射：利用装饰器（如 @Entity, @PrimaryGeneratedColumn, @Column）定义数据库表结构。
+ 关系映射：通过 @OneToOne, @OneToMany, @ManyToMany 等装饰器定义表间关系。
+ 初始化与操作：DataSource.initialize 建立连接和表，EntityManager 负责实体的 CRUD 操作。



## nest 结合 typeorm
### 初始化环境
创建 Nest 项目：

```bash
nest new nest-typeorm -p npm
```

然后创建一个 crud 的模块：

```bash
nest g resource user
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714579782404-81d08eff-9a41-4e42-a0f2-45b6d5d9d272.png)

引入 mysql、typeorm：

```bash
npm install @nestjs/typeorm typeorm mysql2
```

@nestjs/typeorm 就是把 typeorm api 封装了一层。

引入动态模块 TypeOrmModule，使用 forRoot 方法进行全局注册，只需配置一次即可在任何地方使用，TypeOrmModule 是全局模块，这样就无需在每个模块中重复导入：

```typescript
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { User } from './user/entities/user.entity';
import { UserModule } from './user/user.module';

@Module({
  imports: [
    UserModule,
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: 'localhost',
      port: 3306,
      username: 'root',
      password: 'xxx',
      database: 'typeorm_test',
      synchronize: true,
      logging: true,
      entities: [User],
      poolSize: 10,
      connectorPackage: 'mysql2',
      extra: {
        authPlugin: 'sha256_password',
      },
    }),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
```

然后在 User 的 Entity 里加一些映射的信息：

```typescript
import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity({
  name: 'nest_user',
})
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({
    name: 'nest_name',
    length: 50,
  })
  name: string;
}
```

给映射的表给个名字叫 nest_user，然后有两个数据库列，分别是 id 和 nest_name。

运行：

```bash
npm run start:dev
```

在 workbench 看下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714580074724-b62b6dd3-494d-4113-83bd-e10fcc1cb3ed.png)



### CRUD 操作
然后是增删改查，我们可以注入 EntityManager 来做：

```typescript
import { Injectable } from '@nestjs/common';
import { InjectEntityManager } from '@nestjs/typeorm';
import { EntityManager } from 'typeorm';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { User } from './entities/user.entity';

@Injectable()
export class UserService {
  @InjectEntityManager()
  private manager: EntityManager;

  create(createUserDto: CreateUserDto) {
    this.manager.save(User, createUserDto);
  }

  findAll() {
    return this.manager.find(User);
  }

  findOne(id: number) {
    return this.manager.findOne(User, {
      where: { id },
    });
  }

  update(id: number, updateUserDto: UpdateUserDto) {
    this.manager.save(User, {
      id: id,
      ...updateUserDto,
    });
  }

  remove(id: number) {
    this.manager.delete(User, id);
  }
}
```

UserController 代码如下：

```typescript
import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
} from '@nestjs/common';
import { UserService } from './user.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Controller('user')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post()
  create(@Body() createUserDto: CreateUserDto) {
    return this.userService.create(createUserDto);
  }

  @Get()
  findAll() {
    return this.userService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.userService.findOne(+id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.userService.update(+id, updateUserDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.userService.remove(+id);
  }
}
```

我们使用 postman 发送 post 请求携带数据测试一下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714581711401-050c79eb-6291-4e39-8e9a-844fc6a07074.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714581724378-3fe52d39-66fd-489d-a6ea-ea08c964bd57.png)





再试试查询：

全部查询：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714581765571-83e6f3ff-c1f3-4421-bb1e-6c29d3ae6034.png)

单个查询：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714581793719-8e9d53ac-f3ba-47e0-95ff-17c2d9139eda.png)



再就是修改：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714581831199-092956cb-f7f9-45b9-bd0f-42f770fa26e2.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714581845873-395eb874-cbb4-4eb0-b24e-0cd857605418.png)



试试删除：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714581870098-c6163ad1-83c5-4315-bf0f-94dddbe54e8f.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714581882994-47201a5d-364d-4ef4-ad32-92035a1d481a.png)

至此，我们就正式打通了从请求到数据库的整个流程！



## **使用 Repository 简化数据操作**
我们上面是通过 @InjectEntityManager 来注入的 entityManager 对象。

直接用 EntityManager 的缺点是每个 api 都要带上对应的 Entity：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687794092239-665c121f-fe30-4bdb-b10b-a3191262dd71.png)

可以先 getRepository(User) 拿到 user 对应的 Repository 对象，再调用这些方法。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687794182262-26258165-beeb-49c0-9641-905efaf1ede0.png)



若需要使用特定实体的 Repository，可以通过 forFeature 方法将实体注入对应模块，便于进行 CRUD 操作：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687794551595-46d47419-4909-42ba-8673-a49546111842.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687794376276-434ae941-82fa-4f6a-8c91-3d352895c6db.png)

它有的方法和 EntityManager 一样，只能用来操作当前 Entity。

还可以注入 DataSource：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687794807945-096ca707-3c6b-4200-927e-97e3b3891733.png)

不过这个不常用。

这就是 Nest 里集成 TypeOrm 的方式。

