# 使用 multer 实现文件上传

目标
- 在 Express 中实现基本的文件上传到本地磁盘。

依赖安装
```bash
npm i express multer
```

示例：upload.js
```js
const express = require('express');
const multer = require('multer');
const path = require('path');

const app = express();
const storage = multer.diskStorage({
  destination: 'uploads/',
  filename: (_req, file, cb) => cb(null, Date.now() + '-' + file.originalname),
});
const upload = multer({ storage });

app.post('/upload', upload.single('file'), (req, res) => {
  res.json({ file: req.file });
});

app.listen(3000, () => console.log('http://localhost:3000'));
```

要点
- 大文件与分片上传需结合分块校验与断点续传策略。
- 对外存储（S3/GCS）建议使用预签名 URL 减少服务端带宽占用。

