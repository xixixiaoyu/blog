# Apollo Server 最小示例

目标
- 使用 @apollo/server 快速启动 GraphQL 服务。

依赖安装
```bash
npm i @apollo/server express body-parser cors
npm i -D tsx typescript @types/express
```

示例：server.ts
```ts
import express from 'express';
import { json } from 'body-parser';
import cors from 'cors';
import { ApolloServer } from '@apollo/server';
import { expressMiddleware } from '@apollo/server/express4';

const typeDefs = `#graphql
  type Query { hello: String }
`;

const resolvers = {
  Query: { hello: () => 'Hello GraphQL' },
};

const app = express();
app.use(cors());
app.use(json());

const server = new ApolloServer({ typeDefs, resolvers });
await server.start();
app.use('/graphql', expressMiddleware(server));

app.listen(4000, () => console.log('http://localhost:4000/graphql'));
```

要点
- 使用 Schema-First 或 Code-First 均可；复杂查询需结合 DataLoader 做批处理与缓存。

