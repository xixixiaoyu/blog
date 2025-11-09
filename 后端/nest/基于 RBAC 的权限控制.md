## 什么是 RBAC
RBAC（Role-Based Access Control）是基于角色的权限控制。

与 ACL 直接给用户分配权限不同，RBAC 通过给角色分配权限，然后将角色分配给用户来实现权限管理。



## ACL 和 RBAC 的对比
+ ACL：直接给用户分配权限。例如，管理员有 test1、test2、test3 三个权限，如果需要给管理员添加 test4 权限，则需要分别为张三、李四、王五等用户分配这个权限。
+ RBAC：给角色分配权限，然后将角色分配给用户。例如，只需要给“管理员”角色分配 test1、test2、test3 权限，并将“管理员”角色分配给张三、李四、王五。若需添加 test4 权限，只需修改“管理员”角色的权限即可。

RBAC 的好处在于，当用户数量很多时，通过角色管理权限变得更加方便和高效。



## Nest 实现 RBAC
### 创建数据库
首先，创建一个名为 `rbac_test` 的数据库：

```sql
CREATE DATABASE rbac_test DEFAULT CHARACTER SET utf8mb4;
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1692413867437-e4d755de-f2b5-4cdf-9868-a2c168a20d78.png)

然后创建 nest 项目：

```bash
nest new rbac-test -p pnpm
```

在项目中安装 TypeORM 和 MySQL 的相关依赖：

```bash
pnpm install @nestjs/typeorm typeorm mysql2
```



### 配置 TypeORM
在 `AppModule` 中引入 `TypeOrmModule` 并进行配置：

```typescript
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: 'localhost',
      port: 3306,
      username: 'root',
      password: 'xxx',
      database: 'rbac_test',
      synchronize: true,
      logging: true,
      entities: [],
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



### 创建 User 模块
使用 Nest CLI 创建一个用户资源模块：

```bash
nest g resource user
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1692415537154-c52d035d-5d08-4ba9-bc34-fe97c5a506ba.png)



### 定义实体
添加 User、Role、Permission 的 Entity：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1692415618733-6bed3712-438a-40f7-a70b-918e290a33f0.png)

用户、角色、权限都是多对多的关系。



#### User 实体
```typescript
import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
  ManyToMany,
  JoinTable,
} from 'typeorm';
import { Role } from './role.entity';

@Entity()
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ length: 50 })
  username: string;

  @Column({ length: 50 })
  password: string;

  @CreateDateColumn()
  createTime: Date;

  @UpdateDateColumn()
  updateTime: Date;

  @ManyToMany(() => Role)
  @JoinTable({
    name: 'user_role_relation',
  })
  roles: Role[];
}
```



#### Role 实体
```typescript
import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
  ManyToMany,
  JoinTable,
} from 'typeorm';
import { Permission } from './permission.entity';

@Entity()
export class Role {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ length: 20 })
  name: string;

  @CreateDateColumn()
  createTime: Date;

  @UpdateDateColumn()
  updateTime: Date;

  @ManyToMany(() => Permission)
  @JoinTable({
    name: 'role_permission_relation',
  })
  permissions: Permission[];
}
```



#### Permission 实体
```typescript
import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity()
export class Permission {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ length: 50 })
  name: string;

  @Column({ length: 100, nullable: true })
  desc: string;

  @CreateDateColumn()
  createTime: Date;

  @UpdateDateColumn()
  updateTime: Date;
}
```



### 更新 TypeORM 配置
将实体添加到 TypeOrmModule.forRoot 配置的 entities 数组中：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716647130885-ec9b174a-7503-46fa-9998-e91cf24ab257.png)



启动 nest 服务：

```jsx
pnpm start:dev
```

在 mysql workbench 里看下这 5 个表：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716647185902-f7f0ef06-1d9d-4889-8cde-347a36554e4c.png)

外键：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716647208634-712ef56d-6bb9-40c7-994f-3fcfc35aed57.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716647227961-f6eff568-fda5-4036-9ecf-8fd2ad593778.png)



## 初始化数据
在 UserService 中添加初始化数据的方法：

```typescript
import { Injectable } from '@nestjs/common';
import { EntityManager } from 'typeorm';
import { User } from './entities/user.entity';
import { Role } from './entities/role.entity';
import { Permission } from './entities/permission.entity';
import { InjectEntityManager } from '@nestjs/typeorm';

@Injectable()
export class UserService {
  constructor(
    @InjectEntityManager() private readonly entityManager: EntityManager,
  ) {}

  private createPermission(name: string): Permission {
    const permission = new Permission();
    permission.name = name;
    return permission;
  }

  private createRole(name: string, permissions: Permission[]): Role {
    const role = new Role();
    role.name = name;
    role.permissions = permissions;
    return role;
  }

  private createUser(username: string, password: string, roles: Role[]): User {
    const user = new User();
    user.username = username;
    user.password = password;
    user.roles = roles;
    return user;
  }

  async initData() {
    await this.entityManager.transaction(async (transactionalEntityManager) => {
      const permissions = [
        this.createPermission('新增 test1'),
        this.createPermission('修改 test1'),
        this.createPermission('删除 test1'),
        this.createPermission('查询 test1'),
        this.createPermission('新增 test2'),
        this.createPermission('修改 test2'),
        this.createPermission('删除 test2'),
        this.createPermission('查询 test2'),
      ];

      const roleAdmin = this.createRole('管理员', permissions);
      const user1 = this.createUser('云云', '111', [roleAdmin]);

      const roleUser = this.createRole('普通用户', permissions.slice(0, 4));
      const user2 = this.createUser('牧牧', '222', [roleUser]);

      await transactionalEntityManager.save(permissions);
      await transactionalEntityManager.save([roleAdmin, roleUser]);
      await transactionalEntityManager.save([user1, user2]);
    });
  }
}
```

在 UserController 中添加初始化数据的方法：

```typescript
@Get('init')
async initData() {
    await this.userService.initData();
    return 'done';
}
```

在浏览器中访问 http://localhost:3000/user/init，初始化数据：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1692427421490-fc9bec4e-8bf6-48ef-a111-b798844e22f1.png)



在 mysql workbench 里看下 permission 表：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716647492709-2279f562-3536-4c79-b9d6-362dc7cdc14a.png)

role 表：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716647509179-bdfd7c7d-2e09-4e12-a057-013bbacc772b.png)

user 表：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716647520327-72a87cd7-e43f-443f-a22a-5eb52ed6639e.png)

role_permission_relation 中间表：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716647618880-c5df3ed3-fa95-434c-a02a-592213adf9e8.png)

user_role_relation 中间表：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716647563972-1b929e1d-fcde-4f63-a488-0ac7b98d3135.png)





## 添加登录接口
我们通过 jwt 的方式实现登录。

在 UserController 中新增一个 login 处理程序：

```typescript
@Inject(JwtService)
private jwtService: JwtService;

@Post('login')
async login(@Body() loginUser: UserLoginDto): Promise<{ token: string }> {
  const user = await this.userService.login(loginUser);

  console.log('user', user);

  // 使用 jwtService 生成一个包含用户名和角色的 JWT token
  const token = this.jwtService.sign({
    user: {
      username: user.username,
      roles: user.roles,
    },
  });

  return { token };
}
```

在 user/dto/user-login.dto.ts 文件中，定义 UserLoginDto：

```typescript
import { IsNotEmpty, Length } from 'class-validator';

export class UserLoginDto {
  @IsNotEmpty()
  @Length(1, 50)
  username: string;

  @IsNotEmpty()
  @Length(1, 50)
  password: string;
}
```

安装 ValidationPipe 用到的包：

```bash
pnpm install class-validator class-transformer
```

全局启用 ValidationPipe：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716647799368-54cd7d89-fd7f-4497-ae25-89895cddf4a3.png)



## 实现登录逻辑
在 UserService 中添加 login 方法：

```typescript
import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectEntityManager } from '@nestjs/typeorm';
import { EntityManager } from 'typeorm';
import { User } from './user.entity';
import { UserLoginDto } from './dto/user-login.dto';

@Injectable()
export class UserService {
    constructor(
        @InjectEntityManager() private readonly entityManager: EntityManager
    ) {}

    async login(loginUserDto: UserLoginDto): Promise<User> {
      const user = await this.entityManager.findOne(User, {
        where: { username: loginUserDto.username },
        relations: { roles: true },
      });
  
      if (!user) {
        throw new HttpException('用户不存在', HttpStatus.ACCEPTED);
      }
  
      if (user.password !== loginUserDto.password) {
        throw new HttpException('密码错误', HttpStatus.ACCEPTED);
      }
  
      return user;
  }
}
```



##  安装并配置 JwtModule
安装 JWT 相关的包：

```typescript
pnpm install @nestjs/jwt
```

在 AppModule 中引入并配置 JwtModule：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716648580191-f7632523-8b40-4c97-aab7-93511e7f55a2.png)

我们先测试下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716648968139-8c7a91af-172d-49ff-b2fa-5373698b19a1.png)

我们需要在后续请求使用这个 token。

服务端打印的 user：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716648989049-cf8da26c-792d-43f4-978c-c44948114395.png)





## 添加并配置守卫（Guards）
### 登录守卫
生成并配置 LoginGuard：

```bash
nest g guard login --no-spec --flat
```

```typescript
import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';

@Injectable()
export class LoginGuard implements CanActivate {
  @Inject()
  private reflector: Reflector;

  @Inject(JwtService)
  private jwtService: JwtService;

  canActivate(context: ExecutionContext): boolean {
    const request: Request = context.switchToHttp().getRequest();

    // 获取 require-login 元数据
    const requireLogin = this.reflector.getAllAndOverride('require-login', [
      context.getClass(),
      context.getHandler(),
    ]);

    if (!requireLogin) {
      return true;
    }

    const authorization = request.headers.authorization;

    if (!authorization) {
      throw new UnauthorizedException('用户未登录');
    }

    try {
      const token = authorization.split(' ')[1];
      const data = this.jwtService.verify(token);
      request.user = data.user;
      return true;
    } catch (e) {
      throw new UnauthorizedException('token 失效，请重新登录');
    }
  }
}
```



### 权限守卫
生成并配置 PermissionGuard：

```bash
nest g guard permission --no-spec --flat
```

```typescript
import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { UserService } from './user/user.service';
import { Role } from './user/entities/role.entity';

// typescript 同名 module 和 interface 会自动合并，所以可以这样扩展类型。
declare module 'express' {
  interface Request {
    user: {
      username: string;
      roles: Role[];
    };
  }
}

@Injectable()
export class PermissionGuard implements CanActivate {
  @Inject(UserService)
  private userService: UserService;

  @Inject(Reflector)
  private reflector: Reflector;

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request: Request = context.switchToHttp().getRequest();

    if (!request.user) {
      return true;
    }

    // 根据用户角色 ID 查找角色
    const roles = await this.userService.findRolesByIds(
      request.user.roles.map((item) => item.id),
    );

    // 获取所有角色的权限
    const permissions = new Set(
      roles.flatMap((role) => role.permissions.map((perm) => perm.name)),
    );

    console.log('permissions', Array.from(permissions));

    // 获取当前处理程序所需的权限
    const requiredPermissions = this.reflector.getAllAndOverride<string[]>(
      'permissions',
      [context.getClass(), context.getHandler()],
    );

    console.log('requiredPermissions', requiredPermissions);

    if (!requiredPermissions) {
      return true;
    }

    // 检查用户是否具有所需的每一个权限
    for (const curPermission of requiredPermissions) {
      if (!permissions.has(curPermission)) {
        throw new UnauthorizedException('您没有访问该接口的权限');
      }
    }

    return true;
  }
}
```

在 UserService 中实现 findRolesByIds 方法：

```typescript
import { EntityManager, In } from 'typeorm';

async findRolesByIds(roleIds: number[]): Promise<Role[]> {
    return this.entityManager.find(Role, {
      where: { id: In(roleIds) },
      relations: { permissions: true },
    });
  }
```

PermissionGuard 需要用到 UserService，所以在 UserModule 里导出下 UserService：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716650534821-7ba06d92-f6f2-4f51-a18e-f24f257be05d.png)



### 声明全局 Guard
在 app.module 声明上面两个 guard 为全局 Guard：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716649890638-a36ea445-4b49-40fb-a2e9-727fd05a9686.png)



## 声明自定义装饰器
在项目中添加一个 custom-decorator.ts 文件，用于放置自定义装饰器：

定义 RequirePermission 和 RequireLogin 装饰器：

```typescript
import { SetMetadata } from '@nestjs/common';

export const RequireLogin = () => SetMetadata('require-login', true);

export const RequirePermission = (...permissions: string[]) =>
  SetMetadata('permissions', permissions);

export const RequireAuth = (...permissions: string[]) => {
  return (target: any, key?: string, descriptor?: PropertyDescriptor) => {
    SetMetadata('require-login', true)(target, key, descriptor);
    SetMetadata('permissions', permissions)(target, key, descriptor);
  };
};
```

我们在需要登录的接口使用 @RequireLogin 装饰器。

需要权限的地方设置 @RequirePermission 装饰器。



## 测试
我们在 AppController 上测试下：

```typescript
import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { RequireLogin, RequirePermission } from './custom-decorator';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @RequireLogin()
  @RequirePermission('查询 test2', '修改 test2')
  getHello(): string {
    return this.appService.getHello();
  }
}
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716651587239-013c6d91-6f70-40a3-8430-271cda6c5f02.png)

我们去登录：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716651688098-fa2e13cc-153c-47d4-b335-0635524fc76e.png)

打印的 permissions 和 requiredPermissions：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716653543301-3924f19b-94d7-4b0e-bad8-c480a03721e8.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716653932406-c7f7973f-0b78-4226-b9f1-db3037f00c19.png)

我们将返回的 token 放到 header 去请求：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716651825497-1b879f18-3cf6-4acf-a8cc-7a9ce49a7756.png)

正常返回了响应。



我们重新登录其他账号：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716653595621-9ce9f55a-7e82-4d9a-a0c6-44661124967c.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716653785694-b5b96638-6e0b-4bc9-87b3-fe9ce7096ed6.png)

很明显没有权限：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716653818506-fbe519dc-e98f-4996-b31d-f5566b61d8bf.png)

此外，这里查询角色需要的权限没必要每次都查数据库，可以通过 redis 来加一层缓存，减少数据库访问，提高性能。（参考 ACL 权限那章）

