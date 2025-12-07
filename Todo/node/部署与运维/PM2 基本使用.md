# PM2 基本使用

目标
- 使用 PM2 管理 Node 进程，支持日志、守护与集群模式。

安装
```bash
npm i -g pm2
```

常用命令
```bash
pm2 start app.js --name api
pm2 status
pm2 logs api
pm2 restart api
pm2 stop api
pm2 delete api
pm2 save # 保存当前进程列表（开机自启需要）
```

ecosystem.config.js 示例
```js
module.exports = {
  apps: [{
    name: 'api',
    script: 'dist/index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: { NODE_ENV: 'production' },
  }],
};
```

要点
- cluster 模式能利用多核，但需注意无状态与会话粘滞。
- 配合健康检查与零停机重启，提升发布稳定性。

