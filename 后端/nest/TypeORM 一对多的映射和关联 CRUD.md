## 环境搭建
创建 typeorm 项目：

```bash
npx typeorm@latest init --name typeorm-relation-mapping2 --database mysql
```

进入项目目录，安装驱动包 mysql2：

```bash
npm install mysql2
```

修改 data-source.ts 文件，配置数据库连接信息：

```typescript
import "reflect-metadata"
import { DataSource } from "typeorm"
import { User } from "./entity/User"

export const AppDataSource = new DataSource({
  type: "mysql",
  host: "localhost",
  port: 3306,
  username: "root",
  password: "xxx",
  database: "typeorm_test",
  synchronize: true,
  logging: true,
  entities: [User],
  migrations: [],
  subscribers: [],
  poolSize: 10,
  connectorPackage: 'mysql2',
  extra: {
    authPlugin: 'sha256_password',
  }
})
```



## 实体创建与映射
创建 Department 和 Employee 两个实体：

```bash
npx typeorm entity:create src/entity/Department
npx typeorm entity:create src/entity/Employee
```

在 Department 和 Employee 实体中添加映射信息：

```typescript
// Department 实体
import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";

@Entity()
export class Department {
   @PrimaryGeneratedColumn()
   id: number;

   @Column({ length: 50 })
   name: string;
}

// Employee 实体
import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";

@Entity()
export class Employee {
   @PrimaryGeneratedColumn()
   id: number;

   @Column({ length: 50 })
   name: string;
}
```

把这俩 Entity 添加到 DataSource 里：

```typescript
import 'reflect-metadata'
import { DataSource } from 'typeorm'
import { User } from './entity/User'
import { Department } from './entity/Department'
import { Employee } from './entity/Employee'

export const AppDataSource = new DataSource({
	type: 'mysql',
	host: 'localhost',
	port: 3306,
	username: 'root',
	password: 'xxx',
	database: 'typeorm_test',
	synchronize: true,
	logging: true,
	entities: [Department, Employee],
	migrations: [],
	subscribers: [],
	poolSize: 10,
	connectorPackage: 'mysql2',
	extra: {
		authPlugin: 'sha256_password',
	},
})
```

index.ts 代码清空：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687602337960-c2a38523-c038-43c7-ab43-40232dc066fd.png)

然后 npm run start：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687602420767-81800182-dde8-4fd7-8420-0ac59a62bcaa.png)

这两个表都创建成功了。



## 添加一对多关系映射
在多的一方使用 @ManyToOne 装饰器：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687602526253-999c2bc7-9e83-449a-927c-629156a30596.png)



把这两个表删掉：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687602567759-bf0ff95b-0b50-4ed6-a447-9b514c99a307.png)

重新 npm run start：

mysql workbench 可以看到这个外键：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687602721151-39ee6dda-11f1-4ff4-ab77-f7f010ea3314.png)



## 一对多的 CRUD 操作
### 初始化和保存数据
引入相关实体和数据源，然后初始化数据源：

```typescript
import { Department } from './entity/Department';
import { Employee } from './entity/Employee';
import { AppDataSource } from "./data-source";

AppDataSource.initialize().then(async () => {
    // 数据初始化和保存的逻辑
}).catch(error => console.log(error));
```



### 添加并保存实体
创建一个部门和几个员工实例，并将员工分配给该部门：

```typescript
const d1 = new Department();
d1.name = '技术部';

const e1 = new Employee();
e1.name = '张三';
e1.department = d1;

const e2 = new Employee();
e2.name = '李四';
e2.department = d1;

const e3 = new Employee();
e3.name = '王五';
e3.department = d1;

await AppDataSource.manager.save(Department, d1);
await AppDataSource.manager.save(Employee, [e1, e2, e3]);
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687603051524-3a713306-d8ea-4ca6-835c-a059ae21fadb.png)

可以看到被 transaction 包裹的 4 条 insert 语句，分别插入 1 了 Department 和 3 个 Employee。



### 建立多对多的外键关联并设置级联保存
我们在 Department 实体中使用 @OneToMany 装饰器声明关系这是“一的一方”，不维护外键关系。

通过第二个参数指定外键列在哪里。并设置 cascade 选项，简化保存逻辑：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687603444964-98035b0d-1914-4340-9caa-c26aa1d3b4c6.png)



多的那一方，即 Employee 会自动添加外键，可以通过 @JoinColumn 来修改外键列的名字：

```typescript
@JoinColumn({
  name: 'd_id',
})
@ManyToOne(() => Department)
department: Department;
```



这样当保存 department 的时候，关联的 employee 也会保存：

```typescript
const e1 = new Employee();
e1.name = '张三';

const e2 = new Employee();
e2.name = '李四';

const e3 = new Employee();
e3.name = '王五';

const d1 = new Department();
d1.name = '技术部';
d1.employees = [e1, e2, e3];

await AppDataSource.manager.save(Department, d1);
```



### 关联查询
查询所有部门：

```typescript
const deps = await AppDataSource.manager.find(Department)
console.log(deps)
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687603714571-e1beeaa6-67a8-4515-93c9-d2d8e601d53f.png)

想要关联查询员工需要声明下 relations：

```typescript
const deps = await AppDataSource.manager.find(Department, {
  relations: {
    employees: true,
  },
})
console.log(deps)
console.log(deps.map(item => item.employees))
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687603768040-33149efc-137f-417a-9ac9-fe3a292cf234.png)

这个 relations 其实就是 left join on。



或者使用 QueryBuilder 进行更灵活的关联查询：

```typescript
const es = await AppDataSource.manager
  .getRepository(Department)
  .createQueryBuilder('d')
  .leftJoinAndSelect('d.employees', 'e')
  .getMany()

console.log(es)
console.log(es.map(item => item.employees))
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687603895017-1657dc9f-7c44-4417-b664-af618930c5bd.png)

也可以直接用 EntityManager 创建 QueryBuilder：

```typescript
const es = await AppDataSource.manager
  .createQueryBuilder(Department, 'd')
  .leftJoinAndSelect('d.employees', 'e')
  .getMany()

console.log(es)
console.log(es.map(item => item.employees))
```

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687603986260-be1cf8a3-84c3-432a-b518-e0cf16bbd9d8.png)



### 删除数据
在删除数据时，如果设置了 onDelete 为 SET NULL 或 CASCADE，我们就只要删除主表（一的那一方）对应的 Entity 就好了，msyql 会做后续的关联删除或者 id 置空：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687604307471-49f57a2b-e525-4ab7-8fd2-f509c9cb4f19.png)

否则就要先删除所有的从表（多的那一方）对应的 Entity 再删除主表对应的 Entity：

```typescript
const deps = await AppDataSource.manager.find(Department, {
    relations: {
        employees: true
    }
});
await AppDataSource.manager.delete(Employee, deps[0].employees);
await AppDataSource.manager.delete(Department, deps[0].id);
```



