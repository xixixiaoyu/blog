# 使用 ws 构建聊天室最小版

目标
- 基于 ws 实现最小聊天服务，理解连接管理与广播。

依赖安装
```bash
npm i ws
```

示例：server.js
```js
const { WebSocketServer } = require('ws');
const wss = new WebSocketServer({ port: 3001 });

wss.on('connection', ws => {
  ws.on('message', msg => {
    // 广播给所有连接
    for (const client of wss.clients) {
      if (client.readyState === ws.OPEN) client.send(msg.toString());
    }
  });
  ws.send('Welcome!');
});

console.log('ws://localhost:3001');
```

要点
- 心跳与断线重连是生产必备；鉴权可通过初次消息或子协议实现。

