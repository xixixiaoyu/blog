## 实体关系映射
### 一对一关系
+ 使用 @OneToOne 和 @JoinColumn 注解来映射实体到数据库表，转换为表之间的外键关联。



### 一对多关系
+ 通过 @OneToMany 和 @ManyToOne 注解实现，不需要使用 @JoinColumn 指定外键列，因为外键自然存在于“多”的一方。



### 多对多关系
+ 多对多关系通过中间表实现，通过 @ManyToMany 注解，可以将多对多关系拆解为两个一对多关系：

![画板](https://cdn.nlark.com/yuque/0/2024/jpeg/21596389/1714553039031-65ba056e-19fd-48a3-b22e-46970837b5dc.jpeg)



## 多对多实体操作
### 初始化项目和配置数据库
```bash
npx typeorm@latest init --name typeorm-relation-mapping --database mysql
cd typeorm-relation-mapping
npm install mysql2
```



### 配置文件（data-source.ts）修改
```typescript
import 'reflect-metadata'
import { DataSource } from 'typeorm'
import { User } from './entity/User'

export const AppDataSource = new DataSource({
	type: 'mysql',
	host: 'localhost',
	port: 3306,
	username: 'root',
	password: 'xxx',
	database: 'typeorm_test',
	synchronize: true,
	logging: true,
	entities: [User],
	migrations: [],
	subscribers: [],
	poolSize: 10,
	connectorPackage: 'mysql2',
	extra: {
		authPlugin: 'sha256_password',
	},
})
```



### 创建实体生成表
这次我们创建 Article 和 Tag 两个实体：

```bash
npx typeorm entity:create src/entity/Article
npx typeorm entity:create src/entity/Tag
```

添加一些属性：

```typescript
// Article 实体
import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";

@Entity()
export class Article {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({
        length: 100,
        comment: '文章标题'
    })
    title: string;

    @Column({
        type: 'text',
        comment: '文章内容'
    })
    content: string;
}

// Tag 实体
import { Column, Entity, PrimaryGeneratedColumn } from "typeorm";

@Entity()
export class Tag {
    @PrimaryGeneratedColumn()
    id: number;

    @Column({
        length: 100
    })
    name: string;
}
```

data-source.ts 引入这两个 Entity：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687612979994-163732c7-47c5-42e4-8344-39e26a684371.png)

把 index.ts 的代码去掉：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687613003594-013d9224-0dfa-4aa1-853d-b36e09a87fb7.png)

然后 npm run start：

可以看到它生成了两个表：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714564362176-d4ba5e7d-01ad-4d4f-9885-efe9bd8e56d4.png)

我们将其删除，然后来添加多对多的关联关系。



### 配置多对多关系
通过 @ManyToMany 关联，比如一篇文章可以有多个标签：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714564828316-5b56029b-ac51-4568-b58d-dd2d26362790.png)

然后 npm run start：

会建三张表：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714564881966-14e27d97-4a0f-4531-98f1-65654c1c316f.png)

中间表 article_my_tags_tag 还有 2 个外键分别引用着两个表：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714564913585-0407e887-5d4c-4632-98b9-2a6431c44fc0.png)

级联删除和级联更新都是 CASCADE，也就是说这两个表的记录删了，那它在中间表中的记录也会跟着被删：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714564724776-9469a680-fdf8-49d6-a015-a7160053103e.png)

也可以自己指定中间表的名字：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714564963399-47a4f0bb-b025-47bf-92cd-4bda1432532c.png)



### 插入
```typescript
import { AppDataSource } from './data-source';
import { Article } from './entity/Article';
import { Tag } from './entity/Tag';

AppDataSource.initialize()
	.then(async () => {
		const article1 = new Article();
		article1.title = '标题一';
		article1.content = '内容一';

		const article2 = new Article();
		article2.title = '标题二';
		article2.content = '内容二';

		const tag1 = new Tag();
		tag1.name = '标签1';
		const tag2 = new Tag();
		tag2.name = '标签2';
		const tag3 = new Tag();
		tag3.name = '标签3';

    // 文章1 有两个 tag
		article1.myTags = [tag1, tag2];
    // 文章2 有三个 tag
		article2.myTags = [tag1, tag2, tag3];

		const entityManager = AppDataSource.manager;
		await entityManager.save([tag1, tag2, tag3]);
		await entityManager.save([article1, article2]);
	})
	.catch(error => console.log(error));
```

创建了两篇文章，3 个标签，建立它们的关系之后，会先保存所有的 tag，再保存 article。

npm run start 可以看到，3 个标签、2 篇文章，还有两者的关系，都插入成功了：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714565315799-5536c885-c765-46b9-9ca9-9a0167e55fee.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714565326049-9ae47624-6818-4b7c-a99d-a52c43594812.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714565341351-e64f4a6d-49a4-47d7-b50a-0532188f91d3.png)





### 查询
```typescript
const entityManager = AppDataSource.manager;

const article = await entityManager.find(Article, {
  relations: {
    myTags: true,
  },
});

console.log(article);
console.log(article.map(item => item.myTags));
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714565429167-0a6f4015-e7f9-4437-871f-98d5b7c0c275.png)

也可以手动用查询构建器（query builder）来获取数据，结果是一样的：

```typescript
const entityManager = AppDataSource.manager;

const article = await entityManager
  .createQueryBuilder(Article, 'a')
  .leftJoinAndSelect('a.myTags', 't')
  .getMany();

console.log(article);
console.log(article.map(item => item.myTags));
```

或者先拿到 Article 的 Repository 再创建 query builder 来查询也行：

```typescript
const entityManager = AppDataSource.manager;

const article = await entityManager
  .getRepository(Article)
  .createQueryBuilder('a')
  .leftJoinAndSelect('a.myTags', 't')
  .getMany();

console.log(article);
console.log(article.map(item => item.myTags));
```





### 更新
如果需要更新文章的标题和标签：

```typescript
const entityManager = AppDataSource.manager;

// 查询ID为2的文章，并包含其标签关系
const articleToUpdate = await entityManager.findOne(Article, {
  where: { id: 2 },
  relations: { myTags: true },
});
// 更新文章标题
articleToUpdate.title = '新标题';
// 筛选包含"标签1"的标签
articleToUpdate.myTags = articleToUpdate.myTags.filter(tag =>
  tag.name.includes('标签1')
);
// 保存更新后的文章
await entityManager.save(articleToUpdate);
```

运行后：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714565824425-9b18fe93-a02a-40ce-a59f-3b375f02e5d1.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714565868758-45cb99cc-57ed-4c21-a21d-82ffa4e2c1dd.png)

articleId 为 2 的新标题对应的 tagId 就只有 1 个了。



### 删除
对于删除操作，由于设置了 CASCADE 级联删除，删除文章或标签时相关的关联记录也会被自动删除：

```typescript
// 删除ID为1的文章记录
await entityManager.delete(Article, 1);
// 删除ID为1的标签记录
await entityManager.delete(Tag, 1);
```

第一行代码执行后：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714566174971-10ccdb5c-a1b2-462b-a5b0-e2605765cad0.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714566245524-2478abe1-8e20-447f-af7f-cd4da8f86fa7.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714566214091-0a101e2c-30ab-401f-a679-d3149ea4671b.png)

可以看到 article 表和中间表对应的数据都被删除。

第二行代码执行后：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714566363349-dde593ce-2397-4224-ab72-503e1cc14d8f.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714566373138-0a4e9f3c-fb11-47f9-a499-b0e06f779099.png)![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714566389616-e594aba9-8e5b-4e7c-8917-e7a2d3656ea8.png)

此时中间表的数据已经清空，代表两张表没有关联的内容了。



## 反向引用
如果 tag 里也想有文章的引用呢？那就再加一个 @ManyToMany 的映射属性：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714575232522-f8bc07f1-cf33-4c3f-a4fc-5ee0ff3ba0de.png)

需要第二个参数指定外键列在哪里。



article 里也要加：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714575268423-5f828b9b-1c8f-4898-a57f-8508ae9e92dc.png)

因为多对多的时候，双方都不维护外键，所以都需要第二个参数来指定外键列在哪里，怎么找到当前 Entity。



然后我们通过 tag 来关联查询下：

```typescript
const entityManager = AppDataSource.manager;

const tags = await entityManager.find(Tag, {
  relations: {
    myArticles: true,
  },
});

console.log(tags);
```

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1714576225796-0eb0c3c1-1c63-4609-9d13-4b39fca1f3e8.png)

成功关联查出来。



话说回来，之前一对一的时候， user 那方不维护外键，所以需要第二个参数来指定通过哪个外键找到 user：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687616719014-acd3240b-d65a-430d-9277-e34498069122.png)



一对多，一对应的 department 那方，不维护外键，所以需要第二个参数来指定通过哪个外键找到 department：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1687616799537-5a6748e1-f1fb-4242-84d6-6273ec26d792.png)

