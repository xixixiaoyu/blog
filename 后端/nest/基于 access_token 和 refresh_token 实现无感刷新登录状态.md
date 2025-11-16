## 单 Token 存在的问题
在最初的设计中，用户登录后系统返回一个 `access_token`，每次访问受保护的接口时都需要携带这个 Token 并进行验证。

然而，这种方法有一个明显的问题：

+ `access_token` 的有效期通常较短（例如 30 分钟），以确保安全性。
+ 如果用户在 Token 过期后继续访问系统，会被要求重新登录，用户体验较差。



## 双 Token 的解决方案
为了解决上述问题，可以引入双 Token 机制：

+ `access_token`：用于认证用户身份，有效期较短（例如 30 分钟）。
+ `refresh_token`：用于刷新 `access_token`，有效期较长（例如 7 天）。



这种机制的工作流程如下：

1. 用户登录成功后，系统返回 `access_token` 和 `refresh_token`。
2. 用户访问受保护的接口时，使用 `access_token` 进行鉴权。
3. 如果 `access_token` 过期，系统使用 `refresh_token` 获取新的 `access_token` 和 `refresh_token`。
4. 如果 `refresh_token` 也过期，用户需要重新登录。



## 具体实现
### 创建 Nest 项目并配置数据库
我们来实现下，创建个 nest 项目：

```bash
nest new access_token_and_refresh_token -p pnpm
```

安装 TypeORM 和 MySQL 依赖：

```bash
pnpm install @nestjs/typeorm typeorm mysql2
```

在 `AppModule` 中配置 TypeORM：

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
      database: 'refresh_token_test',
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

在 MySQL Workbench 中创建数据库：

```typescript
CREATE DATABASE refresh_token_test DEFAULT CHARACTER SET utf8mb4;
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1692504364954-6c3c9c03-dd43-4789-afcc-200dabd4fff8.png)



###  定义 User 实体
新建 User 实体：

```bash
nest g resource user --no-spec
```

```typescript
import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity()
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({
    length: 50,
  })
  username: string;

  @Column({
    length: 50,
  })
  password: string;
}
```

AppModule 注册：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716702713426-53a65928-4b1b-4eaf-a751-00c79a8b8901.png)

运行服务：

```typescript
pnpm start:dev
```

可以看到 user 表：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716704476706-fbc3ad20-6038-4d92-97c2-6dd7076dd701.png)



### 初始化 Login 接口
UserController 添加 login 接口：

```typescript
import { Controller, Post, Body } from '@nestjs/common';
import { LoginUserDto } from './dto/login-user.dto';

@Controller('user')
export class UserController {
  @Post('login')
  login(@Body() loginUser: LoginUserDto) {
    console.log(loginUser);
    return 'success';
  }
}
```

创建 src/user/dto/login-user.dto.ts：

```typescript
export class LoginUserDto {
  username: string;
  password: string;
}
```

测试下：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1692505131463-79ec7eeb-5134-4819-bf46-ddad4b21382f.png)

服务端接收到了

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1692505150197-e2fbb80d-ebb3-4a43-ad8a-2b0a76205d13.png)



### 实现用户登录
 `UserService` 中实现 login 方法：

```typescript
import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { InjectEntityManager } from '@nestjs/typeorm';
import { EntityManager } from 'typeorm';
import { LoginUserDto } from './dto/login-user.dto';
import { User } from './entities/user.entity';

@Injectable()
export class UserService {
  // 注入 EntityManager 实例
  @InjectEntityManager()
  private entityManager: EntityManager;

  // 用户登录方法
  async login(loginUserDto: LoginUserDto) {
    // 根据用户名查找用户
    const user = await this.entityManager.findOne(User, {
      where: { username: loginUserDto.username },
    });

    // 如果用户不存在，抛出异常
    if (!user) {
      throw new HttpException('用户不存在', HttpStatus.OK);
    }

    // 如果密码不匹配，抛出异常
    if (user.password !== loginUserDto.password) {
      throw new HttpException('密码错误', HttpStatus.OK);
    }

    // 返回用户信息
    return user;
  }
}
```



### 引入和配置 JWT
登录成功之后要返回两个 token，我们需要安装 JWT 相关依赖：

```typescript
pnpm install @nestjs/jwt
```

在 `AppModule` 中引入 `JwtModule`：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716704832677-259e0b60-e96c-4e0d-b515-1f318b565f82.png)



###  生成并返回 Token
在 UserController 生成两个 token 返回：

```typescript
import { JwtService } from '@nestjs/jwt';
import { Body, Controller, Inject, Post } from '@nestjs/common';
import { LoginUserDto } from './dto/login-user.dto';
import { UserService } from './user.service';

@Controller('user')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Inject(JwtService)
  private jwtService: JwtService;

  @Post('login')
  async login(@Body() loginUser: LoginUserDto) {
    const user = await this.userService.login(loginUser);

    const access_token = this.jwtService.sign(
      {
        userId: user.id,
        username: user.username,
      },
      { expiresIn: '30m' },
    );

    const refresh_token = this.jwtService.sign(
      { userId: user.id },
      { expiresIn: '7d' },
    );

    return { access_token, refresh_token };
  }
}
```

+ 使用 JwtService 生成一个访问令牌（access token），包含用户 ID 和用户名，有效期为 30 分钟。
+ 使用 JwtService 生成一个刷新令牌（refresh token），只包含用户 ID，有效期为 7 天。

我们在数据库手动添加个用户数据：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716704994586-6b57e9c8-2139-4fbf-8897-a58ed115ebbe.png)

访问下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716705066882-0f883cf2-2976-4c18-9c39-0fd644e9f193.png)

返回了两个 token。



### 实现登录鉴权 Guard
创建 LoginGuard：

```bash
nest g guard login --flat --no-spec
```

实现鉴权逻辑：

```typescript
import { JwtService } from '@nestjs/jwt';
import {
  CanActivate,
  ExecutionContext,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Request } from 'express';

@Injectable()
export class LoginGuard implements CanActivate {
  @Inject(JwtService)
  private jwtService: JwtService;

  canActivate(context: ExecutionContext): boolean {
    // 获取当前请求对象
    const request: Request = context.switchToHttp().getRequest();
    // 从请求头中获取 authorization 字段
    const authorization = request.headers.authorization;

    // 如果没有 authorization 字段，抛出未授权异常
    if (!authorization) {
      throw new UnauthorizedException('用户未登录');
    }

    try {
      // 从 authorization 字段中提取 token
      const token = authorization.split(' ')[1];
      // 使用 jwtService 验证 token
      this.jwtService.verify(token);
      // 验证通过，返回 true
      return true;
    } catch (e) {
      throw new UnauthorizedException('token 失效，请重新登录');
    }
  }
}
```

在 `AppController` 中添加受保护的接口：

```typescript
import { Controller, Get, UseGuards } from '@nestjs/common';
import { LoginGuard } from './login.guard';

@Controller()
export class AppController {
  @Get('test1')
  test1() {
    return 'test1';
  }

  @Get('test2')
  @UseGuards(LoginGuard)
  test2() {
    return 'test2';
  }
}
```

test1 接口可以直接访问，test2 接口需要登录后才能访问：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716705203161-3f8591df-2ad5-49c4-9989-10579e54007b.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716705233995-b28567ef-1f99-4c93-b522-476f8fad85c3.png)

然后访问登录接口 /user/login 获取 access_token，加到 header 里再访问 test2 接口：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716705343962-7a05f002-510f-427e-926e-90dbbfa84712.png)

正常访问了。



### 实现 Token 刷新逻辑
在 `UserController` 中添加 Token 刷新接口：

```typescript
import { Query, UnauthorizedException } from '@nestjs/common';

@Controller('user')
export class UserController {
  // ...

  @Get('refresh')
  async refresh(@Query('refresh_token') refreshToken: string) {
    try {
      // 验证 refresh_token 的有效性
      const data = this.jwtService.verify(refreshToken);
      // 根据从 token 中解析出来的用户 ID 查找用户
      const user = await this.userService.findUserById(data.userId);

      // 生成新的 access_token，有效期为 30 分钟
      const access_token = this.jwtService.sign({
        userId: user.id,
        username: user.username,
      }, { expiresIn: '30m' });

      // 生成新的 refresh_token，有效期为 7 天
      const refresh_token = this.jwtService.sign({ userId: user.id }, { expiresIn: '7d' });

      // 返回新的 access_token 和 refresh_token
      return { access_token, refresh_token };
    } catch (e) {
      // 如果 token 验证失败，抛出 UnauthorizedException 异常，提示用户重新登录
      throw new UnauthorizedException('token 已失效，请重新登录');
    }
  }
}
```

每次刷新 access_token 时同时返回新的 refresh_token，可以避免旧的 refresh_token 长期有效，从而提升系统的安全性。

接着在 `UserService` 中实现查找用户的方法：

```typescript
async findUserById(userId: number) {
    return await this.entityManager.findOne(User, { where: { id: userId } });
}
```

直接访问接口：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716705474971-0a81f102-be46-43bd-80ac-673a172a397c.png)

我们需要带上 refresh_token：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716705547617-2c3ef3a2-2fb9-42a0-8bc0-971a98562031.png)

这样就能拿到新的 access_token 和 refresh_token。



### 前端实现 Token 刷新机制
创建 React 项目并安装 Axios：

```bash
pnpm create vite refresh_token_react_test --template react-ts
cd refresh_token_react_test
pnpm install
pnpm install axios
```

 在 App.tsx 中实现接口调用：

```typescript
import axios from 'axios';
import { useEffect, useState } from 'react';

function App() {
	const [res1, setRes1] = useState<string>();
	const [res2, setRes2] = useState<string>();

	async function login() {
		const res = await axios.post('http://localhost:3000/user/login', {
			username: '云云',
			password: '111',
		});

		// 将 access_token 和 refresh_token 存储到本地存储中
		localStorage.setItem('access_token', res.data?.access_token || '');
		localStorage.setItem('refresh_token', res.data?.refresh_token || '');
	}

	async function query() {
		// 如果本地存储中没有 access_token，则先进行登录
		if (!localStorage.getItem('access_token')) {
			console.log(111222);

			await login();
		}

		const { data: test1Data } = await axios.get('http://localhost:3000/test1');
		console.log('data', test1Data);
		const { data: test2Data } = await axios.get('http://localhost:3000/test2', {
			headers: {
				Authorization: 'Bearer ' + localStorage.getItem('access_token'),
			},
		});

		setRes1(test1Data);
		setRes2(test2Data);
	}

	useEffect(() => {
		query();
	}, []);

	return (
		<>
			<div>res1: {res1}</div>
			<div>res2: {res2}</div>
		</>
	);
}

export default App;
```

服务端开启跨域支持：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716706375003-776cf4d5-0c9a-40a8-94ab-7d4f1b78435e.png)

运行前端服务：

```typescript
pnpm run dev
```

请求成功了 3 个接口：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1716708088863-f715a360-bb40-4087-bc77-d965c666bccb.png)

我们可以将接口添加 header，刷新 token 逻辑放到 axios 拦截器去做：

```typescript
interface PendingTask {
    config: AxiosRequestConfig
    resolve: Function
}

let refreshing = false; // 标识是否正在刷新token
const queue: PendingTask[] = []; // 存储待处理的请求队列

// 添加响应拦截器
axiosInstance.interceptors.response.use(
    (response) => {
        return response; // 如果响应成功，直接返回响应
    },
    async (error) => {
        let { data, config } = error.response;

        if(refreshing) {
            // 如果正在刷新token，将请求加入队列等待
            return new Promise((resolve) => {
                queue.push({
                    config,
                    resolve
                });
            });
        }

        if (data.statusCode === 401 && !config.url.includes('/refresh')) {
            // 如果响应状态码为401且请求不是刷新token的请求，开始刷新token
            refreshing = true;
            
            const res = await refreshToken(); // 调用刷新token的函数

            refreshing = false; // 刷新token结束

            if(res.status === 200) {
                // 如果刷新token成功，重新发送队列中的请求
                queue.forEach(({config, resolve}) => {
                    resolve(axiosInstance(config))
                });

                return axiosInstance(config); // 重新发送当前请求
            } else {
                alert(data || '登录过期，请重新登录'); // 刷新token失败，提示用户重新登录
            }
        } else {
            return error.response; // 其他错误，返回错误响应
        }
    }
);

// 添加请求拦截器
axiosInstance.interceptors.request.use(function (config) {
    const accessToken = localStorage.getItem('access_token'); // 从本地存储获取access token

    if(accessToken) {
        config.headers.authorization = 'Bearer ' + accessToken; // 如果存在access token，将其添加到请求头中
    }
    return config; // 返回配置
});
```

加一个 refreshing 的标记，如果在刷新，那就返回一个 promise，并且把它的 resolve 方法还有 config 加到队列里。

当 refresh 成功之后，重新发送队列中的请求，并且把结果通过 resolve 返回。

保证多次失效请求只 refresh 一次了。

