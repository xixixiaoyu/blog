# 文件上传与下载完全指南：从 Express 到 NestJS 的生产级实践

## 引言：为什么文件传输（尤其是大文件）是个难题？

文件传输是 Web 应用的常见功能，但当文件体积增大时，挑战也随之而来。其核心难题源于网络和设备的双重限制：

1.  **网络不稳定**：网络抖动或中断可能导致长耗时的传输失败，一切重头再来，成本极高。
2.  **资源限制**：浏览器和服务器的内存、CPU 资源有限。一次性加载、处理大文件极易导致客户端卡死或服务器内存溢出而崩溃。
3.  **用户体验**：用户需要清晰的进度反馈、快速的响应速度，以及在传输意外中断后能够继续传输的能力。
4.  **安全需求**：必须防止恶意上传、路径遍历等攻击，并确保数据在传输过程中的完整性与隐私。

解决这些问题的核心思路是 **化整为零** 和 **流式处理**。上传时将文件切成小块（分片）独立传输；下载时则通过流式传输，避免一次性将整个文件读入内存。

本文将从最基础的 Express 文件上传讲起，逐步过渡到 NestJS 中的优雅实现，最终深入探讨大文件分片上传、断-点续传、流式下载等一系列生产级解决方案。

---

## 第一部分：文件上传基础——Express 与 Multer

在 Node.js 生态中，`multer` 是处理 `multipart/form-data` 类型表单数据的首选中间件，尤其擅长文件上传。我们先从 Express 环境下使用 `multer` 开始，掌握其核心用法。

### 1. 环境搭建

首先，创建一个项目并安装必要的库：

```bash
mkdir express-multer-test
cd express-multer-test
npm init -y
npm install express multer cors
```

-   `express`：Node.js Web 应用框架。
-   `multer`：文件上传中间件。
-   `cors`：处理跨域资源共享（CORS）的中间件。

### 2. 单文件上传

**后端实现 (index.js)**

```javascript
const express = require('express')
const multer = require('multer')
const cors = require('cors')

const app = express()

// 允许所有来源的跨域请求
app.use(cors())

// 配置 multer，指定文件上传后存储的临时目录
const upload = multer({ dest: 'uploads/' })

// 创建 POST 路由，使用 upload.single('aaa') 中间件处理单个文件
// 'aaa' 是前端 FormData 中包含文件的字段名
app.post('/aaa', upload.single('aaa'), function (req, res, next) {
	console.log('文件信息:', req.file)
	console.log('其他表单字段:', req.body)
    res.send('上传成功')
})

app.listen(3333, () => {
    console.log('服务已启动于 http://localhost:3333')
})
```

**前端实现 (index.html)**

```html
<!DOCTYPE html>
<html lang="en">
	<head>
		<script src="https://unpkg.com/axios@0.24.0/dist/axios.min.js"></script>
	</head>
	<body>
		<input id="fileInput" type="file" />
		<script>
			const fileInput = document.querySelector('#fileInput')

			async function uploadFile() {
				const data = new FormData()
				data.set('name', 'Yun')
				data.set('age', 20)
				data.set('aaa', fileInput.files[0]) // 'aaa' 字段对应后端的 upload.single('aaa')

				const res = await axios.post('http://localhost:3333/aaa', data)
				console.log(res)
			}

			fileInput.onchange = uploadFile
		</script>
	</body>
</html>
```

当用户选择文件后，文件被上传到后端的 `uploads/` 目录下，同时服务器控制台会打印出文件信息 (`req.file`) 和其他表单数据 (`req.body`)。

### 3. 多文件上传

要支持一次上传多个文件，只需将 `upload.single` 换成 `upload.array`。

**后端实现**

```javascript
// 'bbb' 是字段名，3 是允许上传的最大文件数量
app.post('/bbb', upload.array('bbb', 3), function (req, res, next) {
	console.log('文件列表:', req.files) // 多文件信息在 req.files
	console.log('其他表单字段:', req.body)
    res.send('多文件上传成功')
})
```

**前端实现**

在 `input` 标签上添加 `multiple` 属性，并修改脚本以追加所有选中的文件。

```html
<input id="fileInput" type="file" multiple />
<script>
    // ...
    async function uploadMultipleFiles() {
        const data = new FormData()
        data.set('name', 'Yun')
        data.set('age', 20)
        
        // 遍历选中的文件并用 append 添加到同一个字段
        ;[...fileInput.files].forEach(item => {
            data.append('bbb', item) // 使用 append 而不是 set
        })

        const res = await axios.post('http://localhost:3333/bbb', data)
        console.log(res)
    }

    fileInput.onchange = uploadMultipleFiles
</script>
```

### 4. 多字段文件上传

如果表单包含多个不同的文件字段（例如，`avatar` 和 `gallery`），应使用 `upload.fields`。

**后端实现**

```javascript
app.post(
	'/ccc',
	upload.fields([
		{ name: 'avatar', maxCount: 1 },
		{ name: 'gallery', maxCount: 5 },
	]),
	function (req, res, next) {
        // req.files 是一个对象，key 是字段名，value 是文件数组
		console.log('多字段文件:', req.files) 
		console.log('其他表单字段:', req.body)
        res.send('多字段上传成功')
	}
)
```

前端只需在 `FormData` 中 `append` 对应字段的文件即可。

### 5. 自定义存储目录和文件名

`multer` 允许通过 `multer.diskStorage` 进行精细化控制。

```javascript
const fs = require('fs')
const path = require('path')

const storage = multer.diskStorage({
  // 设置存储目录
  destination: function (req, file, cb) {
    const uploadDir = path.join(process.cwd(), 'my-uploads')
    // 确保目录存在，不存在则创建
    try {
      fs.mkdirSync(uploadDir, { recursive: true })
    } catch (e) {}
    cb(null, uploadDir)
  },
  // 自定义文件名
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9)
    const extension = path.extname(file.originalname)
    // 最终文件名：原始文件名-时间戳.扩展名
    cb(null, `${path.basename(file.originalname, extension)}-${uniqueSuffix}${extension}`)
  },
})

const customUpload = multer({ storage: storage })

app.post('/ddd', customUpload.single('file'), (req, res) => {
    console.log('自定义存储的文件:', req.file)
    res.send('自定义存储成功')
})
```

---

## 第二部分：在 NestJS 中实现文件上传

NestJS 在底层默认使用 Express，因此文件上传功能也是基于 `multer` 实现的。但 NestJS 通过其强大的装饰器和管道（Pipe）机制，使得整个过程更加声明式和优雅。

### 1. 环境与配置

首先，创建一个新的 NestJS 项目并安装 `multer` 的类型定义：

```bash
nest new nest-multer-upload -p npm
cd nest-multer-upload
npm install @types/multer -D
```

为了方便调试，在 `main.ts` 中启用 CORS：

```typescript
// main.ts
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors(); // 启用跨域
  await app.listen(3000);
}
```

### 2. 单文件上传

在 Controller 中，使用 `@UseInterceptors` 和 `FileInterceptor` 装饰器来处理文件。

```typescript
// app.controller.ts
import { Controller, Post, UseInterceptors, UploadedFile, Body } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';

@Controller()
export class AppController {
  @Post('upload-single')
  @UseInterceptors(FileInterceptor('file', { dest: 'uploads' }))
  uploadSingleFile(
    @UploadedFile() file: Express.Multer.File,
    @Body() body,
  ) {
    console.log('文件:', file);
    console.log('正文:', body);
    return { success: true, file: file.path };
  }
}
```

-   `@UseInterceptors(FileInterceptor('file', ...))`: 拦截请求，并使用 `multer` 处理名为 `file` 的文件字段。`dest` 选项指定了存储目录。
-   `@UploadedFile()`: 将处理后的文件对象注入到 `file` 参数中。

### 3. 多文件上传

与 Express 类似，NestJS 提供了 `FilesInterceptor`（多文件）、`FileFieldsInterceptor`（多字段）和 `AnyFilesInterceptor`（任意文件）。

**多文件 (同一字段)**

```typescript
import { UploadedFiles } from '@nestjs/common'
import { FilesInterceptor } from '@nestjs/platform-express'

@Post('upload-multiple')
@UseInterceptors(FilesInterceptor('files', 10, { dest: 'uploads' })) // 最多 10 个文件
uploadMultipleFiles(@UploadedFiles() files: Array<Express.Multer.File>) {
  console.log('文件列表:', files);
  return { success: true, files: files.map(f => f.path) };
}
```

**多字段**

```typescript
import { UploadedFiles } from '@nestjs/common'
import { FileFieldsInterceptor } from '@nestjs/platform-express'

@Post('upload-fields')
@UseInterceptors(FileFieldsInterceptor([
  { name: 'avatar', maxCount: 1 },
  { name: 'gallery', maxCount: 8 },
], { dest: 'uploads' }))
uploadFileFields(
  @UploadedFiles() files: { avatar?: Express.Multer.File[], gallery?: Express.Multer.File[] },
) {
  console.log('多字段文件:', files);
  return { success: true };
}
```

### 4. 文件校验

NestJS 强大的管道（Pipe）系统非常适合用于文件校验。

**使用内置校验器**

NestJS 提供了 `ParseFilePipe` 以及一系列内置的 `FileValidator`，可以方便地对文件大小和类型进行校验。

```typescript
import { ParseFilePipe, MaxFileSizeValidator, FileTypeValidator } from '@nestjs/common';

@Post('upload-validated')
@UseInterceptors(FileInterceptor('file', { dest: 'uploads' }))
uploadAndValidate(
  @UploadedFile(
    new ParseFilePipe({
      validators: [
        // 校验文件大小（例如：小于 1MB）
        new MaxFileSizeValidator({ maxSize: 1024 * 1024 }),
        // 校验文件类型（例如：必须是 jpeg 或 png）
        new FileTypeValidator({ fileType: '.(png|jpeg|jpg)' }),
      ],
    }),
  )
  file: Express.Multer.File,
) {
  return { success: true, file: file.originalname };
}
```

如果上传的文件不满足条件，NestJS 会自动抛出一个 `400 Bad Request` 异常，并附带清晰的错误信息。

**自定义校验器**

你也可以通过继承 `FileValidator` 来创建自己的校验逻辑。

```typescript
import { FileValidator } from '@nestjs/common';

export class MyFileValidator extends FileValidator<{ maxSize: number }> {
  constructor(options: { maxSize: number }) {
    super(options);
  }

  isValid(file: Express.Multer.File): boolean {
    // 示例：文件名不能包含特殊字符
    const invalidChars = /[!@#$%^&*(),?":{}|<>]/;
    if (invalidChars.test(file.originalname)) {
      return false;
    }
    return true;
  }

  buildErrorMessage(file: Express.Multer.File): string {
    return `文件 ${file.originalname} 包含不允许的特殊字符。`;
  }
}
```

---

## 第三部分：生产级方案——大文件分片上传与下载

对于 GB 级别的大文件，直接上传和下载是不可行的。我们需要采用分片上传和流式下载的策略。

### 1. 分片上传：化整为零，高效可靠

分片上传是将一个大文件切割成多个小块（Chunk），逐块上传，最后在服务器端合并。这种方式有三大优势：

-   **高效**：可以并发上传多个分片，充分利用网络带宽。
-   **可靠**：支持断点续传。如果某个分片上传失败，只需重传该分片，而无需从头开始。
-   **秒传**：通过文件内容的哈希值作为唯一标识。如果服务器已存在相同哈希的文件，可以直接跳过上传，瞬间完成。

#### **前端实现：智能切片与上传控制**

前端的核心任务是：文件切片、计算哈希、并发控制和实现断点续传。

**步骤 1：增量计算文件哈希**

为了支持秒传和断点续传，我们需要为文件生成唯一标识——哈希值（如 MD5）。但不能一次性将整个大文件读入内存计算，这会导致浏览器崩溃。我们可以使用 `spark-md5` 这样的库，边读取分片边增量计算哈希。

```javascript
// 需要先安装 spark-md5: npm install spark-md5
import SparkMD5 from 'spark-md5';

async function calculateFileHash(file, chunkSize = 2 * 1024 * 1024) {
  const spark = new SparkMD5.ArrayBuffer();
  const fileReader = new FileReader();
  let currentChunk = 0;
  const chunks = Math.ceil(file.size / chunkSize);

  return new Promise((resolve, reject) => {
    function readNextChunk() {
      const start = currentChunk * chunkSize;
      const end = Math.min(start + chunkSize, file.size);
      const chunk = file.slice(start, end);

      fileReader.onload = (e) => {
        spark.append(e.target.result); // 增量追加分片数据
        currentChunk++;
        if (currentChunk < chunks) {
          readNextChunk();
        } else {
          const hash = spark.end(); // 所有分片处理完毕，计算最终哈希
          resolve(hash);
        }
      };

      fileReader.onerror = reject;
      fileReader.readAsArrayBuffer(chunk);
    }

    readNextChunk();
  });
}
```

**步骤 2：预校验与分片上传**

计算出哈希后，先向后端发送一个“预校验”请求。后端根据哈希判断：
1.  文件是否已存在（实现秒传）。
2.  如果文件部分存在，已上传了哪些分片（实现断点续传）。

```javascript
async function uploadFile(file, chunkSize = 2 * 1024 * 1024) {
  const hash = await calculateFileHash(file);
  const totalChunks = Math.ceil(file.size / chunkSize);

  // 1. 预校验
  const { isUploaded, uploadedChunks, uploadId } = await fetch('/api/upload/precheck', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ hash, fileName: file.name, totalChunks }),
  }).then(res => res.json());

  if (isUploaded) {
    console.log('文件已存在，秒传成功！');
    return;
  }

  // 2. 分片上传（带并发控制）
  const uploadPromises = [];
  for (let i = 0; i < totalChunks; i++) {
    // 跳过已上传的分片
    if (uploadedChunks.includes(i)) {
      continue;
    }

    const start = i * chunkSize;
    const end = Math.min(start + chunkSize, file.size);
    const chunk = file.slice(start, end);
    
    const formData = new FormData();
    formData.append('chunk', chunk);
    formData.append('index', i);
    formData.append('uploadId', uploadId);
    formData.append('hash', hash);

    const promise = fetch('/api/upload/chunk', {
      method: 'POST',
      body: formData,
    });
    uploadPromises.push(promise);
  }
  
  // 简易并发控制，生产环境建议使用 p-limit 等库
  await Promise.all(uploadPromises);

  // 3. 通知后端合并分片
  await fetch('/api/upload/merge', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ uploadId, hash, fileName: file.name }),
  });

  console.log('所有分片上传完毕，合并成功！');
}
```

**步骤 3：上传进度反馈**

为了提供更好的用户体验，我们可以监听每个分片的上传进度（使用 `axios` 的 `onUploadProgress` 事件）并计算总体进度。

#### **后端实现 (NestJS)：安全接收与高效合并**

后端需要安全地接收分片、临时存储、最终合并，并处理各种边界情况。

**目录结构**
- `uploads/`: 存放最终合并好的文件。
- `temp/`: 存放上传过程中的临时分片。

**步骤 1：预校验接口 (`/precheck`)**

此接口接收文件哈希，检查文件是否已存在。如果不存在，则为本次上传创建一个唯一的 `uploadId` 和一个临时目录，并返回已存在的分片列表。

```typescript
// upload.controller.ts
import { Controller, Post, Body, BadRequestException } from '@nestjs/common';
import { join } from 'path';
import { existsSync, mkdirSync, readdirSync } from 'fs';
import { v4 as uuidv4 } from 'uuid';

const UPLOAD_DIR = join(__dirname, '..', 'uploads');
const TEMP_DIR = join(__dirname, '..', 'temp');

@Controller('upload')
export class UploadController {
  // 模拟数据库，生产环境应使用 Redis 或数据库
  private fileRecords: Map<string, string> = new Map(); 

  @Post('precheck')
  precheck(@Body() body: { hash: string; fileName: string; totalChunks: number }) {
    const { hash, totalChunks } = body;

    // 检查秒传
    if (this.fileRecords.has(hash)) {
      return { isUploaded: true, filePath: this.fileRecords.get(hash) };
    }

    // 生成唯一 uploadId 和临时目录
    const uploadId = uuidv4();
    const tempDir = join(TEMP_DIR, uploadId);
    if (!existsSync(tempDir)) {
      mkdirSync(tempDir, { recursive: true });
    }

    // 检查已上传的分片
    const uploadedChunks = [];
    if (existsSync(tempDir)) {
        const files = readdirSync(tempDir);
        files.forEach(file => uploadedChunks.push(parseInt(file)));
    }

    return { uploadId, uploadedChunks, isUploaded: false };
  }
}
```

**步骤 2：接收分片接口 (`/chunk`)**

使用 `FileInterceptor` 接收分片，并根据 `uploadId` 和分片索引 `index` 将其保存到对应的临时目录。

```typescript
import { Body, BadRequestException, UploadedFile, UseInterceptors } from '@nestjs/common'
import { FileInterceptor } from '@nestjs/platform-express'
import { existsSync, writeFileSync } from 'fs'
import { join } from 'path'

@Post('chunk')
@UseInterceptors(FileInterceptor('chunk'))
uploadChunk(
  @UploadedFile() chunk: Express.Multer.File,
  @Body() body: { index: string; uploadId: string },
) {
  const { index, uploadId } = body;
  const tempDir = join(TEMP_DIR, uploadId);

  // 安全校验，确保临时目录存在
  if (!existsSync(tempDir)) {
    throw new BadRequestException('无效的 uploadId');
  }

  // 保存分片，文件名为分片索引
  writeFileSync(join(tempDir, index), chunk.buffer);
  return { success: true };
}
```

**步骤 3：合并分片接口 (`/merge`)**

所有分片上传完成后，前端调用此接口。后端读取临时目录中的所有分片，按顺序将它们合并成一个完整的文件，然后删除临时分片。

```typescript
import { BadRequestException } from '@nestjs/common'
import { existsSync, createReadStream, createWriteStream, readdirSync, rmSync } from 'fs'
import { join } from 'path'
import { pipeline } from 'stream/promises';

@Post('merge')
async mergeChunks(@Body() body: { uploadId: string; hash: string; fileName:string }) {
  const { uploadId, hash, fileName } = body;
  const tempDir = join(TEMP_DIR, uploadId);
  const finalFilePath = join(UPLOAD_DIR, `${hash}-${fileName}`);

  if (!existsSync(tempDir)) {
    throw new BadRequestException('合并失败：无效的 uploadId');
  }

const chunks = readdirSync(tempDir);
// 按分片索引排序
chunks.sort((a, b) => Number(a) - Number(b));

  const writeStream = createWriteStream(finalFilePath);

  try {
    for (const chunkName of chunks) {
      const chunkPath = join(tempDir, chunkName);
      const readStream = createReadStream(chunkPath);
      // 使用 pipeline 流式合并，内存占用极低
      await pipeline(readStream, writeStream, { end: false });
      readStream.close();
    }
  } finally {
    writeStream.end();
  }

  // 记录文件到数据库
  this.fileRecords.set(hash, finalFilePath);

  // 清理临时目录
  rmSync(tempDir, { recursive: true, force: true });

  return { success: true, filePath: finalFilePath };
}
```

### 2. 流式下载：细水长流，避免服务器崩溃

下载大文件时，如果一次性将文件全部读入内存再发送给客户端（如 `fs.readFileSync`），会造成巨大的内存压力，甚至导致服务器崩溃。正确的做法是**流式下载**：边从磁盘读取文件，边将其作为数据流发送给客户端。

NestJS 提供了优雅的 `StreamableFile` 类来简化这个过程。

```typescript
// download.controller.ts
import { Controller, Get, Header, Res, StreamableFile } from '@nestjs/common';
import { createReadStream, readFileSync } from 'fs';
import { join } from 'path';
import type { Response } from 'express';

const UPLOAD_DIR = join(__dirname, '..', 'uploads')

@Controller('download')
export class DownloadController {
  private readonly filePath = join(UPLOAD_DIR, 'large-file.zip');

  // 方式一：错误示范，内存爆炸！
  @Get('bad')
  downloadBad(@Res() res: Response) {
    const file = readFileSync(this.filePath); // 一次性读入内存
    res.header('Content-Disposition', 'attachment; filename="large-file.zip"');
    res.send(file);
  }

  // 方式二：标准 Node.js 流式下载
  @Get('good')
  @Header('Content-Disposition', 'attachment; filename="large-file.zip"')
  downloadGood(@Res({ passthrough: true }) res: Response) {
    const fileStream = createReadStream(this.filePath);
    fileStream.pipe(res); // 将可读流管道连接到响应可写流
  }

  // 方式三：NestJS 推荐的最佳实践
  @Get('best')
  @Header('Content-Disposition', 'attachment; filename="large-file.zip"')
  downloadBest(): StreamableFile {
    const fileStream = createReadStream(this.filePath);
    return new StreamableFile(fileStream); // NestJS 自动处理流和错误
  }
}
```

-   **方式一 (错误)**：绝对禁止在生产环境中使用，它会将整个文件加载到内存中。
-   **方式二 (标准)**：使用 Node.js 的 `stream.pipe()`，是可靠的流式处理方式。
-   **方式三 (最佳)**：`StreamableFile` 是 NestJS 对流式响应的封装，它会自动设置响应头，并处理流传输过程中的错误（如客户端提前关闭连接），代码最简洁、最健壮。

---

## 第四部分：进阶优化

为了让系统更加健壮和用户友好，我们还可以进行以下优化：

### 1. 错误重试机制

网络抖动可能导致个别分片上传失败。在前端的 `uploadChunk` 函数中加入重试逻辑可以显著提高上传成功率。

```javascript
async function uploadChunkWithRetry(formData, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await fetch('/api/upload/chunk', { method: 'POST', body: formData });
      return; // 成功则直接返回
    } catch (error) {
      console.warn(`分片上传失败，第 ${attempt} 次重试...`);
      if (attempt === maxRetries) throw error; // 达到最大次数则抛出错误
      await new Promise(resolve => setTimeout(resolve, 1000 * attempt)); // 延迟重试
    }
  }
}
```

### 2. 支持 HTTP Range 下载

对于视频播放、PDF 预览等场景，客户端可能只需要文件的一部分。通过支持 HTTP `Range` 请求，可以实现部分下载和断点续传下载。

```typescript
import { Req, Res } from '@nestjs/common';
import { statSync, createReadStream } from 'fs';
import type { Request, Response } from 'express';

@Get('range')
downloadRange(@Req() req: Request, @Res() res: Response) {
  const { size } = statSync(this.filePath);
  const range = req.headers.range;

  // 如果没有 range 请求头，则执行普通的全文件下载
  if (!range) {
    res.header('Content-Disposition', 'attachment; filename="large-file.zip"');
    const fileStream = createReadStream(this.filePath);
    fileStream.pipe(res);
    return;
  }

  // 解析 range
  const [startStr, endStr] = range.replace(/bytes=/, '').split('-');
  const start = parseInt(startStr, 10);
  const end = endStr ? parseInt(endStr, 10) : size - 1;
  const chunkSize = (end - start) + 1;

  // 设置 206 Partial Content 响应
  res.status(206).set({
    'Content-Range': `bytes ${start}-${end}/${size}`,
    'Accept-Ranges': 'bytes',
    'Content-Length': chunkSize,
    'Content-Type': 'application/octet-stream', // 根据文件类型设置
    'Content-Disposition': 'attachment; filename="large-file.zip"',
  });

  // 创建从 start 到 end 的可读流
  const fileStream = createReadStream(this.filePath, { start, end });
  fileStream.pipe(res);
}
```

### 3. 清理过期的临时分片

如果用户上传一半就关闭了页面，临时分片会残留在服务器上，浪费磁盘空间。我们可以设置一个定时任务（Cron Job）来定期清理这些过期的临时文件。

```typescript
// cleanup.service.ts
import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { readdirSync, statSync, rmSync } from 'fs';
import { join } from 'path';

@Injectable()
export class CleanupService {
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT) // 每天凌晨执行
  cleanupTempDir() {
    const dirs = readdirSync(TEMP_DIR);
    for (const dir of dirs) {
      const dirPath = join(TEMP_DIR, dir);
      const stats = statSync(dirPath);
      // 如果目录最后修改时间是 24 小时前，则视为过期
      const isExpired = Date.now() - stats.mtimeMs > 24 * 60 * 60 * 1000;
      if (isExpired) {
        rmSync(dirPath, { recursive: true, force: true });
        console.log(`已清理过期临时目录: ${dirPath}`);
      }
    }
  }
}
```
*别忘了在 `AppModule` 中导入 `ScheduleModule.forRoot()` 并将 `CleanupService` 加入 `providers`。*

### 4. 安全性加固

-   **HTTPS**：始终使用 HTTPS 加密传输，防止数据在传输过程中被窃取或篡改。
-   **权限校验**：所有上传和下载接口都应有严格的认证和授权检查。
-   **文件类型与大小限制**：在后端强制校验文件类型和大小，防止恶意用户上传可执行文件或超大文件耗尽服务器资源。
-   **路径遍历防护**：对所有涉及文件路径的参数（如 `uploadId`、`fileName`）进行严格校验，确保它们不会包含 `../` 等路径遍历字符。

---

## 总结

本文从 Express 的基础文件上传出发，逐步深入到 NestJS 中的高级应用，最终构建了一套完整的、生产级的解决方案。

核心思想可以归结为：

-   **简单场景**：对于中小型文件，直接使用 `multer` 配合 NestJS 的 `FileInterceptor` 和 `ParseFilePipe`，即可快速、安全地实现功能。
-   **复杂场景（大文件）**：
    -   **上传**：必须采用 **分片** 策略。前端负责文件切片、增量哈希和并发控制；后端负责预校验（秒传/断点续传）、接收分片、流式合并和临时文件清理。
    -   **下载**：必须采用 **流式处理**。利用 NestJS 的 `StreamableFile` 或 Node.js 的 `stream.pipe`，以极低的内存占用实现大文件下载。
-   **健壮性**：通过 **错误重试**、**Range 请求** 和 **定时清理** 等优化手段，全面提升系统的可靠性和用户体验。

掌握了这些从基础到进阶的知识，你将能够从容应对各种复杂的文件上传与下载需求。
