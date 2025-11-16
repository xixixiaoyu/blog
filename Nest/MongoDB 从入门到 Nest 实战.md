## 前言

不同于传统的关系型数据库如 MySQL，数据存储在表格里，类似于 Excel 电子表格，其中数据按行（记录）和列（字段）组织。

MongoDB 是一种非关系型数据库，使用文档存储（document store），以类似 JSON 格式存储数据。

## 核心概念

+ **数据库（database）**：数据库是一个数据仓库，数据库服务下可以创建很多数据库，数据库中可以存放很多集合。
+ **集合（collection）**：集合类似于 JS 中的数组，在集合中可以存放很多文档。
+ **文档（document）**：文档是数据库中的最小单位，类似于 JS 中的对象，文档可以包含不同的数据类型（如字符串、数字、数组、嵌套文档等）和复杂的嵌套结构。

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710674313627-5b0fe936-8683-4d0b-afcf-31c7fc102892.png)

+ **BSON**：MongoDB 使用 BSON，一种类似于 JSON 的二进制格式（比 JSON 更多的数据类型，如日期和二进制数据类型），用于存储和传输 MongoDB 中的文档。
+ **索引（Index）**：索引支持对 MongoDB 集合中的数据进行快速搜索。默认情况下，每个集合都有一个对 `_id` 字段的自动索引。其他索引需要根据查询的需要手动添加。
+ **复制集（Replica Set）**：复制集是 MongoDB 中的数据冗余和备份机制，用于提高数据的可用性。复制集中的数据自动同步，确保所有副本都保存最新数据。在主节点故障时，复制集可以自动选举新的主节点，保证数据库的可用性。
+ **分片（Sharding）**：分片是 MongoDB 中的一种水平扩展方法。它涉及将数据分布在多个服务器上，每个服务器上存储数据集的一部分。分片可以提高大数据集的处理能力和吞吐量。
+ **聚合（Aggregation）**：聚合是一种强大的数据处理工具，用于执行复杂的数据搜索、过滤、分组和排序等操作。MongoDB 提供了聚合管道，允许用户定义一个数据处理的多阶段管道，每个阶段对数据进行操作并传递给下一阶段。
+ **操作符（Operators）**：在查询和更新文档时，操作符用于指定操作的类型。例如查询操作符（如 `$gt`、`$lt` 用于比较），更新操作符（如 `$set` 用于设置字段值），逻辑操作符（如 `$and`、`$or`）等。

## 安装与运行

### Docker 安装

首先，我们需要在 Docker Desktop 中搜索 `mongodb` 镜像：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1699806861129-e45bec59-3e0c-4fd5-905a-fa1f56aa1039.png)

运行容器，指定容器名、映射的端口号，以及挂载到 `/data/db` 目录：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1699807065175-4c9d0cda-1c18-42f6-8bb6-8d7fffecc3e1.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1699807206309-286289ff-d38f-4ff4-b2b6-45a9f458da26.png)

### 普通安装

+ **下载地址**：[Download MongoDB Community Server](https://www.mongodb.com/try/download/community)
+ 建议选择 zip 类型，通用性更强。配置步骤如下：
    - 将压缩包移动到 `C:\Program Files` 下，然后解压。
    - 创建 `C:\data\db` 目录，MongoDB 会将数据默认保存在这个文件夹。
    - 以 MongoDB 中 `bin` 目录作为工作目录，启动命令行。
    - 运行命令 `mongod`。

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1680056806229-2c2f7975-6b5a-4fdc-bca1-0f580bffccb9.png)

看到最后的 `waiting for connections` 则表明服务已经启动成功。

然后可以使用 `mongo` 命令连接本机的 MongoDB 服务：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1680056853971-f27d88b3-dbb2-43f2-a954-9c96f24254cd.png)

**注意**：

+ 为了方便后续使用 `mongod` 命令，可以将 `bin` 目录配置到环境变量 `Path` 中。
+ 千万不要选中服务端窗口的内容，选中会停止服务，可以敲回车取消选中。

## Mongo Compass 图形化界面

MongoDB 提供了官方的 GUI 工具——Mongo Compass，通过图形界面，用户就可以不敲命令来管理数据库了。

下载官方 GUI 工具 [Mongo Compass](https://link.juejin.cn/?target=https%3A%2F%2Fwww.mongodb.com%2Fproducts%2Ftools%2Fcompass)：

连接上 MongoDB 的 server：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1699809559979-a2d0cab5-37c6-49b4-943d-360703949474.png)

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1699809850190-b0f7b284-8de7-4305-abde-1b2df4ebeeef.png)

在 GUI 工具里操作就很方便直观了。可以看到所有的 database、collection、document。

在这里输入过滤条件后点击 find：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1699809899787-839e2c71-28b3-427c-bd5b-4bd0fbc1e6e0.png)

更新和删除也都很直观：

![](https://cdn.nlark.com/yuque/0/2023/png/21596389/1699809980913-19fd8c6d-4dd4-4493-bed6-9fcb4c5042bd.png)

## 在 Node.js 中使用 Mongoose

在 Node.js 中，我们通常会使用 `mongoose` 这个第三方库来操作 MongoDB 数据库。

### 初始化项目

创建项目并安装 `mongoose`：

```bash
mkdir mongoose-test
cd mongoose-test
npm init -y
npm install mongoose
```

### 连接数据库与操作数据

在 MongoDB 中，集合中的文档可以采用任意结构。因此，我们需要先定义一个 **Schema** 来描述我们想要存储的数据结构，然后根据这个 Schema 创建 **Model**，以便进行增删改查（CRUD）操作。

创建并用 `node` 运行 `index.js` 文件：

```javascript
const mongoose = require('mongoose');

main().catch(err => console.error(err));

async function main() {
	// 连接到本地 MongoDB 实例的 'yun' 数据库
	await mongoose.connect('mongodb://localhost:27017/yun');

	// 定义一个 Person 的 Schema，描述文档结构
	const PersonSchema = new mongoose.Schema({
		name: String,
		age: Number,
    gender: String,
		hobbies: [String],
	});

	// 根据 Schema 创建一个 Model
	const Person = mongoose.model('Person', PersonSchema);

	// 创建两个 Person 文档实例并保存到数据库
	const yun = new Person({ name: '云牧', age: 20 });
	const dai = new Person({ name: '黛玉', age: 21, hobbies: ['reading', 'play'] });

	await yun.save();
	await dai.save();

	// 查询数据库中的所有 Person 记录
	const persons = await Person.find();
	console.log(persons);
}
```

### Schema 字段类型与验证

Schema 支持多种字段类型：

![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710673636782-19697149-78e1-4588-a488-3e36ad1bfaa0.png)

Mongoose 还可以使用对象形式对字段值进行更丰富的验证：

```javascript
const PersonSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true, // 设置为必填字段
        trim: true, // 自动去除字符串两端的空格
        lowercase: true, // 自动将字符串转为小写
        unique: true, // 字段值必须唯一
        minlength: 2, // 最小长度限制
        maxlength: 50, // 最大长度限制
        // 自定义验证器
        validate: {
            validator: function(v) {
                return /[a-zA-Z]/.test(v); // 只允许字母
            },
            message: props => `${props.value} is not a valid name!`
        },
        default: '匿名' // 默认值
    },
    gender: {
      type: String,
      enum: ['男', '女'] // 值必须是枚举数组中的一个
    },
    age: Number,
    hobbies: [String],
});
```

### CRUD 操作

#### 增加 (Create)

```javascript
// 插入单条
PersonModel.create({ name: '张三' });

// 批量插入
PersonModel.insertMany([{ name: '李四' }, { name: '王五' }]);
```

#### 删除 (Delete)

```javascript
// 删除单条
PersonModel.deleteOne({ _id: 'some-id' });

// 批量删除
PersonModel.deleteMany({ name: '张三' });
```

#### 更新 (Update)

```javascript
// 更新单条
PersonModel.updateOne({ _id: 'some-id' }, { age: 30 });

// 批量更新
PersonModel.updateMany({ name: '李四' }, { age: 31 });
```

#### 查询 (Read)

```javascript
// 查询单条
PersonModel.findOne({ name: '张三' });

// 根据 ID 查询
PersonModel.findById('some-id');

// 查询所有
PersonModel.find();

// 条件查询
PersonModel.find({ age: { $gt: 18 } });
```

### 条件与高级查询

**比较运算符**

+ `>`: `$gt` (greater than)
+ `<`: `$lt` (less than)
+ `>=`: `$gte` (greater than or equal)
+ `<=`: `$lte` (less than or equal)
+ `!==`: `$ne` (not equal)

**逻辑运算**

+ `$or`: 逻辑或，`{ $or: [{ age: 18 }, { age: 24 }] }`
+ `$and`: 逻辑与，`{ $and: [{ age: { $lt: 20 } }, { age: { $gt: 15 } }] }`

**正则匹配**

```javascript
db.students.find({ name: /imissyou/ });
```

**个性化读取**

```javascript
PersonModel.find()
  .select({ _id: 0, name: 1, age: 1 }) // 字段筛选：0-排除，1-包含
  .sort({ age: -1 }) // 排序：1-升序，-1-降序
  .skip(10) // 跳过前 10 条
  .limit(10) // 限制返回 10 条
  .exec(); // 执行查询
```

## 在 NestJS 中集成 Mongoose

### 初始化项目

创建项目并安装所需依赖：

```bash
nest new nest-mongoose -p npm
cd nest-mongoose
npm install @nestjs/mongoose mongoose
npm install class-validator class-transformer
npm run start:dev
```

### 配置 MongooseModule

在 `app.module.ts` 中引入 `MongooseModule` 并配置数据库连接：

```typescript
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

@Module({
  imports: [MongooseModule.forRoot('mongodb://localhost:27017/yun')],
  // ... other modules
})
export class AppModule {}
```

### 构建 Dog 模块

使用 Nest CLI 创建一个完整的 `dog` 资源模块：

```bash
nest g resource dog --no-spec
```

#### 1. 定义实体 (Entity)

在 `src/dog/entities/dog.entity.ts` 中定义 `Dog` 实体：

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

@Schema()
export class Dog {
  @Prop()
  name: string;

  @Prop()
  age: number;

  @Prop([String])
  tags: string[];
}

export type DogDocument = HydratedDocument<Dog>;
export const DogSchema = SchemaFactory.createForClass(Dog);
```

#### 2. 定义数据传输对象 (DTO)

在 `src/dog/dto/create-dog.dto.ts` 中定义数据验证规则：

```typescript
import { IsNotEmpty, IsNumber, IsString, Length } from 'class-validator';

export class CreateDogDto {
  @IsString()
  @IsNotEmpty()
  @Length(3)
  name: string;

  @IsNumber()
  @IsNotEmpty()
  age: number;

  tags: string[];
}
```

#### 3. 注册 Schema

在 `dog.module.ts` 中注册 `Dog` Schema：

```typescript
import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Dog, DogSchema } from './entities/dog.entity';
import { DogService } from './dog.service';
import { DogController } from './dog.controller';

@Module({
  imports: [MongooseModule.forFeature([{ name: Dog.name, schema: DogSchema }])],
  controllers: [DogController],
  providers: [DogService],
})
export class DogModule {}
```

#### 4. 实现服务 (Service)

在 `dog.service.ts` 中注入 `Dog` 模型并实现 CRUD 逻辑：

```typescript
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Dog } from './entities/dog.entity';
import { CreateDogDto } from './dto/create-dog.dto';
import { UpdateDogDto } from './dto/update-dog.dto';

@Injectable()
export class DogService {
  @InjectModel(Dog.name)
  private dogModel: Model<Dog>;

  create(createDogDto: CreateDogDto) {
    const dog = new this.dogModel(createDogDto);
    return dog.save();
  }

  findAll() {
    return this.dogModel.find();
  }

  findOne(id: string) {
    return this.dogModel.findById(id);
  }

  update(id: string, updateDogDto: UpdateDogDto) {
    return this.dogModel.findByIdAndUpdate(id, updateDogDto, { new: true });
  }

  remove(id: string) {
    return this.dogModel.findByIdAndDelete(id);
  }
}
```

#### 5. 控制器 (Controller)

`dog.controller.ts` 由 CLI 生成，基本无需修改，它会调用 `DogService` 中对应的方法。

### 使用 Postman 测试

现在，你可以启动应用 (`npm run start:dev`) 并使用 Postman 等工具测试你的 API：

*   **创建 (POST)**: `http://localhost:3000/dog`
    ![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710667248088-a56881ad-43b9-4a7e-9502-349167b0a99e.png)

*   **查询所有 (GET)**: `http://localhost:3000/dog`
    ![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710667487674-5a7501e9-6116-407e-a28a-d7f30cddbb9f.png)

*   **查询单个 (GET)**: `http://localhost:3000/dog/:id`
    ![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710667519635-1e908e13-624b-413e-a7a0-3e35c2a7f606.png)

*   **更新 (PATCH)**: `http://localhost:3000/dog/:id`
    ![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710667642490-621cd6db-0757-4a63-a170-3b34a8e00166.png)

*   **删除 (DELETE)**: `http://localhost:3000/dog/:id`
    ![](https://cdn.nlark.com/yuque/0/2024/png/21596389/1710667784861-5cc1fbf4-dc11-43d5-b8ef-a2503ae1193e.png)

至此，你已经掌握了在 NestJS 项目中集成 MongoDB 并实现完整业务功能的流程。

## 命令行操作 (附录)

直接使用命令行操作数据库的场景较少，可作为了解。

通过 `mongosh` 命令进入 MongoDB 的交互式界面：

*   `show dbs` / `show databases`: 显示所有数据库。
*   `use <db_name>`: 切换或创建数据库。
*   `db`: 查看当前数据库。
*   `db.createCollection('collection_name')`: 创建集合。
*   `show collections`: 显示当前库中所有集合。
*   `db.collection_name.drop()`: 删除集合。
*   `db.dropDatabase()`: 删除数据库。
*   `db.collection_name.insert({ doc })`: 插入文档。
*   `db.collection_name.find({ query })`: 查询文档。
*   `db.collection_name.update({ query }, { $set: { new_data } })`: 更新文档。
*   `db.collection_name.remove({ query })`: 删除文档。
