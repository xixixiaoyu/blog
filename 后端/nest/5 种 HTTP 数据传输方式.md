## 为什么需要不同的数据传输方式？
想象一下，前端需要向后端发送用户信息、搜索条件，或者上传一张图片。不同的数据类型和场景，就像不同的包裹：有的只需要一张便签（简单 ID），有的需要一个结构化的信封（复杂数据），有的甚至是大件行李（文件）。HTTP 提供了以下 5 种传输方式，分别应对不同的需求：

1. **URL 参数（URL Param）**：直接把数据嵌在 URL 路径里，适合传递简单的标识信息。
2. **查询参数（Query String）**：附加在 URL 后的键值对，适合搜索或筛选。
3. **表单编码（Form-urlencoded）**：传统表单提交的方式，适合简单数据。
4. **多部分表单（Form-data）**：专为文件上传和复杂表单设计。
5. **JSON**：现代 API 的主流，适合结构化数据。

每种方式都有对应的 **Content-Type**，告诉服务器如何解析数据。接下来，我们逐一拆解这 5 种方式，并用 NestJS 展示它们的实现。

---

## 一、URL 参数（URL Param）
### 原理
URL 参数是直接嵌入在 URL 路径中的数据，比如 `http://example.com/api/person/123`，这里的 `123` 就是参数。它简单直观，适合传递资源标识（如 ID 或用户名）。

### 适用场景
+ 获取特定资源，比如用户信息、文章详情。
+ RESTful API 中常用，例如 `/users/123` 表示获取 ID 为 123 的用户。

### 注意事项
+ 参数会暴露在 URL 中，可能被浏览器历史记录或服务器日志记录，**不适合敏感数据**。
+ 参数长度受 URL 长度限制（通常 2048 字符）。

### NestJS 实现
在 `src/person/person.controller.ts` 中：

```typescript
import { Controller, Get, Param } from '@nestjs/common';

@Controller('person')
export class PersonController {
  @Get(':id')
  getPersonById(@Param('id') id: string) {
    return { id, message: `Received ID: ${id}` };
  }
}
```

前端请求示例：

```javascript
axios.get('/api/person/123').then(res => console.log(res.data));
```

**输出**：`{ id: '123', message: 'Received ID: 123' }`

---

## 二、查询参数（Query String）
### 原理
查询参数附加在 URL 后，以 `?key1=value1&key2=value2` 的形式出现，比如 `http://example.com/api/person?name=张三&age=25`。它适合传递非敏感的筛选或分页条件。

### 适用场景
+ 搜索功能（例如搜索关键词）。
+ 分页（`?page=1&size=10`）。
+ 过滤条件（`?category=tech&sort=desc`）。

### 注意事项
+ 需要对中文或特殊字符进行 **URL 编码**，否则可能导致解析错误。
+ 参数也会暴露在 URL 中，安全性同 URL 参数。

### NestJS 实现
```typescript
import { Controller, Get, Query } from '@nestjs/common';

@Controller('person')
export class PersonController {
  @Get()
  getPersonByQuery(@Query() query: { name: string; age: string }) {
    return { name: query.name, age: query.age, message: 'Received query params' };
  }
}
```

前端请求示例：

```javascript
axios.get('/api/person?name=张三&age=25').then(res => console.log(res.data));
```

**输出**：`{ name: '张三', age: '25', message: 'Received query params' }`

**提示**：可以用 `query-string` 库自动处理编码：

```javascript
import qs from 'query-string';
const params = { name: '张三', age: 25 };
const url = `/api/person?${qs.stringify(params)}`;
axios.get(url).then(res => console.log(res.data));
```

---

## 三、表单编码（Form-urlencoded）
### 原理
表单编码将数据放在请求体中，格式类似查询参数（`key1=value1&key2=value2`），Content-Type 为 `application/x-www-form-urlencoded`。这是传统 HTML 表单的默认提交方式。

### 适用场景
+ 提交简单的表单数据（如用户名、密码）。
+ 轻量级数据传输，适合简单 POST 请求。

### 注意事项
+ 数据需要 URL 编码，特殊字符会增加传输体积。
+ 不适合传输文件或复杂嵌套数据。

### NestJS 实现
```typescript
import { Controller, Post, Body } from '@nestjs/common';
import { CreatePersonDto } from './dto/create-person.dto';

@Controller('person')
export class PersonController {
  @Post()
  createPerson(@Body() createPersonDto: CreatePersonDto) {
    return { ...createPersonDto, message: 'Received form-urlencoded data' };
  }
}
```

DTO 定义（`src/person/dto/create-person.dto.ts`）：

```typescript
export class CreatePersonDto {
  name: string;
  age: number;
}
```

前端请求示例：

```javascript
axios.post('/api/person', new URLSearchParams({ name: '李四', age: '30' }), {
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
}).then(res => console.log(res.data));
```

**输出**：`{ name: '李四', age: 30, message: 'Received form-urlencoded data' }`

---

## 四、多部分表单（Form-data）
### 原理
Form-data 使用 `multipart/form-data` 格式，将数据分成多个部分，每部分由 `boundary`（边界字符串）分隔。它可以传输文本、文件等二进制数据。

### 适用场景
+ 文件上传（如图片、视频）。
+ 复杂表单，包含文本和文件混合数据。

### 注意事项
+ 传输体积较大，适合大数据量场景。
+ 需要正确设置 boundary，现代框架会自动处理。

### NestJS 实现
需要安装 `@nestjs/platform-express` 和配置 `Multer`：

```bash
npm install @nestjs/platform-express
```

在 `main.ts` 中启用文件上传：

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  await app.listen(3000);
}
bootstrap();
```

控制器代码：

```typescript
import { Controller, Post, UploadedFiles, Body, UseInterceptors } from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';

@Controller('person')
export class PersonController {
  @Post('file')
  @UseInterceptors(FilesInterceptor('files'))
  uploadFile(@UploadedFiles() files: Express.Multer.File[], @Body() body: CreatePersonDto) {
    return {
      name: body.name,
      age: body.age,
      files: files.map(file => file.originalname),
      message: 'Received form-data'
    };
  }
}
```

前端请求示例：

```javascript
const formData = new FormData();
formData.append('name', '赵六');
formData.append('age', '35');
formData.append('files', document.querySelector('#fileInput').files[0]);

axios.post('/api/person/file', formData, {
  headers: { 'Content-Type': 'multipart/form-data' }
}).then(res => console.log(res.data));
```

**输出**：`{ name: '赵六', age: '35', files: ['example.jpg'], message: 'Received form-data' }`

---

## Five、JSON
### 原理
JSON 数据以 `application/json` 格式放在请求体中，结构清晰，易于表达复杂嵌套数据。它是现代 API 的主流选择。

### 适用场景
+ 前后端分离项目，传输复杂结构化数据。
+ RESTful API 的 POST、PUT 请求。

### 注意事项
+ 数据体积小，解析速度快。
+ 需要确保 JSON 格式正确，否则解析会失败。

### NestJS 实现
```typescript
import { Controller, Post, Body } from '@nestjs/common';
import { CreatePersonDto } from './dto/create-person.dto';

@Controller('person')
export class PersonController {
  @Post('json')
  createPersonJson(@Body() createPersonDto: CreatePersonDto) {
    return { ...createPersonDto, message: 'Received JSON data' };
  }
}
```

前端请求示例：

```javascript
axios.post('/api/person/json', { name: '王五', age: 30 }, {
  headers: { 'Content-Type': 'application/json' }
}).then(res => console.log(res.data));
```

**输出**：`{ name: '王五', age: 30, message: 'Received JSON data' }`

---

## Content-Type 一览表
| 传输方式 | Content-Type | 说明 |
| --- | --- | --- |
| URL 参数 | 无需设置 | 参数在 URL 路径中 |
| 查询参数 | 无需设置 | 参数在 URL 查询字符串中 |
| 表单编码 | `application/x-www-form-urlencoded` | 键值对格式，需 URL 编码 |
| 多部分表单 | `multipart/form-data; boundary=xxx` | 支持文件和文本，自动生成边界 |
| JSON | `application/json` | 结构化数据，现代 API 主流 |


---

## 实战：搭建 NestJS 项目
### 1. 初始化项目
```bash
npm i -g @nestjs/cli
nest new project-name
cd project-name
npm run start
```

### 2. 配置静态文件服务
在 `src/main.ts` 中：

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { join } from 'path';
import { NestExpressApplication } from '@nestjs/platform-express';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.useStaticAssets(join(__dirname, '..', 'public'), { prefix: '/static/' });
  app.enableCors();
  await app.listen(3000);
}
bootstrap();
```

创建 `public/index.html`，内容参考问题中的前端测试代码。

### 3. 数据验证
使用 `class-validator` 和 `ValidationPipe` 确保数据安全：

```bash
npm install class-validator class-transformer
```

在 `main.ts` 中启用全局验证：

```typescript
app.useGlobalPipes(new ValidationPipe());
```

更新 DTO：

```typescript
import { IsString, IsInt, Min } from 'class-validator';

export class CreatePersonDto {
  @IsString()
  name: string;

  @IsInt()
  @Min(0)
  age: number;
}
```

---

## 实际应用建议
1. **选择合适的传输方式**：
    - **URL 参数**：适合简单的资源标识，如 ID。
    - **查询参数**：适合搜索、过滤、分页。
    - **表单编码**：适合轻量表单提交。
    - **多部分表单**：文件上传或混合数据。
    - **JSON**：复杂数据和现代 API 的首选。
2. **安全性**：
    - 避免在 URL 中传递敏感信息（如密码），因为会被日志记录。
    - 使用 HTTPS 加密传输。
    - 对用户输入进行验证，防止注入攻击。
3. **性能优化**：
    - JSON 体积小、解析快，优先选择。
    - 文件上传使用 Form-data，必要时压缩文件。
    - 合理使用缓存（如 ETag 或 Redis）减少重复请求。
4. **调试技巧**：
    - 使用 Postman 或浏览器开发者工具检查请求头和响应。
    - 记录服务器日志，排查参数解析问题。

---

## 总结
HTTP 的 5 种数据传输方式各有千秋，理解它们的原理和适用场景，能帮助你设计更高效、更安全的 API。通过 NestJS 的实战代码，我们看到每种方式的实现都直观明了。无论是传递简单的 ID、复杂的 JSON，还是上传文件，选对方式就像选对快递，能让数据传输又快又稳。

