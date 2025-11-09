# dotenv 与多环境配置

目标
- 使用 dotenv 管理配置，并支持 dev/staging/prod 多环境。

依赖安装
```bash
npm i dotenv
```

示例：加载配置
```ts
// config.ts
import dotenv from 'dotenv';
dotenv.config({ path: `.env.${process.env.NODE_ENV || 'dev'}` });

export const config = {
  port: Number(process.env.PORT || 3000),
  dbUrl: process.env.DATABASE_URL || '',
};
```

.env.dev
```
PORT=3000
DATABASE_URL=postgresql://user:pass@localhost:5432/app
```

要点
- 明确优先级：环境变量 > .env 文件 > 默认值；敏感信息不入库。
- 建议对配置做校验（如使用 zod/yup）避免低级错误。

