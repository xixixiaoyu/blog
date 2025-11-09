我们学了 etcd 来做配置中心和注册中心，它比较简单，就是 key 的 put、get、del、watch 这些。

虽然简单，它却是微服务体系必不可少的组件：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705837060292-e38deba9-ce64-465f-a1fb-c94f0bbb7a85.png)

服务注册、发现、配置集中管理，都是用它来做。



下面我们就来写一下：

```typescript
nest new nest-etcd
```

进入项目，安装 etcd3：

```typescript
npm i etcd3
```

把服务跑起来：

```typescript
npm run start:dev
```

把 etcd 服务跑起来：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705837175030-fcec16d5-58e2-47cc-a648-ec20c5ff5ef2.png)

然后我们加一个 etcd 的 provider：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705837415108-54260025-5319-4b2f-9b63-53348a3a7838.png)

在 AppController 里注入下：

```typescript
import { Controller, Get, Inject, Query } from '@nestjs/common';
import { AppService } from './app.service';
import { Etcd3 } from 'etcd3';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Inject('ETCD_CLIENT')
  private etcdClient: Etcd3;

  @Get('put')
  async put(@Query('value') value: string) {
    await this.etcdClient.put('aaa').value(value);
    return 'done';
  }

  @Get('get')
  async get() {
    return await this.etcdClient.get('aaa').string();
  }

  @Get('del')
  async del() {
    await this.etcdClient.delete().key('aaa');
    return 'done';
  }
}
```

测试下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705837520633-01ff4b7b-e945-4aaa-9301-4ba9f30d5700.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705837541965-1669cbb1-ee4d-4b3a-9236-6668827f6db1.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705837552544-457aca2c-8e90-42bd-bd42-66bd5fe0d42a.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705837568473-b1410b6a-ce04-43e8-9029-2cdf461ed2a7.png)

这样 etcd 就集成好了，很简单。

然后我们封装一个动态模块。

创建一个 module 和 service：

```bash
nest g module etcd
nest g service etcd
```

在 EtcdModule 添加 etcd 的 provider：

```typescript
import { Module } from '@nestjs/common';
import { EtcdService } from './etcd.service';
import { Etcd3 } from 'etcd3';

@Module({
  providers: [
    EtcdService,
    {
      provide: 'ETCD_CLIENT',
      useFactory() {
        const client = new Etcd3({
          hosts: 'http://localhost:2379',
          auth: {
            username: 'root',
            password: 'yun',
          },
        });
        return client;
      },
    },
  ],
  exports: [EtcdService],
})
export class EtcdModule {}
```

然后在 EtcdService 添加一些方法：

```typescript
import { Inject, Injectable } from '@nestjs/common';
import { Etcd3 } from 'etcd3';

@Injectable()
export class EtcdService {
  @Inject('ETCD_CLIENT')
  private client: Etcd3;

  // 保存配置
  async saveConfig(key, value) {
    await this.client.put(key).value(value);
  }

  // 读取配置
  async getConfig(key) {
    return await this.client.get(key).string();
  }

  // 删除配置
  async deleteConfig(key) {
    await this.client.delete().key(key);
  }

  // 服务注册
  async registerService(serviceName, instanceId, metadata) {
    const key = `/services/${serviceName}/${instanceId}`;
    const lease = this.client.lease(10);
    await lease.put(key).value(JSON.stringify(metadata));
    lease.on('lost', async () => {
      console.log('租约过期，重新注册...');
      await this.registerService(serviceName, instanceId, metadata);
    });
  }

  // 服务发现
  async discoverService(serviceName) {
    const instances = await this.client
      .getAll()
      .prefix(`/services/${serviceName}`)
      .strings();
    return Object.entries(instances).map(([key, value]) => JSON.parse(value));
  }

  // 监听服务变更
  async watchService(serviceName, callback) {
    const watcher = await this.client
      .watch()
      .prefix(`/services/${serviceName}`)
      .create();
    watcher
      .on('put', async (event) => {
        console.log('新的服务节点添加:', event.key.toString());
        callback(await this.discoverService(serviceName));
      })
      .on('delete', async (event) => {
        console.log('服务节点删除:', event.key.toString());
        callback(await this.discoverService(serviceName));
      });
  }
}
```

配置的管理、服务注册、服务发现、服务变更的监听，这些我们都写过一遍，就不细讲了。

然后再创建个模块，引入它试一下：

```typescript
nest g resource aaa
```

引入 EtcdModule：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705837824458-d0cca900-f47d-4ef2-b3a9-628a9766bc05.png)

然后在 AaaController 注入 EtcdService，添加两个 handler：

```typescript
import { Controller, Get, Inject, Query } from '@nestjs/common';
import { AaaService } from './aaa.service';
import { EtcdService } from 'src/etcd/etcd.service';

@Controller('aaa')
export class AaaController {
  constructor(private readonly aaaService: AaaService) {}

  @Inject(EtcdService)
  private etcdService: EtcdService;

  @Get('save')
  async saveConfig(@Query('value') value: string) {
    await this.etcdService.saveConfig('aaa', value);
    return 'done';
  }

  @Get('get')
  async getConfig() {
    return await this.etcdService.getConfig('aaa');
  }
}
```

测试下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705837985282-f98f5fb4-048c-4519-9b10-4d5e085d0ce4.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705838009106-133a4589-4225-44e3-b078-a41ccf3763b5.png)

没啥问题。



不过现在 EtcdModule 是普通的模块，我们改成动态模块：

```typescript
import { DynamicModule, Module } from '@nestjs/common';
import { EtcdService } from './etcd.service';
import { Etcd3, IOptions } from 'etcd3';

export const ETCD_CLIENT_TOKEN = 'ETCD_CLIENT';
export const ETCD_CLIENT_OPTIONS_TOKEN = 'ETCD_CLIENT_OPTIONS';

@Module({})
export class EtcdModule {
  static forRoot(options?: IOptions): DynamicModule {
    return {
      module: EtcdModule,
      providers: [
        EtcdService,
        {
          provide: ETCD_CLIENT_TOKEN,
          useFactory(options: IOptions) {
            const client = new Etcd3(options);
            return client;
          },
          inject: [ETCD_CLIENT_OPTIONS_TOKEN],
        },
        {
          provide: ETCD_CLIENT_OPTIONS_TOKEN,
          useValue: options,
        },
      ],
      exports: [EtcdService],
    };
  }
}
```

把 EtcdModule 改成动态模块的方式，加一个 forRoot 方法。

把传入的 options 作为一个 provider，然后再创建 etcd client 作为一个 provider。

然后 AaaModule 引入 EtcdModule 的方式也改下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705838596341-3152d9a7-fa0a-4efa-a1e3-646f6ab63f15.png)

用起来和之前是一样的，但是现在 etcd 的参数是动态传入的了，这就是动态模块的好处。

当然，一般动态模块都有 forRootAsync，我们也加一下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705838682996-57e08d5d-b7e0-4d07-b373-d62d6f40c3b9.png)

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705838767926-a33b157a-4841-40e5-8d5a-49b79afa411e.png)

和 forRoot 的区别就是现在的 options 的 provider 是通过 useFactory 的方式创建的，之前是直接传入。

现在就可以这样传入 options 了：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705838814855-fbf39499-d855-4b1b-867b-46d1932ffdc7.png)

我们安装下 config 的包

```typescript
npm install @nestjs/config
```

在 AppModule 引入 ConfigModule：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705838882851-a65ef174-db11-4af4-8ead-95e28974826e.png)

添加对应的 src/.env

```typescript
etcd_hosts=http://localhost:2379
etcd_auth_username=root
etcd_auth_password=yun
```

然后在引入 EtcdModule 的时候，从 ConfigService 拿配置：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705839076976-09031bd8-73b1-4969-9b17-f4d71b87998e.png)

测试下：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1705839136579-5342d0de-71c6-43d5-b8da-30c61c8ad1c1.png)

功能正常。

这样，EtcdModule.forRootAsync 就成功实现了。



## 总结
这节我们做了 Nest 和 etcd 的集成。

或者加一个 provider 创建连接，然后直接注入 etcdClient 来 put、get、del、watch。

或者再做一步，封装一个动态模块来用，用的时候再传入连接配置

和集成 Redis 的时候差不多。

注册中心和配置中心是微服务体系必不可少的组件，后面会大量用到。

